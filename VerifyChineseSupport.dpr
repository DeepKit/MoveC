program VerifyChineseSupport;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  DatabaseManager,
  LanguageManager,
  LanguageTypes,
  DataTypes;

procedure TestFileEncoding;
var
  JsonText: string;
  JsonObj: TJSONValue;
  AppTitle: string;
begin
  Writeln('1. 测试语言文件编码...');
  
  try
    // 读取中文语言文件
    JsonText := TFile.ReadAllText('Languages\zh-CN.json', TEncoding.UTF8);
    JsonObj := TJSONObject.ParseJSONValue(JsonText);
    
    if Assigned(JsonObj) and (JsonObj is TJSONObject) then
    begin
      AppTitle := (JsonObj as TJSONObject).GetValue('app_title').Value;
      Writeln('   从文件读取的应用标题: ' + AppTitle);
      
      if AppTitle = 'C盘超级清理' then
        Writeln('   ✓ 文件编码测试: 成功')
      else
        Writeln('   ✗ 文件编码测试: 失败 - 内容不匹配');
    end
    else
      Writeln('   ✗ 文件编码测试: 失败 - JSON解析错误');
      
  except
    on E: Exception do
      Writeln('   ✗ 文件编码测试: 失败 - ' + E.Message);
  end;
  
  if Assigned(JsonObj) then
    JsonObj.Free;
end;

procedure TestDatabaseOperations;
var
  DbManager: TDatabaseManager;
  TestString, ReadString: string;
begin
  Writeln('2. 测试数据库中文操作...');
  
  DbManager := TDatabaseManager.Create;
  try
    if DbManager.Initialize then
    begin
      TestString := 'C盘超级清理工具';
      
      // 写入测试
      if DbManager.SetLanguageString('zh-CN', 'verify_test', TestString) then
      begin
        // 读取测试
        ReadString := DbManager.GetLanguageString('zh-CN', 'verify_test');
        
        Writeln('   写入的字符串: ' + TestString);
        Writeln('   读取的字符串: ' + ReadString);
        
        if ReadString = TestString then
          Writeln('   ✓ 数据库中文操作: 成功')
        else
          Writeln('   ✗ 数据库中文操作: 失败 - 读写不一致');
      end
      else
        Writeln('   ✗ 数据库中文操作: 失败 - 无法写入');
    end
    else
      Writeln('   ✗ 数据库中文操作: 失败 - 初始化失败');
  finally
    DbManager.Free;
  end;
end;

procedure TestLanguageManager;
var
  LangMgr: TLanguageManager;
  AppTitle: string;
begin
  Writeln('3. 测试语言管理器...');
  
  LangMgr := TLanguageManager.Create;
  try
    // 加载简体中文
    if LangMgr.LoadLanguage(lcChineseSimplified) then
    begin
      AppTitle := LangMgr.GetString('app_title');
      Writeln('   语言管理器获取的标题: ' + AppTitle);
      
      if AppTitle = 'C盘超级清理' then
        Writeln('   ✓ 语言管理器测试: 成功')
      else
        Writeln('   ✗ 语言管理器测试: 失败 - 内容不匹配');
    end
    else
      Writeln('   ✗ 语言管理器测试: 失败 - 无法加载语言');
  finally
    LangMgr.Free;
  end;
end;

procedure TestCompleteWorkflow;
var
  DbManager: TDatabaseManager;
  LangMgr: TLanguageManager;
  TestStrings: array[0..4] of string;
  I: Integer;
  ReadString: string;
  AllSuccess: Boolean;
begin
  Writeln('4. 测试完整工作流程...');
  
  TestStrings[0] := '文件复制操作';
  TestStrings[1] := '删除并创建链接';
  TestStrings[2] := '备份管理功能';
  TestStrings[3] := '系统检查工具';
  TestStrings[4] := '语言设置界面';
  
  AllSuccess := True;
  
  // 测试数据库存储和读取
  DbManager := TDatabaseManager.Create;
  try
    if DbManager.Initialize then
    begin
      for I := 0 to High(TestStrings) do
      begin
        if DbManager.SetLanguageString('zh-CN', 'test_' + IntToStr(I), TestStrings[I]) then
        begin
          ReadString := DbManager.GetLanguageString('zh-CN', 'test_' + IntToStr(I));
          if ReadString <> TestStrings[I] then
          begin
            AllSuccess := False;
            Writeln('   ✗ 字符串 "' + TestStrings[I] + '" 读写不一致');
          end;
        end
        else
        begin
          AllSuccess := False;
          Writeln('   ✗ 无法写入字符串 "' + TestStrings[I] + '"');
        end;
      end;
      
      if AllSuccess then
        Writeln('   ✓ 完整工作流程测试: 成功')
      else
        Writeln('   ✗ 完整工作流程测试: 失败');
    end
    else
    begin
      Writeln('   ✗ 完整工作流程测试: 失败 - 数据库初始化失败');
    end;
  finally
    DbManager.Free;
  end;
end;

begin
  try
    Writeln('=== 中文支持验证程序 ===');
    Writeln('');
    
    TestFileEncoding;
    Writeln('');
    
    TestDatabaseOperations;
    Writeln('');
    
    TestLanguageManager;
    Writeln('');
    
    TestCompleteWorkflow;
    Writeln('');
    
    Writeln('=== 验证完成 ===');
    Writeln('');
    Writeln('说明:');
    Writeln('- 如果所有测试都显示 ✓ 成功，说明中文编码问题已解决');
    Writeln('- 终端显示的乱码是正常现象，不影响程序功能');
    Writeln('- 实际应用程序会正确显示中文界面');
    
  except
    on E: Exception do
      Writeln('验证过程出错: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('按任意键退出...');
  Readln;
end.
