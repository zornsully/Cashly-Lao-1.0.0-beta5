[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})/[A-Za-z0-9._-]+$')]
    [string]$DistributionRepository,
    [Parameter(Mandatory)]
    [string]$PackageDirectory,
    [switch]$ApprovePublicRelease
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Require-File {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Description)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Description was not found at $Path." }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Gh {
    param([Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$Description)
    $output = & gh @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE." }
    return $output
}

if (-not $ApprovePublicRelease) {
    throw 'Refusing to create a public GitHub Release without -ApprovePublicRelease. Obtain explicit owner approval after reviewing the signed APK, certificate fingerprint, checksum, size, version, and notes.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is required. Sign in locally with gh auth login first.' }
    $policyPath = Join-Path $projectRoot 'assets\release\distribution_policy.json'
    $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
    if ($policy.schemaVersion -ne 1 -or $policy.repository -ne $DistributionRepository) {
        throw 'The requested repository does not exactly match the reviewed assets/release/distribution_policy.json policy. Do not publish.'
    }

    $packagePath = (Resolve-Path -LiteralPath $PackageDirectory).Path
    $evidencePath = Require-File (Join-Path $packagePath 'release-evidence.json') 'Release evidence'
    $checksumsPath = Require-File (Join-Path $packagePath 'SHA256SUMS.txt') 'Checksum list'
    $notesPath = Require-File (Join-Path $packagePath 'RELEASE_NOTES.md') 'Reviewed release notes'
    $evidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    if ($evidence.channel -ne 'stable' -or $evidence.tag -notmatch '^v\d+\.\d+\.\d+$') {
        throw 'Only a locally validated stable release evidence file can be published.'
    }
    $releaseTag = [string]$evidence.tag
    $version = [string]$evidence.version
    $artifact = @($evidence.artifacts | Where-Object { $_.platform -eq 'android' })
    if ($artifact.Count -ne 1) { throw 'Release evidence must contain exactly one Android artifact.' }
    $artifactName = [string]$artifact[0].artifactName
    $artifactPath = Require-File (Join-Path $packagePath $artifactName) 'Signed Android APK'
    if ([System.IO.Path]::GetExtension($artifactPath) -ine '.apk') { throw 'Only an APK may be published in this development release channel.' }
    $actualHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actualHash -ne ([string]$artifact[0].sha256).ToUpperInvariant()) { throw 'The APK no longer matches its validated release evidence checksum.' }
    if ((Get-Item -LiteralPath $artifactPath).Length -ne [int64]$artifact[0].fileSizeBytes) { throw 'The APK size no longer matches its validated release evidence.' }
    $checksumLine = "(?m)^$([regex]::Escape($actualHash))  $([regex]::Escape($artifactName))$"
    if ((Get-Content -LiteralPath $checksumsPath -Raw) -notmatch $checksumLine) { throw 'SHA256SUMS.txt does not contain the exact validated APK checksum and filename.' }

    $repository = (Invoke-Gh -Arguments @('repo', 'view', $DistributionRepository, '--json', 'nameWithOwner,isPrivate,isArchived') -Description 'Distribution repository inspection') -join "`n" | ConvertFrom-Json
    if ($repository.nameWithOwner -ne $DistributionRepository -or $repository.isPrivate -or $repository.isArchived) {
        throw 'The approved distribution repository must exist, be public, and not be archived.'
    }

    & gh release view $releaseTag --repo $DistributionRepository *> $null
    if ($LASTEXITCODE -eq 0) { throw "Release $releaseTag already exists. Never overwrite, retag, or append to a versioned public release." }

    # Upload occurs only after the approval switch above. The draft gives the
    # operator a private verification point; no website metadata changes here.
    Invoke-Gh -Arguments @(
        'release', 'create', $releaseTag,
        $artifactPath, $checksumsPath, $evidencePath, $notesPath,
        '--repo', $DistributionRepository,
        '--draft',
        '--title', "Cashly Lao $version",
        '--notes-file', $notesPath
    ) -Description 'Private draft release creation' | Out-Null

    $draftDirectory = Join-Path $packagePath 'draft-download-verification'
    if (Test-Path -LiteralPath $draftDirectory) { throw 'Draft verification directory already exists. Do not overwrite release evidence.' }
    New-Item -ItemType Directory -Path $draftDirectory | Out-Null
    Invoke-Gh -Arguments @(
        'release', 'download', $releaseTag,
        '--repo', $DistributionRepository,
        '--pattern', $artifactName,
        '--dir', $draftDirectory
    ) -Description 'Authenticated draft APK download' | Out-Null
    $draftApk = Require-File (Join-Path $draftDirectory $artifactName) 'Draft APK download'
    if ((Get-FileHash -LiteralPath $draftApk -Algorithm SHA256).Hash.ToUpperInvariant() -ne $actualHash) {
        throw 'The uploaded draft APK checksum differs from the locally validated artifact. The release remains draft and the website was not changed.'
    }

    Invoke-Gh -Arguments @('release', 'edit', $releaseTag, '--repo', $DistributionRepository, '--draft=false') -Description 'Public release publication' | Out-Null
    $release = (Invoke-Gh -Arguments @('api', "repos/$DistributionRepository/releases/tags/$releaseTag") -Description 'Public release inspection') -join "`n" | ConvertFrom-Json
    $expectedReleaseUrl = "https://github.com/$DistributionRepository/releases/tag/$releaseTag"
    $expectedDownloadUrl = "https://github.com/$DistributionRepository/releases/download/$releaseTag/$artifactName"
    if ($release.draft -or $release.prerelease -or $release.html_url -ne $expectedReleaseUrl) {
        throw 'GitHub did not report the expected public stable release. The website was not changed.'
    }
    $publishedAsset = @($release.assets | Where-Object { $_.name -eq $artifactName })
    if ($publishedAsset.Count -ne 1 -or $publishedAsset[0].browser_download_url -ne $expectedDownloadUrl -or [int64]$publishedAsset[0].size -ne [int64]$artifact[0].fileSizeBytes) {
        throw 'GitHub release asset metadata does not match the expected immutable APK. The website was not changed.'
    }
    foreach ($requiredAssetName in @($artifactName, 'SHA256SUMS.txt', 'release-evidence.json', 'RELEASE_NOTES.md')) {
        if (@($release.assets | Where-Object { $_.name -eq $requiredAssetName }).Count -ne 1) {
            throw "The public release is missing the required $requiredAssetName asset. The website was not changed."
        }
    }

    $anonymousPath = Join-Path $packagePath "anonymous-$artifactName"
    Invoke-WebRequest -Uri $expectedDownloadUrl -OutFile $anonymousPath -MaximumRedirection 5 -Headers @{ 'Cache-Control' = 'no-cache' }
    if ((Get-FileHash -LiteralPath $anonymousPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $actualHash -or (Get-Item -LiteralPath $anonymousPath).Length -ne [int64]$artifact[0].fileSizeBytes) {
        throw 'Anonymous public APK verification failed. The release is public, but website metadata remains unchanged and must not be updated.'
    }

    $publicationEvidence = [ordered]@{
        releaseTag = $releaseTag
        distributionRepository = $DistributionRepository
        releaseUrl = $expectedReleaseUrl
        downloadUrl = $expectedDownloadUrl
        sha256 = $actualHash
        fileSizeBytes = [int64]$artifact[0].fileSizeBytes
        verifiedAt = [DateTime]::UtcNow.ToString('o')
    } | ConvertTo-Json -Depth 5
    Write-Utf8NoBom -Path (Join-Path $packagePath 'public-release-verification.json') -Content ($publicationEvidence + "`n")

    Write-Output "Public GitHub Release verified: $expectedReleaseUrl"
    Write-Output 'The website remains unchanged. Obtain a second explicit approval before running publish_web_metadata.ps1.'
} finally {
    Pop-Location
}
