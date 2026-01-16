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
    Write-Log "rclone not found in PATH. Install it or switch to mock mode." -Level ERROR
    exit 1
}

$remotePath = $From
$cmd = if ($UseSync.IsPresent -and $Force.IsPresent) { 'sync' } else { 'copy' }
Write-Log "rclone $cmd $remotePath -> $To" -Level INFO

$rcloneArgs = @($cmd, $remotePath, $To, '--progress')
$rcloneResult = & rclone @rcloneArgs
if ($LASTEXITCODE -ne 0) {
    Write-Log "rclone failed with exit code $LASTEXITCODE" -Level ERROR
    exit $LASTEXITCODE
}
