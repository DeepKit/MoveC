unit DatabaseManager;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  System.Generics.Collections, Winapi.Windows, BasicProtection, DataTypes;

type
  // 简化的文件数据库管理器
  TDatabaseManager = class
  private
    FDatabasePath: string;
    FIsInitialized: Boolean;
    FBackupRecords: TJSONArray;
    FOperationLogs: TJSONArray;
    FConfigSettings: TJSONObject;
    FDonationAddresses: TJSONArray;
    FLanguageStrings: TJSONObject;
    
    function GetDatabasePath: string;
    procedure LoadDataFromFiles;
    procedure SaveDataToFiles;
    procedure InitializeDefaultData;
    procedure InitializeDefaultLanguageStrings;
    function GenerateId: string;
    function BackupRecordsFile: string;
    function OperationLogsFile: string;
    function ConfigSettingsFile: string;
    function DonationAddressesFile: string;
    function LanguageStringsFile: string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 数据库初始化
    function Initialize: Boolean;
    procedure Finalize;
    
    // 备份记录管理
    function AddBackupRecord(const BackupInfo: TBackupInfo): Boolean;
    function GetBackupRecords: TArray<TBackupInfo>;
    function GetBackupRecord(const BackupId: string): TBackupInfo;
    function UpdateBackupRecord(const BackupInfo: TBackupInfo): Boolean;
    function DeleteBackupRecord(const BackupId: string): Boolean;
    
    // 操作日志管理
    function LogOperation(const OpType, Detail, SourcePath, TargetPath, OpResult: string;
                         const ErrorMsg: string = ''; ExecutionTime: Integer = 0): Boolean;
    function GetOperationLogs(const StartDate, EndDate: TDateTime; 
                             const OpType: string = ''): TArray<TOperationLog>;
    function ClearOldLogs(const DaysToKeep: Integer = 30): Boolean;
    
    // 配置管理
    function SetConfig(const Category, Key, Value: string; 
                      const ValueType: string = 'string'; 
                      const Encrypted: Boolean = False): Boolean;
    function GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
    function DeleteConfig(const Category, Key: string): Boolean;
    function GetConfigsByCategory(const Category: string): TArray<TConfigItem>;
    
    // 打赏地址管理
    function SetDonationAddress(const AddressType, AddressValue, Description: string;
                               const IsActive: Boolean = True;
                               const DisplayOrder: Integer = 0): Boolean;
    function GetDonationAddresses(const ActiveOnly: Boolean = True): TArray<TDonationAddress>;
    function UpdateDonationAddress(const AddressType, AddressValue, Description: string): Boolean;
    function DeleteDonationAddress(const AddressType: string): Boolean;

    // 多语言字符串管理
    function SetLanguageString(const LanguageCode, StringKey, StringValue: string): Boolean;
    function GetLanguageString(const LanguageCode, StringKey: string; const DefaultValue: string = ''): string;
    function GetAllLanguageStrings(const LanguageCode: string): TArray<TLanguageStringItem>;
    function DeleteLanguageString(const LanguageCode, StringKey: string): Boolean;
    function ImportLanguageStrings(const LanguageCode: string; const StringData: TJSONObject): Boolean;
    function ExportLanguageStrings(const LanguageCode: string): TJSONObject;
    
    // 数据库维护
    function BackupDatabase(const BackupPath: string): Boolean;
    function RestoreDatabase(const BackupPath: string): Boolean;
    function VacuumDatabase: Boolean;
    function GetDatabaseInfo: TDatabaseInfo;
    
    // 属性
    property DatabasePath: string read FDatabasePath;
    property IsInitialized: Boolean read FIsInitialized;
  end;

implementation

uses
  Vcl.Forms, System.DateUtils;

constructor TDatabaseManager.Create;
begin
  inherited;
  FDatabasePath := '';
  FIsInitialized := False;
  FBackupRecords := nil;
  FOperationLogs := nil;
  FConfigSettings := nil;
  FDonationAddresses := nil;
  FLanguageStrings := nil;
end;

destructor TDatabaseManager.Destroy;
begin
  Finalize;
  inherited;
end;

// 获取数据库路径
function TDatabaseManager.GetDatabasePath: string;
var
  AppDataPath: string;
begin
  // 使用环境变量获取正确的AppData\Local路径
  AppDataPath := GetEnvironmentVariable('LOCALAPPDATA');
  if AppDataPath = '' then
    AppDataPath := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local');
  Result := TPath.Combine(AppDataPath, 'DiskCleanup');
end;

// 获取各个数据文件路径
function TDatabaseManager.BackupRecordsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'backup_records.json');
end;

function TDatabaseManager.OperationLogsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'operation_logs.json');
end;

function TDatabaseManager.ConfigSettingsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'config_settings.json');
end;

function TDatabaseManager.DonationAddressesFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'donation_addresses.json');
end;

function TDatabaseManager.LanguageStringsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'language_strings.json');
end;

