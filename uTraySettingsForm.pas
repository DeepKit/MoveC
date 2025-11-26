unit uTraySettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, uEnhancedTrayIcon;

type
  TfrmTraySettings = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlSettings: TPanel;
    grpTrayOptions: TGroupBox;
    chkMinimizeToTray: TCheckBox;
    chkShowNotifications: TCheckBox;
    grpStartupOptions: TGroupBox;
    chkStartMinimized: TCheckBox;
    chkStartWithWindows: TCheckBox;
    grpNotifications: TGroupBox;
    chkShowCleanupNotifications: TCheckBox;
    chkShowSyncNotifications: TCheckBox;
    chkShowErrorNotifications: TCheckBox;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    btnReset: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure chkStartWithWindowsClick(Sender: TObject);
    
  private
    FTrayManager: TTrayManager;
    FOriginalSettings: record
      MinimizeToTray: Boolean;
      ShowNotifications: Boolean;
      StartMinimized: Boolean;
      StartWithWindows: Boolean;
      ShowCleanupNotifications: Boolean;
      ShowSyncNotifications: Boolean;
      ShowErrorNotifications: Boolean;
    end;
    
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ResetToDefaults;
    procedure UpdateButtonStates;
    function GetStartupShortcutPath: string;
    procedure CreateStartupShortcut;
    procedure RemoveStartupShortcut;
    function IsStartupShortcutExists: Boolean;
    
  public
    procedure Initialize(ATrayManager: TTrayManager);
  end;

var
  frmTraySettings: TfrmTraySettings;

implementation

{$R *.dfm}

uses
  Winapi.ShellApi, Registry;

{ TfrmTraySettings }

procedure TfrmTraySettings.FormCreate(Sender: TObject);
begin
  Caption := '托盘设置';
  Width := 450;
  Height := 400;
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  
  FTrayManager := nil;
  LoadSettings;
  UpdateButtonStates;
end;

procedure TfrmTraySettings.FormDestroy(Sender: TObject);
begin
  // 不释放 FTrayManager，因为它由主窗体拥有
end;

procedure TfrmTraySettings.Initialize(ATrayManager: TTrayManager);
begin
  FTrayManager := ATrayManager;
  LoadSettings;
end;

procedure TfrmTraySettings.LoadSettings;
var
  Registry: TRegistry;
begin
  // 从注册表加载设置
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\MoveC\TraySettings', False) then
    begin
      chkMinimizeToTray.Checked := Registry.ReadBool('MinimizeToTray', True);
      chkShowNotifications.Checked := Registry.ReadBool('ShowNotifications', True);
      chkStartMinimized.Checked := Registry.ReadBool('StartMinimized', False);
      chkStartWithWindows.Checked := Registry.ReadBool('StartWithWindows', False);
      chkShowCleanupNotifications.Checked := Registry.ReadBool('ShowCleanupNotifications', True);
      chkShowSyncNotifications.Checked := Registry.ReadBool('ShowSyncNotifications', True);
      chkShowErrorNotifications.Checked := Registry.ReadBool('ShowErrorNotifications', True);
      Registry.CloseKey;
    end
    else
    begin
      // 默认设置
      ResetToDefaults;
    end;
  finally
    Registry.Free;
  end;
  
  // 保存原始设置用于比较
  FOriginalSettings.MinimizeToTray := chkMinimizeToTray.Checked;
  FOriginalSettings.ShowNotifications := chkShowNotifications.Checked;
  FOriginalSettings.StartMinimized := chkStartMinimized.Checked;
  FOriginalSettings.StartWithWindows := chkStartWithWindows.Checked;
  FOriginalSettings.ShowCleanupNotifications := chkShowCleanupNotifications.Checked;
  FOriginalSettings.ShowSyncNotifications := chkShowSyncNotifications.Checked;
  FOriginalSettings.ShowErrorNotifications := chkShowErrorNotifications.Checked;
  
  // 如果有托盘管理器，同步当前设置
  if Assigned(FTrayManager) then
  begin
    chkMinimizeToTray.Checked := FTrayManager.MinimizeToTray;
    chkShowNotifications.Checked := FTrayManager.ShowNotifications;
  end;
end;

procedure TfrmTraySettings.SaveSettings;
var
  Registry: TRegistry;
