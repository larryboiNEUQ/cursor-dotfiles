$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$DestinationRoot = if ($env:CURSOR_CONFIG_HOME) { $env:CURSOR_CONFIG_HOME } else { Join-Path $HOME '.cursor' }
$Timestamp = Get-Date -Format 'yyyyMMddHHmmss'

function Test-FileContentEqual {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )

    $LeftBytes = [System.IO.File]::ReadAllBytes($Left)
    $RightBytes = [System.IO.File]::ReadAllBytes($Right)
    if ($LeftBytes.Length -ne $RightBytes.Length) {
        return $false
    }

    for ($Index = 0; $Index -lt $LeftBytes.Length; $Index++) {
        if ($LeftBytes[$Index] -ne $RightBytes[$Index]) {
            return $false
        }
    }
    return $true
}

function Install-ManagedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $DestinationDirectory = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null

    if ((Test-Path -LiteralPath $Destination -PathType Leaf) -and
        (Test-FileContentEqual -Left $Source -Right $Destination)) {
        Write-Host "unchanged  $Destination"
        return
    }

    if (Test-Path -LiteralPath $Destination) {
        $Backup = "$Destination.bak.$Timestamp"
        $BackupSuffix = 0
        while (Test-Path -LiteralPath $Backup) {
            $BackupSuffix++
            $Backup = "$Destination.bak.$Timestamp.$BackupSuffix"
        }
        Copy-Item -LiteralPath $Destination -Destination $Backup
        Write-Host "backup     $Backup"
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "installed  $Destination"
}

Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'config/common/agents') -Filter '*.md' -File |
    Sort-Object Name |
    ForEach-Object {
        Install-ManagedFile -Source $_.FullName -Destination (Join-Path $DestinationRoot "agents/$($_.Name)")
    }

Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'config/windows/rules') -Filter '*.mdc' -File |
    Sort-Object Name |
    ForEach-Object {
        Install-ManagedFile -Source $_.FullName -Destination (Join-Path $DestinationRoot "rules/$($_.Name)")
    }

Write-Host "`nCursor configuration installed in $DestinationRoot"
Write-Host 'Restart Cursor CLI so new rules and agent definitions are loaded.'
