. "$PSScriptRoot/helpers.ps1"

Write-Log "Diagnostics" -Level INFO
Write-Log "Admin: $(if (Test-Admin) { 'Yes' } else { 'No' })" -Level INFO
Write-Log "git: $(if (Get-Command git -ErrorAction SilentlyContinue) { 'OK' } else { 'Missing' })" -Level INFO
if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        & git lfs version | Out-Null
        Write-Log "git-lfs: OK" -Level INFO
    } catch {
        Write-Log "git-lfs: Missing (install Git LFS if you need textures via LFS)" -Level INFO
    }
} else {
    Write-Log "git-lfs: Unknown (git is missing)" -Level INFO
}
Write-Log "rclone: $(if (Get-Command rclone -ErrorAction SilentlyContinue) { 'OK' } else { 'Missing' })" -Level INFO

$settingsPath = Join-Path (Resolve-Path "$PSScriptRoot/..") 'config/settings.json'
Write-Log "settings.json: $(if (Test-Path $settingsPath) { 'OK' } else { 'Missing' })" -Level INFO
