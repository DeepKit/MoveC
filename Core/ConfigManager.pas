unit ConfigManager;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, DataTypes;

type
  TConfigManager = class
  private
    FConfigFile: TIniFile;
    FLogFile: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    // 配置管理 - 兼容新接口
    function GetConfigValue(const Section, Key, Default: string): string;
    procedure SetConfigValue(const Section, Key, Value: string);

    // 新增的类型化配置方法
    function GetString(const Key, Default: string): string;
    function GetBoolean(const Key: string; Default: Boolean): Boolean;
    function GetInteger(const Key: string; Default: Integer): Integer;
    procedure SetString(const Key, Value: string);
    procedure SetBoolean(const Key: string; Value: Boolean);
    procedure SetInteger(const Key: string; Value: Integer);

    // 配置文件操作
    procedure LoadConfiguration;
    procedure SaveConfiguration;

    // 日志管理
    procedure LogOperation(const Operation, Description, SourcePath, TargetPath, Status, Details: string);

    // 路径管理
    function GetBackupPath: string;
    function GetLogPath: string;
  end;

implementation

constructor TConfigManager.Create;
begin
  inherited;
  FConfigFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
  FLogFile := TStringList.Create;
end;

destructor TConfigManager.Destroy;
begin
  FLogFile.Free;
  FConfigFile.Free;
  inherited;
end;

function TConfigManager.GetConfigValue(const Section, Key, Default: string): string;
begin
  Result := FConfigFile.ReadString(Section, Key, Default);
end;

procedure TConfigManager.SetConfigValue(const Section, Key, Value: string);
begin
  FConfigFile.WriteString(Section, Key, Value);
end;

procedure TConfigManager.LogOperation(const Operation, Description, SourcePath, TargetPath, Status, Details: string);
var
  LogEntry: string;
begin
  LogEntry := Format('[%s] %s - %s | Source: %s | Target: %s | Status: %s | Details: %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Operation, Description, SourcePath, TargetPath, Status, Details]);
  FLogFile.Add(LogEntry);
  
  // 保存到文件
  try
    FLogFile.SaveToFile(GetLogPath);
  except
    // 忽略日志保存错误
  end;
end;

function TConfigManager.GetBackupPath: string;
begin
  Result := GetConfigValue('Paths', 'BackupPath', ExtractFilePath(ParamStr(0)) + 'Backups\');
  if not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

function TConfigManager.GetLogPath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'DiskCleanup.log';
end;

// 新增的类型化配置方法实现
function TConfigManager.GetString(const Key, Default: string): string;
var
  Section, KeyName: string;
  DotPos: Integer;
begin
  // 解析 "Section.Key" 格式
  DotPos := Pos('.', Key);
  if DotPos > 0 then
  begin
    Section := Copy(Key, 1, DotPos - 1);
    KeyName := Copy(Key, DotPos + 1, Length(Key));
  end
  else
  begin
    Section := 'General';
    KeyName := Key;
  end;

  Result := FConfigFile.ReadString(Section, KeyName, Default);
end;

function TConfigManager.GetBoolean(const Key: string; Default: Boolean): Boolean;
var
  Section, KeyName: string;
  DotPos: Integer;
begin
  // 解析 "Section.Key" 格式
  DotPos := Pos('.', Key);
  if DotPos > 0 then
  begin
    Section := Copy(Key, 1, DotPos - 1);
    KeyName := Copy(Key, DotPos + 1, Length(Key));
  end
  else
  begin
    Section := 'General';
    KeyName := Key;
  end;

  Result := FConfigFile.ReadBool(Section, KeyName, Default);
end;

function TConfigManager.GetInteger(const Key: string; Default: Integer): Integer;
var
  Section, KeyName: string;
  DotPos: Integer;
begin
  // 解析 "Section.Key" 格式
  DotPos := Pos('.', Key);
  if DotPos > 0 then
  begin
    Section := Copy(Key, 1, DotPos - 1);
    KeyName := Copy(Key, DotPos + 1, Length(Key));
  end
  else
  begin
    Section := 'General';
    KeyName := Key;
  end;

  Result := FConfigFile.ReadInteger(Section, KeyName, Default);
end;

procedure TConfigManager.SetString(const Key, Value: string);
var
  Section, KeyName: string;
  DotPos: Integer;
begin
  // 解析 "Section.Key" 格式
  DotPos := Pos('.', Key);
  if DotPos > 0 then
  begin
    Section := Copy(Key, 1, DotPos - 1);
    KeyName := Copy(Key, DotPos + 1, Length(Key));
  end
  else
  begin
    Section := 'General';
    KeyName := Key;
  end;

  FConfigFile.WriteString(Section, KeyName, Value);
end;

procedure TConfigManager.SetBoolean(const Key: string; Value: Boolean);
var
  Section, KeyName: string;
  DotPos: Integer;
begin
  // 解析 "Section.Key" 格式
  DotPos := Pos('.', Key);
  if DotPos > 0 then
  begin
    Section := Copy(Key, 1, DotPos - 1);
    KeyName := Copy(Key, DotPos + 1, Length(Key));
  end
  else
  begin
    Section := 'General';
    KeyName := Key;
  end;

  FConfigFile.WriteBool(Section, KeyName, Value);
end;

procedure TConfigManager.SetInteger(const Key: string; Value: Integer);
var
  Section, KeyName: string;
  DotPos: Integer;
begin
  // 解析 "Section.Key" 格式
  DotPos := Pos('.', Key);
  if DotPos > 0 then
  begin
    Section := Copy(Key, 1, DotPos - 1);
    KeyName := Copy(Key, DotPos + 1, Length(Key));
  end
  else
  begin
    Section := 'General';
    KeyName := Key;
  end;

  FConfigFile.WriteInteger(Section, KeyName, Value);
end;

procedure TConfigManager.LoadConfiguration;
begin
  // 重新加载配置文件
  if Assigned(FConfigFile) then
  begin
    FConfigFile.Free;
    FConfigFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
  end;
end;

procedure TConfigManager.SaveConfiguration;
begin
  // 强制保存配置到文件
  if Assigned(FConfigFile) then
    FConfigFile.UpdateFile;
end;

end.