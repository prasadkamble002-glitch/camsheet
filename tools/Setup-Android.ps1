# TurnApp - one-time PC setup. Right-click -> Run with PowerShell.
# Downloads (once): JDK 17 + Android cmdline-tools + platform-34 + build-tools + Gradle 8.7
# Nothing else needed. No Android Studio.
$ErrorActionPreference = "Stop"
$Root = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent
$Tools = "C:\Users\Shree\AppData\Local\Temp\opencode\buildtools"
$JdkDir = "$Tools\jdk17"
$Jdk = "$JdkDir\jdk-17.0.20.1+1"
$Sdk = "$Root\android-sdk"
$GradleZip = "$Tools\gradle-8.7-bin.zip"
$GradleDir = "$Tools\gradle-8.7"

New-Item -ItemType Directory -Path $Tools -Force | Out-Null
New-Item -ItemType Directory -Path $Sdk -Force | Out-Null

Write-Output "== 1/4 JDK 17 =="
if (-not (Test-Path "$Jdk\bin\java.exe")) {
  Write-Output "Downloading Temurin JDK 17 (~190MB)..."
  $tgz = "$Tools\jdk17.zip"
  if (-not (Test-Path $tgz)) {
    Invoke-WebRequest -Uri "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip" -OutFile $tgz
  }
  Remove-Item $JdkDir -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Path $JdkDir -Force | Out-Null
  Expand-Archive -LiteralPath $tgz -DestinationPath $JdkDir -Force
}
& "$Jdk\bin\java.exe" -version
$env:JAVA_HOME = $Jdk

Write-Output "== 2/4 Android cmdline-tools =="
$Ct = "$Sdk\cmdline-tools\latest"
if (-not (Test-Path "$Ct\bin\sdkmanager.bat")) {
  Write-Output "Downloading cmdline-tools (~150MB)..."
  $zip = "$Tools\cmdtools.zip"
  if (-not (Test-Path $zip)) {
    Invoke-WebRequest -Uri "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -OutFile $zip
  }
  $tmp = "$Tools\ct_tmp"
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
  Remove-Item $Ct -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Path $Ct -Force | Out-Null
  Get-ChildItem "$tmp\cmdline-tools" | Copy-Item -Destination $Ct -Recurse -Force
  Remove-Item $tmp -Recurse -Force
}

Write-Output "== 3/4 SDK packages =="
$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:PATH = "$Jdk\bin;$Ct\bin;$Sdk\platform-tools;" + $env:PATH
echo "y" | & "$Ct\bin\sdkmanager.bat" --licenses | Out-Null
& "$Ct\bin\sdkmanager.bat" "platform-tools" "platforms;android-34" "build-tools;34.0.0"

Write-Output "== 4/4 Gradle 8.7 =="
if (-not (Test-Path "$GradleDir\bin\gradle.bat")) {
  if (-not (Test-Path $GradleZip)) {
    Invoke-WebRequest -Uri "https://services.gradle.org/distributions/gradle-8.7-bin.zip" -OutFile $GradleZip
  }
  Expand-Archive -LiteralPath $GradleZip -DestinationPath $Tools -Force
}
& "$GradleDir\bin\gradle.bat" --version

Write-Output ""
Write-Output "SETUP DONE. Now run tools\Build-APK.ps1 to build your app."
