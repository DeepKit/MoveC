program DiskCleanup;

uses
  Vcl.Forms, System.SysUtils,
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
  DatabaseManager in 'Core\DatabaseManager.pas',
  BasicProtection in 'Core\BasicProtection.pas',
  SecurityManager in 'Core\SecurityManager.pas',
  FileAnalyzer in 'Core\FileAnalyzer.pas',
  DonationManager in 'Core\DonationManager.pas',
  MigrationManager in 'Core\MigrationManager.pas',
  RollbackManager2 in 'Core\RollbackManager2.pas',
  // UI components
  uProgress in 'uProgress.pas' {frmProgress},
  uLanguageDialog in 'uLanguageDialog.pas' {frmLanguageDialog},
  SystemChecker in 'Core\SystemChecker.pas',
  LanguageTypes in 'Core\LanguageTypes.pas',
  LanguageManager in 'Core\LanguageManager.pas',
  // Main form last
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

begin
  // 设置全局异常处理 - 简化版本
  Application.OnException := nil; // 暂时禁用异常处理

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
