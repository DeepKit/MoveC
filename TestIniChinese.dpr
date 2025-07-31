program TestIniChinese;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.IniFiles,
  DatabaseManagerIni,
  DataTypes;

procedure TestDirectIniFile;
var
  IniFile: TMemIniFile;
  TestValue, ReadValue: string;
  IniPath: string;
begin
  Writeln('=== 测试直接使用TMemIniFile处理中文 ===');
  
  IniPath := 'test_chinese.ini';
  
  // 删除旧文件
  if TFile.Exists(IniPath) then
    TFile.Delete(IniPath);
  
  IniFile := TMemIniFile.Create(IniPath, TEncoding.UTF8);
  try
    // 测试中文写入
    TestValue := 'C盘超级清理工具';
    IniFile.WriteString('Chinese', 'app_title', TestValue);
    IniFile.WriteString('Chinese', 'description', '这是一个用于清理C盘的工具程序');
    IniFile.WriteString('Chinese', 'author', '开发者：张三');
    
    // 保存文件
    IniFile.UpdateFile;
    
    Writeln('已写入中文内容到INI文件');
    
    // 读取测试
    ReadValue := IniFile.ReadString('Chinese', 'app_title', '');
    Writeln('写入的值: ' + TestValue);
    Writeln('读取的值: ' + ReadValue);
    
    if ReadValue = TestValue then
      Writeln('✓ 直接INI文件中文测试: 成功')
    else
      Writeln('✗ 直接INI文件中文测试: 失败');
      
  finally
    IniFile.Free;
  end;
  
  Writeln('');
end;

procedure TestDatabaseManagerIni;
var
  DbManager: TDatabaseManagerIni;
  TestString, ReadString: string;
  AllStrings: TArray<TLanguageStringItem>;
  I: Integer;
begin
  Writeln('=== 测试DatabaseManagerIni中文支持 ===');
  
  DbManager := TDatabaseManagerIni.Create;
  try
    if DbManager.Initialize then
    begin
      Writeln('数据库管理器初始化成功');
      
      // 测试中文字符串设置和读取
      TestString := 'C盘超级清理工具';
      
      if DbManager.SetLanguageString('zh-CN', 'test_app_title', TestString) then
      begin
        ReadString := DbManager.GetLanguageString('zh-CN', 'test_app_title');
        
        Writeln('写入的字符串: ' + TestString);
        Writeln('读取的字符串: ' + ReadString);
        
        if ReadString = TestString then
          Writeln('✓ DatabaseManagerIni中文测试: 成功')
        else
          Writeln('✗ DatabaseManagerIni中文测试: 失败 - 读写不一致');
      end
      else
        Writeln('✗ DatabaseManagerIni中文测试: 失败 - 无法写入');
      
      // 测试获取所有中文字符串
      Writeln('');
      Writeln('获取所有zh-CN语言字符串:');
      AllStrings := DbManager.GetAllLanguageStrings('zh-CN');
      
      for I := 0 to High(AllStrings) do
      begin
        Writeln(Format('  %s = %s', [AllStrings[I].StringKey, AllStrings[I].StringValue]));
        if I >= 4 then  // 只显示前5个
        begin
          Writeln('  ... (还有更多)');
          Break;
        end;
      end;
      
      Writeln(Format('总共找到 %d 个中文字符串', [Length(AllStrings)]));
      
    end
    else
      Writeln('✗ 数据库管理器初始化失败');
  finally
    DbManager.Free;
  end;
  
  Writeln('');
end;

procedure TestConfigWithChinese;
var
  DbManager: TDatabaseManagerIni;
  TestConfig, ReadConfig: string;
begin
  Writeln('=== 测试配置项中文支持 ===');
  
  DbManager := TDatabaseManagerIni.Create;
  try
    if DbManager.Initialize then
    begin
      // 测试中文配置项
      TestConfig := '默认清理目录';
      
      if DbManager.SetConfig('用户设置', '清理目录', TestConfig) then
      begin
        ReadConfig := DbManager.GetConfig('用户设置', '清理目录');
        
        Writeln('写入的配置: ' + TestConfig);
        Writeln('读取的配置: ' + ReadConfig);
        
        if ReadConfig = TestConfig then
          Writeln('✓ 配置项中文测试: 成功')
        else
          Writeln('✗ 配置项中文测试: 失败');
      end
      else
        Writeln('✗ 配置项中文测试: 失败 - 无法写入');
    end;
  finally
    DbManager.Free;
  end;
  
  Writeln('');
end;

procedure CheckGeneratedFiles;
var
  IniFiles: TArray<string>;
  I: Integer;
  IniContent: string;
begin
  Writeln('=== 检查生成的INI文件 ===');
  
  IniFiles := TArray<string>.Create(
    'test_chinese.ini',
    TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup'), 'language_strings.ini'),
    TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup'), 'config_settings.ini')
  );
  
  for I := 0 to High(IniFiles) do
  begin
    if TFile.Exists(IniFiles[I]) then
    begin
      Writeln('文件: ' + IniFiles[I]);
      try
        IniContent := TFile.ReadAllText(IniFiles[I], TEncoding.UTF8);
        if IniContent.Contains('C盘') or IniContent.Contains('清理') then
          Writeln('  ✓ 包含中文内容')
        else
          Writeln('  - 未检测到中文内容');
      except
        on E: Exception do
          Writeln('  ✗ 读取失败: ' + E.Message);
      end;
    end
    else
      Writeln('文件不存在: ' + IniFiles[I]);
  end;
end;

begin
  try
    Writeln('INI文件中文编码测试程序');
    Writeln('================================');
    Writeln('');
    
    // 测试1: 直接使用TMemIniFile
    TestDirectIniFile;
    
    // 测试2: 使用DatabaseManagerIni
    TestDatabaseManagerIni;
    
    // 测试3: 配置项中文支持
    TestConfigWithChinese;
    
    // 检查生成的文件
    CheckGeneratedFiles;
    
    Writeln('================================');
    Writeln('测试完成！');
    Writeln('');
    Writeln('如果所有测试都显示 ✓ 成功，说明INI文件可以正确处理中文。');
    
  except
    on E: Exception do
      Writeln('测试过程出错: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('按任意键退出...');
  Readln;
end.
