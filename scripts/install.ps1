$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$DestinationRoot = if ($env:CURSOR_CONFIG_HOME) { $env:CURSOR_CONFIG_HOME } else { Join-Path $HOME '.cursor' }
$Timestamp = Get-Date -Format 'yyyyMMddHHmmss'

function Install-ManagedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $DestinationDirectory = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null

    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $SourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Source).Hash
        $DestinationHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash
        if ($SourceHash -eq $DestinationHash) {
            Write-Host "unchanged  $Destination"
            return
        }
    }

    if (Test-Path -LiteralPath $Destination) {
        $Backup = "$Destination.bak.$Timestamp"
        Copy-Item -LiteralPath $Destination -Destination $Backup -Force
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