// 初始化文件数据库
function TDatabaseManager.Initialize: Boolean;
begin
  Result := False;
  try
    if FIsInitialized then
      Exit(True);
      
    FDatabasePath := GetDatabasePath;
    
    // 创建数据目录
    if not TDirectory.Exists(FDatabasePath) then
      TDirectory.CreateDirectory(FDatabasePath);
    
    // 初始化JSON对象
    FBackupRecords := TJSONArray.Create;
    FOperationLogs := TJSONArray.Create;
    FConfigSettings := TJSONObject.Create;
    FDonationAddresses := TJSONArray.Create;
    FLanguageStrings := TJSONObject.Create;
    
    // 从文件加载数据
    LoadDataFromFiles;
    
    // 初始化默认数据
    InitializeDefaultData;
    
    FIsInitialized := True;
    Result := True;
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('文件数据库初始化失败: ' + E.Message));
      Finalize;
    end;
  end;
end;

// 从文件加载数据
procedure TDatabaseManager.LoadDataFromFiles;
var
  JsonText: string;
  JsonValue: TJSONValue;
begin
  try
    // 加载备份记录
    if TFile.Exists(BackupRecordsFile) then
    begin
      JsonText := TFile.ReadAllText(BackupRecordsFile, TEncoding.UTF8);
      JsonValue := TJSONObject.ParseJSONValue(JsonText);
      if JsonValue is TJSONArray then
      begin
        FBackupRecords.Free;
        FBackupRecords := JsonValue as TJSONArray;
      end
      else
        JsonValue.Free;
    end;

    // 加载操作日志
    if TFile.Exists(OperationLogsFile) then
    begin
      JsonText := TFile.ReadAllText(OperationLogsFile, TEncoding.UTF8);
      JsonValue := TJSONObject.ParseJSONValue(JsonText);
      if JsonValue is TJSONArray then
      begin
        FOperationLogs.Free;
        FOperationLogs := JsonValue as TJSONArray;
      end
      else
        JsonValue.Free;
    end;

    // 加载配置设置
    if TFile.Exists(ConfigSettingsFile) then
    begin
      JsonText := TFile.ReadAllText(ConfigSettingsFile, TEncoding.UTF8);
      JsonValue := TJSONObject.ParseJSONValue(JsonText);
      if JsonValue is TJSONObject then
      begin
        FConfigSettings.Free;
        FConfigSettings := JsonValue as TJSONObject;
      end
      else
        JsonValue.Free;
    end;

    // 加载打赏地址
    if TFile.Exists(DonationAddressesFile) then
    begin
      JsonText := TFile.ReadAllText(DonationAddressesFile, TEncoding.UTF8);
      JsonValue := TJSONObject.ParseJSONValue(JsonText);
      if JsonValue is TJSONArray then
      begin
        FDonationAddresses.Free;
        FDonationAddresses := JsonValue as TJSONArray;
      end
      else
        JsonValue.Free;
    end;

    // 加载语言字符串
    if TFile.Exists(LanguageStringsFile) then
    begin
      JsonText := TFile.ReadAllText(LanguageStringsFile, TEncoding.UTF8);
      JsonValue := TJSONObject.ParseJSONValue(JsonText);
      if JsonValue is TJSONObject then
      begin
        FLanguageStrings.Free;
        FLanguageStrings := JsonValue as TJSONObject;
      end
      else
        JsonValue.Free;
    end;
    
  except
    on E: Exception do
      OutputDebugString(PChar('加载数据文件失败: ' + E.Message));
  end;
end;

// 保存数据到文件
procedure TDatabaseManager.SaveDataToFiles;
begin
  try
    if Assigned(FBackupRecords) then
      TFile.WriteAllText(BackupRecordsFile, FBackupRecords.ToJSON, TEncoding.UTF8);

    if Assigned(FOperationLogs) then
      TFile.WriteAllText(OperationLogsFile, FOperationLogs.ToJSON, TEncoding.UTF8);

    if Assigned(FConfigSettings) then
      TFile.WriteAllText(ConfigSettingsFile, FConfigSettings.ToJSON, TEncoding.UTF8);

    if Assigned(FDonationAddresses) then
      TFile.WriteAllText(DonationAddressesFile, FDonationAddresses.ToJSON, TEncoding.UTF8);

    if Assigned(FLanguageStrings) then
      TFile.WriteAllText(LanguageStringsFile, FLanguageStrings.ToJSON, TEncoding.UTF8);

  except
    on E: Exception do
      OutputDebugString(PChar('保存数据文件失败: ' + E.Message));
  end;
end;

