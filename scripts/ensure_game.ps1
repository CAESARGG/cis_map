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

    # Minimal GTA folder structure expected by the pipeline
    Ensure-Directory -Path (Join-Path $Path 'gta')
    Ensure-Directory -Path (Join-Path $Path 'gta/data')
    Ensure-Directory -Path (Join-Path $Path 'gta/models')
    Ensure-Directory -Path (Join-Path $Path 'gta/modloader/DEV_MIAMI')

    # Placeholder snapshot marker (not used in current pipeline, but handy later)
    Set-Content -Path (Join-Path $Path 'ASSETS_SNAPSHOT.txt') -Value "mock" -Encoding UTF8

    # Stub README
    @(
        "# CIS_GAME (stub)",
        "", 
        "This folder was created automatically by CIS_MAP in MOCK mode.",
        "Replace it by cloning the real CIS_GAME repository when available.",
        ""
    ) | Set-Content -Path (Join-Path $Path 'README.md') -Encoding UTF8

    # If this is a stub, make sure big folders stay untracked even if someone runs git init later.
    @(
        "# Big vanilla GTA folders (downloaded from Drive)",
        "gta/audio/",
        "gta/anim/",
        "gta/text/",
        "gta/cleo/",
        "gta/SAMP/",
        "gta/scripts/",
        "", 
        "# Executables / DLLs", 
        "gta/*.exe",
        "gta/*.dll",
        "", 
        "# IMG archives (usually huge)",
        "gta/models/*.img"
    ) | Set-Content -Path (Join-Path $Path '.gitignore') -Encoding UTF8

    # Optional: initialize as a git repo for convenience (does not require network)
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            if (-not (Test-Path (Join-Path $Path '.git'))) {
                Push-Location $Path
                git init | Out-Null
                git add -A | Out-Null
                git commit -m "Stub CIS_GAME created by CIS_MAP" | Out-Null
                Pop-Location
            }
        } catch {
            try { Pop-Location } catch {}
            Write-Log "Stub git init/commit skipped: $($_.Exception.Message)" -Level WARN
        }
    }
}

if (Test-Path $gameDir) {
    Write-Log "CIS_GAME exists at $gameDir" -Level INFO
    if (Test-Path (Join-Path $gameDir '.git')) {
        try {
            Write-Log "Updating CIS_GAME repository." -Level INFO
            Push-Location $gameDir
            git fetch --all | Out-Null
            git pull | Out-Null
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
