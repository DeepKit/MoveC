unit DatabaseManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  Data.DB, Data.SQLite, Data.SqlExpr, DataTypes, ConfigManager;

type
  TDatabaseManager = class
  private
    FConfigManager: TConfigManager;
    FConnection: TSQLConnection;
    FDatabasePath: string;
    
    function InitializeDatabase: Boolean;
    function CreateTables: Boolean;
    function ExecuteSQL(const ASQL: string): Boolean;
    function ExecuteQuery(const ASQL: string): TSQLQuery;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function Connect: Boolean;
    function Disconnect: Boolean;
    function IsConnected: Boolean;
    
    // 配置数据操作
    function SaveConfig(const AKey, AValue: string): Boolean;
    function LoadConfig(const AKey: string): string;
    function DeleteConfig(const AKey: string): Boolean;
    function GetAllConfigs: TDictionary<string, string>;
    
    // 操作日志
    function LogOperation(const AOperation, ASource, ATarget, AResult, ADetails: string): Boolean;
    function GetOperationHistory(ALimit: Integer = 100): TArray<TOperationLog>;
    function ClearOperationHistory: Boolean;
    
    // 备份清单
    function SaveBackupManifest(const ABackupId, AManifestData: string): Boolean;
    function LoadBackupManifest(const ABackupId: string): string;
    function GetBackupList: TArray<string>;
    function DeleteBackupManifest(const ABackupId: string): Boolean;
  end;

implementation

uses
  System.DateUtils;

constructor TDatabaseManager.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FDatabasePath := TPath.Combine(TPath.GetDocumentsPath, 'DiskCleanup', 'database.db');
  
  // 确保数据库目录存在
  var DatabaseDir := ExtractFilePath(FDatabasePath);
  if not TDirectory.Exists(DatabaseDir) then
    TDirectory.CreateDirectory(DatabaseDir);
    
  FConnection := TSQLConnection.Create(nil);
  FConnection.DriverName := 'SQLite';
  FConnection.Params.Values['Database'] := FDatabasePath;
end;

destructor TDatabaseManager.Destroy;
begin
  Disconnect;
  FConnection.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TDatabaseManager.Connect: Boolean;
begin
  Result := False;
  
  try
    if not FConnection.Connected then
    begin
      FConnection.Open;
      Result := InitializeDatabase;
    end
    else
      Result := True;
      
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('DATABASE', 'Connection error', FDatabasePath, '', 'ERROR', E.Message);
    end;
  end;
end;

function TDatabaseManager.Disconnect: Boolean;
begin
  Result := True;
  
  try
    if FConnection.Connected then
      FConnection.Close;
  except
    Result := False;
  end;
end;

function TDatabaseManager.IsConnected: Boolean;
begin
  Result := FConnection.Connected;
end;

function TDatabaseManager.InitializeDatabase: Boolean;
begin
  Result := CreateTables;
end;

function TDatabaseManager.CreateTables: Boolean;
var
  SQLStatements: TArray<string>;
  I: Integer;
begin
  Result := True;
  
  try
    SetLength(SQLStatements, 3);
    
    // 配置表
    SQLStatements[0] := 
      'CREATE TABLE IF NOT EXISTS configs (' +
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      '  key TEXT UNIQUE NOT NULL,' +
      '  value TEXT,' +
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
      '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
      ')';
    
    // 操作日志表
    SQLStatements[1] := 
      'CREATE TABLE IF NOT EXISTS operation_logs (' +
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      '  operation TEXT NOT NULL,' +
      '  source_path TEXT,' +
      '  target_path TEXT,' +
      '  result TEXT,' +
      '  details TEXT,' +
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
      ')';
    
    // 备份清单表
    SQLStatements[2] := 
      'CREATE TABLE IF NOT EXISTS backup_manifests (' +
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      '  backup_id TEXT UNIQUE NOT NULL,' +
      '  manifest_data TEXT,' +
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
      ')';
    
    for I := 0 to Length(SQLStatements) - 1 do
    begin
      if not ExecuteSQL(SQLStatements[I]) then
      begin
        Result := False;
        Break;
      end;
    end;
    
  except
    Result := False;
  end;
end;

function TDatabaseManager.ExecuteSQL(const ASQL: string): Boolean;
var
  Query: TSQLQuery;
begin
  Result := False;
  
  try
    Query := TSQLQuery.Create(nil);
    try
      Query.SQLConnection := FConnection;
      Query.SQL.Text := ASQL;
      Query.ExecSQL;
      Result := True;
    finally
      Query.Free;
    end;
  except
    Result := False;
  end;
end;

function TDatabaseManager.ExecuteQuery(const ASQL: string): TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.SQLConnection := FConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

