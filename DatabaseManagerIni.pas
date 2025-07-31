unit DatabaseManagerIni;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.Generics.Collections, Winapi.Windows, BasicProtection, DataTypes;

type
  // 基于INI文件的数据库管理器
  TDatabaseManagerIni = class
  private
    FDatabasePath: string;
    FIsInitialized: Boolean;
    FBackupIni: TMemIniFile;
    FOperationIni: TMemIniFile;
    FConfigIni: TMemIniFile;
    FDonationIni: TMemIniFile;
    FLanguageIni: TMemIniFile;
    
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

constructor TDatabaseManagerIni.Create;
begin
  inherited;
  FDatabasePath := '';
  FIsInitialized := False;
  FBackupIni := nil;
  FOperationIni := nil;
  FConfigIni := nil;
  FDonationIni := nil;
  FLanguageIni := nil;
end;

destructor TDatabaseManagerIni.Destroy;
begin
  Finalize;
  inherited;
end;

// 获取数据库路径
function TDatabaseManagerIni.GetDatabasePath: string;
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
function TDatabaseManagerIni.BackupRecordsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'backup_records.ini');
end;

function TDatabaseManagerIni.OperationLogsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'operation_logs.ini');
end;

function TDatabaseManagerIni.ConfigSettingsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'config_settings.ini');
end;

function TDatabaseManagerIni.DonationAddressesFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'donation_addresses.ini');
end;

function TDatabaseManagerIni.LanguageStringsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'language_strings.ini');
end;

// 初始化文件数据库
function TDatabaseManagerIni.Initialize: Boolean;
begin
  Result := False;
  try
    if FIsInitialized then
      Exit(True);
      
    FDatabasePath := GetDatabasePath;
    
    // 创建数据目录
    if not TDirectory.Exists(FDatabasePath) then
      TDirectory.CreateDirectory(FDatabasePath);
    
    // 初始化INI文件对象
    FBackupIni := TMemIniFile.Create(BackupRecordsFile, TEncoding.UTF8);
    FOperationIni := TMemIniFile.Create(OperationLogsFile, TEncoding.UTF8);
    FConfigIni := TMemIniFile.Create(ConfigSettingsFile, TEncoding.UTF8);
    FDonationIni := TMemIniFile.Create(DonationAddressesFile, TEncoding.UTF8);
    FLanguageIni := TMemIniFile.Create(LanguageStringsFile, TEncoding.UTF8);
    
    // 从文件加载数据
    LoadDataFromFiles;
    
    // 初始化默认数据
    InitializeDefaultData;
    
    FIsInitialized := True;
    Result := True;
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('INI数据库初始化失败: ' + E.Message));
      Finalize;
    end;
  end;
end;

// 从文件加载数据
procedure TDatabaseManagerIni.LoadDataFromFiles;
begin
  try
    // TMemIniFile会自动加载文件内容，无需手动操作
    OutputDebugString(PChar('INI数据文件加载完成'));
  except
    on E: Exception do
      OutputDebugString(PChar('加载INI数据文件失败: ' + E.Message));
  end;
end;

// 保存数据到文件
procedure TDatabaseManagerIni.SaveDataToFiles;
begin
  try
    if Assigned(FBackupIni) then
      FBackupIni.UpdateFile;
      
    if Assigned(FOperationIni) then
      FOperationIni.UpdateFile;
      
    if Assigned(FConfigIni) then
      FConfigIni.UpdateFile;
      
    if Assigned(FDonationIni) then
      FDonationIni.UpdateFile;

    if Assigned(FLanguageIni) then
      FLanguageIni.UpdateFile;
      
  except
    on E: Exception do
      OutputDebugString(PChar('保存INI数据文件失败: ' + E.Message));
  end;
end;

// 初始化默认数据
procedure TDatabaseManagerIni.InitializeDefaultData;
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
function TDatabaseManagerIni.GenerateId: string;
begin
  Result := FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + IntToStr(Random(9999));
end;

// 结束数据库连接
procedure TDatabaseManagerIni.Finalize;
begin
  try
    if FIsInitialized then
      SaveDataToFiles;
  except
    // 忽略保存错误
  end;
  
  if Assigned(FBackupIni) then
  begin
    FBackupIni.Free;
    FBackupIni := nil;
  end;
  
  if Assigned(FOperationIni) then
  begin
    FOperationIni.Free;
    FOperationIni := nil;
  end;
  
  if Assigned(FConfigIni) then
  begin
    FConfigIni.Free;
    FConfigIni := nil;
  end;
  
  if Assigned(FDonationIni) then
  begin
    FDonationIni.Free;
    FDonationIni := nil;
  end;

  if Assigned(FLanguageIni) then
  begin
    FLanguageIni.Free;
    FLanguageIni := nil;
  end;

  FIsInitialized := False;
end;

// 初始化默认语言字符串
procedure TDatabaseManagerIni.InitializeDefaultLanguageStrings;
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
function TDatabaseManagerIni.SetLanguageString(const LanguageCode, StringKey, StringValue: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    FLanguageIni.WriteString(LanguageCode, StringKey, StringValue);
    FLanguageIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('设置语言字符串失败: ' + E.Message));
  end;
end;

