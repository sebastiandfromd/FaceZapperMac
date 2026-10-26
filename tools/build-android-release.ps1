# Release App Bundle (.aab) for Google Play - unsigned; sign it afterwards with tools\sign-bundle.cmd
# (the keystore password is typed there by hand and never passes through a script).
#
# Use this instead of a plain Qt Creator release build: it bundles only the Qt plugins the app needs.
# Otherwise the QML debugging plugins end up in the app, and one of them pulls in Qt Quick 3D,
# which is available under GPLv3 only (the app relies on Qt under LGPLv3).
#
# Run:  powershell -ExecutionPolicy Bypass -File tools\build-android-release.ps1
# Version name/code: VERSION and ANDROID_VERSION_CODE in FaceZapper.pro
$ErrorActionPreference = "Stop"
# --- paths on this machine ---
$env:ANDROID_SDK_ROOT = "C:\AndroidSDK"
$env:ANDROID_NDK_ROOT = "C:\AndroidSDK\ndk\27.2.12479018"
$env:JAVA_HOME = "C:\Program Files\OpenLogic\jdk-17.0.16.8-hotspot"
$qt = "C:\Qt\6.12.0\android_arm64_v8a"
# ---
$make = "$env:ANDROID_NDK_ROOT\prebuilt\windows-x86_64\bin\make.exe"
$src = (Resolve-Path "$PSScriptRoot\..").Path
$b = Join-Path (Split-Path $src) "build-FaceZapper-Android_Qt_6_12_0_Clang_arm64_v8a-Release"
New-Item -ItemType Directory -Force $b | Out-Null
Set-Location $b

& "$qt\bin\qmake.bat" "$src\FaceZapper.pro" -spec android-clang "CONFIG+=release" "CONFIG-=qml_debug" "ANDROID_ABIS=arm64-v8a"
if ($LASTEXITCODE -ne 0) { throw "qmake failed" }
& $make -j8 2>&1 | Select-String -Pattern "error|Error" | Select-Object -Last 20
if ($LASTEXITCODE -ne 0) { throw "make failed" }
# androiddeployqt never removes libraries of earlier runs - start from an empty libs folder
Remove-Item -Recurse -Force "$b\android-build\libs" -ErrorAction SilentlyContinue
& $make install INSTALL_ROOT="$b\android-build" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "make install failed" }

$settings = Get-ChildItem "$b\android-*-deployment-settings.json" | Select-Object -First 1
# only the plugins the app needs (qmake can't set this): leaves out the QML debugging plugins - one of
# them pulls in Qt Quick 3D, which is GPLv3 only - and the unused network/TLS plugins
$json = Get-Content $settings.FullName -Raw
if ($json -notmatch '"android-deploy-plugins"') {
    $p = ($qt -replace '\\', '/') + "/plugins"   # androiddeployqt resolves these paths as given: absolute
    $json = $json -replace '^\{', "{`n   `"android-deploy-plugins`": `"$p/platforms;$p/imageformats;$p/iconengines`","
    [System.IO.File]::WriteAllText($settings.FullName, $json, (New-Object System.Text.UTF8Encoding $false))
}
# smaller heap than the template's 3200m (it failed with a small page file); no daemon, it would keep
# this script's output pipe open
$env:GRADLE_OPTS = "-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx1536m"
# via cmd: PowerShell 5.1 would turn any stderr line (e.g. Gradle notices) into a terminating error
cmd /c "`"C:\Qt\6.12.0\mingw_64\bin\androiddeployqt.exe`" --input `"$($settings.FullName)`" --output `"$b\android-build`" --android-platform android-36 --jdk `"$env:JAVA_HOME`" --gradle --release --aab > `"$b\deploy.log`" 2>&1"
$rc = $LASTEXITCODE
Get-Content "$b\deploy.log" -Tail 12
if ($rc -ne 0) { throw "androiddeployqt failed" }
Get-ChildItem -Recurse "$b\android-build\build\outputs" -Include *.aab, *.apk | Select-Object FullName, Length
