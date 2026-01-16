param(
    [switch] $CheckDirectPlay,
    [string] $GameDir,
    [string[]] $BigFolders,
    [string[]] $SourceDirs,
    [string] $SharedTexturesDir
)

. "$PSScriptRoot/helpers.ps1"

if ($CheckDirectPlay) {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction Stop
        if ($feature.State -eq 'Enabled') {
            Write-Log "DirectPlay: Enabled" -Level SUCCESS
        } else {
            Write-Log "DirectPlay: Disabled" -Level WARN
        }
    } catch {
        Write-Log "DirectPlay check failed: $($_.Exception.Message)" -Level WARN
    }
}

if ($GameDir) {
    if (Test-Path (Join-Path $GameDir 'gta')) {
        Write-Log "CIS_GAME/gta exists." -Level SUCCESS
    } else {
        Write-Log "CIS_GAME/gta missing." -Level ERROR
    }
}

foreach ($folder in ($BigFolders | Where-Object { $_ })) {
    if (Test-Path $folder) {
        Write-Log "Big folder ok: $folder" -Level SUCCESS
    } else {
        Write-Log "Big folder missing: $folder" -Level WARN
    }
}

foreach ($dir in ($SourceDirs | Where-Object { $_ })) {
    if (Test-Path $dir) {
        Write-Log "Source dir ok: $dir" -Level SUCCESS
    } else {
        Write-Log "Source dir missing: $dir" -Level WARN
    }
}

if ($SharedTexturesDir) {
    if (Test-Path $SharedTexturesDir) {
        Write-Log "Shared textures ok: $SharedTexturesDir" -Level SUCCESS
    } else {
        Write-Log "Shared textures missing: $SharedTexturesDir" -Level WARN
    }
}
