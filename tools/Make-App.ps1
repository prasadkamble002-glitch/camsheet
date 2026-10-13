# TurnApp - create new app from starter. Right-click -> Run with PowerShell.
# Usage: powershell -ExecutionPolicy Bypass -File tools\Make-App.ps1 -Name mysplitter -Title "My Splitter" -Package com.turnapp.mysplitter
param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Title = "",
  [string]$Package = ""
)
$ErrorActionPreference = "Stop"
$Root = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent
if ($Name -notmatch '^[a-z0-9-]+$') { throw "Name must be lowercase letters/numbers/dashes, e.g. mysplitter" }
if ([string]::IsNullOrWhiteSpace($Title)) { $Title = $Name }
if ([string]::IsNullOrWhiteSpace($Package)) { $Package = "com.turnapp.$($Name -replace '-', '')" }

$Dest = "$Root\apps\$Name"
if (Test-Path $Dest) { throw "apps\$Name already exists." }
New-Item -ItemType Directory -Path $Dest -Force | Out-Null
Copy-Item "$Root\www-template\index.html" -Destination "$Dest\index.html" -Force

$Cfg = Get-Content "$Root\apps.json" -Raw | ConvertFrom-Json
# Add via hashtable then back to JSON (keeps other apps)
$Apps = @{}
foreach ($p in $Cfg.apps.PSObject.Properties) { $Apps[$p.Name] = $p.Value }
$Apps[$Name] = @{ title = $Title; package = $Package; versionCode = 1; versionName = "1.0"; src = "apps/$Name/index.html"; portedFrom = "" }
$Cfg.apps = $Apps
$Cfg | ConvertTo-Json -Depth 5 | Set-Content "$Root\apps.json"

Write-Output "Created apps\$Name\index.html"
Write-Output "Next: tell AI what your PC tool does - AI will fill that index.html."
Write-Output "Then set apps.json active='$Name' and run Build-APK.ps1."