function TDatabaseManager.SaveConfig(const AKey, AValue: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  
  try
    if not Connect then
      Exit;
    
    SQL := 'INSERT OR REPLACE INTO configs (key, value, updated_at) VALUES (' +
           QuotedStr(AKey) + ', ' + QuotedStr(AValue) + ', CURRENT_TIMESTAMP)';
    
    Result := ExecuteSQL(SQL);
    
  except
    Result := False;
  end;
end;

function TDatabaseManager.LoadConfig(const AKey: string): string;
var
  Query: TSQLQuery;
  SQL: string;
begin
  Result := '';
  
  try
    if not Connect then
      Exit;
    
    SQL := 'SELECT value FROM configs WHERE key = ' + QuotedStr(AKey);
    Query := ExecuteQuery(SQL);
    
    try
      if not Query.Eof then
        Result := Query.FieldByName('value').AsString;
    finally
      Query.Free;
    end;
    
  except
    Result := '';
  end;
end;

function TDatabaseManager.DeleteConfig(const AKey: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  
  try
    if not Connect then
      Exit;
    
    SQL := 'DELETE FROM configs WHERE key = ' + QuotedStr(AKey);
    Result := ExecuteSQL(SQL);
    
  except
    Result := False;
  end;
end;

function TDatabaseManager.GetAllConfigs: TDictionary<string, string>;
var
  Query: TSQLQuery;
  SQL: string;
begin
  Result := TDictionary<string, string>.Create;
  
  try
    if not Connect then
      Exit;
    
    SQL := 'SELECT key, value FROM configs ORDER BY key';
    Query := ExecuteQuery(SQL);
    
    try
      while not Query.Eof do
      begin
        Result.Add(Query.FieldByName('key').AsString, Query.FieldByName('value').AsString);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    
  except
    // 返回空字典
  end;
end;

function TDatabaseManager.LogOperation(const AOperation, ASource, ATarget, AResult, ADetails: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  
  try
    if not Connect then
      Exit;
    
    SQL := 'INSERT INTO operation_logs (operation, source_path, target_path, result, details) VALUES (' +
           QuotedStr(AOperation) + ', ' + QuotedStr(ASource) + ', ' + QuotedStr(ATarget) + ', ' +
           QuotedStr(AResult) + ', ' + QuotedStr(ADetails) + ')';
    
    Result := ExecuteSQL(SQL);
    
  except
    Result := False;
  end;
end;

function TDatabaseManager.GetOperationHistory(ALimit: Integer): TArray<TOperationLog>;
var
  Query: TSQLQuery;
  SQL: string;
  Results: TList<TOperationLog>;
  LogEntry: TOperationLog;
begin
  Results := TList<TOperationLog>.Create;
  
  try
    if not Connect then
    begin
      SetLength(Result, 0);
      Exit;
    end;
    
    SQL := 'SELECT * FROM operation_logs ORDER BY created_at DESC LIMIT ' + IntToStr(ALimit);
    Query := ExecuteQuery(SQL);
    
    try
      while not Query.Eof do
      begin
        LogEntry.Id := Query.FieldByName('id').AsInteger;
        LogEntry.Operation := Query.FieldByName('operation').AsString;
        LogEntry.SourcePath := Query.FieldByName('source_path').AsString;
        LogEntry.TargetPath := Query.FieldByName('target_path').AsString;
        LogEntry.Result := Query.FieldByName('result').AsString;
        LogEntry.Details := Query.FieldByName('details').AsString;
        LogEntry.Timestamp := Query.FieldByName('created_at').AsDateTime;
        
        Results.Add(LogEntry);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

function TDatabaseManager.ClearOperationHistory: Boolean;
begin
  Result := False;
  
  try
    if not Connect then
      Exit;
    
    Result := ExecuteSQL('DELETE FROM operation_logs');
    
  except
    Result := False;
  end;
end;

function TDatabaseManager.SaveBackupManifest(const ABackupId, AManifestData: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  
  try
    if not Connect then
      Exit;
    
    SQL := 'INSERT OR REPLACE INTO backup_manifests (backup_id, manifest_data) VALUES (' +
           QuotedStr(ABackupId) + ', ' + QuotedStr(AManifestData) + ')';
    
    Result := ExecuteSQL(SQL);
    
  except
    Result := False;
  end;
end;

function TDatabaseManager.LoadBackupManifest(const ABackupId: string): string;
var
  Query: TSQLQuery;
  SQL: string;
begin
  Result := '';
  
  try
    if not Connect then
      Exit;
    
    SQL := 'SELECT manifest_data FROM backup_manifests WHERE backup_id = ' + QuotedStr(ABackupId);
    Query := ExecuteQuery(SQL);
    
    try
      if not Query.Eof then
        Result := Query.FieldByName('manifest_data').AsString;
    finally
      Query.Free;
    end;
    
  except
    Result := '';
  end;
end;

function TDatabaseManager.GetBackupList: TArray<string>;
var
  Query: TSQLQuery;
  SQL: string;
  Results: TList<string>;
begin
  Results := TList<string>.Create;
  
  try
    if not Connect then
    begin
      SetLength(Result, 0);
      Exit;
    end;
    
    SQL := 'SELECT backup_id FROM backup_manifests ORDER BY created_at DESC';
    Query := ExecuteQuery(SQL);
    
    try
      while not Query.Eof do
      begin
        Results.Add(Query.FieldByName('backup_id').AsString);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

function TDatabaseManager.DeleteBackupManifest(const ABackupId: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  
  try
    if not Connect then
      Exit;
    
    SQL := 'DELETE FROM backup_manifests WHERE backup_id = ' + QuotedStr(ABackupId);
    Result := ExecuteSQL(SQL);
    
  except
    Result := False;
  end;
end;

end.