// 初始化默认数据
procedure TDatabaseManager.InitializeDefaultData;
begin
  // 设置默认配置
  SetConfig('app', 'version', '1.0.0');
  SetConfig('app', 'first_run', 'true');
  SetConfig('backup', 'auto_cleanup_days', '30');
  SetConfig('log', 'retention_days', '90');
  
  // 设置默认打赏地址
  SetDonationAddress('BTC', 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3', 'BTC收款地址', True, 1);
  SetDonationAddress('USDT', 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys', 'USDT收款地址', True, 2);
  SetDonationAddress('WECHAT', '微信收款码', '微信打赏', True, 3);
  SetDonationAddress('ALIPAY', '支付宝收款码', '支付宝打赏', True, 4);

  // 初始化默认语言字符串
  InitializeDefaultLanguageStrings;
end;

// 生成唯一ID
function TDatabaseManager.GenerateId: string;
begin
  Result := FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + IntToStr(Random(9999));
end;

// 结束数据库连接
procedure TDatabaseManager.Finalize;
begin
  try
    if FIsInitialized then
      SaveDataToFiles;
  except
    // 忽略保存错误
  end;
  
  if Assigned(FBackupRecords) then
  begin
    FBackupRecords.Free;
    FBackupRecords := nil;
  end;
  
  if Assigned(FOperationLogs) then
  begin
    FOperationLogs.Free;
    FOperationLogs := nil;
  end;
  
  if Assigned(FConfigSettings) then
  begin
    FConfigSettings.Free;
    FConfigSettings := nil;
  end;
  
  if Assigned(FDonationAddresses) then
  begin
    FDonationAddresses.Free;
    FDonationAddresses := nil;
  end;

  if Assigned(FLanguageStrings) then
  begin
    FLanguageStrings.Free;
    FLanguageStrings := nil;
  end;

  FIsInitialized := False;
end;

// 添加备份记录
function TDatabaseManager.AddBackupRecord(const BackupInfo: TBackupInfo): Boolean;
var
  BackupObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FBackupRecords) then
    Exit;

  try
    BackupObj := TJSONObject.Create;
    BackupObj.AddPair('backup_id', BackupInfo.BackupId);
    BackupObj.AddPair('source_path', BackupInfo.SourcePath);
    BackupObj.AddPair('target_path', BackupInfo.TargetPath);
    BackupObj.AddPair('backup_time', DateTimeToStr(BackupInfo.BackupTime));
    BackupObj.AddPair('backup_size', TJSONNumber.Create(BackupInfo.BackupSize));
    BackupObj.AddPair('file_count', TJSONNumber.Create(BackupInfo.FileCount));
    BackupObj.AddPair('status', BackupInfo.Status);
    BackupObj.AddPair('description', BackupInfo.Description);
    BackupObj.AddPair('created_at', DateTimeToStr(Now));

    FBackupRecords.AddElement(BackupObj);
    SaveDataToFiles;
    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('添加备份记录失败: ' + E.Message));
  end;
end;

// 获取所有备份记录
function TDatabaseManager.GetBackupRecords: TArray<TBackupInfo>;
var
  I: Integer;
  BackupObj: TJSONObject;
  BackupInfo: TBackupInfo;
  BackupList: TArray<TBackupInfo>;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FBackupRecords) then
    Exit;

  try
    SetLength(BackupList, FBackupRecords.Count);

    for I := 0 to FBackupRecords.Count - 1 do
    begin
      BackupObj := FBackupRecords.Items[I] as TJSONObject;

      BackupInfo.BackupId := BackupObj.GetValue('backup_id').Value;
      BackupInfo.SourcePath := BackupObj.GetValue('source_path').Value;
      BackupInfo.TargetPath := BackupObj.GetValue('target_path').Value;
      BackupInfo.BackupTime := StrToDateTimeDef(BackupObj.GetValue('backup_time').Value, Now);
      BackupInfo.BackupSize := StrToInt64Def(BackupObj.GetValue('backup_size').Value, 0);
      BackupInfo.FileCount := StrToIntDef(BackupObj.GetValue('file_count').Value, 0);
      BackupInfo.Status := BackupObj.GetValue('status').Value;
      BackupInfo.Description := BackupObj.GetValue('description').Value;

      BackupList[I] := BackupInfo;
    end;

    Result := BackupList;

  except
    on E: Exception do
      OutputDebugString(PChar('获取备份记录失败: ' + E.Message));
  end;
end;

// 获取单个备份记录
function TDatabaseManager.GetBackupRecord(const BackupId: string): TBackupInfo;
var
  I: Integer;
  BackupObj: TJSONObject;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FIsInitialized or not Assigned(FBackupRecords) then
    Exit;

  try
    for I := 0 to FBackupRecords.Count - 1 do
    begin
      BackupObj := FBackupRecords.Items[I] as TJSONObject;
      if BackupObj.GetValue('backup_id').Value = BackupId then
      begin
        Result.BackupId := BackupObj.GetValue('backup_id').Value;
        Result.SourcePath := BackupObj.GetValue('source_path').Value;
        Result.TargetPath := BackupObj.GetValue('target_path').Value;
        Result.BackupTime := StrToDateTimeDef(BackupObj.GetValue('backup_time').Value, Now);
        Result.BackupSize := StrToInt64Def(BackupObj.GetValue('backup_size').Value, 0);
        Result.FileCount := StrToIntDef(BackupObj.GetValue('file_count').Value, 0);
        Result.Status := BackupObj.GetValue('status').Value;
        Result.Description := BackupObj.GetValue('description').Value;
        Break;
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('获取备份记录失败: ' + E.Message));
  end;
