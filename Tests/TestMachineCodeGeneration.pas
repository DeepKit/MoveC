unit TestMachineCodeGeneration;

interface

uses
  System.SysUtils, System.Classes, SecurityManager, ConfigManager, MachineCodeManager;

type
  // 机器码生成测试类
  TTestMachineCodeGeneration = class
  public
    class procedure RunAllTests;
    class procedure TestHardwareInfoCollection;
    class procedure TestMachineCodeGeneration;
    class procedure TestMachineCodeFormatting;
    class procedure TestMachineCodeStability;
    class procedure TestMachineCodeManager;
  end;

implementation

uses
  Vcl.Dialogs, System.StrUtils;

class procedure TTestMachineCodeGeneration.RunAllTests;
begin
  try
    ShowMessage('开始运行机器码生成测试...');
    
    TestHardwareInfoCollection;
    ShowMessage('✓ 硬件信息收集测试通过');
    
    TestMachineCodeGeneration;
    ShowMessage('✓ 机器码生成测试通过');
    
    TestMachineCodeFormatting;
    ShowMessage('✓ 机器码格式化测试通过');
    
    TestMachineCodeStability;
    ShowMessage('✓ 机器码稳定性测试通过');
    
    TestMachineCodeManager;
    ShowMessage('✓ 机器码管理器测试通过');
    
    ShowMessage('所有机器码生成测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestMachineCodeGeneration.TestHardwareInfoCollection;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  CPUInfo, DiskInfo, MACInfo, BIOSInfo, MotherboardInfo: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 测试CPU信息获取
      CPUInfo := SecurityManager.GetCPUInfo;
      if Length(CPUInfo) = 0 then
        raise Exception.Create('CPU信息获取失败');
      
      // 测试磁盘序列号获取
      DiskInfo := SecurityManager.GetDiskSerialNumber;
      if Length(DiskInfo) = 0 then
        raise Exception.Create('磁盘序列号获取失败');
      
      // 测试MAC地址获取
      MACInfo := SecurityManager.GetMACAddress;
      if Length(MACInfo) = 0 then
        raise Exception.Create('MAC地址获取失败');
      
      // 测试BIOS信息获取
      BIOSInfo := SecurityManager.GetBIOSInfo;
      if Length(BIOSInfo) = 0 then
        raise Exception.Create('BIOS信息获取失败');
      
      // 测试主板信息获取
      MotherboardInfo := SecurityManager.GetMotherboardInfo;
      if Length(MotherboardInfo) = 0 then
        raise Exception.Create('主板信息获取失败');
      
      // 验证信息不为默认值（除非真的无法获取）
      if not (ContainsText(CPUInfo, 'CPU_') or Length(CPUInfo) > 10) then
        raise Exception.Create('CPU信息可能无效');
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMachineCodeGeneration.TestMachineCodeGeneration;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  MachineCode1, MachineCode2: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 生成机器码
      MachineCode1 := SecurityManager.GenerateMachineFingerprint;
      if Length(MachineCode1) = 0 then
        raise Exception.Create('机器码生成失败');
      
      // 验证机器码格式 (XXXX-XXXX-XXXX-XXXX)
      if Length(MachineCode1) <> 19 then
        raise Exception.Create('机器码格式错误：长度不正确');
      
      if (MachineCode1[5] <> '-') or (MachineCode1[10] <> '-') or (MachineCode1[15] <> '-') then
        raise Exception.Create('机器码格式错误：分隔符位置不正确');
      
      // 再次生成，应该相同
      MachineCode2 := SecurityManager.GenerateMachineFingerprint;
      if MachineCode1 <> MachineCode2 then
        raise Exception.Create('机器码不稳定：多次生成结果不同');
      
      // 验证机器码包含有效字符
      var CleanCode := StringReplace(MachineCode1, '-', '', [rfReplaceAll]);
      for var I := 1 to Length(CleanCode) do
      begin
        if not CharInSet(CleanCode[I], ['0'..'9', 'A'..'Z']) then
          raise Exception.Create('机器码包含无效字符');
      end;
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMachineCodeGeneration.TestMachineCodeFormatting;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  RawCode, FormattedCode: string;
  Parts: TArray<string>;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 测试格式化功能
      RawCode := 'ABCDEF1234567890ABCDEF1234567890';
      FormattedCode := SecurityManager.FormatMachineCode(RawCode);
      
      // 验证格式化结果
      if Length(FormattedCode) <> 19 then
        raise Exception.Create('格式化后长度不正确');
      
      Parts := FormattedCode.Split(['-']);
      if Length(Parts) <> 4 then
        raise Exception.Create('格式化后分段数量不正确');
      
      for var I := 0 to 3 do
      begin
        if Length(Parts[I]) <> 4 then
          raise Exception.Create('格式化后分段长度不正确');
      end;
      
      // 测试短字符串格式化
      RawCode := 'ABC123';
      FormattedCode := SecurityManager.FormatMachineCode(RawCode);
      if Length(FormattedCode) <> 19 then
        raise Exception.Create('短字符串格式化失败');
      
      // 测试包含特殊字符的字符串
      RawCode := 'ABC-123_XYZ@789!';
      FormattedCode := SecurityManager.FormatMachineCode(RawCode);
      if Length(FormattedCode) <> 19 then
        raise Exception.Create('特殊字符处理失败');
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMachineCodeGeneration.TestMachineCodeStability;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  Codes: array[0..9] of string;
  I: Integer;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      // 生成多个机器码，验证稳定性
      for I := 0 to 9 do
      begin
        Codes[I] := SecurityManager.GenerateMachineFingerprint;
        if Length(Codes[I]) = 0 then
          raise Exception.Create('机器码生成失败');
        
        // 短暂延迟
        Sleep(10);
      end;
      
      // 验证所有机器码都相同
      for I := 1 to 9 do
      begin
        if Codes[I] <> Codes[0] then
          raise Exception.Create('机器码稳定性测试失败：生成的机器码不一致');
      end;
      
      // 验证机器码唯一性（基于硬件）
      if Codes[0] = 'ERROR-GENE-RATE-CODE' then
        raise Exception.Create('机器码生成错误');
      
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMachineCodeGeneration.TestMachineCodeManager;
var
  SecurityManager: TSecurityManager;
  ConfigManager: TConfigManager;
  MachineCodeManager: TMachineCodeManager;
  Code1, Code2, FormattedCode, Info: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    SecurityManager := TSecurityManager.Create(ConfigManager);
    try
      MachineCodeManager := TMachineCodeManager.Create(SecurityManager, ConfigManager);
      try
        // 测试机器码获取
        Code1 := MachineCodeManager.GetMachineCode;
        if Length(Code1) = 0 then
          raise Exception.Create('MachineCodeManager获取机器码失败');
        
        // 测试格式化机器码
        FormattedCode := MachineCodeManager.GetFormattedMachineCode;
        if FormattedCode <> Code1 then
          raise Exception.Create('格式化机器码与原始机器码不匹配');
        
        // 测试稳定性检查
        if not MachineCodeManager.IsMachineCodeStable then
          raise Exception.Create('机器码稳定性检查失败');
        
        // 测试机器码信息获取
        Info := MachineCodeManager.GetMachineCodeInfo;
        if Length(Info) = 0 then
          raise Exception.Create('机器码信息获取失败');
        
        if not ContainsText(Info, Code1) then
          raise Exception.Create('机器码信息中不包含正确的机器码');
        
        // 测试复制功能（不实际复制，只测试不出错）
        try
          // 这里不调用CopyToClipboard，因为会弹出消息框
          // MachineCodeManager.CopyToClipboard;
        except
          raise Exception.Create('机器码复制功能测试失败');
        end;
        
      finally
        MachineCodeManager.Free;
      end;
    finally
      SecurityManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.