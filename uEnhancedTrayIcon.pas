unit uEnhancedTrayIcon;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Menus,
  System.StrUtils, System.IOUtils, Vcl.Graphics, Vcl.Forms,
  uCleanupManager; //, uEnhancedCleanupManager;

type
  TTrayStatus = (tsIdle, tsSyncing, tsError, tsCleaning);
  
  // 托盘菜单项类型
  TTrayMenuItemType = (
    tmiShow,
    tmiQuickClean,
    tmiEnhancedClean,
    tmiDuplicateCleanup,
    tmiSpaceAnalysis,
    tmiSettings,
    tmiAbout,
    tmiSeparator,
    tmiExit
  );

  TTrayManager = class(TComponent)
  private
    FMainForm: TForm;
    FStatus: TTrayStatus;
    FWnd: HWND;
    FNotifyMsg: UINT;
    FPopupMenu: TPopupMenu;
    FIcon: TIcon;
    FCleanupManager: TCleanupManager;
    FEnhancedCleanupManager: TEnhancedCleanupManager;
    FMinimizeToTray: Boolean;
    FShowNotifications: Boolean;
    
    // 图标资源
    FIconIdle: TIcon;
    FIconSyncing: TIcon;
    FIconError: TIcon;
    FIconCleaning: TIcon;
    
    procedure WndProc(var Msg: TMessage);
    procedure CreateTrayIcon;
    procedure RemoveTrayIcon;
    procedure BuildMenu;
    procedure UpdateIcon;
    
    // 菜单事件处理
    procedure MenuShowClick(Sender: TObject);
    procedure MenuQuickCleanClick(Sender: TObject);
    procedure MenuEnhancedCleanClick(Sender: TObject);
    procedure MenuDuplicateCleanupClick(Sender: TObject);
    procedure MenuSpaceAnalysisClick(Sender: TObject);
    procedure MenuTraySettingsClick(Sender: TObject);
    procedure MenuSettingsClick(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    
    // 清理相关方法
    procedure PerformQuickCleanup;
    procedure ShowCleanupResult(const AResult: TCleanupResult);
    procedure OnCleanupProgress(const AMessage: string; AProgress: Integer);
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Initialize(AMainForm: TForm);
    procedure ShowMainWindow;
    procedure HideToTray;
    procedure SetStatus(AStatus: TTrayStatus);
    procedure ShowBalloon(const ATitle, AText: string; AIconType: Integer = NIIF_INFO);
    
    // 属性
    property MinimizeToTray: Boolean read FMinimizeToTray write FMinimizeToTray;
    property ShowNotifications: Boolean read FShowNotifications write FShowNotifications;
    property CleanupManager: TCleanupManager read FCleanupManager write FCleanupManager;
    property EnhancedCleanupManager: TEnhancedCleanupManager read FEnhancedCleanupManager write FEnhancedCleanupManager;
  end;

implementation

uses
  uMain, uDuplicateFiles, uCleanupPreviewForm, uDiskAnalyzer, uTraySettingsForm;

{ TTrayManager }

constructor TTrayManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNotifyMsg := WM_USER + 101;
  FWnd := AllocateHWnd(WndProc);
  FIcon := TIcon.Create;
  FIconIdle := TIcon.Create;
  FIconSyncing := TIcon.Create;
  FIconError := TIcon.Create;
  FIconCleaning := TIcon.Create;
  FMinimizeToTray := True;
  FShowNotifications := True;
  FCleanupManager := nil;
  FEnhancedCleanupManager := nil;
end;

destructor TTrayManager.Destroy;
begin
  RemoveTrayIcon;
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  FIcon.Free;
  FIconIdle.Free;
  FIconSyncing.Free;
  FIconError.Free;
  FIconCleaning.Free;
  inherited Destroy;
end;

procedure TTrayManager.Initialize(AMainForm: TForm);
begin
  FMainForm := AMainForm;
  FStatus := tsIdle;
  
  // 创建图标资源（这里使用默认图标，实际应该加载不同的图标文件）
  if not Application.Icon.Empty then
  begin
    FIconIdle.Assign(Application.Icon);
    FIconSyncing.Assign(Application.Icon);
    FIconError.Assign(Application.Icon);
    FIconCleaning.Assign(Application.Icon);
  end;
  
  BuildMenu;
  CreateTrayIcon;
end;

procedure TTrayManager.ShowMainWindow;
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

procedure TTrayManager.HideToTray;
begin
  if Assigned(FMainForm) and FMinimizeToTray then
  begin
    FMainForm.Hide;
    if FShowNotifications then
      ShowBalloon('MoveC', '程序已最小化到系统托盘');
  end;
end;

procedure TTrayManager.SetStatus(AStatus: TTrayStatus);
begin
  FStatus := AStatus;
  UpdateIcon;
end;

procedure TTrayManager.ShowBalloon(const ATitle, AText: string; AIconType: Integer = NIIF_INFO);
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

procedure TTrayManager.WndProc(var Msg: TMessage);
var
  P: TPoint;
begin
  if Msg.Msg = FNotifyMsg then
  begin
    case Msg.LParam of
      WM_LBUTTONDBLCLK:
        ShowMainWindow;
      WM_LBUTTONUP:
        ShowMainWindow; // 单击左键也显示主窗口
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

procedure TTrayManager.BuildMenu;
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
  MI.Hint := '显示 MoveC 主界面';
  MI.OnClick := MenuShowClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  // 快速清理
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '快速清理';
  MI.Hint := '清理临时文件、回收站等常见垃圾';
  MI.OnClick := MenuQuickCleanClick;
  FPopupMenu.Items.Add(MI);

  // 增强清理预览
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '增强清理预览...';
  MI.Hint := '预览并选择要清理的项目';
  MI.OnClick := MenuEnhancedCleanClick;
  FPopupMenu.Items.Add(MI);

  // 重复文件清理
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '重复文件清理...';
  MI.Hint := '查找并清理重复文件';
  MI.OnClick := MenuDuplicateCleanupClick;
  FPopupMenu.Items.Add(MI);

  // 空间分析
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := 'C盘空间分析...';
  MI.Hint := '分析C盘空间使用情况';
  MI.OnClick := MenuSpaceAnalysisClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  // 设置
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '托盘设置...';
  MI.Hint := '配置托盘选项和通知';
  MI.OnClick := MenuTraySettingsClick;
  FPopupMenu.Items.Add(MI);

  // 设置
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '程序设置...';
  MI.Hint := '打开程序设置';
  MI.OnClick := MenuSettingsClick;
  FPopupMenu.Items.Add(MI);

  // 关于
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '关于 MoveC';
  MI.Hint := '查看程序信息';
  MI.OnClick := MenuAboutClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  // 退出
  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '退出';
  MI.Hint := '退出程序';
  MI.OnClick := MenuExitClick;
  FPopupMenu.Items.Add(MI);
end;

procedure TTrayManager.UpdateIcon;
begin
  case FStatus of
    tsIdle: FIcon.Assign(FIconIdle);
    tsSyncing: FIcon.Assign(FIconSyncing);
    tsError: FIcon.Assign(FIconError);
    tsCleaning: FIcon.Assign(FIconCleaning);
  end;
  CreateTrayIcon;
end;

procedure TTrayManager.CreateTrayIcon;
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
    tsIdle: StatusText := 'MoveC - 就绪';
    tsSyncing: StatusText := 'MoveC - 同步中';
    tsError: StatusText := 'MoveC - 错误';
    tsCleaning: StatusText := 'MoveC - 清理中';
  else
    StatusText := 'MoveC';
  end;
  
  StrPLCopy(Data.szTip, StatusText, Length(Data.szTip) - 1);
  Shell_NotifyIcon(NIM_MODIFY, @Data);
end;

procedure TTrayManager.RemoveTrayIcon;
var
  Data: TNotifyIconData;
begin
  ZeroMemory(@Data, SizeOf(Data));
  Data.cbSize := SizeOf(Data);
  Data.Wnd := FWnd;
  Data.uID := 1;
  Shell_NotifyIcon(NIM_DELETE, @Data);
end;

// 菜单事件处理

procedure TTrayManager.MenuShowClick(Sender: TObject);
begin
  ShowMainWindow;
end;

procedure TTrayManager.MenuQuickCleanClick(Sender: TObject);
begin
  try
    if Assigned(FMainForm) and (FMainForm is TfrmMain) then
    begin
      SetStatus(tsCleaning);
      ShowBalloon('快速清理', '正在执行快速清理...');
      PerformQuickCleanup;
      SetStatus(tsIdle);
    end;
  except
    on E: Exception do
    begin
      SetStatus(tsError);
      ShowBalloon('清理失败', E.Message, NIIF_ERROR);
      SetStatus(tsIdle);
    end;
  end;
end;

procedure TTrayManager.MenuEnhancedCleanClick(Sender: TObject);
var
  PreviewForm: TfrmCleanupPreview;
begin
  try
    if Assigned(FMainForm) then
    begin
      ShowMainWindow; // 先显示主窗口
      
      PreviewForm := TfrmCleanupPreview.Create(FMainForm);
      try
        PreviewForm.InitializePreview;
        PreviewForm.ShowModal;
      finally
        PreviewForm.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      ShowBalloon('错误', '无法打开增强清理预览：' + E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.MenuDuplicateCleanupClick(Sender: TObject);
var
  DuplicateForm: TfrmDuplicateFiles;
  RootPaths: TArray<string>;
begin
  try
    if Assigned(FMainForm) then
    begin
      ShowMainWindow; // 先显示主窗口
      
      DuplicateForm := TfrmDuplicateFiles.Create(FMainForm);
      try
        SetLength(RootPaths, 1);
        if TDirectory.Exists('C:\Users') then
          RootPaths[0] := 'C:\Users'
        else
          RootPaths[0] := 'C:\';
          
        DuplicateForm.ShowModal;
      finally
        DuplicateForm.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      ShowBalloon('错误', '无法打开重复文件清理：' + E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.MenuSpaceAnalysisClick(Sender: TObject);
begin
  try
    if Assigned(FMainForm) and (FMainForm is TfrmMain) then
    begin
      ShowMainWindow; // 先显示主窗口
      TfrmMain(FMainForm).btnAnalyze.Click;
    end;
  except
    on E: Exception do
    begin
      ShowBalloon('错误', '无法执行空间分析：' + E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.MenuTraySettingsClick(Sender: TObject);
var
  SettingsForm: TfrmTraySettings;
begin
  try
    SettingsForm := TfrmTraySettings.Create(nil);
    try
      SettingsForm.Initialize(Self);
      SettingsForm.ShowModal;
    finally
      SettingsForm.Free;
    end;
  except
    on E: Exception do
    begin
      ShowBalloon('错误', '无法打开托盘设置：' + E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.MenuSettingsClick(Sender: TObject);
begin
  try
    if Assigned(FMainForm) and (FMainForm is TfrmMain) then
    begin
      ShowMainWindow; // 先显示主窗口
      TfrmMain(FMainForm).miAdvancedOptions.Click;
    end;
  except
    on E: Exception do
    begin
      ShowBalloon('错误', '无法打开设置：' + E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.MenuAboutClick(Sender: TObject);
begin
  try
    if Assigned(FMainForm) and (FMainForm is TfrmMain) then
    begin
      ShowMainWindow; // 先显示主窗口
      TfrmMain(FMainForm).MenuHelpAbout.Click;
    end;
  except
    on E: Exception do
    begin
      ShowBalloon('错误', '无法显示关于信息：' + E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.MenuExitClick(Sender: TObject);
begin
  if Assigned(FMainForm) then
    FMainForm.Close;
end;

// 清理相关方法

procedure TTrayManager.PerformQuickCleanup;
var
  Result: TCleanupResult;
begin
  if not Assigned(FCleanupManager) then Exit;
  
  try
    FCleanupManager.OnProgress := OnCleanupProgress;
    Result := FCleanupManager.PerformSmartCleanup;
    ShowCleanupResult(Result);
  except
    on E: Exception do
    begin
      ShowBalloon('清理失败', E.Message, NIIF_ERROR);
    end;
  end;
end;

procedure TTrayManager.ShowCleanupResult(const AResult: TCleanupResult);
begin
  if AResult.Success then
  begin
    ShowBalloon('清理完成', 
      Format('删除 %d 个文件，释放 %s 空间', 
        [AResult.FilesDeleted, FormatFileSize(AResult.SpaceFreed)]), NIIF_INFO);
  end
  else
  begin
    ShowBalloon('清理失败', AResult.ErrorMessage, NIIF_ERROR);
  end;
end;

procedure TTrayManager.OnCleanupProgress(const AMessage: string; AProgress: Integer);
begin
  // 可以在这里更新托盘状态或显示进度提示
  // 由于托盘空间有限，这里暂不显示详细进度
end;

function FormatFileSize(const ASize: Int64): string;
begin
  if ASize < 1024 then
    Result := Format('%d 字节', [ASize])
  else if ASize < 1024 * 1024 then
    Result := Format('%.1f KB', [ASize / 1024.0])
  else if ASize < 1024 * 1024 * 1024 then
    Result := Format('%.1f MB', [ASize / (1024.0 * 1024.0)])
  else
    Result := Format('%.2f GB', [ASize / (1024.0 * 1024.0 * 1024.0)]);
end;

end.
