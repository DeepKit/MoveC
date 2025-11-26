unit uSyncLocalMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Menus, System.IOUtils, System.RegistryAPI,
  uSyncEngine, uSyncDatabase, uSyncLocalTrayIcon, uDatabaseConfig;

type
  TfrmSyncLocalMain = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    pnlStatus: TPanel;
    memoStatus: TMemo;
    pnlBottom: TPanel;
    btnSettings: TButton;
    btnExit: TButton;
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    miFile: TMenuItem;
    miFileExit: TMenuItem;
    miTools: TMenuItem;
    miSettings: TMenuItem;
    miHelp: TMenuItem;
    miAbout: TMenuItem;
    Splitter1: TSplitter;
    lvTasks: TListView;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormWindowStateChange(Sender: TObject);

    procedure btnSettingsClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure miFileExitClick(Sender: TObject);
    procedure miSettingsClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure WMQueryEndSession(var Message: TWMQueryEndSession); message WM_QUERYENDSESSION;

  private
    FTrayIcon: TSyncLocalTrayIcon;
    FDatabase: TSyncDatabase;
    FSyncEngine: TSyncEngine;
    FTaskList: TList;
    FAutoStartEnabled: Boolean;

    procedure InitializeTrayIcon;
    procedure LoadTasks;
    procedure UpdateUI;
    procedure LogMessage(const AMessage: string);
    procedure SetupAutoStart(AEnable: Boolean);
    function IsAutoStartEnabled: Boolean;

  public
    procedure MinimizeToTray;
    procedure RestoreFromTray;
  end;

var
  frmSyncLocalMain: TfrmSyncLocalMain;

implementation

{$R *.dfm}

{ TfrmSyncLocalMain }

procedure TfrmSyncLocalMain.FormCreate(Sender: TObject);
var
  DbPath: string;
begin
  // 创始化数据库
  DbPath := TDatabaseConfig.GetDatabasePath;
  FDatabase := TSyncDatabase.Create(DbPath);
  
  if not FDatabase.Connect then
  begin
    LogMessage('错误：数据库连接失败 - ' + DbPath);
    ShowMessage('数据库连接失败，程序将退出。');
    Application.Terminate;
    Exit;
  end;
  
  LogMessage('数据库已连接: ' + DbPath);
  
  FTaskList := TList.Create;
  FAutoStartEnabled := IsAutoStartEnabled;
  
  // 初始化托盘图标
  InitializeTrayIcon;
  
  // 加载同步任务
  LoadTasks;
  
  // 更新界面
  UpdateUI;
end;

procedure TfrmSyncLocalMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FTrayIcon) then
    FreeAndNil(FTrayIcon);
  
  if Assigned(FSyncEngine) then
    FreeAndNil(FSyncEngine);
  
  if Assigned(FDatabase) then
  begin
    FDatabase.Disconnect;
    FreeAndNil(FDatabase);
  end;
  
  FreeAndNil(FTaskList);
end;

procedure TfrmSyncLocalMain.FormShow(Sender: TObject);
begin
  LogMessage('syncLocal ' + GetFileVersion(ParamStr(0)) + ' 已启动');
end;

procedure TfrmSyncLocalMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // 最小化到托盘而不是关闭
  if not (csDestroying in ComponentState) then
  begin
    Action := caNone;
    MinimizeToTray;
  end;
end;

procedure TfrmSyncLocalMain.FormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then
    MinimizeToTray;
end;

procedure TfrmSyncLocalMain.WMQueryEndSession(var Message: TWMQueryEndSession);
begin
  // 系统关闭时保存状态
  LogMessage('系统关闭事件');
  Message.Result := 1; // 允许系统关闭
end;

procedure TfrmSyncLocalMain.InitializeTrayIcon;
begin
  FTrayIcon := TSyncLocalTrayIcon.Create(Self);
  FSyncEngine := TSyncEngine.Create(Self);
  FTrayIcon.Initialize(Self, FDatabase, FSyncEngine);
  FTrayIcon.MinimizeToTray := True;
  FTrayIcon.ShowNotifications := True;
end;

