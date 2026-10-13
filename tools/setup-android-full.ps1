# setup-android.ps1 - run this file ONCE in PowerShell (as admin if needed)
$ErrorActionPreference = "Stop"

$Tools = "C:\Users\Shree\AppData\Local\Temp\opencode\buildtools"
$Sdk = "D:\Research for projects\turn app\android-sdk"

New-Item -ItemType Directory -Path $Tools -Force
New-Item -ItemType Directory -Path $Sdk -Force

Write-Host "1/7 Downloading JDK 17..."
$JdkZip = "$Tools\jdk17.zip"
Invoke-WebRequest -Uri "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip" -OutFile $JdkZip

Write-Host "2/7 Extracting JDK..."
Expand-Archive -Path $JdkZip -DestinationPath "$Tools\jdk17" -Force
$env:JAVA_HOME = "$Tools\jdk17\jdk-17.0.20.1+1"

Write-Host "3/7 Downloading Android cmdline-tools..."
$CmdZip = "$Tools\cmdtools.zip"
Invoke-WebRequest -Uri "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -OutFile $CmdZip

Write-Host "4/7 Extracting cmdline-tools..."
Expand-Archive -Path $CmdZip -DestinationPath "$Tools\ct_tmp" -Force

Write-Host "5/7 Creating Android SDK structure..."
New-Item -ItemType Directory -Path "$Sdk\cmdline-tools\latest" -Force
Copy-Item "$Tools\ct_tmp\cmdline-tools\*" "$Sdk\cmdline-tools\latest" -Recurse -Force

Write-Host "6/7 Installing SDK packages..."
$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:PATH = "$Sdk\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;" + $env:PATH
echo "y" | "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
"$Sdk\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "platforms;android-34" "build-tools;34.0.0"

Write-Host "7/7 Downloading & extracting Gradle..."
$GradleZip = "$Tools\gradle-8.7-bin.zip"
Invoke-WebRequest -Uri "https://services.gradle.org/distributions/gradle-8.7-bin.zip" -OutFile $GradleZip
Expand-Archive -Path $GradleZip -DestinationPath $Tools -Force

Write-Host "SETUP COMPLETE. Now run:"
Write-Host "  cd 'D:\Research for projects\turn app'"
Write-Host "  & '$Tools\gradle-8.7\bin\gradle.bat' --version"
Write-Host "  powershell -ExecutionPolicy Bypass -File tools\Build-APK.ps1"