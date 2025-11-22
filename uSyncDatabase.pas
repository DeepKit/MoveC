unit uSyncDatabase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, Data.DB, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.DApt, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Stan.Param, System.Hash, uBasicProtection, uAntiTamperPackage;

type
  // 同步模式枚举
  TSyncMode = (smManual, smRealtime);
  
  // 同步状态枚举
  TSyncStatus = (ssIdle, ssRunning, ssPaused, ssError, ssCompleted);
  
  // 同步分类枚举
  TSyncCategory = (scDocuments, scCode, scMedia, scBackup, scCustom);
  
  // 冲突解决策略枚举
  TConflictStrategy = (csSourcePriority, csTargetPriority, csNewerPriority, csAskUser);
  
  // 同步任务记录
  TSyncTask = record
    TaskID: Integer;
    Name: string;
    SourcePath: string;
    TargetPath: string;
    SyncMode: TSyncMode;
    ConflictStrategy: TConflictStrategy;
    IsEnabled: Boolean;
    FilterRules: string; // JSON格式的过滤规则
    PresetID: Integer;
    CreatedAt: TDateTime;
    UpdatedAt: TDateTime;
  end;
  
  // 预设模板记录
  TSyncPreset = record
    ID: Integer;
    Name: string;
    Description: string;
    FilterRules: string; // JSON格式的过滤规则
    ConflictStrategy: TConflictStrategy;
    IsSystem: Boolean; // 是否为系统预设
    CreatedAt: TDateTime;
  end;
  
  // 同步历史记录
  TSyncHistory = record
    ID: Integer;
    TaskID: Integer;
    SyncType: string; // 'manual' 或 'realtime'
    StartTime: TDateTime;
    EndTime: TDateTime;
    FilesScanned: Integer;
    FilesCopied: Integer;
    FilesUpdated: Integer;
    FilesDeleted: Integer;
    FilesSkipped: Integer;
    BytesTransferred: Int64;
    ErrorMessage: string;
    Status: string; // 'success', 'error', 'cancelled'
  end;
  
  // 文件状态记录
  TFileState = record
    ID: Integer;
    TaskID: Integer;
    FilePath: string; // 相对路径
    FileHash: string;
    FileSize: Int64;
    ModifiedTime: TDateTime;
    LastSyncTime: TDateTime;
    SyncStatus: string; // 'synced', 'pending', 'conflict', 'error'
    ExistsInSource: Boolean;
    ExistsInTarget: Boolean;
  end;

type
  TSyncDatabase = class
  private
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    FDatabasePath: string;
    FPassword: string;
    FConnected: Boolean;
    
    procedure InitializeDatabase;
    procedure CreateTables;
    procedure LogError(const AMessage: string);
    procedure LogInfo(const AMessage: string);
    
  public
    constructor Create(const ADatabasePath: string; const APassword: string = '');
    destructor Destroy; override;
    
    // 连接管理
    function Connect: Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    
    // 同步任务管理
    function CreateSyncTask(const ATask: TSyncTask): Integer;
    function UpdateSyncTask(const ATask: TSyncTask): Boolean;
    function DeleteSyncTask(const ATaskID: Integer): Boolean;
    function GetSyncTask(const ATaskID: Integer): TSyncTask;
    function GetAllSyncTasks: TArray<TSyncTask>;
    function GetEnabledSyncTasks: TArray<TSyncTask>;
    
    // 预设模板管理
    function CreatePreset(const APreset: TSyncPreset): Integer;
    function UpdatePreset(const APreset: TSyncPreset): Boolean;
    function DeletePreset(const APresetID: Integer): Boolean;
    function GetPreset(const APresetID: Integer): TSyncPreset;
    function GetAllPresets: TArray<TSyncPreset>;
    function GetSystemPresets: TArray<TSyncPreset>;
    
    // 同步历史管理
    function CreateSyncHistory(const AHistory: TSyncHistory): Integer;
    function GetSyncHistory(const ATaskID: Integer; const ALimit: Integer = 100): TArray<TSyncHistory>;
    function DeleteSyncHistory(const ATaskID: Integer): Boolean;
    
    // 文件状态管理
    function UpdateFileState(const AFileState: TFileState): Boolean;
    function GetFileStates(const ATaskID: Integer): TArray<TFileState>;
    function DeleteFileStates(const ATaskID: Integer): Boolean;
    function GetPendingFiles(const ATaskID: Integer): TArray<TFileState>;
    function GetConflictFiles(const ATaskID: Integer): TArray<TFileState>;
    
    // 获取项目根目录下的数据库路径
    class function GetProjectDatabasePath: string;
  end;

