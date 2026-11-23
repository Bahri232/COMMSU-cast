; Inno Setup Script for ComSSU Cast
#define MyAppName "ComSSU Cast"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Abdul Malik Barrie (BAHRI) — ComSSU, UniMak"
#define MyAppURL "https://unimak.edu.sl"
#define MyAppExeName "ComSSUCast.exe"

[Setup]
AppId={{9F85F8C7-1F4A-4B6A-9148-569A5EB60C0A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppCopyright=Copyright (C) 2026-2027 Abdul Malik Barrie (BAHRI) - ComSSU, University of Makeni
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=ComSSU Wireless Display System Setup
VersionInfoVersion=1.0.0.0
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoCopyright=Copyright (C) 2026-2027 Abdul Malik Barrie (BAHRI)
DefaultDirName={autopf}\ComSSUCast
DisableProgramGroupPage=yes
SourceDir=..\..
OutputDir=dist
OutputBaseFilename=ComSSUCast-windows-x64-Setup
SetupIconFile=resources\icons\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
#ifdef SIGN_TOOL
SignTool=comssu_sign
SignedUninstaller=yes
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\ComSSUCast\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""ComSSUCast Application"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""ComSSUCast Application"" dir=in action=allow program=""{app}\{#MyAppExeName}"" profile=private,domain,public enable=yes"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""ComSSUMiracastHelper Application"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""ComSSUMiracastHelper Application"" dir=in action=allow program=""{app}\ComSSUMiracastHelper.exe"" profile=private,domain,public enable=yes"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""ComSSUCast Windows CastSrv"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""ComSSUCast Windows CastSrv"" dir=in action=allow program=""{sys}\CastSrv.exe"" profile=private,domain,public enable=yes"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""ComSSUCast Windows WUDFHost"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""ComSSUCast Windows WUDFHost"" dir=in action=allow program=""{sys}\WUDFHost.exe"" profile=private,domain,public enable=yes"; Flags: runhidden
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
