program C盘瘦身;

uses
  Vcl.Forms,
  Winapi.Windows,
  System.SysUtils, System.IOUtils,
  uSplash in 'uSplash.pas' {frmSplash},
  uMain in 'uMain.pas' {frmMain},
  uIconManager in 'uIconManager.pas',

  FrameAboutMe in 'FrameAboutMe.pas' {FrameAboutMe: TFrame},
  // 图像安全模块
  uImageSecurity in 'uImageSecurity.pas',
  // 清理管理器
  uCleanupManager in 'uCleanupManager.pas';

{$R 'C盘超级瘦身.res' 'C盘瘦身.rc'}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := True;

  // 入口前置关键资源自检（fail-closed）
  try
    var DbPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
    if not TFile.Exists(DbPath) then
    begin
      MessageBox(0, '检测到关键资源缺失：MoveC.db。程序将退出。', '安全警告', MB_OK or MB_ICONERROR or MB_TOPMOST);
      Halt(1);
    end;
  except
    Halt(1);
  end;

  // 先创建并显示启动画面（不使用 Application.CreateForm，避免成为 MainForm）
  frmSplash := TfrmSplash.Create(nil);
  frmSplash.Show;
  Application.ProcessMessages;

  // 稍作等待，确保 Splash 已绘制首帧
  Sleep(50);

  // 再创建主窗体（较重的DFM加载放在Splash之后）
  Application.CreateForm(TfrmMain, frmMain);
  frmMain.Show; // 显式显示主窗体

  // 进入消息循环
  Application.Run;
end.
