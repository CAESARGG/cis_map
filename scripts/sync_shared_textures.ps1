param(
    [Parameter(Mandatory)] [string] $RepoRoot,
    [Parameter(Mandatory)] [psobject] $Settings,
    [switch] $Force
)

. "$PSScriptRoot/helpers.ps1"

$source = Join-Path $RepoRoot 'assets_textures'
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $RepoRoot $Settings.local_source_root))
Ensure-Directory -Path $sourceRoot
$target = Join-Path $sourceRoot '_shared_textures'

Write-Log "Syncing shared textures $source -> $target" -Level INFO
Copy-Tree -Source $source -Destination $target -Mirror:$false -Force:$Force
