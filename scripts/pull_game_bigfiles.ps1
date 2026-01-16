param(
    [Parameter(Mandatory)] [string] $RepoRoot,
    [Parameter(Mandatory)] [psobject] $Settings,
    [Parameter(Mandatory)] [string] $GameDir,
    [switch] $Force
)

. "$PSScriptRoot/helpers.ps1"

$manifestPath = Join-Path $RepoRoot 'manifests/game_bigfolders.json'
$manifestExample = Join-Path $RepoRoot 'manifests/game_bigfolders.example.json'
if (-not (Test-Path $manifestPath)) {
    Write-Log "Manifest not found. Using example manifest." -Level WARN
    $manifestPath = $manifestExample
}

$entries = Read-JsonFile -Path $manifestPath
$mockRoot = Join-Path $RepoRoot 'mock_drive/BASE_GAME'

foreach ($entry in $entries) {
    $fromRel = $entry.from
    $toRel = $entry.to
    $target = Join-Path $GameDir $toRel

    if ($Settings.mode -eq 'mock') {
        & "$PSScriptRoot/drive_sync.ps1" -Mode mock -From $fromRel -To $target -Settings $Settings -UseSync:$false -Force:$Force -MockRoot $mockRoot
    } else {
        $remotePath = "{0}{1}/{2}" -f $Settings.drive_remote, $Settings.drive_base_game_path, $fromRel
        & "$PSScriptRoot/drive_sync.ps1" -Mode drive -From $remotePath -To $target -Settings $Settings -UseSync:$false -Force:$Force
    }
}
