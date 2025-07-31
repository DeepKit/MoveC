unit TestIntegrityVerification;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, SecurityManager, ConfigManager, BasicProtection;

type
  // 完整性验证测试类
  TTestIntegrityVerification = class
  public
    class procedure RunAllTests;
    class procedure TestExecutableIntegrityCheck;
    class procedure TestConfigurationIntegrityCheck;
    class procedure TestFileIntegrityValidation;
    class procedure TestTamperingDetection;
    class procedure TestSelfCheckMechanism;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestIntegrityVerification.RunAllTests;
begin
  try
    ShowMessage('开始运行完整性验证测试...');
    
    TestExecutableIntegrityCheck;
    ShowMessage('✓ 可执行文件完整性检查测试通过');
    
    TestConfigurationIntegrityCheck;
    ShowMessage('✓ 配置完整性检查测试通过');
    
    TestFileIntegrityValidation;
    ShowMessage('✓ 文件完整性验证测试通过');
    
    TestTamperingDetection;
    ShowMessage('✓ 篡改检测测试通过');
    
    TestSelfCheckMechanism;
    ShowMessage('✓ 自检机制测试通过');
    
    ShowMessage('所有完整性验证测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestIntegrityVerification.TestExecutableIntegrityCheck;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  OriginalHash, CurrentHash: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 测试主程序文件哈希计算
      if not FileExists(Application.ExeName) then
        raise Exception.Create('主程序文件不存在');
      
      OriginalHash := TBasicProtection.CalculateFileHash(Application.ExeName);
      if Length(OriginalHash) = 0 then
        raise Exception.Create('无法计算主程序文件哈希');
      
      // 再次计算，应该相同
      CurrentHash := TBasicProtection.CalculateFileHash(Application.ExeName);
      if OriginalHash <> CurrentHash then
        raise Exception.Create('主程序文件哈希不一致');
      
      // 测试文件完整性验证
      if not SecurityManager.ValidateFileIntegrity(Application.ExeName) then
        raise Exception.Create('主程序文件完整性验证失败');
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestIntegrityVerification.TestConfigurationIntegrityCheck;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  TestConfigFile: string;
  ConfigData, HMAC1, HMAC2: string;
begin
  TestConfigFile := 'test_config.ini';
  
  try
    ConfigManager := TConfigManager.Create(TestConfigFile);
    try
      SecurityManager := TSecurityManager.Create(ConfigManager);
      try
        // 设置一些测试配置
        ConfigManager.SetString('Application', 'Language', 'zh-CN');
        ConfigManager.SetInteger('Application', 'SecurityLevel', 2);
        ConfigManager.SetBoolean('Security', 'EnableIntegrityCheck', True);
        ConfigManager.SaveConfig;
        
        // 计算配置数据HMAC
        ConfigData := 'zh-CN|2||True|True|256|True|True|True';
        HMAC1 := TBasicProtection.CalculateHMAC(ConfigData);
        if Length(HMAC1) = 0 then
          raise Exception.Create('配置HMAC计算失败');
        
        // 验证HMAC一致性
        HMAC2 := TBasicProtection.CalculateHMAC(ConfigData);
        if HMAC1 <> HMAC2 then
          raise Exception.Create('配置HMAC不一致');
        
        // 测试完整性验证
        if not TBasicProtection.VerifyDataIntegrity(ConfigData, HMAC1) then
          raise Exception.Create('配置数据完整性验证失败');
        
      finally
        SecurityManager.Free;
      end;
    finally
      ConfigManager.Free;
    end;
  finally
    // 清理测试文件
    if FileExists(TestConfigFile) then
      DeleteFile(TestConfigFile);
  end;
end;

class procedure TTestIntegrityVerification.TestFileIntegrityValidation;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  TestFile: string;
  FileStream: TFileStream;
  TestData: TBytes;
begin
  TestFile := 'test_integrity_file.tmp';
  ConfigManager := TConfigManager.Create;
  
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 创建测试文件
      FileStream := TFileStream.Create(TestFile, fmCreate);
      try
        TestData := TEncoding.UTF8.GetBytes('测试文件完整性验证内容');
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
      
      // 首次验证（应该成功并保存哈希）
      if not SecurityManager.ValidateFileIntegrity(TestFile) then
        raise Exception.Create('首次文件完整性验证失败');
      
      // 再次验证（应该成功）
      if not SecurityManager.ValidateFileIntegrity(TestFile) then
        raise Exception.Create('第二次文件完整性验证失败');
      
      // 修改文件内容
      FileStream := TFileStream.Create(TestFile, fmOpenWrite);
      try
        TestData := TEncoding.UTF8.GetBytes('修改后的文件内容');
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
      
      // 验证应该失败（检测到文件被修改）
      if SecurityManager.ValidateFileIntegrity(TestFile) then
        raise Exception.Create('文件修改检测失败：应该检测到文件被篡改');
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
    // 清理测试文件
    if FileExists(TestFile) then
      DeleteFile(TestFile);
  end;
end;

class procedure TTestIntegrityVerification.TestTamperingDetection;
var
  OriginalData, TamperedData, HMAC: string;
begin
  OriginalData := '重要的系统配置数据';
  TamperedData := '被篡改的系统配置数据';
  
  // 计算原始数据的HMAC
  HMAC := TBasicProtection.CalculateHMAC(OriginalData);
  
  // 验证原始数据（应该成功）
  if not TBasicProtection.VerifyDataIntegrity(OriginalData, HMAC) then
    raise Exception.Create('原始数据完整性验证失败');
  
  // 验证篡改数据（应该失败）
  if TBasicProtection.VerifyDataIntegrity(TamperedData, HMAC) then
    raise Exception.Create('篡改检测失败：应该检测到数据被修改');
  
  // 测试空数据
  if TBasicProtection.VerifyDataIntegrity('', HMAC) then
    raise Exception.Create('空数据篡改检测失败');
  
  // 测试HMAC篡改
  if TBasicProtection.VerifyDataIntegrity(OriginalData, HMAC + 'X') then
    raise Exception.Create('HMAC篡改检测失败');
end;

class procedure TTestIntegrityVerification.TestSelfCheckMechanism;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  SelfCheckResult: Boolean;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 执行自检
      SelfCheckResult := SecurityManager.PerformSelfCheck;
      
      // 在开发模式下，自检应该总是成功
      if not SelfCheckResult then
        raise Exception.Create('自检机制失败');
      
      // 测试机器指纹生成
      var MachineFingerprint := SecurityManager.GenerateMachineFingerprint;
      if Length(MachineFingerprint) = 0 then
        raise Exception.Create('机器指纹生成失败');
      
      // 再次生成，应该相同
      var MachineFingerprint2 := SecurityManager.GenerateMachineFingerprint;
      if MachineFingerprint <> MachineFingerprint2 then
        raise Exception.Create('机器指纹不一致');
      
      // 测试管理员权限检查
      var IsAdmin := SecurityManager.IsRunningAsAdmin;
      // 这里不验证具体结果，只确保函数能正常执行
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.