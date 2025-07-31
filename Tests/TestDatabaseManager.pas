unit TestDatabaseManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DatabaseManager, DataTypes;

type
  // 数据库管理器测试类
  TTestDatabaseManager = class
  public
    class procedure RunAllTests;
    class procedure TestDatabaseInitialization;
    class procedure TestBackupRecordManagement;
    class procedure TestOperationLogging;
    class procedure TestConfigurationManagement;
    class procedure TestDonationAddressManagement;
    class procedure TestLanguageStringManagement;
    class procedure TestDatabaseMaintenance;
  end;

implementation

uses
  Vcl.Dialogs, System.DateUtils;

class procedure TTestDatabaseManager.RunAllTests;
begin
  try
    ShowMessage('开始运行数据库管理器测试...');
    
    TestDatabaseInitialization;
    ShowMessage('✓ 数据库初始化测试通过');
    
    TestBackupRecordManagement;
    ShowMessage('✓ 备份记录管理测试通过');
    
    TestOperationLogging;
    ShowMessage('✓ 操作日志测试通过');
    
    TestConfigurationManagement;
    ShowMessage('✓ 配置管理测试通过');
    
    TestDonationAddressManagement;
    ShowMessage('✓ 打赏地址管理测试通过');
    
    TestLanguageStringManagement;
    ShowMessage('✓ 语言字符串管理测试通过');
    
    TestDatabaseMaintenance;
    ShowMessage('✓ 数据库维护测试通过');
    
    ShowMessage('所有数据库管理器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestDatabaseManager.TestDatabaseInitialization;
var
  DatabaseManager: TDatabaseManager;
  DatabaseInfo: TDatabaseInfo;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    // 测试初始化
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    if not DatabaseManager.IsInitialized then
      raise Exception.Create('数据库初始化状态错误');
    
    // 测试数据库路径
    if not TDirectory.Exists(DatabaseManager.DatabasePath) then
      raise Exception.Create('数据库目录不存在');
    
    // 测试数据库信息获取
    DatabaseInfo := DatabaseManager.GetDatabaseInfo;
    if DatabaseInfo.DatabasePath = '' then
      raise Exception.Create('数据库信息获取失败');
    
    // 测试重复初始化
    if not DatabaseManager.Initialize then
      raise Exception.Create('重复初始化失败');
    
  finally
    DatabaseManager.Free;
  end;
end;

class procedure TTestDatabaseManager.TestBackupRecordManagement;
var
  DatabaseManager: TDatabaseManager;
  BackupInfo, RetrievedInfo: TBackupInfo;
  BackupRecords: TArray<TBackupInfo>;
  BackupId: string;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    // 创建测试备份记录
    BackupId := 'TEST_BACKUP_' + FormatDateTime('yyyymmddhhnnss', Now);
    BackupInfo.BackupId := BackupId;
    BackupInfo.SourcePath := 'C:\TestSource';
    BackupInfo.TargetPath := 'D:\TestTarget';
    BackupInfo.BackupTime := Now;
    BackupInfo.BackupSize := 1024 * 1024; // 1MB
    BackupInfo.FileCount := 100;
    BackupInfo.Status := 'COMPLETED';
    BackupInfo.Description := '测试备份记录';
    
    // 测试添加备份记录
    if not DatabaseManager.AddBackupRecord(BackupInfo) then
      raise Exception.Create('添加备份记录失败');
    
    // 测试获取单个备份记录
    RetrievedInfo := DatabaseManager.GetBackupRecord(BackupId);
    if RetrievedInfo.BackupId <> BackupId then
      raise Exception.Create('获取备份记录失败');
    
    if RetrievedInfo.SourcePath <> BackupInfo.SourcePath then
      raise Exception.Create('备份记录数据不匹配');
    
    // 测试获取所有备份记录
    BackupRecords := DatabaseManager.GetBackupRecords;
    if Length(BackupRecords) = 0 then
      raise Exception.Create('获取备份记录列表失败');
    
    // 测试更新备份记录
    BackupInfo.Status := 'UPDATED';
    BackupInfo.Description := '更新后的测试备份记录';
    if not DatabaseManager.UpdateBackupRecord(BackupInfo) then
      raise Exception.Create('更新备份记录失败');
    
    // 验证更新
    RetrievedInfo := DatabaseManager.GetBackupRecord(BackupId);
    if RetrievedInfo.Status <> 'UPDATED' then
      raise Exception.Create('备份记录更新验证失败');
    
    // 测试删除备份记录
    if not DatabaseManager.DeleteBackupRecord(BackupId) then
      raise Exception.Create('删除备份记录失败');
    
    // 验证删除
    RetrievedInfo := DatabaseManager.GetBackupRecord(BackupId);
    if RetrievedInfo.BackupId = BackupId then
      raise Exception.Create('备份记录删除验证失败');
    
  finally
    DatabaseManager.Free;
  end;
end;

class procedure TTestDatabaseManager.TestOperationLogging;
var
  DatabaseManager: TDatabaseManager;
  OperationLogs: TArray<TOperationLog>;
  StartDate, EndDate: TDateTime;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    // 测试记录操作日志
    if not DatabaseManager.LogOperation('TEST', '测试操作', 'C:\Test', 'D:\Test', 'SUCCESS') then
      raise Exception.Create('记录操作日志失败');
    
    if not DatabaseManager.LogOperation('ERROR', '错误测试', 'C:\Error', '', 'FAILED', '测试错误消息', 1000) then
      raise Exception.Create('记录错误日志失败');
    
    // 测试获取操作日志
    StartDate := Now - 1; // 昨天
    EndDate := Now + 1;   // 明天
    OperationLogs := DatabaseManager.GetOperationLogs(StartDate, EndDate);
    
    if Length(OperationLogs) < 2 then
      raise Exception.Create('获取操作日志失败');
    
    // 测试按类型过滤日志
    OperationLogs := DatabaseManager.GetOperationLogs(StartDate, EndDate, 'TEST');
    if Length(OperationLogs) = 0 then
      raise Exception.Create('按类型过滤日志失败');
    
    // 验证日志内容
    var Found := False;
    for var Log in OperationLogs do
    begin
      if (Log.OperationType = 'TEST') and (Log.OperationDetail = '测试操作') then
      begin
        Found := True;
        Break;
      end;
    end;
    
    if not Found then
      raise Exception.Create('日志内容验证失败');
    
    // 测试清理旧日志（不实际清理，只测试功能）
    if not DatabaseManager.ClearOldLogs(365) then
      raise Exception.Create('清理旧日志功能测试失败');
    
  finally
    DatabaseManager.Free;
  end;
end;

class procedure TTestDatabaseManager.TestConfigurationManagement;
var
  DatabaseManager: TDatabaseManager;
  ConfigItems: TArray<TConfigItem>;
  Value: string;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    // 测试设置配置项
    if not DatabaseManager.SetConfig('test', 'string_value', '测试字符串') then
      raise Exception.Create('设置字符串配置失败');
    
    if not DatabaseManager.SetConfig('test', 'number_value', '12345', 'number') then
      raise Exception.Create('设置数字配置失败');
    
    if not DatabaseManager.SetConfig('test', 'encrypted_value', '敏感数据', 'string', True) then
      raise Exception.Create('设置加密配置失败');
    
    // 测试获取配置项
    Value := DatabaseManager.GetConfig('test', 'string_value');
    if Value <> '测试字符串' then
      raise Exception.Create('获取字符串配置失败');
    
    Value := DatabaseManager.GetConfig('test', 'number_value');
    if Value <> '12345' then
      raise Exception.Create('获取数字配置失败');
    
    Value := DatabaseManager.GetConfig('test', 'nonexistent', 'default');
    if Value <> 'default' then
      raise Exception.Create('获取不存在配置的默认值失败');
    
    // 测试获取分类下的所有配置
    ConfigItems := DatabaseManager.GetConfigsByCategory('test');
    if Length(ConfigItems) < 3 then
      raise Exception.Create('获取配置分类失败');
    
    // 测试删除配置项
    if not DatabaseManager.DeleteConfig('test', 'string_value') then
      raise Exception.Create('删除配置项失败');
    
    // 验证删除
    Value := DatabaseManager.GetConfig('test', 'string_value', 'deleted');
    if Value <> 'deleted' then
      raise Exception.Create('配置项删除验证失败');
    
  finally
    DatabaseManager.Free;
  end;
end;

class procedure TTestDatabaseManager.TestDonationAddressManagement;
var
  DatabaseManager: TDatabaseManager;
  DonationAddresses: TArray<TDonationAddress>;
  Found: Boolean;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    // 测试设置打赏地址
    if not DatabaseManager.SetDonationAddress('TEST_BTC', 'test_btc_address_12345', '测试BTC地址', True, 1) then
      raise Exception.Create('设置BTC打赏地址失败');
    
    if not DatabaseManager.SetDonationAddress('TEST_ETH', 'test_eth_address_67890', '测试ETH地址', False, 2) then
      raise Exception.Create('设置ETH打赏地址失败');
    
    // 测试获取活跃地址
    DonationAddresses := DatabaseManager.GetDonationAddresses(True);
    Found := False;
    for var Address in DonationAddresses do
    begin
      if (Address.AddressType = 'TEST_BTC') and (Address.AddressValue = 'test_btc_address_12345') then
      begin
        Found := True;
        if not Address.IsActive then
          raise Exception.Create('打赏地址状态错误');
        Break;
      end;
    end;
    
    if not Found then
      raise Exception.Create('获取活跃打赏地址失败');
    
    // 测试获取所有地址（包括非活跃）
    DonationAddresses := DatabaseManager.GetDonationAddresses(False);
    Found := False;
    for var Address in DonationAddresses do
    begin
      if Address.AddressType = 'TEST_ETH' then
      begin
        Found := True;
        Break;
      end;
    end;
    
    if not Found then
      raise Exception.Create('获取所有打赏地址失败');
    
    // 测试更新打赏地址
    if not DatabaseManager.UpdateDonationAddress('TEST_BTC', 'updated_btc_address', '更新的BTC地址') then
      raise Exception.Create('更新打赏地址失败');
    
    // 测试删除打赏地址
    if not DatabaseManager.DeleteDonationAddress('TEST_BTC') then
      raise Exception.Create('删除打赏地址失败');
    
    if not DatabaseManager.DeleteDonationAddress('TEST_ETH') then
      raise Exception.Create('删除打赏地址失败');
    
  finally
    DatabaseManager.Free;
  end;
end;

class procedure TTestDatabaseManager.TestLanguageStringManagement;
var
  DatabaseManager: TDatabaseManager;
  LanguageStrings: TArray<TLanguageStringItem>;
  Value: string;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    // 测试设置语言字符串
    if not DatabaseManager.SetLanguageString('test-lang', 'hello', '你好') then
      raise Exception.Create('设置语言字符串失败');
    
    if not DatabaseManager.SetLanguageString('test-lang', 'goodbye', '再见') then
      raise Exception.Create('设置语言字符串失败');
    
    if not DatabaseManager.SetLanguageString('en-US', 'hello', 'Hello') then
      raise Exception.Create('设置英文字符串失败');
    
    // 测试获取语言字符串
    Value := DatabaseManager.GetLanguageString('test-lang', 'hello');
    if Value <> '你好' then
      raise Exception.Create('获取语言字符串失败');
    
    Value := DatabaseManager.GetLanguageString('test-lang', 'nonexistent', 'default');
    if Value <> 'default' then
      raise Exception.Create('获取不存在字符串的默认值失败');
    
    // 测试获取所有语言字符串
    LanguageStrings := DatabaseManager.GetAllLanguageStrings('test-lang');
    if Length(LanguageStrings) < 2 then
      raise Exception.Create('获取所有语言字符串失败');
    
    // 验证字符串内容
    var Found := False;
    for var Item in LanguageStrings do
    begin
      if (Item.StringKey = 'hello') and (Item.StringValue = '你好') then
      begin
        Found := True;
        Break;
      end;
    end;
    
    if not Found then
      raise Exception.Create('语言字符串内容验证失败');
    
    // 测试删除语言字符串
    if not DatabaseManager.DeleteLanguageString('test-lang', 'hello') then
      raise Exception.Create('删除语言字符串失败');
    
    // 验证删除
    Value := DatabaseManager.GetLanguageString('test-lang', 'hello', 'deleted');
    if Value <> 'deleted' then
      raise Exception.Create('语言字符串删除验证失败');
    
    // 清理测试数据
    DatabaseManager.DeleteLanguageString('test-lang', 'goodbye');
    DatabaseManager.DeleteLanguageString('en-US', 'hello');
    
  finally
    DatabaseManager.Free;
  end;
end;

class procedure TTestDatabaseManager.TestDatabaseMaintenance;
var
  DatabaseManager: TDatabaseManager;
  BackupPath: string;
  DatabaseInfo: TDatabaseInfo;
begin
  DatabaseManager := TDatabaseManager.Create;
  try
    if not DatabaseManager.Initialize then
      raise Exception.Create('数据库初始化失败');
    
    // 添加一些测试数据
    DatabaseManager.LogOperation('MAINTENANCE_TEST', '维护测试', '', '', 'SUCCESS');
    DatabaseManager.SetConfig('maintenance', 'test', 'value');
    
    // 测试数据库信息获取
    DatabaseInfo := DatabaseManager.GetDatabaseInfo;
    if DatabaseInfo.DatabasePath = '' then
      raise Exception.Create('获取数据库信息失败');
    
    if DatabaseInfo.LogRecordCount < 0 then
      raise Exception.Create('数据库信息统计错误');
    
    // 测试数据库压缩
    if not DatabaseManager.VacuumDatabase then
      raise Exception.Create('数据库压缩失败');
    
    // 测试数据库备份
    BackupPath := TPath.Combine(TPath.GetTempPath, 'test_db_backup_' + FormatDateTime('yyyymmddhhnnss', Now));
    try
      if not DatabaseManager.BackupDatabase(BackupPath) then
        raise Exception.Create('数据库备份失败');
      
      if not TDirectory.Exists(BackupPath) then
        raise Exception.Create('备份目录不存在');
      
      // 测试数据库恢复（注意：这会重置当前数据库）
      // 为了测试安全，我们不实际执行恢复操作
      // if not DatabaseManager.RestoreDatabase(BackupPath) then
      //   raise Exception.Create('数据库恢复失败');
      
    finally
      // 清理备份文件
      if TDirectory.Exists(BackupPath) then
        TDirectory.Delete(BackupPath, True);
    end;
    
  finally
    DatabaseManager.Free;
  end;
end;

end.