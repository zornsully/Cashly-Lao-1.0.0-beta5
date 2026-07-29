[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^v\d+\.\d+\.\d+$')]
    [string]$ReleaseTag,
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Fa-f0-9:\s]{64,95}$')]
    [string]$ExpectedAndroidCertificateSha256,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Checked {
    param([Parameter(Mandatory)][scriptblock]$Command, [Parameter(Mandatory)][string]$Description)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE." }
}

function Get-PubspecVersion {
    param([Parameter(Mandatory)][string]$Path)
    $source = Get-Content -LiteralPath $Path -Raw
    if ($source -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') {
        throw 'pubspec.yaml must declare a stable version and positive build number, for example 1.2.3+4.'
    }
    return @{ Version = $Matches[1]; BuildNumber = $Matches[2] }
}

function Resolve-AndroidTool {
    param([Parameter(Mandatory)][string]$ToolName)
    $configured = if ($ToolName -eq 'apksigner') { $env:APKSIGNER_PATH } else { $env:AAPT_PATH }
    if ($configured -and (Test-Path -LiteralPath $configured -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $configured).Path
    }

    $sdkDirectory = $env:ANDROID_HOME
    if (-not $sdkDirectory) { $sdkDirectory = $env:ANDROID_SDK_ROOT }
    $localProperties = Join-Path $projectRoot 'android\local.properties'
    if (-not $sdkDirectory -and (Test-Path -LiteralPath $localProperties -PathType Leaf)) {
        $local = Get-Content -LiteralPath $localProperties -Raw
        if ($local -match '(?m)^sdk\.dir=(.+)$') {
            $sdkDirectory = $Matches[1].Trim() -replace '\\', '\'
        }
    }
    if (-not $sdkDirectory) { throw "Android SDK was not found. Set ANDROID_HOME or configure android/local.properties before validating $ToolName." }

    $isWindowsHost = $env:OS -eq 'Windows_NT'
    $exe = if ($ToolName -eq 'aapt' -and $isWindowsHost) { 'aapt.exe' } elseif ($ToolName -eq 'apksigner' -and $isWindowsHost) { 'apksigner.bat' } else { $ToolName }
    $candidates = Get-ChildItem -LiteralPath (Join-Path $sdkDirectory 'build-tools') -Directory |
        Sort-Object -Property Name -Descending |
        ForEach-Object { Join-Path $_.FullName $exe } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
    if (-not $candidates) { throw "Could not find $ToolName in Android build-tools under $sdkDirectory." }
    return $candidates[0]
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required to prepare an immutable release.' }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter is required to build the signed APK.' }
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw 'Dart is required to validate the release.' }

    $tagCommit = (& git rev-list -n 1 $ReleaseTag).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $tagCommit) { throw "Release tag $ReleaseTag does not exist locally." }
    $headCommit = (& git rev-parse HEAD).Trim()
    if ($headCommit -ne $tagCommit) { throw "HEAD ($headCommit) is not the immutable $ReleaseTag commit ($tagCommit). Check out the tag before building." }
    $trackedChanges = & git status --porcelain --untracked-files=no
    if ($trackedChanges) { throw 'Tracked source changes are present. Build only from a clean immutable tag checkout.' }

    $appVersion = Get-PubspecVersion (Join-Path $projectRoot 'pubspec.yaml')
    if ($ReleaseTag -ne "v$($appVersion.Version)") { throw "Release tag $ReleaseTag does not match pubspec version $($appVersion.Version)." }

    if (-not $OutputDirectory) { $OutputDirectory = "build\manual-release\$ReleaseTag" }
    $outputPath = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory } else { Join-Path $projectRoot $OutputDirectory }
    if (Test-Path -LiteralPath $outputPath) { throw "Evidence directory already exists: $outputPath. Do not overwrite versioned release evidence." }
    New-Item -ItemType Directory -Path $outputPath | Out-Null

    Invoke-Checked { flutter pub get } 'Dependency restore'
    Invoke-Checked { flutter gen-l10n } 'Localization generation'
    $previousCi = $env:CI
    $env:CI = 'true'
    try {
        Invoke-Checked { flutter build apk --release } 'Signed Android APK build'
    } finally {
        if ($null -eq $previousCi) {
            Remove-Item Env:CI -ErrorAction SilentlyContinue
        } else {
            $env:CI = $previousCi
        }
    }

    $builtApk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path -LiteralPath $builtApk -PathType Leaf)) { throw 'Flutter did not produce app-release.apk.' }
    $artifactName = "Cashly-Lao-Android-$($appVersion.Version).apk"
    $artifactPath = Join-Path $outputPath $artifactName
    Copy-Item -LiteralPath $builtApk -Destination $artifactPath -ErrorAction Stop

    $env:APKSIGNER_PATH = Resolve-AndroidTool 'apksigner'
    $env:AAPT_PATH = Resolve-AndroidTool 'aapt'
    $evidencePath = Join-Path $outputPath 'release-evidence.json'
    Invoke-Checked {
        dart run tool/verify_release.dart `
            --tag $ReleaseTag `
            --ref $tagCommit `
            --artifact "android=$artifactPath" `
            --require-artifacts `
            --verify-android-signature `
            --expected-android-certificate-sha256 $ExpectedAndroidCertificateSha256 `
            --output $evidencePath
    } 'Signed APK validation'

    $checksum = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToUpperInvariant()
    [System.IO.File]::WriteAllText((Join-Path $outputPath 'SHA256SUMS.txt'), "$checksum  $artifactName`n", [System.Text.UTF8Encoding]::new($false))
    $notesPath = Join-Path $projectRoot 'RELEASE_NOTES.md'
    if (-not (Test-Path -LiteralPath $notesPath -PathType Leaf)) { throw 'RELEASE_NOTES.md is required for release evidence.' }
    Copy-Item -LiteralPath $notesPath -Destination (Join-Path $outputPath 'RELEASE_NOTES.md')
    $notesChecksum = (Get-FileHash -LiteralPath $notesPath -Algorithm SHA256).Hash.ToUpperInvariant()

    $evidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    $evidence | Add-Member -NotePropertyName sourceRepository -NotePropertyValue 'zornsully/Cashly-Lao-1.0.0-beta5' -Force
    $evidence | Add-Member -NotePropertyName releaseNotesSha256 -NotePropertyValue $notesChecksum -Force
    $evidence | Add-Member -NotePropertyName preparedAt -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
    [System.IO.File]::WriteAllText(
        $evidencePath,
        (($evidence | ConvertTo-Json -Depth 10) + "`n"),
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Output "Prepared local evidence for $ReleaseTag at $outputPath."
    Write-Output "APK: $artifactName"
    Write-Output "SHA-256: $checksum"
    Write-Output 'No GitHub Release, public download link, Firebase deployment, or website metadata was changed.'
    Write-Output 'Stop here and obtain explicit approval before running publish_github_release.ps1.'
} finally {
    Pop-Location
}
