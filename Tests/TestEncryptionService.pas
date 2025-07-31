unit TestEncryptionService;

interface

uses
  System.SysUtils, System.Classes, BasicProtection, SecurityManager, ConfigManager;

type
  // 加密服务测试类
  TTestEncryptionService = class
  public
    class procedure RunAllTests;
    class procedure TestAESEncryption;
    class procedure TestHMACVerification;
    class procedure TestFileHashCalculation;
    class procedure TestSecurityManagerIntegration;
    class procedure TestDynamicKeyGeneration;
  end;

implementation

uses
  Vcl.Dialogs;

class procedure TTestEncryptionService.RunAllTests;
begin
  try
    ShowMessage('开始运行加密服务测试...');
    
    TestAESEncryption;
    ShowMessage('✓ AES加密测试通过');
    
    TestHMACVerification;
    ShowMessage('✓ HMAC验证测试通过');
    
    TestFileHashCalculation;
    ShowMessage('✓ 文件哈希计算测试通过');
    
    TestSecurityManagerIntegration;
    ShowMessage('✓ 安全管理器集成测试通过');
    
    TestDynamicKeyGeneration;
    ShowMessage('✓ 动态密钥生成测试通过');
    
    ShowMessage('所有加密服务测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestEncryptionService.TestAESEncryption;
var
  OriginalData, EncryptedData, DecryptedData: string;
begin
  // 测试字符串加密解密
  OriginalData := 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
  
  // 加密
  EncryptedData := TBasicProtection.EncryptSensitiveData(OriginalData);
  if EncryptedData = OriginalData then
    raise Exception.Create('加密失败：加密后数据与原数据相同');
  
  if Length(EncryptedData) = 0 then
    raise Exception.Create('加密失败：加密后数据为空');
  
  // 解密
  DecryptedData := TBasicProtection.DecryptSensitiveData(EncryptedData);
  if DecryptedData <> OriginalData then
    raise Exception.Create('解密失败：解密后数据与原数据不匹配');
  
  // 测试空字符串
  OriginalData := '';
  EncryptedData := TBasicProtection.EncryptSensitiveData(OriginalData);
  DecryptedData := TBasicProtection.DecryptSensitiveData(EncryptedData);
  if DecryptedData <> OriginalData then
    raise Exception.Create('空字符串加密解密失败');
  
  // 测试长字符串
  OriginalData := StringOfChar('A', 1000);
  EncryptedData := TBasicProtection.EncryptSensitiveData(OriginalData);
  DecryptedData := TBasicProtection.DecryptSensitiveData(EncryptedData);
  if DecryptedData <> OriginalData then
    raise Exception.Create('长字符串加密解密失败');
end;

class procedure TTestEncryptionService.TestHMACVerification;
var
  TestData, HMAC1, HMAC2: string;
begin
  TestData := '这是测试数据';
  
  // 计算HMAC
  HMAC1 := TBasicProtection.CalculateHMAC(TestData);
  if Length(HMAC1) = 0 then
    raise Exception.Create('HMAC计算失败：结果为空');
  
  // 验证相同数据的HMAC应该相同
  HMAC2 := TBasicProtection.CalculateHMAC(TestData);
  if HMAC1 <> HMAC2 then
    raise Exception.Create('HMAC一致性测试失败');
  
  // 验证数据完整性
  if not TBasicProtection.VerifyDataIntegrity(TestData, HMAC1) then
    raise Exception.Create('数据完整性验证失败');
  
  // 测试篡改检测
  if TBasicProtection.VerifyDataIntegrity(TestData + 'X', HMAC1) then
    raise Exception.Create('篡改检测失败：应该检测到数据被修改');
end;

class procedure TTestEncryptionService.TestFileHashCalculation;
var
  TestFile: string;
  Hash1, Hash2: string;
  FileStream: TFileStream;
begin
  TestFile := 'test_hash_file.tmp';
  
  try
    // 创建测试文件
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试文件内容');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    // 计算文件哈希
    Hash1 := TBasicProtection.CalculateFileHash(TestFile);
    if Length(Hash1) = 0 then
      raise Exception.Create('文件哈希计算失败');
    
    // 再次计算，应该相同
    Hash2 := TBasicProtection.CalculateFileHash(TestFile);
    if Hash1 <> Hash2 then
      raise Exception.Create('文件哈希一致性测试失败');
    
    // 修改文件内容
    FileStream := TFileStream.Create(TestFile, fmOpenWrite);
    try
      var ModifiedData := TEncoding.UTF8.GetBytes('修改后的文件内容');
      FileStream.WriteBuffer(ModifiedData[0], Length(ModifiedData));
    finally
      FileStream.Free;
    end;
    
    // 哈希应该不同
    Hash2 := TBasicProtection.CalculateFileHash(TestFile);
    if Hash1 = Hash2 then
      raise Exception.Create('文件修改检测失败：哈希值应该不同');
    
  finally
    // 清理测试文件
    if FileExists(TestFile) then
      DeleteFile(TestFile);
  end;
end;

class procedure TTestEncryptionService.TestSecurityManagerIntegration;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  OriginalData, EncryptedData, DecryptedData: string;
  MachineFingerprint: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 测试加密解密
      OriginalData := '敏感数据测试';
      EncryptedData := SecurityManager.EncryptSensitiveData(OriginalData);
      DecryptedData := SecurityManager.DecryptSensitiveData(EncryptedData);
      
      if DecryptedData <> OriginalData then
        raise Exception.Create('SecurityManager加密解密测试失败');
      
      // 测试机器指纹生成
      MachineFingerprint := SecurityManager.GenerateMachineFingerprint;
      if Length(MachineFingerprint) = 0 then
        raise Exception.Create('机器指纹生成失败');
      
      // 测试自检功能
      if not SecurityManager.PerformSelfCheck then
        raise Exception.Create('安全自检失败');
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestEncryptionService.TestDynamicKeyGeneration;
var
  I: Integer;
  Keys: array[0..9] of string;
  TestData, EncryptedData, DecryptedData: string;
begin
  TestData := '动态密钥测试数据';
  
  // 生成多个加密结果，验证每次都不同（因为IV随机）
  for I := 0 to 9 do
  begin
    Keys[I] := TBasicProtection.EncryptSensitiveData(TestData);
    
    // 验证可以正确解密
    DecryptedData := TBasicProtection.DecryptSensitiveData(Keys[I]);
    if DecryptedData <> TestData then
      raise Exception.Create('动态密钥解密失败');
  end;
  
  // 验证每次加密结果都不同（因为IV随机）
  for I := 0 to 8 do
  begin
    if Keys[I] = Keys[I + 1] then
      raise Exception.Create('动态密钥测试失败：加密结果不应该相同');
  end;
end;

end.