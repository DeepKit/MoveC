program C盘瘦身;

uses
  Vcl.Forms,
  Winapi.Windows,
  uSplash in 'uSplash.pas' {frmSplash},
  uMain in 'uMain.pas' {frmMain},
  uIconManager in 'uIconManager.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := True;

  // 先创建并显示启动画面（不使用 Application.CreateForm，避免成为 MainForm）
  frmSplash := TfrmSplash.Create(nil);
  frmSplash.Show;
  Application.ProcessMessages;

  // 稍作等待，确保 Splash 已绘制首帧
  Sleep(50);

  // 再创建主窗体（较重的DFM加载放在Splash之后）
  Application.CreateForm(TfrmMain, frmMain);
  frmMain.Show; // 显式显示主窗体

  // 进入消息循环；主窗体在 InitAfterShow 完成后关闭并释放 Splash
  Application.Run;
end.
