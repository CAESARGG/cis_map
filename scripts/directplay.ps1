param(
    [switch] $CheckOnly
)

. "$PSScriptRoot/helpers.ps1"

try {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction Stop
} catch {
    Write-Log "Failed to query DirectPlay. Ensure you are on Windows 10/11." -Level ERROR
    exit 1
}

if ($feature.State -eq 'Enabled') {
    Write-Log "DirectPlay is already enabled." -Level SUCCESS
    exit 0
}

Write-Log "DirectPlay is disabled." -Level WARN

if ($CheckOnly) {
    exit 0
}

if (-not (Test-Admin)) {
    Write-Log "Run this script as Administrator to enable DirectPlay." -Level ERROR
    exit 1
}

try {
    Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -All -ErrorAction Stop | Out-Null
    Write-Log "DirectPlay enabled successfully." -Level SUCCESS
} catch {
    Write-Log "Failed to enable DirectPlay: $($_.Exception.Message)" -Level ERROR
    exit 1
}