procedure TfrmSyncLocalMain.LoadTasks;
var
  Tasks: TArray<uSyncDatabase.TSyncTask>;
  I: Integer;
  Item: TListItem;
begin
  if not Assigned(FDatabase) then
    Exit;
  
  lvTasks.Clear;
  Tasks := FDatabase.GetAllSyncTasks;
  
  LogMessage(Format('已加载 %d 个同步任务', [Length(Tasks)]));
  
  for I := 0 to High(Tasks) do
  begin
    Item := lvTasks.Items.Add;
    Item.Caption := Tasks[I].Name;
    Item.SubItems.Add(Tasks[I].SourcePath);
    Item.SubItems.Add(Tasks[I].TargetPath);
    if Tasks[I].IsEnabled then
      Item.SubItems.Add('已启用')
    else
      Item.SubItems.Add('已禁用');
  end;
end;

procedure TfrmSyncLocalMain.UpdateUI;
begin
  StatusBar1.SimpleText := '状态：空闲 | ' + FormatDateTime('HH:mm:ss', Now);
  
  if lvTasks.Items.Count = 0 then
    lblStatus.Caption := '未配置任何同步任务'
  else
    lblStatus.Caption := Format('已配置 %d 个同步任务', [lvTasks.Items.Count]);
end;

procedure TfrmSyncLocalMain.LogMessage(const AMessage: string);
begin
  memoStatus.Lines.Add('[' + FormatDateTime('HH:mm:ss', Now) + '] ' + AMessage);
  
  // 自动滚动到最底部
  if memoStatus.Lines.Count > 0 then
    memoStatus.Perform(EM_LINESCROLL, 0, memoStatus.Lines.Count);
end;

procedure TfrmSyncLocalMain.SetupAutoStart(AEnable: Boolean);
const
  RegPath = 'Software\Microsoft\Windows\CurrentVersion\Run';
  RegKey = 'syncLocal';
begin
  var
    Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey(RegPath, True) then
    begin
      if AEnable then
      begin
        // 添加开机自启
        Registry.WriteString(RegKey, '"' + ParamStr(0) + '" /silent');
        LogMessage('已启用开机自启动');
      end
      else
      begin
        // 删除开机自启
        Registry.DeleteValue(RegKey);
        LogMessage('已禁用开机自启动');
      end;
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

function TfrmSyncLocalMain.IsAutoStartEnabled: Boolean;
const
  RegPath = 'Software\Microsoft\Windows\CurrentVersion\Run';
  RegKey = 'syncLocal';
begin
  var
    Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey(RegPath, False) then
    begin
      Result := Registry.ValueExists(RegKey);
      Registry.CloseKey;
    end
    else
      Result := False;
  finally
    Registry.Free;
  end;
end;

procedure TfrmSyncLocalMain.MinimizeToTray;
begin
  ShowWindow(Handle, SW_HIDE);
  WindowState := wsMinimized;
end;

procedure TfrmSyncLocalMain.RestoreFromTray;
begin
  ShowWindow(Handle, SW_SHOW);
  WindowState := wsNormal;
  BringToFront;
end;

procedure TfrmSyncLocalMain.btnSettingsClick(Sender: TObject);
begin
  miSettingsClick(Sender);
end;

procedure TfrmSyncLocalMain.btnExitClick(Sender: TObject);
begin
  Close;
  Application.Terminate;
end;

procedure TfrmSyncLocalMain.miFileExitClick(Sender: TObject);
begin
  btnExitClick(Sender);
end;

procedure TfrmSyncLocalMain.miSettingsClick(Sender: TObject);
begin
  // 打开同步设置窗体
  if Assigned(frmSyncSettingsBasic) then
    frmSyncSettingsBasic.ShowModal;
end;

procedure TfrmSyncLocalMain.miAboutClick(Sender: TObject);
begin
  ShowMessage(
    'syncLocal v1.0.0' + sLineBreak +
    '本地文件同步服务' + sLineBreak + sLineBreak +
    '© 2025 Augment Code' + sLineBreak +
    'https://github.com/yourusername/syncLocal'
  );
end;

function GetFileVersion(const AFilePath: string): string;
begin
  Result := 'v1.0.0'; // TODO: 从资源获取真实版本
end;

end.