implementation

{ TSyncDatabase }

constructor TSyncDatabase.Create(const ADatabasePath: string; const APassword: string = '');
begin
  inherited Create;
  FDatabasePath := ADatabasePath;
  FPassword := APassword;
  FConnection := TFDConnection.Create(nil);
  FQuery := TFDQuery.Create(nil);
  FConnected := False;
end;

destructor TSyncDatabase.Destroy;
begin
  Disconnect;
  FreeAndNil(FQuery);
  FreeAndNil(FConnection);
  inherited Destroy;
end;

function TSyncDatabase.Connect: Boolean;
begin
  Result := False;
  try
    if FConnected then
    begin
      Result := True;
      Exit;
    end;
    
    FConnection.DriverName := 'SQLite';
    FConnection.Params.Values['Database'] := FDatabasePath;
    
    if FPassword <> '' then
      FConnection.Params.Values['Password'] := FPassword;
    
    FConnection.LoginPrompt := False;
    FConnection.Connected := True;
    
    FQuery.Connection := FConnection;
    
    InitializeDatabase;
    CreateTables;
    
    FConnected := True;
    Result := True;
    
    LogInfo('数据库连接成功');
  except
    on E: Exception do
    begin
      LogError('数据库连接失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TSyncDatabase.Disconnect;
begin
  if FConnected then
  begin
    FConnection.Connected := False;
    FConnected := False;
    LogInfo('数据库已断开连接');
  end;
end;

function TSyncDatabase.IsConnected: Boolean;
begin
  Result := FConnected and FConnection.Connected;
end;

procedure TSyncDatabase.InitializeDatabase;
begin
  // 设置数据库参数
  FConnection.ExecSQL('PRAGMA foreign_keys = ON');
  FConnection.ExecSQL('PRAGMA journal_mode = WAL');
  FConnection.ExecSQL('PRAGMA synchronous = NORMAL');
  FConnection.ExecSQL('PRAGMA cache_size = 10000');
  FConnection.ExecSQL('PRAGMA temp_store = memory');
end;

procedure TSyncDatabase.CreateTables;
begin
  // 创建同步任务表
  FQuery.SQL.Text := 
    'CREATE TABLE IF NOT EXISTS sync_tasks (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL,' +
    '  source_path TEXT NOT NULL,' +
    '  target_path TEXT NOT NULL,' +
    '  sync_mode INTEGER NOT NULL DEFAULT 0,' + // 0=manual, 1=realtime
    '  conflict_strategy INTEGER NOT NULL DEFAULT 0,' + // 0=source, 1=target, 2=newer, 3=ask
    '  is_enabled BOOLEAN NOT NULL DEFAULT 1,' +
    '  filter_rules TEXT,' + // JSON格式
    '  preset_id INTEGER,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  FOREIGN KEY (preset_id) REFERENCES sync_presets(id)' +
    ')';
  FQuery.ExecSQL;
  
  // 创建预设模板表
  FQuery.SQL.Text := 
    'CREATE TABLE IF NOT EXISTS sync_presets (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL UNIQUE,' +
    '  description TEXT,' +
    '  filter_rules TEXT,' + // JSON格式
    '  conflict_strategy INTEGER NOT NULL DEFAULT 0,' +
    '  is_system BOOLEAN NOT NULL DEFAULT 0,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')';
  FQuery.ExecSQL;
  
  // 创建同步历史表
  FQuery.SQL.Text := 
    'CREATE TABLE IF NOT EXISTS sync_history (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  task_id INTEGER NOT NULL,' +
    '  sync_type TEXT NOT NULL,' + // 'manual' 或 'realtime'
    '  start_time DATETIME NOT NULL,' +
    '  end_time DATETIME,' +
    '  files_scanned INTEGER DEFAULT 0,' +
    '  files_copied INTEGER DEFAULT 0,' +
    '  files_updated INTEGER DEFAULT 0,' +
    '  files_deleted INTEGER DEFAULT 0,' +
    '  files_skipped INTEGER DEFAULT 0,' +
    '  bytes_transferred INTEGER DEFAULT 0,' +
    '  error_message TEXT,' +
    '  status TEXT NOT NULL DEFAULT ''pending'',' + // 'success', 'error', 'cancelled', 'pending'
    '  FOREIGN KEY (task_id) REFERENCES sync_tasks(id) ON DELETE CASCADE' +
    ')';
  FQuery.ExecSQL;
  
  // 创建文件状态表
  FQuery.SQL.Text := 
    'CREATE TABLE IF NOT EXISTS file_states (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  task_id INTEGER NOT NULL,' +
    '  file_path TEXT NOT NULL,' + // 相对路径
    '  file_hash TEXT,' +
    '  file_size INTEGER DEFAULT 0,' +
    '  modified_time DATETIME,' +
    '  last_sync_time DATETIME,' +
    '  sync_status TEXT NOT NULL DEFAULT ''pending'',' + // 'synced', 'pending', 'conflict', 'error'
    '  exists_in_source BOOLEAN NOT NULL DEFAULT 0,' +
    '  exists_in_target BOOLEAN NOT NULL DEFAULT 0,' +
    '  UNIQUE(task_id, file_path),' +
    '  FOREIGN KEY (task_id) REFERENCES sync_tasks(id) ON DELETE CASCADE' +
    ')';
  FQuery.ExecSQL;
  
  // 创建索引
  FConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_sync_tasks_enabled ON sync_tasks(is_enabled)');
  FConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_sync_history_task ON sync_history(task_id)');
  FConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_file_states_task ON file_states(task_id)');
  FConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_file_states_status ON file_states(sync_status)');
