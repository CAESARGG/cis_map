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
