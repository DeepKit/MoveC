program CDiskCleaner;

uses
  Vcl.Forms,
  // Core data types first
  DataTypes in 'Core\DataTypes.pas',
  // UI components
  uStyles in 'uStyles.pas',
  uSplash in 'uSplash.pas' {frmSplash},
  // Main form last
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  // 显示启动画面
  Application.CreateForm(TfrmSplash, frmSplash);
  frmSplash.ShowModal;
  frmSplash.Free;

  // 创建主窗体
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
