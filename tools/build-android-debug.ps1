# Debug APK for testing on the phone (signed with the Android debug key).
# If the release build (upload key) is installed, uninstall it first - otherwise the install
# fails with a signature mismatch:
#   adb uninstall de.herrdiel.facezapper
#   adb install -r <build dir>\android-build\build\outputs\apk\debug\android-build-debug.apk
#
# Run:  powershell -ExecutionPolicy Bypass -File tools\build-android-debug.ps1
$ErrorActionPreference = "Stop"
# --- paths on this machine ---
$env:ANDROID_SDK_ROOT = "C:\AndroidSDK"
$env:ANDROID_NDK_ROOT = "C:\AndroidSDK\ndk\27.2.12479018"
$env:JAVA_HOME = "C:\Program Files\OpenLogic\jdk-17.0.16.8-hotspot"
$qt = "C:\Qt\6.12.0\android_arm64_v8a"
# ---
$make = "$env:ANDROID_NDK_ROOT\prebuilt\windows-x86_64\bin\make.exe"
$src = (Resolve-Path "$PSScriptRoot\..").Path
$b = Join-Path (Split-Path $src) "build-FaceZapper-Android_Qt_6_12_0_Clang_arm64_v8a-Debug"
New-Item -ItemType Directory -Force $b | Out-Null
Set-Location $b

& "$qt\bin\qmake.bat" "$src\FaceZapper.pro" -spec android-clang "CONFIG+=debug" "CONFIG+=qml_debug" "ANDROID_ABIS=arm64-v8a"
if ($LASTEXITCODE -ne 0) { throw "qmake failed" }
& $make -j8 2>&1 | Select-String -Pattern "error|Error" | Select-Object -Last 20
if ($LASTEXITCODE -ne 0) { throw "make failed" }
& $make install INSTALL_ROOT="$b\android-build" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "make install failed" }

$settings = Get-ChildItem "$b\android-*-deployment-settings.json" | Select-Object -First 1
# no Gradle daemon: a lingering daemon keeps this script's output pipe open
# smaller heap than the template's 3200m: this machine has only a 1 GB page file
$env:GRADLE_OPTS = "-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx1536m"
# via cmd: PowerShell 5.1 would turn any stderr line (e.g. Gradle notices) into a terminating error
cmd /c "`"C:\Qt\6.12.0\mingw_64\bin\androiddeployqt.exe`" --input `"$($settings.FullName)`" --output `"$b\android-build`" --android-platform android-36 --jdk `"$env:JAVA_HOME`" --gradle > `"$b\deploy.log`" 2>&1"
$rc = $LASTEXITCODE
Get-Content "$b\deploy.log" -Tail 25
if ($rc -ne 0) { throw "androiddeployqt failed" }
Get-ChildItem -Recurse "$b\android-build\build\outputs\apk" -Filter *.apk | Select-Object FullName, Length
