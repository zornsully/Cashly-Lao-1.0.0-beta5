[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})/[A-Za-z0-9._-]+$')]
    [string]$DistributionRepository,
    [Parameter(Mandatory)]
    [string]$PackageDirectory,
    [switch]$ApproveWebsiteRollback,
    [switch]$DeployToSpark,
    [switch]$ApproveSparkDeployment
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $ApproveWebsiteRollback) {
    throw 'Refusing to roll back website metadata without -ApproveWebsiteRollback. A rollback changes only the website manifest; it never deletes or changes a GitHub Release.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$packagePath = (Resolve-Path -LiteralPath $PackageDirectory).Path
$evidencePath = Join-Path $packagePath 'release-evidence.json'
$verificationPath = Join-Path $packagePath 'public-release-verification.json'
if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf) -or -not (Test-Path -LiteralPath $verificationPath -PathType Leaf)) {
    throw 'Rollback requires the preserved, locally validated release-evidence.json and public-release-verification.json for the known-good release.'
}

$evidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
$verification = Get-Content -LiteralPath $verificationPath -Raw | ConvertFrom-Json
if ($evidence.channel -ne 'stable' -or $verification.releaseTag -ne $evidence.tag -or $verification.distributionRepository -ne $DistributionRepository) {
    throw 'The rollback evidence does not identify one verified stable public release.'
}

Write-Output "Preparing a website-only rollback to $($evidence.tag)."
Write-Output 'The current GitHub release and all newer releases will remain unchanged.'

$publishScript = Join-Path $PSScriptRoot 'publish_web_metadata.ps1'
& $publishScript `
    -DistributionRepository $DistributionRepository `
    -PackageDirectory $packagePath `
    -ApproveWebsiteMetadata `
    -DeployToSpark:$DeployToSpark `
    -ApproveSparkDeployment:$ApproveSparkDeployment
if ($LASTEXITCODE -ne 0) {
    throw 'Website metadata rollback preparation or deployment failed. The GitHub Release was not changed.'
}

Write-Output "Rollback completed for website metadata pointing to $($verification.downloadUrl)."
