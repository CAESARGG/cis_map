param(
    [switch] $Force
)

. "$PSScriptRoot/helpers.ps1"

$repoRoot = Resolve-RepoRoot -StartPath "$PSScriptRoot/.."
$settingsResult = Get-Settings -RepoRoot $repoRoot
$settings = $settingsResult.Data

$workspaceRoot = Resolve-Path (Join-Path $repoRoot $settings.workspace_root)
$gameDir = Join-Path $workspaceRoot $settings.game_dir_name
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot $settings.local_source_root))
$cacheRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot $settings.local_cache_root))

Write-Log "CIS_MAP Wizard" -Level INFO
Write-Log "Mode: $($settings.mode)" -Level INFO
Write-Log "Workspace root: $workspaceRoot" -Level INFO
Write-Log "Game dir: $gameDir" -Level INFO
Write-Log "Source root: $sourceRoot" -Level INFO
Write-Log "Cache root: $cacheRoot" -Level INFO

$doDirectPlay = Confirm-Choice -Prompt "Enable/verify DirectPlay?" -Default 'Y'
$doGame = Confirm-Choice -Prompt "Setup/update CIS_GAME?" -Default 'Y'
$cloneRemote = $false
if ($doGame) {
    $cloneRemote = Confirm-Choice -Prompt "Clone/update CIS_GAME from remote?" -Default 'Y'
}

$doBigFiles = Confirm-Choice -Prompt "Download big game folders?" -Default 'Y'
$doSources = Confirm-Choice -Prompt "Setup map development sources?" -Default 'Y'

$sourceSelection = 0
if ($doSources) {
    $sourceSelection = Select-Choice -Prompt "Choose DCC source:" -Options @('3ds Max','Blender','Both') -DefaultIndex 3
}

if ($doDirectPlay) {
    & "$PSScriptRoot/directplay.ps1"
}

if ($doGame) {
    $gameDir = & "$PSScriptRoot/ensure_game.ps1" -RepoRoot $repoRoot -Settings $settings -CloneRemote:$cloneRemote
}

if ($doBigFiles) {
    if (-not $gameDir) {
        $gameDir = & "$PSScriptRoot/ensure_game.ps1" -RepoRoot $repoRoot -Settings $settings -CloneRemote:$false
    }
    & "$PSScriptRoot/pull_game_bigfiles.ps1" -RepoRoot $repoRoot -Settings $settings -GameDir $gameDir -Force:$Force
}

if ($doSources) {
    if ($sourceSelection -eq 1 -or $sourceSelection -eq 3) {
        & "$PSScriptRoot/pull_sources.ps1" -RepoRoot $repoRoot -Settings $settings -SourceType max -Force:$Force
    }
    if ($sourceSelection -eq 2 -or $sourceSelection -eq 3) {
        & "$PSScriptRoot/pull_sources.ps1" -RepoRoot $repoRoot -Settings $settings -SourceType blender -Force:$Force
    }
    & "$PSScriptRoot/sync_shared_textures.ps1" -RepoRoot $repoRoot -Settings $settings -Force:$Force
}

$bigFolderTargets = @()
if ($doBigFiles -and $gameDir) {
    $manifestPath = Join-Path $repoRoot 'manifests/game_bigfolders.json'
    $manifestExample = Join-Path $repoRoot 'manifests/game_bigfolders.example.json'
    $manifestToUse = if (Test-Path $manifestPath) { $manifestPath } else { $manifestExample }
    $entries = Read-JsonFile -Path $manifestToUse
    foreach ($entry in $entries) {
        $bigFolderTargets += (Join-Path $gameDir $entry.to)
    }
}

$sourceDirs = @()
if ($doSources) {
    if ($sourceSelection -eq 1 -or $sourceSelection -eq 3) { $sourceDirs += (Join-Path $sourceRoot 'max') }
    if ($sourceSelection -eq 2 -or $sourceSelection -eq 3) { $sourceDirs += (Join-Path $sourceRoot 'blender') }
}

$sharedTexturesDir = if ($doSources) { Join-Path $sourceRoot '_shared_textures' } else { $null }

& "$PSScriptRoot/verify.ps1" -CheckDirectPlay:$doDirectPlay -GameDir $gameDir -BigFolders $bigFolderTargets -SourceDirs $sourceDirs -SharedTexturesDir $sharedTexturesDir

Write-Log "Wizard completed." -Level SUCCESS
Write-Host "" 
Write-Host "Next steps:" 
Write-Host "- CIS_GAME: $gameDir"
Write-Host "- Sources: $sourceRoot"
Write-Host "- Manual export: copy DFF/COL/TXD into CIS_GAME/gta/models or modloader/DEV_MIAMI"
Write-Host "- Run game as usual (placeholder)."
