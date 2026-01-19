Set-StrictMode -Version Latest

function Write-Log {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')] [string] $Level = 'INFO'
    )
    $prefix = "[$Level]"
    switch ($Level) {
        'ERROR' { Write-Host "$prefix $Message" -ForegroundColor Red }
        'WARN' { Write-Host "$prefix $Message" -ForegroundColor Yellow }
        'SUCCESS' { Write-Host "$prefix $Message" -ForegroundColor Green }
        default { Write-Host "$prefix $Message" }
    }
}

function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-Choice {
    param(
        [Parameter(Mandatory)] [string] $Prompt,
        [string] $Default = 'Y'
    )
    $suffix = if ($Default -match '^[Yy]') { 'Y/n' } else { 'y/N' }
    $answer = Read-Host "$Prompt [$suffix]"
    if ([string]::IsNullOrWhiteSpace($answer)) {
        return ($Default -match '^[Yy]')
    }
    return ($answer -match '^[Yy]')
}

function Select-Choice {
    param(
        [Parameter(Mandatory)] [string] $Prompt,
        [Parameter(Mandatory)] [string[]] $Options,
        [int] $DefaultIndex = 1
    )
    Write-Host $Prompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("  {0}) {1}" -f ($i + 1), $Options[$i])
    }
    $selection = Read-Host ("Select [1-{0}] (default {1})" -f $Options.Count, $DefaultIndex)
    if ([string]::IsNullOrWhiteSpace($selection)) {
        return $DefaultIndex
    }
    if ($selection -notmatch '^\d+$') {
        return $DefaultIndex
    }
    $num = [int]$selection
    if ($num -lt 1 -or $num -gt $Options.Count) {
        return $DefaultIndex
    }
    return $num
}

function Ensure-Directory {
    param([Parameter(Mandatory)] [string] $Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-Tree {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination,
        [switch] $Mirror,
        [switch] $Force
    )
    Ensure-Directory -Path $Destination
    if (Get-Command robocopy -ErrorAction SilentlyContinue) {
        $robocopyArgs = @()
        $robocopyArgs += '"' + $Source + '"'
        $robocopyArgs += '"' + $Destination + '"'
        if ($Mirror.IsPresent -and $Force.IsPresent) {
            $robocopyArgs += '/MIR'
        } else {
            $robocopyArgs += '/E'
        }
        $robocopyArgs += '/NFL'
        $robocopyArgs += '/NDL'
        $robocopyArgs += '/NJH'
        $robocopyArgs += '/NJS'
        $robocopyArgs += '/NP'
        $robocopyArgs += '/R:1'
        $robocopyArgs += '/W:1'
        & robocopy @robocopyArgs | Out-Null
    } else {
        if ($Mirror.IsPresent -and $Force.IsPresent) {
            Write-Log "Mirror without robocopy: extra files won't be deleted." -Level WARN
        }
        Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force -ErrorAction Stop
    }
}

function Read-JsonFile {
    param([Parameter(Mandatory)] [string] $Path)
    if (-not (Test-Path $Path)) {
        throw "Missing JSON file: $Path"
    }
    $raw = Get-Content -Path $Path -Raw
    return $raw | ConvertFrom-Json
}

function Get-Settings {
    param(
        [Parameter(Mandatory)] [string] $RepoRoot
    )
    $settingsPath = Join-Path $RepoRoot 'config/settings.json'
    $examplePath = Join-Path $RepoRoot 'config/settings.example.json'

    if (-not (Test-Path $settingsPath)) {
        Write-Log "settings.json not found. Creating from example." -Level WARN
        Copy-Item -Path $examplePath -Destination $settingsPath -Force
    }

    $settings = Read-JsonFile -Path $settingsPath
    return @{ Path = $settingsPath; Data = $settings }
}

function Resolve-RepoRoot {
    param([string] $StartPath)
    $current = Resolve-Path $StartPath
    return $current.Path
}

function Resolve-WorkspacePath {
    param(
        [Parameter(Mandatory)] [string] $RepoRoot,
        [Parameter(Mandatory)] [string] $RelativePath
    )
    return (Resolve-Path (Join-Path $RepoRoot $RelativePath)).Path
}

function Ensure-Rclone {
    <#
      Ensures rclone is available.
      - If Settings.rclone_exe points to an existing file, uses it.
      - Else tries to find 'rclone' in PATH.
      - Else downloads and installs rclone locally into: <repo>\_tools\rclone\rclone.exe
      Download is performed via Invoke-WebRequest (alias: wget in PowerShell).
    #>
    param(
        [Parameter(Mandatory)] $Settings
    )

    # 1) Explicit path in settings
    $hasRcloneExe = ($Settings.PSObject.Properties.Name -contains 'rclone_exe')
    if ($hasRcloneExe -and -not [string]::IsNullOrWhiteSpace($Settings.rclone_exe)) {
        if (Test-Path $Settings.rclone_exe) {
            return $Settings.rclone_exe
        }
        Write-Log "rclone_exe is set but file not found: $($Settings.rclone_exe)" -Level WARN
    }

    # 2) PATH
    $cmd = Get-Command rclone -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    # 3) Local install into repo
    $repoRoot = Split-Path -Parent $PSScriptRoot  # ...\CIS_MAP
    $installDir = Join-Path $repoRoot "_tools\rclone"
    $exePath = Join-Path $installDir "rclone.exe"

    if (Test-Path $exePath) {
        return $exePath
    }

    Ensure-Directory -Path $installDir

    $zipUrl = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
    $zipPath = Join-Path $env:TEMP "rclone-current.zip"
    $tmpDir = Join-Path $env:TEMP ("rclone_unpack_" + [Guid]::NewGuid().ToString("N"))

    Write-Log "rclone not found. Installing locally to $installDir" -Level INFO

    try {
        # Invoke-WebRequest is aliased as 'wget' in Windows PowerShell.
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

        Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

        $foundExe = Get-ChildItem -Path $tmpDir -Recurse -Filter "rclone.exe" | Select-Object -First 1
        if (-not $foundExe) {
            throw "Downloaded archive does not contain rclone.exe"
        }

        Copy-Item -Path $foundExe.FullName -Destination $exePath -Force

        & $exePath version | Out-Null
        Write-Log "rclone installed: $exePath" -Level SUCCESS

        # Persist path into settings object for this run
        if (-not $hasRcloneExe) {
            $Settings | Add-Member -NotePropertyName rclone_exe -NotePropertyValue $exePath -Force
        } else {
            $Settings.rclone_exe = $exePath
        }

        return $exePath
    }
    catch {
        throw "Failed to install rclone automatically: $($_.Exception.Message)"
    }
    finally {
        Remove-Item -Force $zipPath -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    }
}