end;

// 更新备份记录
function TDatabaseManager.UpdateBackupRecord(const BackupInfo: TBackupInfo): Boolean;
var
  I: Integer;
  BackupObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FBackupRecords) then
    Exit;

  try
    for I := 0 to FBackupRecords.Count - 1 do
    begin
      BackupObj := FBackupRecords.Items[I] as TJSONObject;
      if BackupObj.GetValue('backup_id').Value = BackupInfo.BackupId then
      begin
        BackupObj.RemovePair('source_path').Free;
        BackupObj.RemovePair('target_path').Free;
        BackupObj.RemovePair('backup_time').Free;
        BackupObj.RemovePair('backup_size').Free;
        BackupObj.RemovePair('file_count').Free;
        BackupObj.RemovePair('status').Free;
        BackupObj.RemovePair('description').Free;

        BackupObj.AddPair('source_path', BackupInfo.SourcePath);
        BackupObj.AddPair('target_path', BackupInfo.TargetPath);
        BackupObj.AddPair('backup_time', DateTimeToStr(BackupInfo.BackupTime));
        BackupObj.AddPair('backup_size', TJSONNumber.Create(BackupInfo.BackupSize));
        BackupObj.AddPair('file_count', TJSONNumber.Create(BackupInfo.FileCount));
        BackupObj.AddPair('status', BackupInfo.Status);
        BackupObj.AddPair('description', BackupInfo.Description);
        BackupObj.AddPair('updated_at', DateTimeToStr(Now));

        SaveDataToFiles;
        Result := True;
        Break;
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('更新备份记录失败: ' + E.Message));
  end;
end;

// 删除备份记录
function TDatabaseManager.DeleteBackupRecord(const BackupId: string): Boolean;
var
  I: Integer;
  BackupObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FBackupRecords) then
    Exit;

  try
    for I := FBackupRecords.Count - 1 downto 0 do
    begin
      BackupObj := FBackupRecords.Items[I] as TJSONObject;
      if BackupObj.GetValue('backup_id').Value = BackupId then
      begin
        FBackupRecords.Remove(I);
        SaveDataToFiles;
        Result := True;
        Break;
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('删除备份记录失败: ' + E.Message));
  end;
end;

// 记录操作日志
function TDatabaseManager.LogOperation(const OpType, Detail, SourcePath, TargetPath, OpResult: string;
                                      const ErrorMsg: string = ''; ExecutionTime: Integer = 0): Boolean;
var
  LogObj: TJSONObject;
  UserName, MachineCode: string;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FOperationLogs) then
    Exit;

  try
    UserName := GetEnvironmentVariable('USERNAME');
    MachineCode := TBasicProtection.CalculateHMAC(GetEnvironmentVariable('COMPUTERNAME'));

    LogObj := TJSONObject.Create;
    LogObj.AddPair('id', TJSONNumber.Create(FOperationLogs.Count + 1));
    LogObj.AddPair('operation_type', OpType);
    LogObj.AddPair('operation_detail', Detail);
    LogObj.AddPair('source_path', SourcePath);
    LogObj.AddPair('target_path', TargetPath);
    LogObj.AddPair('result', OpResult);
    LogObj.AddPair('error_message', ErrorMsg);
    LogObj.AddPair('execution_time', TJSONNumber.Create(ExecutionTime));
    LogObj.AddPair('user_name', UserName);
    LogObj.AddPair('machine_code', MachineCode);
    LogObj.AddPair('created_at', DateTimeToStr(Now));

    FOperationLogs.AddElement(LogObj);
    SaveDataToFiles;
    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('记录操作日志失败: ' + E.Message));
  end;
end;

// 获取操作日志
function TDatabaseManager.GetOperationLogs(const StartDate, EndDate: TDateTime;
                                          const OpType: string = ''): TArray<TOperationLog>;
var
  I: Integer;
  LogObj: TJSONObject;
  LogInfo: TOperationLog;
  LogList: TArray<TOperationLog>;
  LogTime: TDateTime;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FOperationLogs) then
    Exit;

  try
    SetLength(LogList, 0);

    for I := 0 to FOperationLogs.Count - 1 do
    begin
      LogObj := FOperationLogs.Items[I] as TJSONObject;
      LogTime := StrToDateTimeDef(LogObj.GetValue('created_at').Value, Now);

      // 检查日期范围
      if (LogTime >= StartDate) and (LogTime <= EndDate) then
      begin
        // 检查操作类型过滤
        if (OpType = '') or (LogObj.GetValue('operation_type').Value = OpType) then
        begin
          LogInfo.Id := StrToIntDef(LogObj.GetValue('id').Value, 0);
          LogInfo.OperationType := LogObj.GetValue('operation_type').Value;
          LogInfo.OperationDetail := LogObj.GetValue('operation_detail').Value;
          LogInfo.SourcePath := LogObj.GetValue('source_path').Value;
          LogInfo.TargetPath := LogObj.GetValue('target_path').Value;
          LogInfo.Result := LogObj.GetValue('result').Value;
          LogInfo.ErrorMessage := LogObj.GetValue('error_message').Value;
          LogInfo.ExecutionTime := StrToIntDef(LogObj.GetValue('execution_time').Value, 0);
          LogInfo.UserName := LogObj.GetValue('user_name').Value;
          LogInfo.MachineCode := LogObj.GetValue('machine_code').Value;
          LogInfo.CreatedAt := LogTime;

          SetLength(LogList, Length(LogList) + 1);
          LogList[High(LogList)] := LogInfo;
        end;
      end;
    end;

    Result := LogList;

  except
    on E: Exception do
      OutputDebugString(PChar('获取操作日志失败: ' + E.Message));
  end;
