; -- MuhRO Professional Web Setup Script --

[Setup]
AppName=MuhRO
AppVersion=1.0
WizardStyle=modern
DefaultDirName={userdocs}\Games\MuhRO
DefaultGroupName=MuhRO
PrivilegesRequired=lowest
DisableDirPage=no
DisableProgramGroupPage=no
OutputBaseFilename=MuhRO_Installer
SetupIconFile=muhro.ico
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\Muh.exe
UninstallDisplayName=MuhRO
AppPublisher=
AppPublisherURL=

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";

[Files]
Source: "7za.exe"; Flags: dontcopy
Source: "curl.exe"; Flags: dontcopy
Source: "libcurl.dll"; Flags: dontcopy
Source: "progress.vbs"; Flags: dontcopy

[Icons]
Name: "{group}\MuhRO"; Filename: "{app}\Muh_Patcher.exe"
Name: "{userdesktop}\MuhRO"; Filename: "{app}\Muh_Patcher.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Muh_Patcher.exe"; Description: "Run Launcher now"; Flags: shellexec nowait skipifdoesntexist postinstall
[UninstallDelete]
Type: filesandordirs; Name: "{app}"


[Code]
var
  DownloadPage: TWizardPage;
  StatusLabel: TNewStaticText;
  DownloadProgressBar: TNewProgressBar;
  ProgressTimerID: Integer;
  AnimationCounter: Integer;
  LastProgress: String;
  ProgressKey: String;

// Timer functions from kernel32.dll
function SetTimer(hWnd: HWND; nIDEvent, uElapse: UINT; lpTimerFunc: LongWord): UINT;
  external 'SetTimer@user32.dll stdcall';
function KillTimer(hWnd: HWND; uIDEvent: UINT): BOOL;
  external 'KillTimer@user32.dll stdcall';

procedure CheckDownloadAndExtractFinished(Wnd: HWND; Msg, TimerID, Time: LongWord);
var
  ResultCode: Integer;
  UnzipCommand, ZipPath, SevenZipPath: String;
  AnimationText: String;
  sProgress: String;
  ProgressFloat: Extended;
  ProgressInt: Integer;
begin
  if FileExists(ExpandConstant('{tmp}\download.finished')) then
  begin
    KillTimer(0, ProgressTimerID);
    DeleteFile(ExpandConstant('{tmp}\download.finished'));

    if FileExists(ExpandConstant('{tmp}\MuhRO.7z')) then
    begin
      StatusLabel.Caption := 'Download complete. Extracting files...';
      WizardForm.ProgressGauge.Style := npbstMarquee;
      DownloadProgressBar.Style := npbstMarquee;
      
      CreateDir(ExpandConstant('{app}'));

      ZipPath := ExpandConstant('{tmp}\MuhRO.7z');
      SevenZipPath := ExpandConstant('{tmp}\7za.exe');
      UnzipCommand := 'x "' + ZipPath + '" -o"' + ExpandConstant('{app}') + '" -y';
      
      if Exec(SevenZipPath, UnzipCommand, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode <= 1) then
      begin
        StatusLabel.Caption := 'Installation complete.';
        WizardForm.ProgressGauge.Style := npbstNormal;
        DownloadProgressBar.Style := npbstNormal;
        WizardForm.ProgressGauge.Position := 100;
        DownloadProgressBar.Position := 100;
        WizardForm.NextButton.Enabled := True;
      end
      else
      begin
        StatusLabel.Caption := 'Extraction failed.';
        MsgBox('Failed to extract game files. Error code: ' + IntToStr(ResultCode), mbError, MB_OK);
        WizardForm.Close;
      end;
      DeleteFile(ZipPath);
    end
    else
    begin
      MsgBox('Download failed: The 7z file was not found after download.', mbError, MB_OK);
      WizardForm.Close;
    end;
  end
  else
  begin
    // Set a static status label text
    AnimationText := 'Downloading game files... Please wait';

    // Read progress from the registry
    if RegQueryStringValue(HKCU, 'Software\MuhRO', 'InstallProgress', sProgress) then
    begin
      try
        ProgressFloat := StrToFloat(sProgress);
        ProgressInt := Trunc(ProgressFloat);
        LastProgress := IntToStr(ProgressInt) + '%';
        WizardForm.ProgressGauge.Style := npbstNormal;
        WizardForm.ProgressGauge.Position := ProgressInt;
        DownloadProgressBar.Position := ProgressInt;
      except
        // Ignore conversion errors, keep marquee
      end;
    end;

    if LastProgress <> '' then
      StatusLabel.Caption := AnimationText + ' (' + LastProgress + ')'
    else
      StatusLabel.Caption := AnimationText;
  end;
