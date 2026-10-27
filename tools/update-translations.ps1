# Collects all qsTr()/tr() texts of the app (German, the source language) into the translation files
# i18n\FaceZapper_<code>.ts listed in FaceZapper.pro. New or changed texts are marked unfinished there;
# translate them (e.g. with Qt Linguist: linguist.exe i18n\FaceZapper_fr.ts). The build turns the
# .ts files into .qm files inside the app (CONFIG += lrelease embed_translations).
#
# Run:  powershell -ExecutionPolicy Bypass -File tools\update-translations.ps1
$ErrorActionPreference = "Stop"
$qt = "C:\Qt\6.12.0\mingw_64"   # Qt on this machine
$src = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location $src
# -locations none: no line numbers in the .ts files, so they only change when texts change
cmd /c "`"$qt\bin\lupdate-pro.exe`" FaceZapper.pro -no-obsolete -locations none 2>&1"
if ($LASTEXITCODE -ne 0) { throw "lupdate failed" }
