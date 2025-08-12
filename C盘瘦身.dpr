program CDiskCleaner;

uses
  Vcl.Forms,
  Winapi.Windows,  // 添加Windows单元以使用Sleep函数
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

  // 并行处理：显示启动画面的同时创建主窗体
  Application.CreateForm(TfrmSplash, frmSplash);
  Application.CreateForm(TfrmMain, frmMain);

  // 显示启动画面（非模态）
  frmSplash.Show;

  // 处理消息，让启动画面显示
  Application.ProcessMessages;

  // 等待启动画面完成（通过检查其可见性）
  while frmSplash.Visible do
  begin
    Application.ProcessMessages;
    Sleep(10);
  end;

  // 释放启动画面
  frmSplash.Free;

  // 显示主窗体
  frmMain.Show;
  Application.Run;
end.
