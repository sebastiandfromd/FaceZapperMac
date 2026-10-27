@echo off
rem Signs a copy of the release APK with the upload key, for installing it on the phone directly.
rem apksigner asks for the password itself; it is typed by the user and never stored anywhere.
set "BT=C:\AndroidSDK\build-tools\36.1.0"
set "KEYSTORE=C:\Users\SeDi\KeystoreForQtApps\android_release.keystore"
set "BUILD=C:\Users\SeDi\cpp\build-FaceZapper-Android_Qt_6_12_0_Clang_arm64_v8a-Release"
set "UNSIGNED=%BUILD%\android-build\build\outputs\apk\release\android-build-release-unsigned.apk"
rem version name from FaceZapper.pro ("VERSION = 1.2")
for /f "tokens=3" %%v in ('findstr /b /c:"VERSION = " "%~dp0..\FaceZapper.pro"') do set "VER=%%v"
set "ALIGNED=%BUILD%\FaceZapper-%VER%-aligned.apk"
set "SIGNED=%BUILD%\FaceZapper-%VER%-signed.apk"
set "JAVA_HOME=C:\Program Files\OpenLogic\jdk-17.0.16.8-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

"%BT%\zipalign.exe" -p -f 4 "%UNSIGNED%" "%ALIGNED%" || (echo zipalign fehlgeschlagen & exit /b 1)
echo Signiere eine Kopie der Release-APK mit Schluessel "qtappskeystore".
echo Bitte das Keystore-Kennwort eingeben (wird nicht angezeigt):
call "%BT%\apksigner.bat" sign --ks "%KEYSTORE%" --ks-key-alias qtappskeystore --out "%SIGNED%" "%ALIGNED%"
if errorlevel 1 (
    echo Signieren fehlgeschlagen.
    exit /b 1
)
del "%ALIGNED%"
echo Fertig: %SIGNED%
