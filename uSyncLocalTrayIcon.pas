unit uSyncLocalTrayIcon;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Classes,
  Vcl.Menus, Vcl.Forms, Vcl.Graphics, System.StrUtils, System.IOUtils,
  uSyncEngine, uSyncDatabase;

type
  // 同步任务的托盘状态
  TSyncTrayStatus = (stIdle, stSyncing, stSyncError, stSyncPaused, stSyncCompleted);

  TSyncLocalTrayIcon = class(TComponent)
  private
    FMainForm: TForm;
    FStatus: TSyncTrayStatus;
    FWnd: HWND;
    FNotifyMsg: UINT;
    FPopupMenu: TPopupMenu;
    FIcon: TIcon;
    FSyncEngine: TSyncEngine;
    FDatabase: TSyncDatabase;
    FMinimizeToTray: Boolean;
    FShowNotifications: Boolean;
    FEnableAutoStart: Boolean;

    // 图标资源
    FIconIdle: TIcon;
    FIconSyncing: TIcon;
    FIconError: TIcon;
    FIconPaused: TIcon;

    procedure WndProc(var Msg: TMessage);
    procedure CreateTrayIcon;
    procedure RemoveTrayIcon;
    procedure BuildMenu;
    procedure UpdateIcon;

    // 菜单事件处理
    procedure MenuShowClick(Sender: TObject);
    procedure MenuStartSyncClick(Sender: TObject);
    procedure MenuPauseSyncClick(Sender: TObject);
    procedure MenuResumeSyncClick(Sender: TObject);
    procedure MenuSettingsClick(Sender: TObject);
    procedure MenuAutoStartClick(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Initialize(AMainForm: TForm; ADatabase: TSyncDatabase; ASyncEngine: TSyncEngine);
    procedure ShowMainWindow;
    procedure HideToTray;
    procedure SetStatus(AStatus: TSyncTrayStatus);
    procedure ShowBalloon(const ATitle, AText: string; AIconType: Integer = NIIF_INFO);
    procedure UpdateSyncMenu;

    // 属性
    property MinimizeToTray: Boolean read FMinimizeToTray write FMinimizeToTray;
    property ShowNotifications: Boolean read FShowNotifications write FShowNotifications;
    property EnableAutoStart: Boolean read FEnableAutoStart write FEnableAutoStart;
    property Status: TSyncTrayStatus read FStatus write SetStatus;
    property SyncEngine: TSyncEngine read FSyncEngine write FSyncEngine;
  end;

implementation

uses
  System.RegistryAPI;

const
  AutoStartRegPath = 'Software\Microsoft\Windows\CurrentVersion\Run';
  AutoStartKey = 'syncLocal';

{ TSyncLocalTrayIcon }

constructor TSyncLocalTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNotifyMsg := WM_USER + 102;
  FWnd := AllocateHWnd(WndProc);
  FIcon := TIcon.Create;
  FIconIdle := TIcon.Create;
  FIconSyncing := TIcon.Create;
  FIconError := TIcon.Create;
  FIconPaused := TIcon.Create;
  FMinimizeToTray := True;
  FShowNotifications := True;
  FEnableAutoStart := False;
  FStatus := stIdle;
end;

destructor TSyncLocalTrayIcon.Destroy;
begin
  RemoveTrayIcon;
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  FIcon.Free;
  FIconIdle.Free;
  FIconSyncing.Free;
  FIconError.Free;
  FIconPaused.Free;
  inherited Destroy;
end;

procedure TSyncLocalTrayIcon.Initialize(AMainForm: TForm; ADatabase: TSyncDatabase; ASyncEngine: TSyncEngine);
begin
  FMainForm := AMainForm;
  FDatabase := ADatabase;
  FSyncEngine := ASyncEngine;
  FStatus := stIdle;

  // 创建图标资源（使用应用图标）
  if not Application.Icon.Empty then
  begin
    FIconIdle.Assign(Application.Icon);
    FIconSyncing.Assign(Application.Icon);
    FIconError.Assign(Application.Icon);
    FIconPaused.Assign(Application.Icon);
  end;

  BuildMenu;
  CreateTrayIcon;
end;

procedure TSyncLocalTrayIcon.ShowMainWindow;
begin
  if Assigned(FMainForm) then
  begin
    FMainForm.Show;
    FMainForm.BringToFront;
    if FMainForm.WindowState = wsMinimized then
      FMainForm.WindowState := wsNormal;
    Application.Restore;
    SetForegroundWindow(FMainForm.Handle);
  end;
end;

procedure TSyncLocalTrayIcon.HideToTray;
begin
  if Assigned(FMainForm) and FMinimizeToTray then
  begin
    FMainForm.Hide;
    if FShowNotifications then
      ShowBalloon('syncLocal', '程序已最小化到系统托盘');
  end;
end;

procedure TSyncLocalTrayIcon.SetStatus(AStatus: TSyncTrayStatus);
begin
  if FStatus <> AStatus then
  begin
    FStatus := AStatus;
    UpdateIcon;
    UpdateSyncMenu;
  end;
end;

procedure TSyncLocalTrayIcon.ShowBalloon(const ATitle, AText: string; AIconType: Integer = NIIF_INFO);
var
  Data: TNotifyIconData;
begin
  if not FShowNotifications then Exit;

  ZeroMemory(@Data, SizeOf(Data));
  Data.cbSize := SizeOf(Data);
  Data.Wnd := FWnd;
  Data.uID := 1;
  Data.uFlags := NIF_INFO;
  StrPLCopy(Data.szInfoTitle, ATitle, Length(Data.szInfoTitle) - 1);
  StrPLCopy(Data.szInfo, AText, Length(Data.szInfo) - 1);
  Data.uTimeout := 3000;
  Data.dwInfoFlags := AIconType;
  Shell_NotifyIcon(NIM_MODIFY, @Data);
end;

procedure TSyncLocalTrayIcon.WndProc(var Msg: TMessage);
var
  P: TPoint;
begin
  if Msg.Msg = FNotifyMsg then
  begin
    case Msg.LParam of
      WM_LBUTTONDBLCLK:
        ShowMainWindow;
      WM_LBUTTONUP:
        ShowMainWindow;
      WM_RBUTTONUP:
        begin
          GetCursorPos(P);
          if Assigned(FPopupMenu) then
          begin
            SetForegroundWindow(FWnd);
            FPopupMenu.Popup(P.X, P.Y);
            PostMessage(FWnd, WM_NULL, 0, 0);
          end;
        end;
    end;
  end
  else
    Msg.Result := DefWindowProc(FWnd, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TSyncLocalTrayIcon.BuildMenu;
var
  MI: TMenuItem;
begin
  if not Assigned(FPopupMenu) then
    FPopupMenu := TPopupMenu.Create(Self)
  else
    FPopupMenu.Items.Clear;

  // 显示主窗口
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '显示主窗口';
  MI.Hint := '显示 syncLocal 主界面';
  MI.OnClick := MenuShowClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  // 开始同步
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '开始同步';
  MI.Hint := '启动所有已启用的同步任务';
  MI.OnClick := MenuStartSyncClick;
  MI.Tag := 1; // 标记为同步相关菜单
  FPopupMenu.Items.Add(MI);

  // 暂停同步
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '暂停同步';
  MI.Hint := '暂停当前运行的同步任务';
  MI.OnClick := MenuPauseSyncClick;
  MI.Enabled := False;
  MI.Tag := 1;
  FPopupMenu.Items.Add(MI);

  // 恢复同步
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '恢复同步';
  MI.Hint := '恢复被暂停的同步任务';
  MI.OnClick := MenuResumeSyncClick;
  MI.Enabled := False;
  MI.Tag := 1;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  MI.Tag := 1;
  FPopupMenu.Items.Add(MI);

  // 开机自启
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '开机自启(&A)';
  MI.Hint := '设置程序是否开机时自动启动';
  MI.Checked := FEnableAutoStart;
  MI.OnClick := MenuAutoStartClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  // 设置
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '设置(&S)';
  MI.Hint := '打开程序设置';
  MI.OnClick := MenuSettingsClick;
  FPopupMenu.Items.Add(MI);

  // 关于
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '关于(&H)';
  MI.Hint := '查看程序信息';
  MI.OnClick := MenuAboutClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  // 退出
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '退出(&X)';
  MI.Hint := '退出程序';
  MI.OnClick := MenuExitClick;
  FPopupMenu.Items.Add(MI);

  UpdateSyncMenu;
end;

procedure TSyncLocalTrayIcon.UpdateIcon;
begin
  case FStatus of
    stIdle: FIcon.Assign(FIconIdle);
    stSyncing: FIcon.Assign(FIconSyncing);
    stSyncError: FIcon.Assign(FIconError);
    stSyncPaused: FIcon.Assign(FIconPaused);
    stSyncCompleted: FIcon.Assign(FIconIdle);
  end;
  CreateTrayIcon;
end;

procedure TSyncLocalTrayIcon.CreateTrayIcon;
var
  Data: TNotifyIconData;
  StatusText: string;
begin
  ZeroMemory(@Data, SizeOf(Data));
  Data.cbSize := SizeOf(Data);
  Data.Wnd := FWnd;
  Data.uID := 1;
  Data.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  Data.uCallbackMessage := FNotifyMsg;
  Data.hIcon := FIcon.Handle;

  case FStatus of
    stIdle: StatusText := 'syncLocal - 就绪';
    stSyncing: StatusText := 'syncLocal - 同步中';
    stSyncError: StatusText := 'syncLocal - 错误';
    stSyncPaused: StatusText := 'syncLocal - 已暂停';
    stSyncCompleted: StatusText := 'syncLocal - 同步完成';
  else
    StatusText := 'syncLocal';
  end;

  StrPLCopy(Data.szTip, StatusText, Length(Data.szTip) - 1);
  Shell_NotifyIcon(NIM_MODIFY, @Data);
end;

procedure TSyncLocalTrayIcon.RemoveTrayIcon;
var
  Data: TNotifyIconData;
begin
  ZeroMemory(@Data, SizeOf(Data));
  Data.cbSize := SizeOf(Data);
  Data.Wnd := FWnd;
  Data.uID := 1;
  Shell_NotifyIcon(NIM_DELETE, @Data);
end;

procedure TSyncLocalTrayIcon.UpdateSyncMenu;
var
  I: Integer;
  MenuItem: TMenuItem;
begin
  if not Assigned(FPopupMenu) then Exit;

  // 根据状态更新菜单项可用性
  for I := 0 to FPopupMenu.Items.Count - 1 do
  begin
    MenuItem := FPopupMenu.Items[I];
    if MenuItem.Tag = 1 then // 同步相关菜单
    begin
      case FStatus of
        stIdle:
          begin
            // 只有"开始同步"启用
            if MenuItem.Caption = '开始同步' then
              MenuItem.Enabled := True
            else if MenuItem.Caption <> '-' then
              MenuItem.Enabled := False;
          end;

        stSyncing:
          begin
            // 只有"暂停同步"启用
            if MenuItem.Caption = '暂停同步' then
              MenuItem.Enabled := True
            else if MenuItem.Caption <> '-' then
              MenuItem.Enabled := False;
          end;

        stSyncPaused:
          begin
            // "恢复同步"和"开始同步"启用
            if MenuItem.Caption = '恢复同步' then
              MenuItem.Enabled := True
            else if MenuItem.Caption = '开始同步' then
              MenuItem.Enabled := True
            else if MenuItem.Caption <> '-' then
              MenuItem.Enabled := False;
          end;

        stSyncError, stSyncCompleted:
          begin
            // "开始同步"启用
            if MenuItem.Caption = '开始同步' then
              MenuItem.Enabled := True
            else if MenuItem.Caption <> '-' then
              MenuItem.Enabled := False;
          end;
      end;
    end;
  end;
end;

// 菜单事件处理

procedure TSyncLocalTrayIcon.MenuShowClick(Sender: TObject);
begin
  ShowMainWindow;
end;

procedure TSyncLocalTrayIcon.MenuStartSyncClick(Sender: TObject);
begin
  if Assigned(FSyncEngine) then
  begin
    try
      SetStatus(stSyncing);
      ShowBalloon('同步开始', '正在启动同步任务...');
      FSyncEngine.StartAllSyncTasks;
    except
      on E: Exception do
      begin
        SetStatus(stSyncError);
        ShowBalloon('同步失败', E.Message, NIIF_ERROR);
        SetStatus(stIdle);
      end;
    end;
  end;
end;

procedure TSyncLocalTrayIcon.MenuPauseSyncClick(Sender: TObject);
begin
  if Assigned(FSyncEngine) then
  begin
    try
      FSyncEngine.PauseSync;
      SetStatus(stSyncPaused);
      ShowBalloon('同步暂停', '已暂停当前同步任务');
    except
      on E: Exception do
      begin
        ShowBalloon('暂停失败', E.Message, NIIF_ERROR);
      end;
    end;
  end;
end;

procedure TSyncLocalTrayIcon.MenuResumeSyncClick(Sender: TObject);
begin
  if Assigned(FSyncEngine) then
  begin
    try
      FSyncEngine.ResumeSync;
      SetStatus(stSyncing);
      ShowBalloon('同步恢复', '已恢复同步任务');
    except
      on E: Exception do
      begin
        ShowBalloon('恢复失败', E.Message, NIIF_ERROR);
      end;
    end;
  end;
end;

procedure TSyncLocalTrayIcon.MenuSettingsClick(Sender: TObject);
begin
  ShowMainWindow;
  if Assigned(FMainForm) then
  begin
    // 发送消息给主窗口打开设置
    PostMessage(FMainForm.Handle, WM_USER + 1, 0, 0);
  end;
end;

procedure TSyncLocalTrayIcon.MenuAutoStartClick(Sender: TObject);
const
  RegPath = AutoStartRegPath;
  RegKey = AutoStartKey;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey(RegPath, True) then
    begin
      FEnableAutoStart := not FEnableAutoStart;

      if FEnableAutoStart then
      begin
        // 添加开机自启
        Registry.WriteString(RegKey, '"' + ParamStr(0) + '" /silent');
        ShowBalloon('已启用', '已启用开机自启动');
      end
      else
      begin
        // 删除开机自启
        if Registry.ValueExists(RegKey) then
          Registry.DeleteValue(RegKey);
        ShowBalloon('已禁用', '已禁用开机自启动');
      end;

      Registry.CloseKey;

      // 更新菜单项的勾选状态
      UpdateSyncMenu;
      BuildMenu; // 重建菜单以更新勾选状态
    end;
  finally
    Registry.Free;
  end;
end;

procedure TSyncLocalTrayIcon.MenuAboutClick(Sender: TObject);
begin
  ShowMessage(
    'syncLocal v1.0.0' + sLineBreak +
    '本地文件同步服务' + sLineBreak + sLineBreak +
    '© 2025 Augment Code' + sLineBreak +
    'https://github.com/yourusername/syncLocal'
  );
end;

procedure TSyncLocalTrayIcon.MenuExitClick(Sender: TObject);
begin
  if Assigned(FMainForm) then
  begin
    FMainForm.Close;
    Application.Terminate;
  end;
end;

end.
