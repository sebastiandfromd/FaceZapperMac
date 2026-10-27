@echo off
rem Signs the release bundle (tools\build-android-release.ps1) with the upload key for Google Play.
rem jarsigner asks for the keystore password itself: it is typed by hand and never stored anywhere.
rem Paths below are the ones on this machine.
set "JARSIGNER=C:\Program Files\OpenLogic\jdk-17.0.16.8-hotspot\bin\jarsigner.exe"
set "KEYSTORE=C:\Users\SeDi\KeystoreForQtApps\android_release.keystore"
set "BUILD=C:\Users\SeDi\cpp\build-FaceZapper-Android_Qt_6_12_0_Clang_arm64_v8a-Release"
set "UNSIGNED=%BUILD%\android-build\build\outputs\bundle\release\android-build-release.aab"
rem version name from FaceZapper.pro ("VERSION = 1.2")
for /f "tokens=3" %%v in ('findstr /b /c:"VERSION = " "%~dp0..\FaceZapper.pro"') do set "VER=%%v"
set "SIGNED=%BUILD%\FaceZapper-%VER%-signed.aab"

echo Signiere FaceZapper %VER% mit Schluessel "qtappskeystore".
echo Bitte gleich das Keystore-Kennwort eingeben (wird nicht angezeigt):
"%JARSIGNER%" -keystore "%KEYSTORE%" -sigalg SHA256withRSA -digestalg SHA-256 -signedjar "%SIGNED%" "%UNSIGNED%" qtappskeystore
if errorlevel 1 (
    echo Signieren fehlgeschlagen.
    exit /b 1
)
echo.
echo Pruefe die Signatur ...
"%JARSIGNER%" -verify "%SIGNED%"
echo Fertig: %SIGNED%
