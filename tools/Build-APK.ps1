# TurnApp - build APK for apps/<name>. Right-click -> Run with PowerShell.
# Usage: powershell -ExecutionPolicy Bypass -File tools\Build-APK.ps1 [-App renumber]
param([string]$App = "")
$ErrorActionPreference = "Stop"
$Root = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent

# 1. Read apps.json
$CfgPath = "$Root\apps.json"
if (-not (Test-Path $CfgPath)) { throw "apps.json not found at $CfgPath" }
$Cfg = Get-Content $CfgPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($App)) { $App = $Cfg.active }
if (-not $Cfg.apps.PSObject.Properties[$App]) { throw "App '$App' not in apps.json. Available: $(($Cfg.apps.PSObject.Properties.Name) -join ', ')" }
$Meta = $Cfg.apps.$App
$Title = $Meta.title
$Pkg = $Meta.package
$VCode = $Meta.versionCode
$VName = $Meta.versionName
$SrcHtml = Join-Path $Root ($Meta.src -replace '/', '\')
if (-not (Test-Path $SrcHtml)) { throw "HTML not found: $SrcHtml" }

Write-Output "Building app '$App' - $Title ($Pkg v$VName)"

# 2. Tool paths (same as Setup-Android.ps1)
$Tools = "C:\Users\Shree\AppData\Local\Temp\opencode\buildtools"
$Jdk = "$Tools\jdk17\jdk-17.0.20.1+1"
$Sdk = "$Root\android-sdk"
$GradleDir = "$Tools\gradle-8.7"
if (-not (Test-Path "$Jdk\bin\java.exe")) { throw "JDK missing. Run tools\Setup-Android.ps1 first." }
if (-not (Test-Path "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat")) { throw "SDK missing. Run tools\Setup-Android.ps1 first." }
if (-not (Test-Path "$GradleDir\bin\gradle.bat")) { throw "Gradle missing. Run tools\Setup-Android.ps1 first." }
$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:PATH = "$Jdk\bin;$Sdk\cmdline-tools\latest\bin;$Sdk\platform-tools;" + $env:PATH

# 3. Stage build dir from template (fresh each time)
$Stage = "$Root\.build\$App"
Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Stage -Force | Out-Null
Copy-Item "$Root\template\*" -Destination $Stage -Recurse -Force

# 4. Inject app HTML into assets
$Assets = "$Stage\app\src\main\assets\app"
New-Item -ItemType Directory -Path $Assets -Force | Out-Null
Copy-Item $SrcHtml -Destination "$Assets\index.html" -Force

# 5. Patch package id / version / label
$AppGradle = "$Stage\app\build.gradle"
(Get-Content $AppGradle -Raw) `
  -replace 'namespace = ".*?"', "namespace = `"$Pkg`"" `
  -replace 'applicationId = ".*?"', "applicationId = `"$Pkg`"" `
  -replace 'versionCode = \d+', "versionCode = $VCode" `
  -replace 'versionName = ".*?"', "versionName = `"$VName`"" |
  Set-Content $AppGradle -NoNewline

$Manifest = "$Stage\app\src\main\AndroidManifest.xml"
(Get-Content $Manifest -Raw) -replace 'android:label=".*?"', "android:label=`"$Title`"" |
  Set-Content $Manifest -NoNewline

$Strings = "$Stage\app\src\main\res\values\strings.xml"
(Get-Content $Strings -Raw) -replace '<string name="app_name">.*?</string>', "<string name=`"app_name`">$Title</string>" |
  Set-Content $Strings -NoNewline

# Move MainActivity.kt package dir to match $Pkg
$JavaRoot = "$Stage\app\src\main\java"
$OldPkgDir = "$JavaRoot\com\turnapp\factory"
$NewPkgDir = Join-Path $JavaRoot ($Pkg -replace '\.', '\')
if ($Pkg -ne "com.turnapp.factory") {
  New-Item -ItemType Directory -Path $NewPkgDir -Force | Out-Null
  $Kt = Get-Content "$OldPkgDir\MainActivity.kt" -Raw
  $Kt = $Kt -replace 'package com\.turnapp\.factory', "package $Pkg"
  Set-Content (Join-Path $NewPkgDir "MainActivity.kt") $Kt -NoNewline
  # Delete ONLY the old factory file (new dir may live under com\turnapp too)
  Remove-Item "$OldPkgDir\MainActivity.kt" -Force
}

# 6. Accept licenses + build
echo "y" | & "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses | Out-Null
Set-Location $Stage
& "$GradleDir\bin\gradle.bat" assembleDebug --no-daemon

$Apk = "$Stage\app\build\outputs\apk\debug\app-debug.apk"
$OutDir = "$Root\out"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$OutApk = "$OutDir\${App}-v${VName}.apk"
Copy-Item $Apk -Destination $OutApk -Force

Write-Output ""
Write-Output "DONE: $OutApk"
Write-Output "Copy it to your phone and tap to install."
