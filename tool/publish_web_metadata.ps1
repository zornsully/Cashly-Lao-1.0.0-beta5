[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})/[A-Za-z0-9._-]+$')]
    [string]$DistributionRepository,
    [Parameter(Mandatory)]
    [string]$PackageDirectory,
    [switch]$ApproveWebsiteMetadata,
    [switch]$DeployToSpark,
    [switch]$ApproveSparkDeployment
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Require-File {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Description)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Description was not found at $Path." }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Invoke-GhJson {
    param([Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$Description)
    $output = & gh @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE." }
    return (($output -join "`n") | ConvertFrom-Json)
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

if (-not $ApproveWebsiteMetadata) {
    throw 'Refusing to update website download metadata without -ApproveWebsiteMetadata. This must be a separate owner approval after the public APK has been verified.'
}
if ($DeployToSpark -and -not $ApproveSparkDeployment) {
    throw 'Refusing Firebase Spark deployment without -ApproveSparkDeployment.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$metadataApplied = $false
$deploymentStarted = $false
$websiteManifest = $null
$backupPath = $null
Push-Location $projectRoot
try {
    foreach ($command in 'gh', 'dart', 'flutter') {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "$command is required to update verified website metadata." }
    }
    if ($DeployToSpark -and -not (Get-Command firebase -ErrorAction SilentlyContinue)) {
        throw 'Firebase CLI is required for an approved Spark deployment. Sign in locally with firebase login first.'
    }

    $policyPath = Join-Path $projectRoot 'assets\release\distribution_policy.json'
    $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
    if ($policy.schemaVersion -ne 1 -or $policy.repository -ne $DistributionRepository) {
        throw 'The requested repository does not exactly match the reviewed bundled distribution policy. The website remains unchanged.'
    }

    $packagePath = (Resolve-Path -LiteralPath $PackageDirectory).Path
    $evidencePath = Require-File (Join-Path $packagePath 'release-evidence.json') 'Local release evidence'
    $notesPath = Require-File (Join-Path $packagePath 'RELEASE_NOTES.md') 'Reviewed release notes'
    $publicationPath = Require-File (Join-Path $packagePath 'public-release-verification.json') 'Public release verification'
    $evidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    $publication = Get-Content -LiteralPath $publicationPath -Raw | ConvertFrom-Json
    $releaseTag = [string]$evidence.tag
    if ($evidence.channel -ne 'stable' -or $releaseTag -notmatch '^v\d+\.\d+\.\d+$' -or $publication.releaseTag -ne $releaseTag -or $publication.distributionRepository -ne $DistributionRepository) {
        throw 'Local release evidence and public release verification do not describe the same stable target.'
    }
    $artifact = @($evidence.artifacts | Where-Object { $_.platform -eq 'android' })
    if ($artifact.Count -ne 1) { throw 'Release evidence must contain exactly one Android artifact.' }
    $artifactName = [string]$artifact[0].artifactName
    $expectedHash = ([string]$artifact[0].sha256).ToUpperInvariant()
    $expectedSize = [int64]$artifact[0].fileSizeBytes
    $expectedReleaseUrl = "https://github.com/$DistributionRepository/releases/tag/$releaseTag"
    $expectedDownloadUrl = "https://github.com/$DistributionRepository/releases/download/$releaseTag/$artifactName"

    $release = Invoke-GhJson -Arguments @('api', "repos/$DistributionRepository/releases/tags/$releaseTag") -Description 'Public GitHub Release inspection'
    if ($release.draft -or $release.prerelease -or $release.html_url -ne $expectedReleaseUrl) {
        throw 'The GitHub release is not the expected public stable release. The website remains unchanged.'
    }
    $remoteAsset = @($release.assets | Where-Object { $_.name -eq $artifactName })
    if ($remoteAsset.Count -ne 1 -or $remoteAsset[0].browser_download_url -ne $expectedDownloadUrl -or [int64]$remoteAsset[0].size -ne $expectedSize) {
        throw 'GitHub public asset metadata does not match the locally validated artifact. The website remains unchanged.'
    }

    $anonymousArtifact = Join-Path $packagePath "metadata-anonymous-$artifactName"
    if (Test-Path -LiteralPath $anonymousArtifact) {
        throw "Anonymous metadata-verification file already exists: $anonymousArtifact. Do not overwrite release evidence."
    }
    Invoke-WebRequest -Uri $expectedDownloadUrl -OutFile $anonymousArtifact -MaximumRedirection 5 -Headers @{ 'Cache-Control' = 'no-cache' }
    if ((Get-FileHash -LiteralPath $anonymousArtifact -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedHash -or (Get-Item -LiteralPath $anonymousArtifact).Length -ne $expectedSize) {
        throw 'Anonymous GitHub asset verification failed. The website remains unchanged.'
    }

    $artifactMetadataPath = Join-Path $packagePath 'public-artifacts.json'
    $artifactMetadata = [ordered]@{
        artifacts = @([ordered]@{
            platform = 'android'
            artifactName = $artifactName
            fileSizeBytes = $expectedSize
            sha256 = $expectedHash
            downloadUrl = $expectedDownloadUrl
            minimumOsVersion = 'Android 7.0+'
            packageFormat = 'APK'
            installationNote = 'Download the APK, then allow installation from this source if Android asks.'
        })
    } | ConvertTo-Json -Depth 6
    Write-Utf8NoBom -Path $artifactMetadataPath -Content ($artifactMetadata + "`n")

    $websiteManifest = Join-Path $projectRoot 'web\release-manifest.json'
    $manifestPath = Join-Path $packagePath 'generated-release-manifest.json'
    & dart run tool/generate_release_manifest.dart `
        --version $evidence.version `
        --tag $releaseTag `
        --commit $evidence.commitSha `
        --distribution-repository $DistributionRepository `
        --distribution-policy $policyPath `
        --release-url $expectedReleaseUrl `
        --artifacts $artifactMetadataPath `
        --notes $notesPath `
        --template $websiteManifest `
        --output $manifestPath
    if ($LASTEXITCODE -ne 0) { throw 'Release manifest generation failed. The website remains unchanged.' }
    & dart run tool/verify_release.dart `
        --tag $releaseTag `
        --ref $evidence.commitSha `
        --manifest $manifestPath `
        --distribution-policy $policyPath
    if ($LASTEXITCODE -ne 0) { throw 'Generated release manifest validation failed. The website remains unchanged.' }

    $backupPath = Join-Path $packagePath 'previous-web-release-manifest.json'
    if (-not (Test-Path -LiteralPath $backupPath)) { Copy-Item -LiteralPath $websiteManifest -Destination $backupPath }
    Copy-Item -LiteralPath $manifestPath -Destination $websiteManifest -Force
    $metadataApplied = $true
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency restore failed after metadata generation.' }
    & flutter gen-l10n
    if ($LASTEXITCODE -ne 0) { throw 'Localization generation failed after metadata generation.' }
    & flutter build web --release
    if ($LASTEXITCODE -ne 0) { throw 'Website build failed after metadata generation.' }
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $projectRoot 'build\web\release-manifest.json') -Force
    $installer = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'build\web') -Recurse -File |
        Where-Object { $_.Extension -in '.apk', '.ipa', '.exe', '.msi', '.dmg' } | Select-Object -First 1
    if ($installer) { throw "Firebase Spark bundle contains forbidden installer $($installer.FullName)." }

    if (-not $DeployToSpark) {
        Write-Output 'Verified website metadata was generated and the web bundle passed checks. No Firebase deployment was run.'
        Write-Output 'After reviewing the generated manifest and bundle, run this command again with -DeployToSpark -ApproveSparkDeployment to deploy only hosting:cashly-lao.'
        return
    }

    $deploymentStarted = $true
    & firebase deploy --only hosting:cashly-lao --project cashly-lao
    if ($LASTEXITCODE -ne 0) { throw 'Firebase Spark deployment failed. Review the deployed state before any manual rollback.' }
    $liveManifestPath = Join-Path $packagePath 'live-release-manifest.json'
    Invoke-WebRequest -Uri 'https://cashly-lao.web.app/release-manifest.json' -OutFile $liveManifestPath -Headers @{ 'Cache-Control' = 'no-cache' }
    & dart run tool/verify_release.dart `
        --tag $releaseTag `
        --ref $evidence.commitSha `
        --manifest $liveManifestPath `
        --distribution-policy $policyPath
    if ($LASTEXITCODE -ne 0) {
        throw 'The live manifest did not validate after deployment. Do not alter the GitHub release; use the documented manual metadata rollback.'
    }
    Write-Output "Firebase Spark metadata deployment verified for $expectedDownloadUrl."
} catch {
    if ($metadataApplied -and -not $deploymentStarted -and $websiteManifest -and $backupPath -and (Test-Path -LiteralPath $backupPath)) {
        Copy-Item -LiteralPath $backupPath -Destination $websiteManifest -Force
        Write-Warning 'The local web manifest was restored because validation failed before deployment.'
    }
    throw
} finally {
    Pop-Location
}
