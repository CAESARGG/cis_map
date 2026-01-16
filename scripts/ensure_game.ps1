param(
    [Parameter(Mandatory)] [string] $RepoRoot,
    [Parameter(Mandatory)] [psobject] $Settings,
    [switch] $CloneRemote
)

. "$PSScriptRoot/helpers.ps1"

$workspaceRoot = Resolve-Path (Join-Path $RepoRoot $Settings.workspace_root)
$gameDir = Join-Path $workspaceRoot $Settings.game_dir_name
$mode = $Settings.mode

function Initialize-GameStub {
    param([string] $Path)
    Write-Log "Creating stub CIS_GAME at $Path" -Level WARN
    Ensure-Directory -Path $Path
    Ensure-Directory -Path (Join-Path $Path 'gta')
    Set-Content -Path (Join-Path $Path 'ASSETS_SNAPSHOT.txt') -Value "Stub game snapshot. Replace with real data."
    Set-Content -Path (Join-Path $Path 'README.md') -Value "Stub CIS_GAME. Replace with real repo contents."
}

if (Test-Path $gameDir) {
    Write-Log "CIS_GAME exists at $gameDir" -Level INFO
    if (Test-Path (Join-Path $gameDir '.git')) {
        try {
            Write-Log "Updating CIS_GAME repository." -Level INFO
            Push-Location $gameDir
            git fetch --all
            git pull
            Pop-Location
            Write-Log "CIS_GAME updated." -Level SUCCESS
        } catch {
            Pop-Location
            Write-Log "Failed to update CIS_GAME: $($_.Exception.Message)" -Level WARN
        }
    }
    return $gameDir
}

if ($mode -eq 'drive' -or $CloneRemote.IsPresent) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Log "git not found. Creating stub instead." -Level WARN
        Initialize-GameStub -Path $gameDir
        return $gameDir
    }
    if ($Settings.game_repo_url -like '*PUT_CIS_GAME_REPO_URL_HERE*') {
        Write-Log "game_repo_url placeholder detected. Creating stub instead." -Level WARN
        Initialize-GameStub -Path $gameDir
        return $gameDir
    }
    try {
        Write-Log "Cloning CIS_GAME from $($Settings.game_repo_url)" -Level INFO
        git clone $Settings.game_repo_url $gameDir
        Write-Log "Clone completed." -Level SUCCESS
        return $gameDir
    } catch {
        Write-Log "Clone failed. Falling back to stub. $($_.Exception.Message)" -Level WARN
        Initialize-GameStub -Path $gameDir
        return $gameDir
    }
}

Write-Log "Mock mode or clone skipped. Creating stub CIS_GAME." -Level WARN
Initialize-GameStub -Path $gameDir
return $gameDir
