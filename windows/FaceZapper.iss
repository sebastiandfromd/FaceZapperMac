; Inno Setup 6 script for FaceZapper (built by tools\build-windows-release.ps1, which passes
; AppVersion, SourceDir = the deployed app folder and OutputDir).
; Installs for the current user only (no administrator rights), German dialogs.
; Uninstalling leaves the user's data alone: .faceZapperData in the picture folders,
; %APPDATA%\FaceZapper and the settings in the registry - a reinstall keeps the learning progress.

#ifndef AppVersion
  #define AppVersion "0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\deploy\FaceZapper"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist"
#endif

[Setup]
; fixed id: a newer setup installs over the old version
AppId={{5E2C3A71-9B4D-4F2E-8C6A-1D7F0B93A4E5}
AppName=FaceZapper
AppVersion={#AppVersion}
AppVerName=FaceZapper {#AppVersion}
AppPublisher=Sebastian Diel
AppCopyright=(c) 2026 Sebastian Diel
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\FaceZapper
DefaultGroupName=FaceZapper
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=FaceZapper-{#AppVersion}-Setup
SetupIconFile=FaceZapper.ico
UninstallDisplayIcon={app}\FaceZapper.exe
UninstallDisplayName=FaceZapper
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\FaceZapper"; Filename: "{app}\FaceZapper.exe"
Name: "{autodesktop}\FaceZapper"; Filename: "{app}\FaceZapper.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\FaceZapper.exe"; Description: "{cm:LaunchProgram,FaceZapper}"; Flags: nowait postinstall skipifsilent