end;

procedure DeinitializeSetup();
var
  ResultCode: Integer;
begin
  // Forcefully terminate the VBScript and curl processes to prevent orphaned downloads
  Exec('taskkill.exe', '/F /IM wscript.exe', '', SW_HIDE, ewNoWait, ResultCode);
  Exec('taskkill.exe', '/F /IM curl.exe', '', SW_HIDE, ewNoWait, ResultCode);
  // Clean up the registry key
  RegDeleteKeyIncludingSubkeys(HKCU, 'Software\MuhRO');
end;

procedure StartDownload(Page: TWizardPage);
var
  ResultCode: Integer;
  URL, ZipPath, SentinelPath, VBSPath, Params: String;
begin
  WizardForm.NextButton.Enabled := False;
  WizardForm.BackButton.Enabled := False;

  WizardForm.ProgressGauge.Visible := True;
  WizardForm.ProgressGauge.Style := npbstMarquee;
  StatusLabel.Caption := 'Downloading game files... Please wait.';

  ExtractTemporaryFile('7za.exe');
  ExtractTemporaryFile('curl.exe');
  ExtractTemporaryFile('libcurl.dll');
  ExtractTemporaryFile('progress.vbs');
  
  ZipPath := ExpandConstant('{tmp}\MuhRO.7z');
  SentinelPath := ExpandConstant('{tmp}\download.finished');
  VBSPath := ExpandConstant('{tmp}\progress.vbs');
  URL := 'https://muhro.ecneproject.com/muhinstaller/MuhRO.7z';
  
  // Execute the download VBScript
  Params := '"' + VBSPath + '" "' + URL + '" "' + ZipPath + '" "' + SentinelPath + '"';
  if not Exec('wscript.exe', Params, '', SW_HIDE, ewNoWait, ResultCode) then
  begin
    MsgBox('Failed to start the downloader script.', mbError, MB_OK);
    WizardForm.Close;
    Exit;
  end;

  ProgressTimerID := SetTimer(0, 0, 1000, CreateCallback(@CheckDownloadAndExtractFinished));
end;

procedure InitializeWizard();
var
  Margin: Integer;
begin
  DownloadPage := CreateCustomPage(wpReady, 'Downloading and Installing', 'Please wait while the game is downloaded and installed.');
  
  Margin := ScaleX(10);

  StatusLabel := TNewStaticText.Create(DownloadPage);
  StatusLabel.Parent := DownloadPage.Surface;
  StatusLabel.Left := Margin;
  StatusLabel.Top := DownloadPage.SurfaceHeight div 2 - ScaleY(10);
  StatusLabel.Width := DownloadPage.SurfaceWidth - 2 * Margin;
  StatusLabel.Caption := 'Initializing...';

  DownloadProgressBar := TNewProgressBar.Create(DownloadPage);
  DownloadProgressBar.Parent := DownloadPage.Surface;
  DownloadProgressBar.Left := Margin;
  DownloadProgressBar.Top := StatusLabel.Top + StatusLabel.Height + ScaleY(5);
  DownloadProgressBar.Width := DownloadPage.SurfaceWidth - 2 * Margin;

  AnimationCounter := 0;
  LastProgress := '';
end;

procedure CurPageChanged(CurPageID: Integer);
var
  I: Integer;
begin
  if CurPageID = DownloadPage.ID then
  begin
    StartDownload(DownloadPage);
  end
  else if CurPageID = wpFinished then
  begin
    // Find the 'Run Launcher now' checkbox and check it by default.
    for I := 0 to WizardForm.RunList.Items.Count - 1 do
    begin
      if Pos('Run Launcher now', WizardForm.RunList.Items[I]) > 0 then
      begin
        WizardForm.RunList.Checked[I] := True;
        break;
      end;
    end;
  end;
end;
