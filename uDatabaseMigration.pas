unit uDatabaseMigration;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  uSyncDatabase, FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Phys.SQLite;

type
  TDatabaseMigration = class
  private
    FSourceDb: TSyncDatabase;
    FTargetDb: TSyncDatabase;
    FMigrationLog: TStringList;
    
    procedure LogMigration(const AMessage: string);
    procedure MigrateSyncTasks;
    procedure MigratePresets;
    procedure MigrateSyncHistory;
    procedure MigrateFileStates;
  public
    constructor Create;
    destructor Destroy; override;
    
    function MigrateFromMoveC(const AMoveCDbPath, ASyncLocalDbPath: string): Boolean;
    function GetMigrationLog: string;
  end;

implementation

{ TDatabaseMigration }

constructor TDatabaseMigration.Create;
begin
  inherited Create;
  FMigrationLog := TStringList.Create;
end;

destructor TDatabaseMigration.Destroy;
begin
  FreeAndNil(FMigrationLog);
  if Assigned(FSourceDb) then
    FreeAndNil(FSourceDb);
  if Assigned(FTargetDb) then
    FreeAndNil(FTargetDb);
  inherited Destroy;
end;

procedure TDatabaseMigration.LogMigration(const AMessage: string);
begin
  FMigrationLog.Add('[' + FormatDateTime('HH:mm:ss', Now) + '] ' + AMessage);
end;

function TDatabaseMigration.MigrateFromMoveC(const AMoveCDbPath, ASyncLocalDbPath: string): Boolean;
begin
  Result := False;
  
  try
    // 验证源数据库
    if not TFile.Exists(AMoveCDbPath) then
    begin
      LogMigration('错误：找不到源数据库 ' + AMoveCDbPath);
      Exit;
    end;
    
    LogMigration('开始从 MoveC.db 迁移数据...');
    
    // 连接源数据库
    FSourceDb := TSyncDatabase.Create(AMoveCDbPath);
    if not FSourceDb.Connect then
    begin
      LogMigration('错误：无法连接源数据库');
      Exit;
    end;
    LogMigration('源数据库连接成功');
    
    // 创建/连接目标数据库
    FTargetDb := TSyncDatabase.Create(ASyncLocalDbPath);
    if not FTargetDb.Connect then
    begin
      LogMigration('错误：无法连接目标数据库');
      Exit;
    end;
    LogMigration('目标数据库连接成功');
    
    // 执行迁移
    MigrateSyncTasks;
    MigratePresets;
    MigrateSyncHistory;
    MigrateFileStates;
    
    LogMigration('数据迁移完成！');
    Result := True;
    
  except
    on E: Exception do
    begin
      LogMigration('迁移过程中出错: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TDatabaseMigration.MigrateSyncTasks;
var
  SourceTasks: TArray<uSyncDatabase.TSyncTask>;
  I: Integer;
begin
  if not Assigned(FSourceDb) or not Assigned(FTargetDb) then
    Exit;
  
  LogMigration('开始迁移同步任务...');
  
  try
    SourceTasks := FSourceDb.GetAllSyncTasks;
    LogMigration(Format('找到 %d 个同步任务', [Length(SourceTasks)]));
    
    for I := 0 to High(SourceTasks) do
    begin
      try
        FTargetDb.CreateSyncTask(SourceTasks[I]);
        LogMigration('  ✓ 迁移任务: ' + SourceTasks[I].Name);
      except
        on E: Exception do
          LogMigration('  ✗ 迁移任务失败: ' + SourceTasks[I].Name + ' - ' + E.Message);
      end;
    end;
  except
    on E: Exception do
      LogMigration('迁移同步任务时出错: ' + E.Message);
  end;
end;

procedure TDatabaseMigration.MigratePresets;
var
  SourcePresets: TArray<TSyncPreset>;
  I: Integer;
begin
  if not Assigned(FSourceDb) or not Assigned(FTargetDb) then
    Exit;
  
  LogMigration('开始迁移预设模板...');
  
  try
    SourcePresets := FSourceDb.GetAllPresets;
    LogMigration(Format('找到 %d 个预设模板', [Length(SourcePresets)]));
    
    for I := 0 to High(SourcePresets) do
    begin
      try
        FTargetDb.CreatePreset(SourcePresets[I]);
        LogMigration('  ✓ 迁移预设: ' + SourcePresets[I].Name);
      except
        on E: Exception do
          LogMigration('  ✗ 迁移预设失败: ' + SourcePresets[I].Name + ' - ' + E.Message);
      end;
    end;
  except
    on E: Exception do
      LogMigration('迁移预设模板时出错: ' + E.Message);
  end;
end;

procedure TDatabaseMigration.MigrateSyncHistory;
var
  AllTasks: TArray<uSyncDatabase.TSyncTask>;
  TaskHistory: TArray<TSyncHistory>;
  I, J: Integer;
begin
  if not Assigned(FSourceDb) or not Assigned(FTargetDb) then
    Exit;
  
  LogMigration('开始迁移同步历史...');
  
  try
    AllTasks := FSourceDb.GetAllSyncTasks;
    
    for I := 0 to High(AllTasks) do
    begin
      TaskHistory := FSourceDb.GetSyncHistory(AllTasks[I].TaskID, 1000);
      
      for J := 0 to High(TaskHistory) do
      begin
        try
          FTargetDb.CreateSyncHistory(TaskHistory[J]);
        except
          on E: Exception do
            LogMigration('  ✗ 迁移历史记录失败: ' + E.Message);
        end;
      end;
      
      if Length(TaskHistory) > 0 then
        LogMigration(Format('  ✓ 迁移任务 %s 的 %d 条历史记录', [AllTasks[I].Name, Length(TaskHistory)]));
    end;
  except
    on E: Exception do
      LogMigration('迁移同步历史时出错: ' + E.Message);
  end;
end;

procedure TDatabaseMigration.MigrateFileStates;
var
  AllTasks: TArray<uSyncDatabase.TSyncTask>;
  TaskStates: TArray<TFileState>;
  I, J: Integer;
begin
  if not Assigned(FSourceDb) or not Assigned(FTargetDb) then
    Exit;
  
  LogMigration('开始迁移文件状态...');
  
  try
    AllTasks := FSourceDb.GetAllSyncTasks;
    
    for I := 0 to High(AllTasks) do
    begin
      TaskStates := FSourceDb.GetFileStates(AllTasks[I].TaskID);
      
      for J := 0 to High(TaskStates) do
      begin
        try
          FTargetDb.UpdateFileState(TaskStates[J]);
        except
          on E: Exception do
            LogMigration('  ✗ 迁移文件状态失败: ' + E.Message);
        end;
      end;
      
      if Length(TaskStates) > 0 then
        LogMigration(Format('  ✓ 迁移任务 %s 的 %d 个文件状态', [AllTasks[I].Name, Length(TaskStates)]));
    end;
  except
    on E: Exception do
      LogMigration('迁移文件状态时出错: ' + E.Message);
  end;
end;

function TDatabaseMigration.GetMigrationLog: string;
begin
  Result := FMigrationLog.Text;
end;

end.