end;

// 清理旧日志
function TDatabaseManager.ClearOldLogs(const DaysToKeep: Integer = 30): Boolean;
var
  I: Integer;
  LogObj: TJSONObject;
  LogTime, CutoffDate: TDateTime;
  RemovedCount: Integer;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FOperationLogs) then
    Exit;

  try
    CutoffDate := Now - DaysToKeep;
    RemovedCount := 0;

    for I := FOperationLogs.Count - 1 downto 0 do
    begin
      LogObj := FOperationLogs.Items[I] as TJSONObject;
      LogTime := StrToDateTimeDef(LogObj.GetValue('created_at').Value, Now);

      if LogTime < CutoffDate then
      begin
        FOperationLogs.Remove(I);
        Inc(RemovedCount);
      end;
    end;

    if RemovedCount > 0 then
      SaveDataToFiles;

    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('清理旧日志失败: ' + E.Message));
  end;
end;

// 设置配置项
function TDatabaseManager.SetConfig(const Category, Key, Value: string;
                                   const ValueType: string = 'string';
                                   const Encrypted: Boolean = False): Boolean;
var
  CategoryObj: TJSONObject;
  EncryptedValue: string;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FConfigSettings) then
    Exit;

  try
    // 如果需要加密，则加密值
    if Encrypted then
      EncryptedValue := TBasicProtection.EncryptSensitiveData(Value)
    else
      EncryptedValue := Value;

    // 获取或创建分类对象
    CategoryObj := FConfigSettings.GetValue(Category) as TJSONObject;
    if not Assigned(CategoryObj) then
    begin
      CategoryObj := TJSONObject.Create;
      FConfigSettings.AddPair(Category, CategoryObj);
    end;

    // 移除旧值（如果存在）
    if Assigned(CategoryObj.GetValue(Key)) then
      CategoryObj.RemovePair(Key).Free;

    // 添加新值
    CategoryObj.AddPair(Key, EncryptedValue);

    SaveDataToFiles;
    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('设置配置项失败: ' + E.Message));
  end;
end;

// 获取配置项
function TDatabaseManager.GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
var
  CategoryObj: TJSONObject;
  ValuePair: TJSONPair;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FConfigSettings) then
    Exit;

  try
    CategoryObj := FConfigSettings.GetValue(Category) as TJSONObject;
    if Assigned(CategoryObj) then
    begin
      ValuePair := CategoryObj.Get(Key);
      if Assigned(ValuePair) then
        Result := ValuePair.JsonValue.Value;
    end;

  except
    on E: Exception do
    begin
      OutputDebugString(PChar('获取配置项失败: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

// 删除配置项
function TDatabaseManager.DeleteConfig(const Category, Key: string): Boolean;
var
  CategoryObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FConfigSettings) then
    Exit;

  try
    CategoryObj := FConfigSettings.GetValue(Category) as TJSONObject;
    if Assigned(CategoryObj) then
    begin
      if Assigned(CategoryObj.GetValue(Key)) then
      begin
        CategoryObj.RemovePair(Key).Free;
        SaveDataToFiles;
        Result := True;
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('删除配置项失败: ' + E.Message));
  end;
end;

// 获取分类下的所有配置项
function TDatabaseManager.GetConfigsByCategory(const Category: string): TArray<TConfigItem>;
var
  CategoryObj: TJSONObject;
  ConfigList: TArray<TConfigItem>;
  ConfigItem: TConfigItem;
  I: Integer;
  Pair: TJSONPair;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FConfigSettings) then
    Exit;

  try
    CategoryObj := FConfigSettings.GetValue(Category) as TJSONObject;
    if Assigned(CategoryObj) then
    begin
      SetLength(ConfigList, CategoryObj.Count);

      for I := 0 to CategoryObj.Count - 1 do
      begin
        Pair := CategoryObj.Pairs[I];
        ConfigItem.Category := Category;
        ConfigItem.KeyName := Pair.JsonString.Value;
        ConfigItem.ValueData := Pair.JsonValue.Value;
        ConfigItem.ValueType := 'string';
        ConfigItem.IsEncrypted := False;
        ConfigItem.Description := '';
        ConfigItem.CreatedAt := Now;
        ConfigItem.UpdatedAt := Now;

        ConfigList[I] := ConfigItem;
      end;

      Result := ConfigList;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('获取配置分类失败: ' + E.Message));
  end;
