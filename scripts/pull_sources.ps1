param(
    [Parameter(Mandatory)] [string] $RepoRoot,
    [Parameter(Mandatory)] [psobject] $Settings,
    [ValidateSet('max','blender')] [string] $SourceType,
    [switch] $Force
)

. "$PSScriptRoot/helpers.ps1"

$manifestName = if ($SourceType -eq 'max') { 'sources_max.json' } else { 'sources_blender.json' }
$exampleName = if ($SourceType -eq 'max') { 'sources_max.example.json' } else { 'sources_blender.example.json' }
$manifestPath = Join-Path $RepoRoot "manifests/$manifestName"
$manifestExample = Join-Path $RepoRoot "manifests/$exampleName"
if (-not (Test-Path $manifestPath)) {
    Write-Log "Manifest not found. Using example manifest for $SourceType." -Level WARN
    $manifestPath = $manifestExample
}

$entries = Read-JsonFile -Path $manifestPath
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $RepoRoot $Settings.local_source_root))
Ensure-Directory -Path $sourceRoot
$targetRoot = Join-Path $sourceRoot $SourceType
Ensure-Directory -Path $targetRoot

$mockSubdir = if ($SourceType -eq 'max') { 'SOURCE_MAX' } else { 'SOURCE_BLENDER' }
$mockRoot = Join-Path $RepoRoot ("mock_drive/$mockSubdir")
$remoteBase = if ($SourceType -eq 'max') { $Settings.drive_source_max_path } else { $Settings.drive_source_blender_path }

foreach ($entry in $entries) {
    $fromRel = $entry.from
    $toRel = $entry.to
    $target = Join-Path $targetRoot $toRel

    if ($Settings.mode -eq 'mock') {
        & "$PSScriptRoot/drive_sync.ps1" -Mode mock -From $fromRel -To $target -Settings $Settings -UseSync:$false -Force:$Force -MockRoot $mockRoot
    } else {
        $remotePath = "{0}{1}/{2}" -f $Settings.drive_remote, $remoteBase, $fromRel
        & "$PSScriptRoot/drive_sync.ps1" -Mode drive -From $remotePath -To $target -Settings $Settings -UseSync:$false -Force:$Force
    }
}
