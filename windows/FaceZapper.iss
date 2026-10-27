; Inno Setup 6 script for FaceZapper (built by tools\build-windows-release.ps1, which passes
; AppVersion, SourceDir = the deployed app folder and OutputDir).
; Installs for the current user only (no administrator rights), dialogs in the app's languages.
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
; the app's languages (i18n/); the setup picks the one matching Windows, otherwise the first (English)
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\FaceZapper"; Filename: "{app}\FaceZapper.exe"
Name: "{autodesktop}\FaceZapper"; Filename: "{app}\FaceZapper.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\FaceZapper.exe"; Description: "{cm:LaunchProgram,FaceZapper}"; Flags: nowait postinstall skipifsilent
