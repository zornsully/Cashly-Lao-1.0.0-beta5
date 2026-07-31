# Deploys website-only content to Firebase Hosting (hosting:cashly-lao).
#
# This is the pre-approved, narrowly-scoped path described in CLAUDE.md's
# "Website-only content deploys" section: landing page, legal pages, FAQ,
# screenshots, website localization, other static web assets, and web-only
# bug/accessibility/responsive fixes. It deliberately refuses to run if the
# change touches any release-trust file -- those changes belong to the
# manual, two-approval-gate release pipeline (tool/publish_web_metadata.ps1),
# not this script.
#
# Deployment uses whichever local `firebase login` session is available in
# the environment running this script. No credentials are read from or
# written to this repository.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Paths that mark a change as release-related rather than content-only. Any
# match here is a hard stop back to the manual release pipeline.
$guardedPathPrefixes = @(
    'web/release-manifest.json'
    'assets/release/'
    'android/app/build.gradle'
    'android/key.properties'
    'android/app/upload-keystore.jks'
)

function Test-GuardedPath {
    param([Parameter(Mandatory)][string]$Path)
    $normalized = $Path -replace '\\', '/'
    foreach ($prefix in $guardedPathPrefixes) {
        if ($normalized -eq $prefix -or $normalized.StartsWith($prefix)) { return $true }
    }
    return $false
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    foreach ($command in 'flutter', 'firebase', 'git') {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "$command is required to deploy the website."
        }
    }

    Write-Output 'Checking for release-trust file changes...'
    $changedPaths = New-Object System.Collections.Generic.List[string]

    $porcelain = & git status --porcelain=v1
    foreach ($line in $porcelain) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $entry = $line.Substring(3).Trim('"')
        if ($entry -match '->') { $entry = ($entry -split '->')[1].Trim().Trim('"') }
        $changedPaths.Add($entry)
    }

    & git fetch origin --quiet 2>$null
    $mergeBase = $null
    try {
        $mergeBase = (& git merge-base HEAD origin/main 2>$null)
    } catch {
        $mergeBase = $null
    }
    if ($LASTEXITCODE -eq 0 -and $mergeBase) {
        $committedDiff = & git diff --name-only $mergeBase HEAD
        foreach ($entry in $committedDiff) {
            if (-not [string]::IsNullOrWhiteSpace($entry)) { $changedPaths.Add($entry) }
        }
    } else {
        throw 'Could not determine committed changes against origin/main (git fetch/merge-base failed). Refusing to deploy without being able to check for release-trust file changes.'
    }

    $guardedHits = $changedPaths | Where-Object { Test-GuardedPath -Path $_ } | Sort-Object -Unique
    if ($guardedHits.Count -gt 0) {
        throw "Refusing a content-only deploy: this change touches release-trust path(s): $($guardedHits -join ', '). Use the manual release pipeline (tool/publish_web_metadata.ps1) instead."
    }

    Write-Output 'Running flutter analyze...'
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed. Not deploying.' }

    Write-Output 'Running flutter test...'
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed. Not deploying.' }

    Write-Output 'Building the production web bundle...'
    & flutter build web --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build web failed. Not deploying.' }

    Write-Output 'Confirming the configured Firebase Hosting target...'
    $firebaseRcPath = Join-Path $projectRoot '.firebaserc'
    $firebaseRc = Get-Content -LiteralPath $firebaseRcPath -Raw | ConvertFrom-Json
    $configuredTargets = $firebaseRc.targets.'cashly-lao'.hosting.'cashly-lao'
    if (-not $configuredTargets -or ($configuredTargets -notcontains 'cashly-lao')) {
        throw 'Firebase Hosting target "cashly-lao" is not configured in .firebaserc as expected. Not deploying.'
    }

    Write-Output 'Deploying hosting:cashly-lao...'
    & firebase deploy --only hosting:cashly-lao --project cashly-lao
    if ($LASTEXITCODE -ne 0) { throw 'firebase deploy failed.' }

    Write-Output 'Verifying the live website...'
    Start-Sleep -Seconds 3
    $response = Invoke-WebRequest -Uri 'https://cashly-lao.web.app/' -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
    if ($response.StatusCode -ne 200) {
        throw "Live site check failed: https://cashly-lao.web.app/ returned HTTP $($response.StatusCode)."
    }

    Write-Output ''
    Write-Output 'Deployed and verified: https://cashly-lao.web.app/'
    Write-Output 'Record this deployment in CLAUDE.md under "Website-only content deploys" (date/time, files changed, tests run, deployment result).'
}
finally {
    Pop-Location
}
