param(
    [Parameter(Mandatory)] [ValidateSet('mock','drive')] [string] $Mode,
    [Parameter(Mandatory)] [string] $From,
    [Parameter(Mandatory)] [string] $To,
    [Parameter(Mandatory)] [psobject] $Settings,
    [switch] $UseSync,
    [switch] $Force,
    [string] $MockRoot
)

. "$PSScriptRoot/helpers.ps1"

if ($Mode -eq 'mock') {
    if (-not $MockRoot) {
        throw "MockRoot is required in mock mode."
    }
    $sourcePath = Join-Path $MockRoot $From
    if (-not (Test-Path $sourcePath)) {
        Write-Log "Mock source missing: $sourcePath" -Level ERROR
        exit 1
    }
    Write-Log "Mock copy $sourcePath -> $To" -Level INFO
    Copy-Tree -Source $sourcePath -Destination $To -Mirror:$UseSync -Force:$Force
    return
}

if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    # Try auto-install locally (CIS_MAP/_tools/rclone/rclone.exe)
    try {
        $null = Ensure-Rclone -Settings $Settings
    } catch {
        Write-Log "rclone not found and auto-install failed: $($_.Exception.Message)" -Level ERROR
        exit 1
    }
}

# Resolve rclone exe (from settings or PATH)
$rcloneExe = $null
if (($Settings.PSObject.Properties.Name -contains 'rclone_exe') -and (Test-Path $Settings.rclone_exe)) {
    $rcloneExe = $Settings.rclone_exe
} else {
    $cmdPath = Get-Command rclone -ErrorAction SilentlyContinue
    if ($cmdPath) { $rcloneExe = $cmdPath.Source }
}

if (-not $rcloneExe) {
    Write-Log "rclone executable not available." -Level ERROR
    exit 1
}

$remotePath = $From
$cmd = if ($UseSync.IsPresent -and $Force.IsPresent) { 'sync' } else { 'copy' }
Write-Log "rclone $cmd $remotePath -> $To" -Level INFO

$rcloneArgs = @($cmd, $remotePath, $To, '--progress')
$rcloneResult = & $rcloneExe @rcloneArgs
if ($LASTEXITCODE -ne 0) {
    Write-Log "rclone failed with exit code $LASTEXITCODE" -Level ERROR
    exit $LASTEXITCODE
}
