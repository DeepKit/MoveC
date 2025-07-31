program C������;

uses
  Vcl.Forms,
  // Core data types first
  DataTypes in 'Core\DataTypes.pas',
  // Interfaces
  IFileAnalyzer2 in 'Interfaces\IFileAnalyzer2.pas',
  IMigrationManager2 in 'Interfaces\IMigrationManager2.pas',
  IRollbackManager2 in 'Interfaces\IRollbackManager2.pas',
  ISecurityManager2 in 'Interfaces\ISecurityManager2.pas',
  IDonationManager2 in 'Interfaces\IDonationManager2.pas',
  // Core implementations
  ConfigManager in 'Core\ConfigManager.pas',
  BasicProtection in 'Core\BasicProtection.pas',
  SecurityManager in 'Core\SecurityManager.pas',
  FileAnalyzer in 'Core\FileAnalyzer.pas',
  DonationManager in 'Core\DonationManager.pas',
  MigrationManager in 'Core\MigrationManager.pas',
  RollbackManager2 in 'Core\RollbackManager2.pas',
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