end;

procedure TSyncDatabase.LogError(const AMessage: string);
begin
  // TODO: 实现日志记录
end;

procedure TSyncDatabase.LogInfo(const AMessage: string);
begin
  // TODO: 实现日志记录
end;

function TSyncDatabase.CreateSyncTask(const ATask: TSyncTask): Integer;
begin
  try
    FQuery.SQL.Text := 
      'INSERT INTO sync_tasks (name, source_path, target_path, sync_mode, ' +
      'conflict_strategy, is_enabled, filter_rules, preset_id) ' +
      'VALUES (:name, :source_path, :target_path, :sync_mode, ' +
      ':conflict_strategy, :is_enabled, :filter_rules, :preset_id)';
    
    FQuery.ParamByName('name').AsString := ATask.Name;
    FQuery.ParamByName('source_path').AsString := ATask.SourcePath;
    FQuery.ParamByName('target_path').AsString := ATask.TargetPath;
    FQuery.ParamByName('sync_mode').AsInteger := Integer(ATask.SyncMode);
    FQuery.ParamByName('conflict_strategy').AsInteger := Integer(ATask.ConflictStrategy);
    FQuery.ParamByName('is_enabled').AsBoolean := ATask.IsEnabled;
    FQuery.ParamByName('filter_rules').AsString := ATask.FilterRules;
    if ATask.PresetID > 0 then
      FQuery.ParamByName('preset_id').AsInteger := ATask.PresetID
    else
      FQuery.ParamByName('preset_id').Clear;
    
    FQuery.ExecSQL;
    Result := FConnection.GetLastAutoGenValue('sync_tasks');
  except
    on E: Exception do
    begin
      LogError('创建同步任务失败: ' + E.Message);
      Result := -1;
    end;
  end;
end;

