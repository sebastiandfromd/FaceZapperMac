# Windows release: FaceZapper.exe with all needed Qt files (deploy\FaceZapper), a portable ZIP and an
# Inno Setup installer in dist\. Not signed (Windows SmartScreen shows "Unbekannter Herausgeber").
#
# Only the Qt plugins the app needs are deployed: the QML debugging plugins stay out - one of them pulls
# in Qt Quick 3D, which is available under GPLv3 only (the app relies on Qt under LGPLv3).
#
# Run:  powershell -ExecutionPolicy Bypass -File tools\build-windows-release.ps1
# Version: VERSION in FaceZapper.pro
$ErrorActionPreference = "Stop"
# --- paths on this machine ---
$qt = "C:\Qt\6.12.0\mingw_64"
$mingw = "C:\Qt\Tools\mingw1310_64"
$iscc = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $iscc)) { $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" }
# ---
$src = (Resolve-Path "$PSScriptRoot\..").Path
$b = Join-Path (Split-Path $src) "build-FaceZapper-Desktop_Qt_6_12_0_MinGW_64_bit-Release"
$deploy = "$b\deploy\FaceZapper"
$dist = "$src\dist"
$env:PATH = "$qt\bin;$mingw\bin;$env:PATH"
$version = ((Select-String -Path "$src\FaceZapper.pro" -Pattern '^VERSION\s*=\s*(\S+)').Matches[0].Groups[1].Value)
Write-Host "FaceZapper $version - Windows release"

# 1. build (release, without QML debugging)
New-Item -ItemType Directory -Force $b | Out-Null
Set-Location $b
cmd /c "qmake.exe `"$src\FaceZapper.pro`" -spec win32-g++ CONFIG+=release CONFIG-=qml_debug > qmake.log 2>&1"
if ($LASTEXITCODE -ne 0) { throw "qmake failed (see $b\qmake.log)" }
# via cmd: PowerShell 5.1 would turn any stderr line into a terminating error
cmd /c "mingw32-make -j8 > build.log 2>&1"
if ($LASTEXITCODE -ne 0) { Get-Content build.log -Tail 20; throw "build failed (see $b\build.log)" }

# 2. deploy: exe + needed Qt libraries, QML modules, plugins and the MinGW runtime
Remove-Item -Recurse -Force "$b\deploy" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $deploy | Out-Null
Copy-Item "$b\release\FaceZapper.exe" $deploy
cmd /c "windeployqt.exe --release --qmldir `"$src`" --compiler-runtime --no-translations --no-opengl-sw --no-system-d3d-compiler --skip-plugin-types qmltooling,tls,networkinformation,generic,position,sensors,multimedia `"$deploy\FaceZapper.exe`" > `"$b\windeployqt.log`" 2>&1"
if ($LASTEXITCODE -ne 0) { Get-Content "$b\windeployqt.log" -Tail 20; throw "windeployqt failed" }

# 2b. the app uses the Material style only (qtquickcontrols2.conf), which builds on Basic - the other
#     Qt Quick Controls styles are never loaded, windeployqt just can't leave QML modules out
foreach ($style in "FluentWinUI3", "Imagine", "Universal", "Fusion", "Windows") {
    Remove-Item -Recurse -Force "$deploy\qml\QtQuick\Controls\$style" -ErrorAction SilentlyContinue
    Remove-Item -Force "$deploy\Qt6QuickControls2$style.dll", "$deploy\Qt6QuickControls2${style}StyleImpl.dll" -ErrorAction SilentlyContinue
}
# the native style is only used by the Windows/macOS styles removed above
Remove-Item -Recurse -Force "$deploy\qml\QtQuick\Controls\Native", "$deploy\qml\QtQuick\NativeStyle" -ErrorAction SilentlyContinue
Remove-Item -Force "$deploy\Qt6QuickNativeStyle.dll" -ErrorAction SilentlyContinue

# 3. licence texts next to the exe (the app also shows them on "Über FaceZapper")
Copy-Item -Recurse "$src\licenses" "$deploy\licenses"

# 4. nothing that must not be there
$unwanted = Get-ChildItem -Recurse $deploy | Where-Object { $_.Name -match 'Quick3D|qmldbg|opengl32sw|tls|d3dcompiler' }
if ($unwanted) { $unwanted | ForEach-Object { $_.FullName }; throw "unwanted files deployed" }
$size = (Get-ChildItem -Recurse $deploy | Measure-Object Length -Sum).Sum
Write-Host ("deployed: {0} files, {1:N1} MB" -f (Get-ChildItem -Recurse -File $deploy).Count, ($size / 1MB))

# 5. portable ZIP
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = "$dist\FaceZapper-$version-Windows-portable.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path $deploy -DestinationPath $zip
Write-Host "ZIP: $zip"

# 6. installer
if (-not (Test-Path $iscc)) { throw "Inno Setup not found ($iscc) - winget install --id JRSoftware.InnoSetup -e" }
cmd /c "`"$iscc`" /Q /DAppVersion=$version /DSourceDir=`"$deploy`" /DOutputDir=`"$dist`" `"$src\windows\FaceZapper.iss`" > `"$b\iscc.log`" 2>&1"
if ($LASTEXITCODE -ne 0) { Get-Content "$b\iscc.log" -Tail 20; throw "Inno Setup failed" }
Get-ChildItem $dist | Select-Object Name, @{n='MB';e={[math]::Round($_.Length / 1MB, 1)}}
