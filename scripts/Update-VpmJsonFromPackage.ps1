param(
    [Parameter(Mandatory = $true)]
    [string]$PackageManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$ZipSha256,

    [string]$OutputPath = "vpm.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PackageManifestPath)) {
    throw "Package manifest not found: $PackageManifestPath"
}

$package = Get-Content -Path $PackageManifestPath -Raw | ConvertFrom-Json

if (-not (Test-Path $OutputPath)) {
    throw "Listing file not found: $OutputPath"
}

$vpm = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json

if (-not $vpm.packages) {
    $vpm | Add-Member -MemberType NoteProperty -Name packages -Value ([pscustomobject]@{})
}

$packageName = [string]$package.name
$version = [string]$package.version

if ([string]::IsNullOrWhiteSpace($packageName)) {
    throw "package.json: name is empty"
}
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "package.json: version is empty"
}

if (-not ($vpm.packages.PSObject.Properties.Name -contains $packageName)) {
    $vpm.packages | Add-Member -MemberType NoteProperty -Name $packageName -Value ([pscustomobject]@{ versions = [pscustomobject]@{} })
}

$pkgNode = $vpm.packages.$packageName
if (-not $pkgNode.versions) {
    $pkgNode | Add-Member -MemberType NoteProperty -Name versions -Value ([pscustomobject]@{}) -Force
}

$entry = $package | ConvertTo-Json -Depth 100 | ConvertFrom-Json
$entry | Add-Member -MemberType NoteProperty -Name zipSHA256 -Value $ZipSha256 -Force

if ($pkgNode.versions.PSObject.Properties.Name -contains $version) {
    $pkgNode.versions.$version = $entry
} else {
    $pkgNode.versions | Add-Member -MemberType NoteProperty -Name $version -Value $entry
}

$vpm | ConvertTo-Json -Depth 100 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Updated $OutputPath for $packageName@$version"
