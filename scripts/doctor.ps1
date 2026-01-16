. "$PSScriptRoot/helpers.ps1"

Write-Log "Diagnostics" -Level INFO
Write-Log "Admin: $(if (Test-Admin) { 'Yes' } else { 'No' })" -Level INFO
Write-Log "git: $(if (Get-Command git -ErrorAction SilentlyContinue) { 'OK' } else { 'Missing' })" -Level INFO
Write-Log "git-lfs: $(if (Get-Command git-lfs -ErrorAction SilentlyContinue) { 'OK' } else { 'Missing' })" -Level INFO
Write-Log "rclone: $(if (Get-Command rclone -ErrorAction SilentlyContinue) { 'OK' } else { 'Missing' })" -Level INFO

$settingsPath = Join-Path (Resolve-Path "$PSScriptRoot/..") 'config/settings.json'
Write-Log "settings.json: $(if (Test-Path $settingsPath) { 'OK' } else { 'Missing' })" -Level INFO
