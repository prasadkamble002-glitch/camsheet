# TurnApp - quick health check. Right-click -> Run with PowerShell.
$ErrorActionPreference = "Continue"
$Root = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent
Write-Output "Root: $Root"
Write-Output ""

$ok = $true
function Check($label, $cond) {
  if ($cond) { Write-Output "[OK] $label" } else { Write-Output "[MISSING] $label"; $script:ok = $false }
}

Check "apps.json" (Test-Path "$Root\apps.json")
Check "template/build.gradle" (Test-Path "$Root\template\build.gradle")
Check "template MainActivity.kt" (Test-Path "$Root\template\app\src\main\java\com\turnapp\factory\MainActivity.kt")
Check "www-template/index.html" (Test-Path "$Root\www-template\index.html")

try {
  $Cfg = Get-Content "$Root\apps.json" -Raw | ConvertFrom-Json
  $a = $Cfg.active
  Check "active app '$a' html exists" (Test-Path (Join-Path $Root ($Cfg.apps.$a.src -replace '/', '\')))
} catch { Write-Output "[MISSING] apps.json parse: $_"; $ok = $false }

try { java -version 2>&1 | Select-Object -First 1 | Write-Output } catch { Write-Output "[INFO] system java: none (setup script brings JDK17)" }

$Tools = "C:\Users\Shree\AppData\Local\Temp\opencode\buildtools"
Check "JDK17 (setup done?)" (Test-Path "$Tools\jdk17\jdk-17.0.11+9\bin\java.exe")
Check "Android SDK (setup done?)" (Test-Path "$Root\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat")
Check "Gradle 8.7 (setup done?)" (Test-Path "$Tools\gradle-8.7\bin\gradle.bat")

Write-Output ""
if ($ok) { Write-Output "Factory files OK." } else { Write-Output "Some factory files missing - see above." }
Write-Output "If JDK/SDK/Gradle missing: run tools\Setup-Android.ps1 once."