// 获取语言字符串
function TDatabaseManagerIni.GetLanguageString(const LanguageCode, StringKey: string; const DefaultValue: string = ''): string;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    Result := FLanguageIni.ReadString(LanguageCode, StringKey, DefaultValue);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('获取语言字符串失败: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

// 获取指定语言的所有字符串
function TDatabaseManagerIni.GetAllLanguageStrings(const LanguageCode: string): TArray<TLanguageStringItem>;
var
  Keys: TStringList;
  StringList: TArray<TLanguageStringItem>;
  StringItem: TLanguageStringItem;
  I: Integer;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  Keys := TStringList.Create;
  try
    FLanguageIni.ReadSection(LanguageCode, Keys);
    SetLength(StringList, Keys.Count);

    for I := 0 to Keys.Count - 1 do
    begin
      StringItem.LanguageCode := LanguageCode;
      StringItem.StringKey := Keys[I];
      StringItem.StringValue := FLanguageIni.ReadString(LanguageCode, Keys[I], '');
      StringItem.CreatedAt := Now;
      StringItem.UpdatedAt := Now;

      StringList[I] := StringItem;
    end;

    Result := StringList;
  finally
    Keys.Free;
  end;
end;

// 删除语言字符串
function TDatabaseManagerIni.DeleteLanguageString(const LanguageCode, StringKey: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    FLanguageIni.DeleteKey(LanguageCode, StringKey);
    FLanguageIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('删除语言字符串失败: ' + E.Message));
  end;
end;

// 设置配置项
function TDatabaseManagerIni.SetConfig(const Category, Key, Value: string;
                                      const ValueType: string = 'string';
                                      const Encrypted: Boolean = False): Boolean;
var
  EncryptedValue: string;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    // 如果需要加密，则加密值
    if Encrypted then
      EncryptedValue := TBasicProtection.EncryptSensitiveData(Value)
    else
      EncryptedValue := Value;

    FConfigIni.WriteString(Category, Key, EncryptedValue);
    FConfigIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('设置配置项失败: ' + E.Message));
  end;
end;

// 获取配置项
function TDatabaseManagerIni.GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    Result := FConfigIni.ReadString(Category, Key, DefaultValue);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('获取配置项失败: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

// 删除配置项
function TDatabaseManagerIni.DeleteConfig(const Category, Key: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    FConfigIni.DeleteKey(Category, Key);
    FConfigIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('删除配置项失败: ' + E.Message));
  end;
end;

// 获取分类下的所有配置项
function TDatabaseManagerIni.GetConfigsByCategory(const Category: string): TArray<TConfigItem>;
var
  Keys: TStringList;
  ConfigList: TArray<TConfigItem>;
  ConfigItem: TConfigItem;
  I: Integer;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  Keys := TStringList.Create;
  try
    FConfigIni.ReadSection(Category, Keys);
    SetLength(ConfigList, Keys.Count);

    for I := 0 to Keys.Count - 1 do
    begin
      ConfigItem.Category := Category;
      ConfigItem.KeyName := Keys[I];
      ConfigItem.ValueData := FConfigIni.ReadString(Category, Keys[I], '');
      ConfigItem.ValueType := 'string';
      ConfigItem.IsEncrypted := False;
      ConfigItem.Description := '';
      ConfigItem.CreatedAt := Now;
      ConfigItem.UpdatedAt := Now;

      ConfigList[I] := ConfigItem;
    end;

    Result := ConfigList;
  finally
    Keys.Free;
  end;
end;

// 简化实现的其他方法（为了演示INI文件的中文支持）
function TDatabaseManagerIni.AddBackupRecord(const BackupInfo: TBackupInfo): Boolean;
begin
  Result := False;
  // 简化实现，主要演示INI文件操作
end;

function TDatabaseManagerIni.GetBackupRecords: TArray<TBackupInfo>;
begin
  SetLength(Result, 0);
  // 简化实现
end;

function TDatabaseManagerIni.GetBackupRecord(const BackupId: string): TBackupInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  // 简化实现
end;

function TDatabaseManagerIni.UpdateBackupRecord(const BackupInfo: TBackupInfo): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.DeleteBackupRecord(const BackupId: string): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.LogOperation(const OpType, Detail, SourcePath, TargetPath, OpResult: string;
                                         const ErrorMsg: string = ''; ExecutionTime: Integer = 0): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.GetOperationLogs(const StartDate, EndDate: TDateTime;
                                             const OpType: string = ''): TArray<TOperationLog>;
begin
  SetLength(Result, 0);
  // 简化实现
end;

function TDatabaseManagerIni.ClearOldLogs(const DaysToKeep: Integer = 30): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.SetDonationAddress(const AddressType, AddressValue, Description: string;
                                               const IsActive: Boolean = True;
                                               const DisplayOrder: Integer = 0): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.GetDonationAddresses(const ActiveOnly: Boolean = True): TArray<TDonationAddress>;
begin
  SetLength(Result, 0);
  // 简化实现
end;

function TDatabaseManagerIni.UpdateDonationAddress(const AddressType, AddressValue, Description: string): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.DeleteDonationAddress(const AddressType: string): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.BackupDatabase(const BackupPath: string): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.RestoreDatabase(const BackupPath: string): Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.VacuumDatabase: Boolean;
begin
  Result := False;
  // 简化实现
end;

function TDatabaseManagerIni.GetDatabaseInfo: TDatabaseInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  // 简化实现
end;

end.