end;

// 设置打赏地址
function TDatabaseManager.SetDonationAddress(const AddressType, AddressValue, Description: string;
                                             const IsActive: Boolean = True;
                                             const DisplayOrder: Integer = 0): Boolean;
var
  AddressObj: TJSONObject;
  EncryptedValue, Checksum: string;
  I: Integer;
  Found: Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FDonationAddresses) then
    Exit;

  try
    EncryptedValue := TBasicProtection.EncryptSensitiveData(AddressValue);
    Checksum := TBasicProtection.CalculateHMAC(AddressType + AddressValue);

    // 查找是否已存在
    Found := False;
    for I := 0 to FDonationAddresses.Count - 1 do
    begin
      AddressObj := FDonationAddresses.Items[I] as TJSONObject;
      if AddressObj.GetValue('address_type').Value = AddressType then
      begin
        // 更新现有记录
        AddressObj.RemovePair('address_value').Free;
        AddressObj.RemovePair('description').Free;
        AddressObj.RemovePair('is_active').Free;
        AddressObj.RemovePair('display_order').Free;

        AddressObj.AddPair('address_value', EncryptedValue);
        AddressObj.AddPair('description', Description);
        AddressObj.AddPair('is_active', TJSONBool.Create(IsActive));
        AddressObj.AddPair('display_order', TJSONNumber.Create(DisplayOrder));
        AddressObj.AddPair('updated_at', DateTimeToStr(Now));

        Found := True;
        Break;
      end;
    end;

    // 如果不存在，创建新记录
    if not Found then
    begin
      AddressObj := TJSONObject.Create;
      AddressObj.AddPair('address_type', AddressType);
      AddressObj.AddPair('address_value', EncryptedValue);
      AddressObj.AddPair('description', Description);
      AddressObj.AddPair('is_active', TJSONBool.Create(IsActive));
      AddressObj.AddPair('display_order', TJSONNumber.Create(DisplayOrder));
      AddressObj.AddPair('checksum', Checksum);
      AddressObj.AddPair('created_at', DateTimeToStr(Now));
      AddressObj.AddPair('updated_at', DateTimeToStr(Now));

      FDonationAddresses.AddElement(AddressObj);
    end;

    SaveDataToFiles;
    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('设置打赏地址失败: ' + E.Message));
  end;
end;

// 获取打赏地址列表
function TDatabaseManager.GetDonationAddresses(const ActiveOnly: Boolean = True): TArray<TDonationAddress>;
var
  I: Integer;
  AddressObj: TJSONObject;
  AddressInfo: TDonationAddress;
  AddressList: TArray<TDonationAddress>;
  IsActive: Boolean;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FDonationAddresses) then
    Exit;

  try
    SetLength(AddressList, 0);

    for I := 0 to FDonationAddresses.Count - 1 do
    begin
      AddressObj := FDonationAddresses.Items[I] as TJSONObject;
      IsActive := StrToBoolDef(AddressObj.GetValue('is_active').Value, True);

      if (not ActiveOnly) or IsActive then
      begin
        AddressInfo.AddressType := AddressObj.GetValue('address_type').Value;
        AddressInfo.Description := AddressObj.GetValue('description').Value;
        AddressInfo.IsActive := IsActive;
        AddressInfo.DisplayOrder := StrToIntDef(AddressObj.GetValue('display_order').Value, 0);
        AddressInfo.CreatedAt := StrToDateTimeDef(AddressObj.GetValue('created_at').Value, Now);
        AddressInfo.UpdatedAt := StrToDateTimeDef(AddressObj.GetValue('updated_at').Value, Now);

        // 解密地址值
        try
          AddressInfo.AddressValue := TBasicProtection.DecryptSensitiveData(
            AddressObj.GetValue('address_value').Value);
        except
          AddressInfo.AddressValue := '[解密失败]';
        end;

        SetLength(AddressList, Length(AddressList) + 1);
        AddressList[High(AddressList)] := AddressInfo;
      end;
    end;

    Result := AddressList;

  except
    on E: Exception do
      OutputDebugString(PChar('获取打赏地址失败: ' + E.Message));
  end;
end;

// 更新打赏地址
function TDatabaseManager.UpdateDonationAddress(const AddressType, AddressValue, Description: string): Boolean;
begin
  Result := SetDonationAddress(AddressType, AddressValue, Description, True, 0);
end;

// 删除打赏地址
function TDatabaseManager.DeleteDonationAddress(const AddressType: string): Boolean;
var
  I: Integer;
  AddressObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FDonationAddresses) then
    Exit;

  try
    for I := FDonationAddresses.Count - 1 downto 0 do
    begin
      AddressObj := FDonationAddresses.Items[I] as TJSONObject;
      if AddressObj.GetValue('address_type').Value = AddressType then
      begin
        FDonationAddresses.Remove(I);
        SaveDataToFiles;
        Result := True;
        Break;
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('删除打赏地址失败: ' + E.Message));
  end;
