unit uTrayIcon;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Menus,
  Winapi.Windows, Winapi.ShellAPI, Vcl.Graphics, Winapi.Messages;

type
  TTrayStatus = (tsIdle, tsSyncing, tsError);
  
  TExitEvent = procedure of object;

  TTrayManager = class(TComponent)
  private
    FMainForm: TForm;
    FStatus: TTrayStatus;
    FWnd: HWND;
    FNotifyMsg: UINT;
    FPopupMenu: TPopupMenu;
    FIcon: TIcon;
    FOnExit: TExitEvent;
    procedure WndProc(var Msg: TMessage);
    procedure CreateTrayIcon;
    procedure RemoveTrayIcon;
    procedure BuildMenu;
    procedure MenuShowClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialize(AMainForm: TForm);
    procedure ShowMainWindow;
    procedure SetStatus(AStatus: TTrayStatus);
    procedure ShowBalloon(const ATitle, AText: string);
    property OnExit: TExitEvent read FOnExit write FOnExit;
  end;

implementation

{ TTrayManager }

constructor TTrayManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNotifyMsg := WM_USER + 101;
  FWnd := AllocateHWnd(WndProc);
  FIcon := TIcon.Create;
end;

destructor TTrayManager.Destroy;
begin
  RemoveTrayIcon;
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  FIcon.Free;
  inherited Destroy;
end;

procedure TTrayManager.Initialize(AMainForm: TForm);
begin
  FMainForm := AMainForm;
  FStatus := tsIdle;
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
  end;
end;

procedure TTrayManager.SetStatus(AStatus: TTrayStatus);
begin
  FStatus := AStatus;
  // 可按状态切换不同图标，现使用应用主图标
  CreateTrayIcon;
end;

procedure TTrayManager.ShowBalloon(const ATitle, AText: string);
var
  Data: TNotifyIconData;
begin
  ZeroMemory(@Data, SizeOf(Data));
  Data.cbSize := SizeOf(Data);
  Data.Wnd := FWnd;
  Data.uID := 1;
  Data.uFlags := NIF_INFO;
  StrPLCopy(Data.szInfoTitle, ATitle, Length(Data.szInfoTitle) - 1);
  StrPLCopy(Data.szInfo, AText, Length(Data.szInfo) - 1);
  Data.uTimeout := 3000;
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

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '显示主窗口';
  MI.OnClick := MenuShowClick;
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '-';
  FPopupMenu.Items.Add(MI);

  MI := TMenuItem.Create(FPopupMenu);
  MI.Caption := '退出';
  MI.OnClick := MenuExitClick;
  FPopupMenu.Items.Add(MI);
end;

procedure TTrayManager.MenuShowClick(Sender: TObject);
begin
  ShowMainWindow;
end;

procedure TTrayManager.MenuExitClick(Sender: TObject);
begin
  // 调用OnExit事件处理真正退出
  if Assigned(FOnExit) then
    FOnExit
  else if Assigned(FMainForm) then
    FMainForm.Close;
end;

procedure TTrayManager.CreateTrayIcon;
var
  Data: TNotifyIconData;
begin
  if not Application.Icon.Empty then
    FIcon.Assign(Application.Icon)
  else if Assigned(FMainForm) and not FMainForm.Icon.Empty then
    FIcon.Assign(FMainForm.Icon);

  ZeroMemory(@Data, SizeOf(Data));
  Data.cbSize := SizeOf(Data);
  Data.Wnd := FWnd;
  Data.uID := 1;
  Data.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  Data.uCallbackMessage := FNotifyMsg;
  Data.hIcon := FIcon.Handle;
  StrPLCopy(Data.szTip, 'MoveC 后台运行中', Length(Data.szTip) - 1);
  Shell_NotifyIcon(NIM_ADD, @Data);
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

end.