function TSyncDatabase.UpdateSyncTask(const ATask: TSyncTask): Boolean;
begin
  try
    FQuery.SQL.Text := 
      'UPDATE sync_tasks SET name = :name, source_path = :source_path, ' +
      'target_path = :target_path, sync_mode = :sync_mode, ' +
      'conflict_strategy = :conflict_strategy, is_enabled = :is_enabled, ' +
      'filter_rules = :filter_rules, preset_id = :preset_id, ' +
      'updated_at = CURRENT_TIMESTAMP WHERE id = :id';
    
    FQuery.ParamByName('id').AsInteger := ATask.TaskID;
    FQuery.ParamByName('name').AsString := ATask.Name;
    FQuery.ParamByName('source_path').AsString := ATask.SourcePath;
    FQuery.ParamByName('target_path').AsString := ATask.TargetPath;
    FQuery.ParamByName('sync_mode').AsInteger := Integer(ATask.SyncMode);
    FQuery.ParamByName('conflict_strategy').AsInteger := Integer(ATask.ConflictStrategy);
    FQuery.ParamByName('is_enabled').AsBoolean := ATask.IsEnabled;
    FQuery.ParamByName('filter_rules').AsString := ATask.FilterRules;
    if ATask.PresetID > 0 then
      FQuery.ParamByName('preset_id').AsInteger := ATask.PresetID
    else
      FQuery.ParamByName('preset_id').Clear;
    
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('更新同步任务失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSyncDatabase.DeleteSyncTask(const ATaskID: Integer): Boolean;
begin
  try
    FQuery.SQL.Text := 'DELETE FROM sync_tasks WHERE id = :id';
    FQuery.ParamByName('id').AsInteger := ATaskID;
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('删除同步任务失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSyncDatabase.GetSyncTask(const ATaskID: Integer): TSyncTask;
begin
  Result.TaskID := -1;
  try
    FQuery.SQL.Text := 
      'SELECT id, name, source_path, target_path, sync_mode, ' +
      'conflict_strategy, is_enabled, filter_rules, preset_id, ' +
      'created_at, updated_at FROM sync_tasks WHERE id = :id';
    
    FQuery.ParamByName('id').AsInteger := ATaskID;
    FQuery.Open;
    
    if not FQuery.Eof then
    begin
      Result.TaskID := FQuery.FieldByName('id').AsInteger;
      Result.Name := FQuery.FieldByName('name').AsString;
      Result.SourcePath := FQuery.FieldByName('source_path').AsString;
      Result.TargetPath := FQuery.FieldByName('target_path').AsString;
      Result.SyncMode := TSyncMode(FQuery.FieldByName('sync_mode').AsInteger);
      Result.ConflictStrategy := TConflictStrategy(FQuery.FieldByName('conflict_strategy').AsInteger);
      Result.IsEnabled := FQuery.FieldByName('is_enabled').AsBoolean;
      Result.FilterRules := FQuery.FieldByName('filter_rules').AsString;
      Result.PresetID := FQuery.FieldByName('preset_id').AsInteger;
      Result.CreatedAt := FQuery.FieldByName('created_at').AsDateTime;
      Result.UpdatedAt := FQuery.FieldByName('updated_at').AsDateTime;
    end;
    
    FQuery.Close;
  except
    on E: Exception do
    begin
      LogError('获取同步任务失败: ' + E.Message);
    end;
  end;
end;

function TSyncDatabase.GetAllSyncTasks: TArray<TSyncTask>;
var
  List: TList<TSyncTask>;
begin
  List := TList<TSyncTask>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, name, source_path, target_path, sync_mode, ' +
      'conflict_strategy, is_enabled, filter_rules, preset_id, ' +
      'created_at, updated_at FROM sync_tasks ORDER BY name';
    
    FQuery.Open;
    while not FQuery.Eof do
    begin
      var Task: TSyncTask;
      Task.TaskID := FQuery.FieldByName('id').AsInteger;
      Task.Name := FQuery.FieldByName('name').AsString;
      Task.SourcePath := FQuery.FieldByName('source_path').AsString;
      Task.TargetPath := FQuery.FieldByName('target_path').AsString;
      Task.SyncMode := TSyncMode(FQuery.FieldByName('sync_mode').AsInteger);
      Task.ConflictStrategy := TConflictStrategy(FQuery.FieldByName('conflict_strategy').AsInteger);
      Task.IsEnabled := FQuery.FieldByName('is_enabled').AsBoolean;
      Task.FilterRules := FQuery.FieldByName('filter_rules').AsString;
      Task.PresetID := FQuery.FieldByName('preset_id').AsInteger;
      Task.CreatedAt := FQuery.FieldByName('created_at').AsDateTime;
      Task.UpdatedAt := FQuery.FieldByName('updated_at').AsDateTime;
      
      List.Add(Task);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSyncDatabase.GetEnabledSyncTasks: TArray<TSyncTask>;
var
  List: TList<TSyncTask>;
begin
  List := TList<TSyncTask>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, name, source_path, target_path, sync_mode, ' +
      'conflict_strategy, is_enabled, filter_rules, preset_id, ' +
      'created_at, updated_at FROM sync_tasks WHERE is_enabled = 1 ORDER BY name';
    
    FQuery.Open;
    while not FQuery.Eof do
    begin
      var Task: TSyncTask;
      Task.TaskID := FQuery.FieldByName('id').AsInteger;
      Task.Name := FQuery.FieldByName('name').AsString;
      Task.SourcePath := FQuery.FieldByName('source_path').AsString;
      Task.TargetPath := FQuery.FieldByName('target_path').AsString;
      Task.SyncMode := TSyncMode(FQuery.FieldByName('sync_mode').AsInteger);
      Task.ConflictStrategy := TConflictStrategy(FQuery.FieldByName('conflict_strategy').AsInteger);
      Task.IsEnabled := FQuery.FieldByName('is_enabled').AsBoolean;
      Task.FilterRules := FQuery.FieldByName('filter_rules').AsString;
      Task.PresetID := FQuery.FieldByName('preset_id').AsInteger;
      Task.CreatedAt := FQuery.FieldByName('created_at').AsDateTime;
      Task.UpdatedAt := FQuery.FieldByName('updated_at').AsDateTime;
      
      List.Add(Task);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

// 预设模板相关方法实现
function TSyncDatabase.CreatePreset(const APreset: TSyncPreset): Integer;
begin
  try
    FQuery.SQL.Text := 
      'INSERT INTO sync_presets (name, description, filter_rules, ' +
      'conflict_strategy, is_system) ' +
      'VALUES (:name, :description, :filter_rules, :conflict_strategy, :is_system)';
    
    FQuery.ParamByName('name').AsString := APreset.Name;
    FQuery.ParamByName('description').AsString := APreset.Description;
    FQuery.ParamByName('filter_rules').AsString := APreset.FilterRules;
    FQuery.ParamByName('conflict_strategy').AsInteger := Integer(APreset.ConflictStrategy);
    FQuery.ParamByName('is_system').AsBoolean := APreset.IsSystem;
    
    FQuery.ExecSQL;
    Result := FConnection.GetLastAutoGenValue('sync_presets');
  except
    on E: Exception do
    begin
      LogError('创建预设模板失败: ' + E.Message);
      Result := -1;
    end;
  end;
end;

function TSyncDatabase.UpdatePreset(const APreset: TSyncPreset): Boolean;
begin
  try
    FQuery.SQL.Text := 
      'UPDATE sync_presets SET name = :name, description = :description, ' +
      'filter_rules = :filter_rules, conflict_strategy = :conflict_strategy ' +
      'WHERE id = :id';
    
    FQuery.ParamByName('id').AsInteger := APreset.ID;
    FQuery.ParamByName('name').AsString := APreset.Name;
    FQuery.ParamByName('description').AsString := APreset.Description;
    FQuery.ParamByName('filter_rules').AsString := APreset.FilterRules;
    FQuery.ParamByName('conflict_strategy').AsInteger := Integer(APreset.ConflictStrategy);
    
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('更新预设模板失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSyncDatabase.DeletePreset(const APresetID: Integer): Boolean;
begin
  try
    FQuery.SQL.Text := 'DELETE FROM sync_presets WHERE id = :id AND is_system = 0';
    FQuery.ParamByName('id').AsInteger := APresetID;
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('删除预设模板失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSyncDatabase.GetPreset(const APresetID: Integer): TSyncPreset;
begin
  Result.ID := -1;
  try
    FQuery.SQL.Text := 
      'SELECT id, name, description, filter_rules, conflict_strategy, ' +
      'is_system, created_at FROM sync_presets WHERE id = :id';
    
    FQuery.ParamByName('id').AsInteger := APresetID;
    FQuery.Open;
    
    if not FQuery.Eof then
    begin
      Result.ID := FQuery.FieldByName('id').AsInteger;
      Result.Name := FQuery.FieldByName('name').AsString;
      Result.Description := FQuery.FieldByName('description').AsString;
      Result.FilterRules := FQuery.FieldByName('filter_rules').AsString;
      Result.ConflictStrategy := TConflictStrategy(FQuery.FieldByName('conflict_strategy').AsInteger);
      Result.IsSystem := FQuery.FieldByName('is_system').AsBoolean;
      Result.CreatedAt := FQuery.FieldByName('created_at').AsDateTime;
    end;
    
    FQuery.Close;
  except
    on E: Exception do
    begin
      LogError('获取预设模板失败: ' + E.Message);
    end;
  end;
end;

function TSyncDatabase.GetAllPresets: TArray<TSyncPreset>;
var
  List: TList<TSyncPreset>;
begin
  List := TList<TSyncPreset>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, name, description, filter_rules, conflict_strategy, ' +
      'is_system, created_at FROM sync_presets ORDER BY is_system DESC, name';
    
    FQuery.Open;
    while not FQuery.Eof do
    begin
      var Preset: TSyncPreset;
      Preset.ID := FQuery.FieldByName('id').AsInteger;
      Preset.Name := FQuery.FieldByName('name').AsString;
      Preset.Description := FQuery.FieldByName('description').AsString;
      Preset.FilterRules := FQuery.FieldByName('filter_rules').AsString;
      Preset.ConflictStrategy := TConflictStrategy(FQuery.FieldByName('conflict_strategy').AsInteger);
      Preset.IsSystem := FQuery.FieldByName('is_system').AsBoolean;
      Preset.CreatedAt := FQuery.FieldByName('created_at').AsDateTime;
      
      List.Add(Preset);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSyncDatabase.GetSystemPresets: TArray<TSyncPreset>;
var
  List: TList<TSyncPreset>;
begin
  List := TList<TSyncPreset>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, name, description, filter_rules, conflict_strategy, ' +
      'is_system, created_at FROM sync_presets WHERE is_system = 1 ORDER BY name';
    
    FQuery.Open;
    while not FQuery.Eof do
    begin
      var Preset: TSyncPreset;
      Preset.ID := FQuery.FieldByName('id').AsInteger;
      Preset.Name := FQuery.FieldByName('name').AsString;
      Preset.Description := FQuery.FieldByName('description').AsString;
      Preset.FilterRules := FQuery.FieldByName('filter_rules').AsString;
      Preset.ConflictStrategy := TConflictStrategy(FQuery.FieldByName('conflict_strategy').AsInteger);
      Preset.IsSystem := FQuery.FieldByName('is_system').AsBoolean;
      Preset.CreatedAt := FQuery.FieldByName('created_at').AsDateTime;
      
      List.Add(Preset);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

// 同步历史相关方法实现
function TSyncDatabase.CreateSyncHistory(const AHistory: TSyncHistory): Integer;
begin
  try
    FQuery.SQL.Text := 
      'INSERT INTO sync_history (task_id, sync_type, start_time, end_time, ' +
      'files_scanned, files_copied, files_updated, files_deleted, ' +
      'files_skipped, bytes_transferred, error_message, status) ' +
      'VALUES (:task_id, :sync_type, :start_time, :end_time, ' +
      ':files_scanned, :files_copied, :files_updated, :files_deleted, ' +
      ':files_skipped, :bytes_transferred, :error_message, :status)';
    
    FQuery.ParamByName('task_id').AsInteger := AHistory.TaskID;
    FQuery.ParamByName('sync_type').AsString := AHistory.SyncType;
    FQuery.ParamByName('start_time').AsDateTime := AHistory.StartTime;
    FQuery.ParamByName('end_time').AsDateTime := AHistory.EndTime;
    FQuery.ParamByName('files_scanned').AsInteger := AHistory.FilesScanned;
    FQuery.ParamByName('files_copied').AsInteger := AHistory.FilesCopied;
    FQuery.ParamByName('files_updated').AsInteger := AHistory.FilesUpdated;
    FQuery.ParamByName('files_deleted').AsInteger := AHistory.FilesDeleted;
    FQuery.ParamByName('files_skipped').AsInteger := AHistory.FilesSkipped;
    FQuery.ParamByName('bytes_transferred').AsLargeInt := AHistory.BytesTransferred;
    FQuery.ParamByName('error_message').AsString := AHistory.ErrorMessage;
    FQuery.ParamByName('status').AsString := AHistory.Status;
    
    FQuery.ExecSQL;
    Result := FConnection.GetLastAutoGenValue('sync_history');
  except
    on E: Exception do
    begin
      LogError('创建同步历史失败: ' + E.Message);
      Result := -1;
    end;
  end;
end;

function TSyncDatabase.GetSyncHistory(const ATaskID: Integer; const ALimit: Integer = 100): TArray<TSyncHistory>;
var
  List: TList<TSyncHistory>;
begin
  List := TList<TSyncHistory>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, task_id, sync_type, start_time, end_time, ' +
      'files_scanned, files_copied, files_updated, files_deleted, ' +
      'files_skipped, bytes_transferred, error_message, status ' +
      'FROM sync_history WHERE task_id = :task_id ' +
      'ORDER BY start_time DESC LIMIT :limit';
    
    FQuery.ParamByName('task_id').AsInteger := ATaskID;
    FQuery.ParamByName('limit').AsInteger := ALimit;
    FQuery.Open;
    
    while not FQuery.Eof do
    begin
      var History: TSyncHistory;
      History.ID := FQuery.FieldByName('id').AsInteger;
      History.TaskID := FQuery.FieldByName('task_id').AsInteger;
      History.SyncType := FQuery.FieldByName('sync_type').AsString;
      History.StartTime := FQuery.FieldByName('start_time').AsDateTime;
      History.EndTime := FQuery.FieldByName('end_time').AsDateTime;
      History.FilesScanned := FQuery.FieldByName('files_scanned').AsInteger;
      History.FilesCopied := FQuery.FieldByName('files_copied').AsInteger;
      History.FilesUpdated := FQuery.FieldByName('files_updated').AsInteger;
      History.FilesDeleted := FQuery.FieldByName('files_deleted').AsInteger;
      History.FilesSkipped := FQuery.FieldByName('files_skipped').AsInteger;
      History.BytesTransferred := FQuery.FieldByName('bytes_transferred').AsLargeInt;
      History.ErrorMessage := FQuery.FieldByName('error_message').AsString;
      History.Status := FQuery.FieldByName('status').AsString;
      
      List.Add(History);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSyncDatabase.DeleteSyncHistory(const ATaskID: Integer): Boolean;
begin
  try
    FQuery.SQL.Text := 'DELETE FROM sync_history WHERE task_id = :task_id';
    FQuery.ParamByName('task_id').AsInteger := ATaskID;
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('删除同步历史失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

// 文件状态相关方法实现
function TSyncDatabase.UpdateFileState(const AFileState: TFileState): Boolean;
begin
  try
    FQuery.SQL.Text := 
      'INSERT OR REPLACE INTO file_states (task_id, file_path, file_hash, ' +
      'file_size, modified_time, last_sync_time, sync_status, ' +
      'exists_in_source, exists_in_target) ' +
      'VALUES (:task_id, :file_path, :file_hash, :file_size, ' +
      ':modified_time, :last_sync_time, :sync_status, ' +
      ':exists_in_source, :exists_in_target)';
    
    FQuery.ParamByName('task_id').AsInteger := AFileState.TaskID;
    FQuery.ParamByName('file_path').AsString := AFileState.FilePath;
    FQuery.ParamByName('file_hash').AsString := AFileState.FileHash;
    FQuery.ParamByName('file_size').AsLargeInt := AFileState.FileSize;
    FQuery.ParamByName('modified_time').AsDateTime := AFileState.ModifiedTime;
    FQuery.ParamByName('last_sync_time').AsDateTime := AFileState.LastSyncTime;
    FQuery.ParamByName('sync_status').AsString := AFileState.SyncStatus;
    FQuery.ParamByName('exists_in_source').AsBoolean := AFileState.ExistsInSource;
    FQuery.ParamByName('exists_in_target').AsBoolean := AFileState.ExistsInTarget;
    
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('更新文件状态失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSyncDatabase.GetFileStates(const ATaskID: Integer): TArray<TFileState>;
var
  List: TList<TFileState>;
begin
  List := TList<TFileState>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, task_id, file_path, file_hash, file_size, ' +
      'modified_time, last_sync_time, sync_status, ' +
      'exists_in_source, exists_in_target ' +
      'FROM file_states WHERE task_id = :task_id ORDER BY file_path';
    
    FQuery.ParamByName('task_id').AsInteger := ATaskID;
    FQuery.Open;
    
    while not FQuery.Eof do
    begin
      var FileState: TFileState;
      FileState.ID := FQuery.FieldByName('id').AsInteger;
      FileState.TaskID := FQuery.FieldByName('task_id').AsInteger;
      FileState.FilePath := FQuery.FieldByName('file_path').AsString;
      FileState.FileHash := FQuery.FieldByName('file_hash').AsString;
      FileState.FileSize := FQuery.FieldByName('file_size').AsLargeInt;
      FileState.ModifiedTime := FQuery.FieldByName('modified_time').AsDateTime;
      FileState.LastSyncTime := FQuery.FieldByName('last_sync_time').AsDateTime;
      FileState.SyncStatus := FQuery.FieldByName('sync_status').AsString;
      FileState.ExistsInSource := FQuery.FieldByName('exists_in_source').AsBoolean;
      FileState.ExistsInTarget := FQuery.FieldByName('exists_in_target').AsBoolean;
      
      List.Add(FileState);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSyncDatabase.DeleteFileStates(const ATaskID: Integer): Boolean;
begin
  try
    FQuery.SQL.Text := 'DELETE FROM file_states WHERE task_id = :task_id';
    FQuery.ParamByName('task_id').AsInteger := ATaskID;
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      LogError('删除文件状态失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSyncDatabase.GetPendingFiles(const ATaskID: Integer): TArray<TFileState>;
var
  List: TList<TFileState>;
begin
  List := TList<TFileState>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, task_id, file_path, file_hash, file_size, ' +
      'modified_time, last_sync_time, sync_status, ' +
      'exists_in_source, exists_in_target ' +
      'FROM file_states WHERE task_id = :task_id AND sync_status = ''pending'' ' +
      'ORDER BY file_path';
    
    FQuery.ParamByName('task_id').AsInteger := ATaskID;
    FQuery.Open;
    
    while not FQuery.Eof do
    begin
      var FileState: TFileState;
      FileState.ID := FQuery.FieldByName('id').AsInteger;
      FileState.TaskID := FQuery.FieldByName('task_id').AsInteger;
      FileState.FilePath := FQuery.FieldByName('file_path').AsString;
      FileState.FileHash := FQuery.FieldByName('file_hash').AsString;
      FileState.FileSize := FQuery.FieldByName('file_size').AsLargeInt;
      FileState.ModifiedTime := FQuery.FieldByName('modified_time').AsDateTime;
      FileState.LastSyncTime := FQuery.FieldByName('last_sync_time').AsDateTime;
      FileState.SyncStatus := FQuery.FieldByName('sync_status').AsString;
      FileState.ExistsInSource := FQuery.FieldByName('exists_in_source').AsBoolean;
      FileState.ExistsInTarget := FQuery.FieldByName('exists_in_target').AsBoolean;
      
      List.Add(FileState);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSyncDatabase.GetConflictFiles(const ATaskID: Integer): TArray<TFileState>;
var
  List: TList<TFileState>;
begin
  List := TList<TFileState>.Create;
  try
    FQuery.SQL.Text := 
      'SELECT id, task_id, file_path, file_hash, file_size, ' +
      'modified_time, last_sync_time, sync_status, ' +
      'exists_in_source, exists_in_target ' +
      'FROM file_states WHERE task_id = :task_id AND sync_status = ''conflict'' ' +
      'ORDER BY file_path';
    
    FQuery.ParamByName('task_id').AsInteger := ATaskID;
    FQuery.Open;
    
    while not FQuery.Eof do
    begin
      var FileState: TFileState;
      FileState.ID := FQuery.FieldByName('id').AsInteger;
      FileState.TaskID := FQuery.FieldByName('task_id').AsInteger;
      FileState.FilePath := FQuery.FieldByName('file_path').AsString;
      FileState.FileHash := FQuery.FieldByName('file_hash').AsString;
      FileState.FileSize := FQuery.FieldByName('file_size').AsLargeInt;
      FileState.ModifiedTime := FQuery.FieldByName('modified_time').AsDateTime;
      FileState.LastSyncTime := FQuery.FieldByName('last_sync_time').AsDateTime;
      FileState.SyncStatus := FQuery.FieldByName('sync_status').AsString;
      FileState.ExistsInSource := FQuery.FieldByName('exists_in_source').AsBoolean;
      FileState.ExistsInTarget := FQuery.FieldByName('exists_in_target').AsBoolean;
      
      List.Add(FileState);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

class function TSyncDatabase.GetProjectDatabasePath: string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'MoveC.db');
end;

end.
