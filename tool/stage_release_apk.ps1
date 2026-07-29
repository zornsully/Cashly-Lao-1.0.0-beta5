[CmdletBinding()]
param(
    [string]$Source = 'build\app\outputs\flutter-apk\app-release.apk',
    [string]$Destination,
    [switch]$AllowPreviewHostingStaging
)

# This helper is intentionally blocked by default. Production APK delivery is
# GitHub Release based and approval gated; Firebase ZIP staging is available
# only for a local preview bundle with an explicit acknowledgement.
if (-not $AllowPreviewHostingStaging) {
    throw 'Legacy Firebase APK staging is preview-only. Use the approved GitHub Actions release workflow for production, or pass -AllowPreviewHostingStaging for a local preview bundle.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot $Source

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $pubspec = Get-Content -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Raw
    if ($pubspec -notmatch '(?m)^version:\s*([^\s+]+)') {
        throw 'Unable to read the application version from pubspec.yaml.'
    }
    $Destination = "build\web\downloads\cashly-lao-v$($Matches[1]).apk.zip"
}

$destinationPath = if ([System.IO.Path]::IsPathRooted($Destination)) {
    $Destination
} else {
    Join-Path $projectRoot $Destination
}

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Release APK was not found at $sourcePath. Build the Android release before staging it."
}

$destinationDirectory = Split-Path -Parent $destinationPath
New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
Compress-Archive -LiteralPath $sourcePath -DestinationPath $destinationPath -Force

$stagedApk = Get-Item -LiteralPath $destinationPath
Write-Output "Staged $($stagedApk.Name) ($($stagedApk.Length) bytes) for Firebase Hosting."