end;

// 备份数据库
function TDatabaseManager.BackupDatabase(const BackupPath: string): Boolean;
var
  BackupDir: string;
begin
  Result := False;
  if not FIsInitialized then
    Exit;

  try
    BackupDir := TPath.GetDirectoryName(BackupPath);
    if not TDirectory.Exists(BackupDir) then
      TDirectory.CreateDirectory(BackupDir);

    // 保存当前数据
    SaveDataToFiles;

    // 复制整个数据目录
    TDirectory.Copy(FDatabasePath, BackupPath);
    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('备份数据库失败: ' + E.Message));
  end;
end;

// 恢复数据库
function TDatabaseManager.RestoreDatabase(const BackupPath: string): Boolean;
begin
  Result := False;
  if not TDirectory.Exists(BackupPath) then
    Exit;

  try
    Finalize;

    // 删除当前数据目录
    if TDirectory.Exists(FDatabasePath) then
      TDirectory.Delete(FDatabasePath, True);

    // 复制备份数据
    TDirectory.Copy(BackupPath, FDatabasePath);

    // 重新初始化
    Result := Initialize;

  except
    on E: Exception do
      OutputDebugString(PChar('恢复数据库失败: ' + E.Message));
  end;
end;

// 压缩数据库（对于文件数据库，这里只是重新保存）
function TDatabaseManager.VacuumDatabase: Boolean;
begin
  Result := False;
  if not FIsInitialized then
    Exit;

  try
    SaveDataToFiles;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('压缩数据库失败: ' + E.Message));
  end;
end;

// 获取数据库信息
function TDatabaseManager.GetDatabaseInfo: TDatabaseInfo;
var
  TotalSize: Int64;
  SearchRec: TSearchRec;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FIsInitialized then
    Exit;

  try
    Result.DatabasePath := FDatabasePath;
    Result.IsConnected := FIsInitialized;

    // 计算数据库文件总大小
    TotalSize := 0;
    if FindFirst(TPath.Combine(FDatabasePath, '*.json'), faAnyFile, SearchRec) = 0 then
    begin
      repeat
        Inc(TotalSize, SearchRec.Size);
      until FindNext(SearchRec) <> 0;
      System.SysUtils.FindClose(SearchRec);
    end;
    Result.FileSize := TotalSize;

    // 获取记录统计
    if Assigned(FBackupRecords) then
      Result.BackupRecordCount := FBackupRecords.Count;

    if Assigned(FOperationLogs) then
      Result.LogRecordCount := FOperationLogs.Count;

    if Assigned(FConfigSettings) then
      Result.ConfigRecordCount := FConfigSettings.Count;

    if Assigned(FDonationAddresses) then
      Result.DonationRecordCount := FDonationAddresses.Count;

    if Assigned(FLanguageStrings) then
      Result.LanguageStringCount := FLanguageStrings.Count;

  except
    on E: Exception do
      OutputDebugString(PChar('获取数据库信息失败: ' + E.Message));
  end;
end;

// 初始化默认语言字符串
procedure TDatabaseManager.InitializeDefaultLanguageStrings;
begin
  // 简体中文
  SetLanguageString('zh-CN', 'app_title', 'C盘超级清理');
  SetLanguageString('zh-CN', 'menu_file', '文件(&F)');
  SetLanguageString('zh-CN', 'menu_exit', '退出(&X)');
  SetLanguageString('zh-CN', 'menu_tools', '工具(&T)');
  SetLanguageString('zh-CN', 'menu_system_check', '系统检查(&S)');
  SetLanguageString('zh-CN', 'menu_language', '语言设置(&L)');
  SetLanguageString('zh-CN', 'menu_help', '帮助(&H)');
  SetLanguageString('zh-CN', 'menu_about', '关于(&A)');
  SetLanguageString('zh-CN', 'btn_copy', '复制文件');
  SetLanguageString('zh-CN', 'btn_delete', '删除并链接');
  SetLanguageString('zh-CN', 'btn_backup', '创建备份');
  SetLanguageString('zh-CN', 'btn_cancel', '取消');
  SetLanguageString('zh-CN', 'btn_ok', '确定');
  SetLanguageString('zh-CN', 'btn_yes', '是');
  SetLanguageString('zh-CN', 'btn_no', '否');
  SetLanguageString('zh-CN', 'btn_close', '关闭');
  SetLanguageString('zh-CN', 'tab_backup', '备份管理');
  SetLanguageString('zh-CN', 'tab_about', '关于开发者');
  SetLanguageString('zh-CN', 'status_ready', '就绪');
  SetLanguageString('zh-CN', 'status_copying', '正在复制...');
  SetLanguageString('zh-CN', 'status_complete', '操作完成');
  SetLanguageString('zh-CN', 'progress_title', '操作进度');
  SetLanguageString('zh-CN', 'confirm_delete', '确定要删除选中的文件吗？');
  SetLanguageString('zh-CN', 'language_changed', '语言设置已更改，部分界面将在重启后生效。');
  SetLanguageString('zh-CN', 'donation_title', '支持开发者');
  SetLanguageString('zh-CN', 'machine_code', '机器码');
