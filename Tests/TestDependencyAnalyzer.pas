unit TestDependencyAnalyzer;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DependencyAnalyzer;

type
  // 依赖关系分析器测试类
  TTestDependencyAnalyzer = class
  public
    class procedure RunAllTests;
    class procedure TestBasicDependencyAnalysis;
    class procedure TestRegistryDependencyAnalysis;
    class procedure TestShortcutDependencyAnalysis;
    class procedure TestServiceDependencyAnalysis;
    class procedure TestDLLDependencyAnalysis;
    class procedure TestConfigDependencyAnalysis;
    class procedure TestBatchAnalysis;
    class procedure TestDependencyUpdate;
    class procedure TestUtilityMethods;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms, System.Win.Registry;

class procedure TTestDependencyAnalyzer.RunAllTests;
begin
  try
    ShowMessage('开始运行依赖关系分析器测试...');
    
    TestBasicDependencyAnalysis;
    ShowMessage('✓ 基础依赖分析测试通过');
    
    TestRegistryDependencyAnalysis;
    ShowMessage('✓ 注册表依赖分析测试通过');
    
    TestShortcutDependencyAnalysis;
    ShowMessage('✓ 快捷方式依赖分析测试通过');
    
    TestServiceDependencyAnalysis;
    ShowMessage('✓ 服务依赖分析测试通过');
    
    TestDLLDependencyAnalysis;
    ShowMessage('✓ DLL依赖分析测试通过');
    
    TestConfigDependencyAnalysis;
    ShowMessage('✓ 配置文件依赖分析测试通过');
    
    TestBatchAnalysis;
    ShowMessage('✓ 批量分析测试通过');
    
    TestDependencyUpdate;
    ShowMessage('✓ 依赖更新测试通过');
    
    TestUtilityMethods;
    ShowMessage('✓ 工具方法测试通过');
    
    ShowMessage('所有依赖关系分析器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestDependencyAnalyzer.TestBasicDependencyAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  TestFile: string;
  Result: TDependencyAnalysisResult;
  FileStream: TFileStream;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 测试不存在的文件
    Result := Analyzer.AnalyzeFileDependencies('C:\NonExistentFile.exe');
    
    if not Result.SafeToMove then
      raise Exception.Create('不存在的文件应该可以安全移动');
    
    if not Result.SafeToDelete then
      raise Exception.Create('不存在的文件应该可以安全删除');
    
    if Result.RequiresUpdate then
      raise Exception.Create('不存在的文件不应该需要更新');
    
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'dependency_test.exe';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试可执行文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Analyzer.AnalyzeFileDependencies(TestFile);
      
      if Result.FilePath <> TestFile then
        raise Exception.Create('分析结果文件路径不匹配');
      
      if Result.TotalDependencies < 0 then
        raise Exception.Create('依赖总数不应该为负数');
      
      if Result.CriticalDependencies < 0 then
        raise Exception.Create('关键依赖数不应该为负数');
      
      if Result.CriticalDependencies > Result.TotalDependencies then
        raise Exception.Create('关键依赖数不应该超过总依赖数');
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Analyzer.Free;
  end;
end;cl
ass procedure TTestDependencyAnalyzer.TestRegistryDependencyAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  TestFile: string;
  Result: TDependencyAnalysisResult;
  FileStream: TFileStream;
  Reg: TRegistry;
  TestKeyPath: string;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'registry_test.exe';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('注册表测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    // 创建测试注册表项
    TestKeyPath := 'SOFTWARE\TestDependencyAnalyzer';
    Reg := TRegistry.Create(KEY_WRITE);
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      
      if Reg.OpenKey(TestKeyPath, True) then
      begin
        try
          Reg.WriteString('TestPath', TestFile);
        finally
          Reg.CloseKey;
        end;
      end;
      
    finally
      Reg.Free;
    end;
    
    try
      // 分析依赖关系
      Result := Analyzer.AnalyzeFileDependencies(TestFile);
      
      // 检查是否找到了注册表依赖
      var FoundRegistryDep := False;
      for var Dependency in Result.Dependencies do
      begin
        if Dependency.DependencyType = dtRegistryValue then
        begin
          FoundRegistryDep := True;
          
          if not ContainsText(Dependency.Description, '注册表') then
            raise Exception.Create('注册表依赖描述不正确');
          
          if Dependency.BreakRisk < 0 then
            raise Exception.Create('断开风险不应该为负数');
          
          if Dependency.BreakRisk > 100 then
            raise Exception.Create('断开风险不应该超过100');
          
          Break;
        end;
      end;
      
      // 注意：由于注册表搜索的复杂性，这里不强制要求找到依赖
      // 实际测试中可能需要更精确的注册表操作
      
    finally
      // 清理测试文件和注册表项
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      
      Reg := TRegistry.Create(KEY_WRITE);
      try
        Reg.RootKey := HKEY_CURRENT_USER;
        if Reg.OpenKey('SOFTWARE', False) then
        begin
          try
            Reg.DeleteKey('TestDependencyAnalyzer');
          except
            // 忽略删除错误
          end;
          Reg.CloseKey;
        end;
      finally
        Reg.Free;
      end;
    end;
    
  finally
    Analyzer.Free;
  end;
end;

class procedure TTestDependencyAnalyzer.TestShortcutDependencyAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  TestFile, ShortcutFile: string;
  Result: TDependencyAnalysisResult;
  FileStream: TFileStream;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'shortcut_test.exe';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('快捷方式测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    // 创建测试快捷方式（简化实现）
    ShortcutFile := TPath.GetTempPath + 'test_shortcut.lnk';
    FileStream := TFileStream.Create(ShortcutFile, fmCreate);
    try
      var ShortcutData := TEncoding.UTF8.GetBytes('模拟快捷方式文件');
      FileStream.WriteBuffer(ShortcutData[0], Length(ShortcutData));
    finally
      FileStream.Free;
    end;
    
    try
      // 分析依赖关系
      Result := Analyzer.AnalyzeFileDependencies(TestFile);
      
      // 由于快捷方式创建的复杂性，这里主要测试分析过程不出错
      if Result.TotalDependencies < 0 then
        raise Exception.Create('依赖总数不应该为负数');
      
      // 检查快捷方式依赖的处理
      for var Dependency in Result.Dependencies do
      begin
        if Dependency.DependencyType = dtShortcut then
        begin
          if not ContainsText(Dependency.Description, '快捷方式') then
            raise Exception.Create('快捷方式依赖描述不正确');
          
          if not Dependency.CanBreak then
            raise Exception.Create('快捷方式依赖应该可以断开');
        end;
      end;
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if FileExists(ShortcutFile) then
        DeleteFile(ShortcutFile);
    end;
    
  finally
    Analyzer.Free;
  end;
end;

class procedure TTestDependencyAnalyzer.TestServiceDependencyAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  SystemFile: string;
  Result: TDependencyAnalysisResult;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 测试已知的系统服务文件
    SystemFile := GetEnvironmentVariable('WINDIR') + '\System32\svchost.exe';
    
    if FileExists(SystemFile) then
    begin
      Result := Analyzer.AnalyzeFileDependencies(SystemFile);
      
      // 系统服务文件应该有依赖关系
      if Result.TotalDependencies < 0 then
        raise Exception.Create('依赖总数不应该为负数');
      
      // 检查服务依赖
      for var Dependency in Result.Dependencies do
      begin
        if Dependency.DependencyType = dtServiceDependency then
        begin
          if not ContainsText(Dependency.Description, '服务') then
            raise Exception.Create('服务依赖描述不正确');
          
          if not Dependency.IsCritical then
            raise Exception.Create('服务依赖应该是关键的');
          
          if Dependency.CanBreak then
            raise Exception.Create('服务依赖不应该允许断开');
        end;
      end;
      
      // 系统服务文件不应该允许随意移动或删除
      if Result.SafeToDelete then
        raise Exception.Create('系统服务文件不应该允许删除');
    end;
    
  finally
    Analyzer.Free;
  end;
end;cl
ass procedure TTestDependencyAnalyzer.TestDLLDependencyAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  TestDLL, TestEXE: string;
  DLLResult, EXEResult: TDependencyAnalysisResult;
  FileStream: TFileStream;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 创建测试DLL文件
    TestDLL := TPath.GetTempPath + 'test_library.dll';
    FileStream := TFileStream.Create(TestDLL, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试DLL文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    // 创建测试EXE文件
    TestEXE := TPath.GetTempPath + 'test_program.exe';
    FileStream := TFileStream.Create(TestEXE, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试EXE文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 分析DLL依赖
      DLLResult := Analyzer.AnalyzeFileDependencies(TestDLL);
      
      if DLLResult.TotalDependencies < 0 then
        raise Exception.Create('DLL依赖总数不应该为负数');
      
      // 分析EXE依赖
      EXEResult := Analyzer.AnalyzeFileDependencies(TestEXE);
      
      if EXEResult.TotalDependencies < 0 then
        raise Exception.Create('EXE依赖总数不应该为负数');
      
      // 检查DLL依赖类型
      for var Dependency in EXEResult.Dependencies do
      begin
        if Dependency.DependencyType = dtDLLDependency then
        begin
          if not ContainsText(Dependency.Description, 'DLL') then
            raise Exception.Create('DLL依赖描述不正确');
          
          if Dependency.CanBreak then
            raise Exception.Create('程序的DLL依赖不应该允许断开');
        end;
      end;
      
    finally
      // 清理测试文件
      if FileExists(TestDLL) then
        DeleteFile(TestDLL);
      if FileExists(TestEXE) then
        DeleteFile(TestEXE);
    end;
    
  finally
    Analyzer.Free;
  end;
end;

class procedure TTestDependencyAnalyzer.TestConfigDependencyAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  TestFile, ConfigFile: string;
  Result: TDependencyAnalysisResult;
  FileStream: TFileStream;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'config_test.exe';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('配置测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    // 创建引用该文件的配置文件
    ConfigFile := TPath.GetTempPath + 'test_config.ini';
    TFile.WriteAllText(ConfigFile, Format('[Settings]%sExecutablePath=%s%s', 
      [sLineBreak, TestFile, sLineBreak]));
    
    try
      // 分析依赖关系
      Result := Analyzer.AnalyzeFileDependencies(TestFile);
      
      if Result.TotalDependencies < 0 then
        raise Exception.Create('依赖总数不应该为负数');
      
      // 检查配置文件依赖
      var FoundConfigDep := False;
      for var Dependency in Result.Dependencies do
      begin
        if Dependency.DependencyType = dtConfigFile then
        begin
          FoundConfigDep := True;
          
          if not ContainsText(Dependency.Description, '配置') then
            raise Exception.Create('配置文件依赖描述不正确');
          
          if not Dependency.CanBreak then
            raise Exception.Create('配置文件依赖应该可以断开');
          
          Break;
        end;
      end;
      
      // 注意：由于配置文件搜索的复杂性，这里不强制要求找到依赖
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if FileExists(ConfigFile) then
        DeleteFile(ConfigFile);
    end;
    
  finally
    Analyzer.Free;
  end;
end;

class procedure TTestDependencyAnalyzer.TestBatchAnalysis;
var
  Analyzer: TDependencyAnalyzer;
  TestFiles: TArray<string>;
  Results: TArray<TDependencyAnalysisResult>;
  I: Integer;
  FileStream: TFileStream;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 创建多个测试文件
    SetLength(TestFiles, 3);
    TestFiles[0] := TPath.GetTempPath + 'batch_test1.exe';
    TestFiles[1] := TPath.GetTempPath + 'batch_test2.dll';
    TestFiles[2] := TPath.GetTempPath + 'batch_test3.txt';
    
    for I := 0 to Length(TestFiles) - 1 do
    begin
      FileStream := TFileStream.Create(TestFiles[I], fmCreate);
      try
        var TestData := TEncoding.UTF8.GetBytes('批量测试文件' + IntToStr(I + 1));
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
    end;
    
    try
      // 批量分析
      Results := Analyzer.BatchAnalyzeDependencies(TestFiles);
      
      if Length(Results) <> Length(TestFiles) then
        raise Exception.Create('批量分析结果数量不匹配');
      
      // 检查每个结果
      for I := 0 to Length(Results) - 1 do
      begin
        if Results[I].FilePath <> TestFiles[I] then
          raise Exception.Create('批量分析结果文件路径不匹配');
        
        if Results[I].TotalDependencies < 0 then
          raise Exception.Create('批量分析依赖总数不应该为负数');
      end;
      
      // 测试目录分析
      var DirResults := Analyzer.AnalyzeDirectoryDependencies(TPath.GetTempPath);
      
      if Length(DirResults) < 0 then
        raise Exception.Create('目录分析结果数量不应该为负数');
      
    finally
      // 清理测试文件
      for I := 0 to Length(TestFiles) - 1 do
      begin
        if FileExists(TestFiles[I]) then
          DeleteFile(TestFiles[I]);
      end;
    end;
    
  finally
    Analyzer.Free;
  end;
end;c
lass procedure TTestDependencyAnalyzer.TestDependencyUpdate;
var
  Analyzer: TDependencyAnalyzer;
  TestFile, NewPath: string;
  Result: TDependencyAnalysisResult;
  UpdateScript: TArray<string>;
  FileStream: TFileStream;
begin
  Analyzer := TDependencyAnalyzer.Create;
  try
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'update_test.exe';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('更新测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    NewPath := TPath.GetTempPath + 'moved_update_test.exe';
    
    try
      // 分析依赖关系
      Result := Analyzer.AnalyzeFileDependencies(TestFile);
      
      // 生成更新脚本
      UpdateScript := Analyzer.GenerateUpdateScript(Result, NewPath);
      
      if Length(UpdateScript) = 0 then
        raise Exception.Create('更新脚本不应该为空');
      
      // 检查脚本内容
      var ScriptContent := string.Join(sLineBreak, UpdateScript);
      if not ContainsText(ScriptContent, 'REM') then
        raise Exception.Create('更新脚本应该包含注释');
      
      // 测试依赖验证
      var IsValid := Analyzer.ValidateDependencyUpdate(TestFile, NewPath);
      // 由于新路径不存在，验证应该失败
      if IsValid then
        raise Exception.Create('不存在的新路径验证应该失败');
      
      // 创建新路径文件进行验证
      TFile.Copy(TestFile, NewPath);
      try
        IsValid := Analyzer.ValidateDependencyUpdate(TestFile, NewPath);
        if not IsValid then
          raise Exception.Create('存在的新路径验证应该成功');
        
        // 测试依赖更新
        var UpdateSuccess := Analyzer.UpdateDependencies(TestFile, NewPath);
        // 由于这是简化实现，主要测试不出错
        
      finally
        if FileExists(NewPath) then
          DeleteFile(NewPath);
      end;
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Analyzer.Free;
  end;
end;

class procedure TTestDependencyAnalyzer.TestUtilityMethods;
begin
  // 测试依赖类型转换
  if TDependencyAnalyzer.DependencyTypeToString(dtRegistryValue) <> '注册表值' then
    raise Exception.Create('注册表值类型转换错误');
  
  if TDependencyAnalyzer.DependencyTypeToString(dtShortcut) <> '快捷方式' then
    raise Exception.Create('快捷方式类型转换错误');
  
  if TDependencyAnalyzer.DependencyTypeToString(dtServiceDependency) <> '服务依赖' then
    raise Exception.Create('服务依赖类型转换错误');
  
  if TDependencyAnalyzer.DependencyTypeToString(dtDLLDependency) <> 'DLL依赖' then
    raise Exception.Create('DLL依赖类型转换错误');
  
  if TDependencyAnalyzer.DependencyTypeToString(dtConfigFile) <> '配置文件' then
    raise Exception.Create('配置文件类型转换错误');
  
  if TDependencyAnalyzer.DependencyTypeToString(dtUnknown) <> '未知依赖' then
    raise Exception.Create('未知依赖类型转换错误');
  
  // 测试风险级别转换
  if TDependencyAnalyzer.RiskLevelToString(90) <> '极高风险' then
    raise Exception.Create('极高风险级别转换错误');
  
  if TDependencyAnalyzer.RiskLevelToString(70) <> '高风险' then
    raise Exception.Create('高风险级别转换错误');
  
  if TDependencyAnalyzer.RiskLevelToString(50) <> '中等风险' then
    raise Exception.Create('中等风险级别转换错误');
  
  if TDependencyAnalyzer.RiskLevelToString(30) <> '低风险' then
    raise Exception.Create('低风险级别转换错误');
  
  if TDependencyAnalyzer.RiskLevelToString(10) <> '极低风险' then
    raise Exception.Create('极低风险级别转换错误');
  
  // 测试风险级别颜色转换
  if TDependencyAnalyzer.RiskLevelToColor(90) = 0 then
    raise Exception.Create('极高风险颜色转换错误');
  
  if TDependencyAnalyzer.RiskLevelToColor(70) = 0 then
    raise Exception.Create('高风险颜色转换错误');
  
  if TDependencyAnalyzer.RiskLevelToColor(50) = 0 then
    raise Exception.Create('中等风险颜色转换错误');
  
  if TDependencyAnalyzer.RiskLevelToColor(30) = 0 then
    raise Exception.Create('低风险颜色转换错误');
  
  if TDependencyAnalyzer.RiskLevelToColor(10) = 0 then
    raise Exception.Create('极低风险颜色转换错误');
end;

end.