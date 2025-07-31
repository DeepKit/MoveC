unit ConfigManager;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, DataTypes, DatabaseManager;

type
  // 配置管理器类
  TConfigManager = class
  private
    FConfigFile: TIniFile;
    FConfigPath: string;
    FDatabaseManager: TDatabaseManager;

    procedure CreateDefaultConfig;
    
  public
    constructor Create(const AConfigPath: string = '');
    destructor Destroy; override;
    
    // 基本配置操作
    function GetString(const ASection, AKey, ADefault: string): string;
    procedure SetString(const ASection, AKey, AValue: string);
    function GetInteger(const ASection, AKey: string; ADefault: Integer): Integer;
    procedure SetInteger(const ASection, AKey: string; AValue: Integer);
    function GetBoolean(const ASection, AKey: string; ADefault: Boolean): Boolean;
    procedure SetBoolean(const ASection, AKey: string; AValue: Boolean);
    
    // 应用程序特定配置
    function GetLanguage: string;
    procedure SetLanguage(const ALanguage: string);
    function GetSecurityLevel: Integer;
    procedure SetSecurityLevel(ALevel: Integer);
    function GetLastBackupId: string;
    procedure SetLastBackupId(const ABackupId: string);
    
    // 配置文件操作
    procedure SaveConfig;
    procedure LoadConfig;
    function ConfigExists: Boolean;

    // 数据库相关方法
    function InitializeDatabase: Boolean;
    function GetDatabaseManager: TDatabaseManager;
    function LogOperation(const OpType, Detail, SourcePath, TargetPath, OpResult: string;
                         const ErrorMsg: string = ''; ExecutionTime: Integer = 0): Boolean;
    function GetBackupRecords: TArray<TBackupInfo>;
    function AddBackupRecord(const BackupInfo: TBackupInfo): Boolean;

    property ConfigPath: string read FConfigPath;
    property DatabaseManager: TDatabaseManager read FDatabaseManager;
  end;

implementation

constructor TConfigManager.Create(const AConfigPath: string);
begin
  inherited Create;

  if AConfigPath = '' then
    FConfigPath := ChangeFileExt(ParamStr(0), '.ini')
  else
    FConfigPath := AConfigPath;

  FConfigFile := TIniFile.Create(FConfigPath);

  // 初始化数据库管理器
  FDatabaseManager := TDatabaseManager.Create;

  if not ConfigExists then
    CreateDefaultConfig;
end;

destructor TConfigManager.Destroy;
begin
  if Assigned(FDatabaseManager) then
    FDatabaseManager.Free;
  FConfigFile.Free;
  inherited;
end;

procedure TConfigManager.CreateDefaultConfig;
begin
  // 创建默认配置
  SetString('Application', 'Language', 'zh-CN');
  SetInteger('Application', 'SecurityLevel', 1);
  SetString('Application', 'LastBackupId', '');
  SetBoolean('Application', 'FirstRun', True);
  
  // 安全配置
  SetBoolean('Security', 'EnableIntegrityCheck', True);
  SetBoolean('Security', 'EnableEncryption', True);
  SetInteger('Security', 'EncryptionLevel', 256);
  
  // 迁移配置
  SetBoolean('Migration', 'CreateBackupBeforeMigration', True);
  SetBoolean('Migration', 'ValidateDependencies', True);
  SetBoolean('Migration', 'RequireAdminRights', True);
  
  SaveConfig;
end;

function TConfigManager.GetString(const ASection, AKey, ADefault: string): string;
begin
  Result := FConfigFile.ReadString(ASection, AKey, ADefault);
end;

procedure TConfigManager.SetString(const ASection, AKey, AValue: string);
begin
  FConfigFile.WriteString(ASection, AKey, AValue);
end;

function TConfigManager.GetInteger(const ASection, AKey: string; ADefault: Integer): Integer;
begin
  Result := FConfigFile.ReadInteger(ASection, AKey, ADefault);
end;

procedure TConfigManager.SetInteger(const ASection, AKey: string; AValue: Integer);
begin
  FConfigFile.WriteInteger(ASection, AKey, AValue);
end;

function TConfigManager.GetBoolean(const ASection, AKey: string; ADefault: Boolean): Boolean;
begin
  Result := FConfigFile.ReadBool(ASection, AKey, ADefault);
end;

procedure TConfigManager.SetBoolean(const ASection, AKey: string; AValue: Boolean);
begin
  FConfigFile.WriteBool(ASection, AKey, AValue);
end;

function TConfigManager.GetLanguage: string;
begin
  Result := GetString('Application', 'Language', 'zh-CN');
end;

procedure TConfigManager.SetLanguage(const ALanguage: string);
begin
  SetString('Application', 'Language', ALanguage);
end;

function TConfigManager.GetSecurityLevel: Integer;
begin
  Result := GetInteger('Application', 'SecurityLevel', 1);
end;

procedure TConfigManager.SetSecurityLevel(ALevel: Integer);
begin
  SetInteger('Application', 'SecurityLevel', ALevel);
end;

function TConfigManager.GetLastBackupId: string;
begin
  Result := GetString('Application', 'LastBackupId', '');
end;

procedure TConfigManager.SetLastBackupId(const ABackupId: string);
begin
  SetString('Application', 'LastBackupId', ABackupId);
end;

procedure TConfigManager.SaveConfig;
begin
  FConfigFile.UpdateFile;
end;

procedure TConfigManager.LoadConfig;
begin
  // 重新加载配置文件
  FConfigFile.Free;
  FConfigFile := TIniFile.Create(FConfigPath);
end;

function TConfigManager.ConfigExists: Boolean;
begin
  Result := FileExists(FConfigPath);
end;

// 初始化数据库
function TConfigManager.InitializeDatabase: Boolean;
begin
  Result := False;
  if Assigned(FDatabaseManager) then
    Result := FDatabaseManager.Initialize;
end;

// 获取数据库管理器
function TConfigManager.GetDatabaseManager: TDatabaseManager;
begin
  Result := FDatabaseManager;
end;

// 记录操作日志
function TConfigManager.LogOperation(const OpType, Detail, SourcePath, TargetPath, OpResult: string;
                                    const ErrorMsg: string = ''; ExecutionTime: Integer = 0): Boolean;
begin
  Result := False;
  if Assigned(FDatabaseManager) and FDatabaseManager.IsInitialized then
    Result := FDatabaseManager.LogOperation(OpType, Detail, SourcePath, TargetPath, OpResult, ErrorMsg, ExecutionTime);
end;

// 获取备份记录
function TConfigManager.GetBackupRecords: TArray<TBackupInfo>;
begin
  SetLength(Result, 0);
  if Assigned(FDatabaseManager) and FDatabaseManager.IsInitialized then
    Result := FDatabaseManager.GetBackupRecords;
end;

// 添加备份记录
function TConfigManager.AddBackupRecord(const BackupInfo: TBackupInfo): Boolean;
begin
  Result := False;
  if Assigned(FDatabaseManager) and FDatabaseManager.IsInitialized then
    Result := FDatabaseManager.AddBackupRecord(BackupInfo);
end;

end.