begin
  // 保存到注册表
  Registry := TRegistry.Create(KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\MoveC\TraySettings', True) then
    begin
      Registry.WriteBool('MinimizeToTray', chkMinimizeToTray.Checked);
      Registry.WriteBool('ShowNotifications', chkShowNotifications.Checked);
      Registry.WriteBool('StartMinimized', chkStartMinimized.Checked);
      Registry.WriteBool('StartWithWindows', chkStartWithWindows.Checked);
      Registry.WriteBool('ShowCleanupNotifications', chkShowCleanupNotifications.Checked);
      Registry.WriteBool('ShowSyncNotifications', chkShowSyncNotifications.Checked);
      Registry.WriteBool('ShowErrorNotifications', chkShowErrorNotifications.Checked);
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
  
  // 应用到托盘管理器
  if Assigned(FTrayManager) then
  begin
    FTrayManager.MinimizeToTray := chkMinimizeToTray.Checked;
    FTrayManager.ShowNotifications := chkShowNotifications.Checked;
  end;
  
  // 处理开机启动
  if chkStartWithWindows.Checked then
    CreateStartupShortcut
  else
    RemoveStartupShortcut;
end;

procedure TfrmTraySettings.ResetToDefaults;
begin
  chkMinimizeToTray.Checked := True;
  chkShowNotifications.Checked := True;
  chkStartMinimized.Checked := False;
  chkStartWithWindows.Checked := False;
  chkShowCleanupNotifications.Checked := True;
  chkShowSyncNotifications.Checked := True;
  chkShowErrorNotifications.Checked := True;
end;

procedure TfrmTraySettings.UpdateButtonStates;
begin
  btnApply.Enabled := 
    (FOriginalSettings.MinimizeToTray <> chkMinimizeToTray.Checked) or
    (FOriginalSettings.ShowNotifications <> chkShowNotifications.Checked) or
    (FOriginalSettings.StartMinimized <> chkStartMinimized.Checked) or
    (FOriginalSettings.StartWithWindows <> chkStartWithWindows.Checked) or
    (FOriginalSettings.ShowCleanupNotifications <> chkShowCleanupNotifications.Checked) or
    (FOriginalSettings.ShowSyncNotifications <> chkShowSyncNotifications.Checked) or
    (FOriginalSettings.ShowErrorNotifications <> chkShowErrorNotifications.Checked);
end;

procedure TfrmTraySettings.btnOKClick(Sender: TObject);
begin
  SaveSettings;
  ModalResult := mrOk;
end;

procedure TfrmTraySettings.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmTraySettings.btnApplyClick(Sender: TObject);
begin
  SaveSettings;
  
  // 更新原始设置
  FOriginalSettings.MinimizeToTray := chkMinimizeToTray.Checked;
  FOriginalSettings.ShowNotifications := chkShowNotifications.Checked;
  FOriginalSettings.StartMinimized := chkStartMinimized.Checked;
  FOriginalSettings.StartWithWindows := chkStartWithWindows.Checked;
  FOriginalSettings.ShowCleanupNotifications := chkShowCleanupNotifications.Checked;
  FOriginalSettings.ShowSyncNotifications := chkShowSyncNotifications.Checked;
  FOriginalSettings.ShowErrorNotifications := chkShowErrorNotifications.Checked;
  
  UpdateButtonStates;
end;

procedure TfrmTraySettings.btnResetClick(Sender: TObject);
begin
  ResetToDefaults;
  UpdateButtonStates;
end;

procedure TfrmTraySettings.chkStartWithWindowsClick(Sender: TObject);
begin
  UpdateButtonStates;
end;

// 开机启动相关方法

function TfrmTraySettings.GetStartupShortcutPath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 
            'Microsoft\Windows\Start Menu\Programs\Startup\MoveC.lnk';
end;

function TfrmTraySettings.IsStartupShortcutExists: Boolean;
begin
  Result := FileExists(GetStartupShortcutPath);
end;

procedure TfrmTraySettings.CreateStartupShortcut;
var
  ShellLink: IShellLink;
  PersistFile: IPersistFile;
  ShortcutPath: WideString;
begin
  if IsStartupShortcutExists then Exit;
  
  ShellLink := CoShellLink.Create;
  PersistFile := ShellLink as IPersistFile;
  
  // 设置快捷方式属性
  ShellLink.SetPath(PChar(Application.ExeName));
  ShellLink.SetWorkingDirectory(PChar(ExtractFilePath(Application.ExeName)));
  ShellLink.SetDescription(PChar('MoveC C盘瘦身神器'));
  
  if chkStartMinimized.Checked then
    ShellLink.SetArguments(PChar('-minimized'))
  else
    ShellLink.SetArguments('');
  
  // 保存快捷方式
  ShortcutPath := GetStartupShortcutPath;
  PersistFile.Save(PWideChar(ShortcutPath), False);
end;

procedure TfrmTraySettings.RemoveStartupShortcut;
begin
  if IsStartupShortcutExists then
    DeleteFile(GetStartupShortcutPath);
end;

end.