end;

// 设置语言字符串
function TDatabaseManager.SetLanguageString(const LanguageCode, StringKey, StringValue: string): Boolean;
var
  LanguageObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageStrings) then
    Exit;

  try
    // 获取或创建语言对象
    LanguageObj := FLanguageStrings.GetValue(LanguageCode) as TJSONObject;
    if not Assigned(LanguageObj) then
    begin
      LanguageObj := TJSONObject.Create;
      FLanguageStrings.AddPair(LanguageCode, LanguageObj);
    end;

    // 移除旧值（如果存在）
    if Assigned(LanguageObj.GetValue(StringKey)) then
      LanguageObj.RemovePair(StringKey).Free;

    // 添加新值
    LanguageObj.AddPair(StringKey, StringValue);

    SaveDataToFiles;
    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('设置语言字符串失败: ' + E.Message));
  end;
end;

// 获取语言字符串
function TDatabaseManager.GetLanguageString(const LanguageCode, StringKey: string; const DefaultValue: string = ''): string;
var
  LanguageObj: TJSONObject;
  ValuePair: TJSONPair;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FLanguageStrings) then
    Exit;

  try
    LanguageObj := FLanguageStrings.GetValue(LanguageCode) as TJSONObject;
    if Assigned(LanguageObj) then
    begin
      ValuePair := LanguageObj.Get(StringKey);
      if Assigned(ValuePair) then
        Result := ValuePair.JsonValue.Value;
    end;

  except
    on E: Exception do
    begin
      OutputDebugString(PChar('获取语言字符串失败: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

// 获取指定语言的所有字符串
function TDatabaseManager.GetAllLanguageStrings(const LanguageCode: string): TArray<TLanguageStringItem>;
var
  LanguageObj: TJSONObject;
  StringList: TArray<TLanguageStringItem>;
  StringItem: TLanguageStringItem;
  I: Integer;
  Pair: TJSONPair;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FLanguageStrings) then
    Exit;

  try
    LanguageObj := FLanguageStrings.GetValue(LanguageCode) as TJSONObject;
    if Assigned(LanguageObj) then
    begin
      SetLength(StringList, LanguageObj.Count);

      for I := 0 to LanguageObj.Count - 1 do
      begin
        Pair := LanguageObj.Pairs[I];
        StringItem.LanguageCode := LanguageCode;
        StringItem.StringKey := Pair.JsonString.Value;
        StringItem.StringValue := Pair.JsonValue.Value;
        StringItem.CreatedAt := Now;
        StringItem.UpdatedAt := Now;

        StringList[I] := StringItem;
      end;

      Result := StringList;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('获取语言字符串列表失败: ' + E.Message));
  end;
end;

// 删除语言字符串
function TDatabaseManager.DeleteLanguageString(const LanguageCode, StringKey: string): Boolean;
var
  LanguageObj: TJSONObject;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageStrings) then
    Exit;

  try
    LanguageObj := FLanguageStrings.GetValue(LanguageCode) as TJSONObject;
    if Assigned(LanguageObj) then
    begin
      if Assigned(LanguageObj.GetValue(StringKey)) then
      begin
        LanguageObj.RemovePair(StringKey).Free;
        SaveDataToFiles;
        Result := True;
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('删除语言字符串失败: ' + E.Message));
  end;
end;

// 导入语言字符串
function TDatabaseManager.ImportLanguageStrings(const LanguageCode: string; const StringData: TJSONObject): Boolean;
var
  I: Integer;
  Pair: TJSONPair;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageStrings) or not Assigned(StringData) then
    Exit;

  try
    for I := 0 to StringData.Count - 1 do
    begin
      Pair := StringData.Pairs[I];
      SetLanguageString(LanguageCode, Pair.JsonString.Value, Pair.JsonValue.Value);
    end;

    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('导入语言字符串失败: ' + E.Message));
  end;
end;

// 导出语言字符串
function TDatabaseManager.ExportLanguageStrings(const LanguageCode: string): TJSONObject;
var
  LanguageObj: TJSONObject;
  I: Integer;
  Pair: TJSONPair;
begin
  Result := nil;
  if not FIsInitialized or not Assigned(FLanguageStrings) then
    Exit;

  try
    LanguageObj := FLanguageStrings.GetValue(LanguageCode) as TJSONObject;
    if Assigned(LanguageObj) then
    begin
      Result := TJSONObject.Create;

      // 手动复制所有键值对
      for I := 0 to LanguageObj.Count - 1 do
      begin
        Pair := LanguageObj.Pairs[I];
        Result.AddPair(Pair.JsonString.Value, Pair.JsonValue.Value);
      end;
    end;

  except
    on E: Exception do
    begin
      OutputDebugString(PChar('导出语言字符串失败: ' + E.Message));
      if Assigned(Result) then
      begin
        Result.Free;
        Result := nil;
      end;
    end;
  end;
end;

end.
