program syncLocal;

uses
  Vcl.Forms,
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  uSplash in 'uSplash.pas' {frmSplash},
  uSyncLocalMain in 'uSyncLocalMain.pas' {frmSyncLocalMain},
  uIconManager in 'uIconManager.pas',
  uTrayIcon in 'uTrayIcon.pas',
  uEnhancedTrayIcon in 'uEnhancedTrayIcon.pas',
  uSyncDatabase in 'uSyncDatabase.pas',
  uSyncEngine in 'uSyncEngine.pas',
  uFileSystemWatcher in 'uFileSystemWatcher.pas',
  uNativeFileWatcher in 'uNativeFileWatcher.pas',
  uRealtimeSyncManager in 'uRealtimeSyncManager.pas',
  uSyncExecutor in 'uSyncExecutor.pas',
  uSyncExecutorSimple in 'uSyncExecutorSimple.pas',
  uFileSyncComparer in 'uFileSyncComparer.pas',
  uFileSyncComparerSimple in 'uFileSyncComparerSimple.pas',
  uConflictResolver in 'uConflictResolver.pas',
  uSyncSettingsBasic in 'uSyncSettingsBasic.pas' {frmSyncSettingsBasic},
  uSyncTaskEdit in 'uSyncTaskEdit.pas' {frmSyncTaskEdit},
  uSyncHistory in 'uSyncHistory.pas' {frmSyncHistory},
  uLogger in 'uLogger.pas',
  uNetworkPathManager in 'uNetworkPathManager.pas',
  uNetworkConnectionMonitor in 'uNetworkConnectionMonitor.pas',
  uSyncPresets in 'uSyncPresets.pas',
  uDatabaseMigration in 'uDatabaseMigration.pas',
  uDatabaseConfig in 'uDatabaseConfig.pas',
  uSyncLocalTrayIcon in 'uSyncLocalTrayIcon.pas',
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Phys.SQLite, Data.DB;

{$R *.res}

var
  DbPath: string;
  CmdLineParams: string;
  IsSilent: Boolean;
  ShowConfig: Boolean;
  ExecuteSync: Boolean;

procedure ParseCommandLine;
var
  I: Integer;
  Param: string;
begin
  IsSilent := False;
  ShowConfig := False;
  ExecuteSync := False;
  
  for I := 1 to ParamCount do
  begin
    Param := ParamStr(I).ToLower;
    if Param = '/silent' then
      IsSilent := True
    else if Param = '/config' then
      ShowConfig := True
    else if Param = '/sync' then
      ExecuteSync := True;
  end;
end;

begin
  // 解析命令行参数
  ParseCommandLine;
  
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := not IsSilent;

  // 入口前置关键资源自检（fail-closed）
  try
    DbPath := TDatabaseConfig.GetDatabasePath;
    
    // 如果数据库不存在，尝试迁移或创建
    if not TFile.Exists(DbPath) then
    begin
      // 可选：尝试从 MoveC.db 迁移数据
      // 如果没有 MoveC.db，就创建新的空数据库
      var
        MoveC_DB := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
      if TFile.Exists(MoveC_DB) then
      begin
        // 提示用户是否迁移（如果不是无窗口模式）
        if not IsSilent then
        begin
          if Application.MessageBox(
            '检测到旧版本数据库 (MoveC.db)。是否迁移同步数据到 syncLocal.db？',
            '数据迁移',
            MB_YESNO or MB_ICONQUESTION) = ID_YES then
          begin
            // 迁移逻辑将在主窗体初始化时执行
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      MessageBox(0, 
        PChar('错误：' + E.Message), 
        '初始化失败', 
        MB_OK or MB_ICONERROR or MB_TOPMOST);
      Halt(1);
    end;
  end;

  // 创建启动画面
  if not IsSilent then
  begin
    frmSplash := TfrmSplash.Create(nil);
    frmSplash.Show;
    Application.ProcessMessages;
    Sleep(50);
  end;

  // 创建主窗体
  Application.CreateForm(TfrmSyncLocalMain, frmSyncLocalMain);
  Application.CreateForm(TfrmSyncSettingsBasic, frmSyncSettingsBasic);
  Application.CreateForm(TfrmSyncTaskEdit, frmSyncTaskEdit);
  Application.CreateForm(TfrmSyncHistory, frmSyncHistory);

  // 根据命令行参数决定窗体显示
  if ShowConfig then
    frmSyncSettingsBasic.Show
  else if not IsSilent then
    frmSyncLocalMain.Show;

  // 进入消息循环
  Application.Run;
end.
