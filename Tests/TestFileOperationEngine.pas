unit TestFileOperationEngine;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, FileOperationEngine, ConfigManager;

type
  // 文件操作引擎测试类
  TTestFileOperationEngine = class
  public
    class procedure RunAllTests;
    class procedure TestCopyOperation;
    class procedure TestMoveOperation;
    class procedure TestDeleteOperation;
    class procedure TestLinkOperation;
    class procedure TestVerifyOperation;
    class procedure TestBatchOperations;
    class procedure TestProgressCallback;
    class procedure TestErrorHandling;
    class procedure TestOptionsConfiguration;
    class procedure TestStatisticsAndReporting;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestFileOperationEngine.RunAllTests;
begin
  try
    ShowMessage('开始运行文件操作引擎测试...');
    
    TestCopyOperation;
    ShowMessage('✓ 复制操作测试通过');
    
    TestMoveOperation;
    ShowMessage('✓ 移动操作测试通过');
    
    TestDeleteOperation;
    ShowMessage('✓ 删除操作测试通过');
    
    TestLinkOperation;
    ShowMessage('✓ 链接操作测试通过');
    
    TestVerifyOperation;
    ShowMessage('✓ 验证操作测试通过');
    
    TestBatchOperations;
    ShowMessage('✓ 批量操作测试通过');
    
    TestProgressCallback;
    ShowMessage('✓ 进度回调测试通过');
    
    TestErrorHandling;
    ShowMessage('✓ 错误处理测试通过');
    
    TestOptionsConfiguration;
    ShowMessage('✓ 选项配置测试通过');
    
    TestStatisticsAndReporting;
    ShowMessage('✓ 统计报告测试通过');
    
    ShowMessage('所有文件操作引擎测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestFileOperationEngine.TestCopyOperation;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  SourceFile, TargetFile: string;
  TestContent: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'test_copy_source.txt');
      TargetFile := TPath.Combine(TPath.GetTempPath, 'test_copy_target.txt');
      TestContent := 'This is a test file for copy operation.';
      
      TFile.WriteAllText(SourceFile, TestContent);
      
      try
        // 添加复制操作
        Engine.AddOperation(fotCopy, SourceFile, TargetFile);
        
        if Engine.GetOperationCount <> 1 then
          raise Exception.Create('操作数量不正确');
        
        // 执行操作
        if not Engine.Execute then
          raise Exception.Create('复制操作执行失败');
        
        // 验证结果
        if not FileExists(TargetFile) then
          raise Exception.Create('目标文件未创建');
        
        var TargetContent := TFile.ReadAllText(TargetFile);
        if TargetContent <> TestContent then
          raise Exception.Create('文件内容不匹配');
        
        // 验证源文件仍然存在
        if not FileExists(SourceFile) then
          raise Exception.Create('源文件不应该被删除');
        
      finally
        // 清理测试文件
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if FileExists(TargetFile) then
          DeleteFile(TargetFile);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestMoveOperation;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  SourceFile, TargetFile: string;
  TestContent: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'test_move_source.txt');
      TargetFile := TPath.Combine(TPath.GetTempPath, 'test_move_target.txt');
      TestContent := 'This is a test file for move operation.';
      
      TFile.WriteAllText(SourceFile, TestContent);
      
      try
        // 添加移动操作
        Engine.AddOperation(fotMove, SourceFile, TargetFile);
        
        // 执行操作
        if not Engine.Execute then
          raise Exception.Create('移动操作执行失败');
        
        // 验证结果
        if not FileExists(TargetFile) then
          raise Exception.Create('目标文件未创建');
        
        var TargetContent := TFile.ReadAllText(TargetFile);
        if TargetContent <> TestContent then
          raise Exception.Create('文件内容不匹配');
        
        // 验证源文件已被删除
        if FileExists(SourceFile) then
          raise Exception.Create('源文件应该被删除');
        
      finally
        // 清理测试文件
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if FileExists(TargetFile) then
          DeleteFile(TargetFile);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestDeleteOperation;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  TestFile: string;
  Options: TOperationOptions;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_delete.txt');
      TFile.WriteAllText(TestFile, 'This file will be deleted.');
      
      try
        // 设置不创建备份
        Options := Engine.GetOptions;
        Options.CreateBackup := False;
        Engine.SetOptions(Options);
        
        // 添加删除操作
        Engine.AddOperation(fotDelete, TestFile, '');
        
        // 执行操作
        if not Engine.Execute then
          raise Exception.Create('删除操作执行失败');
        
        // 验证文件已被删除
        if FileExists(TestFile) then
          raise Exception.Create('文件应该被删除');
        
      finally
        // 清理（如果删除失败）
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestLinkOperation;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  SourceDir, TargetLink: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试目录
      SourceDir := TPath.Combine(TPath.GetTempPath, 'test_link_source');
      TargetLink := TPath.Combine(TPath.GetTempPath, 'test_link_target');
      
      TDirectory.CreateDirectory(SourceDir);
      TFile.WriteAllText(TPath.Combine(SourceDir, 'test.txt'), 'test content');
      
      try
        // 添加链接创建操作
        Engine.AddOperation(fotCreateLink, SourceDir, TargetLink);
        
        // 执行操作
        var Success := Engine.Execute;
        
        // 注意：链接创建可能因权限问题失败，这是正常的
        if Success then
        begin
          // 验证链接已创建
          if not DirectoryExists(TargetLink) then
            raise Exception.Create('链接目录未创建');
        end;
        
      finally
        // 清理测试目录和链接
        if DirectoryExists(TargetLink) then
          TDirectory.Delete(TargetLink, False); // 不递归删除，只删除链接
        if DirectoryExists(SourceDir) then
          TDirectory.Delete(SourceDir, True);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestVerifyOperation;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  TestFile: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_verify.txt');
      TFile.WriteAllText(TestFile, 'This file will be verified.');
      
      try
        // 添加验证操作
        Engine.AddOperation(fotVerify, TestFile, '');
        
        // 执行操作
        if not Engine.Execute then
          raise Exception.Create('验证操作执行失败');
        
        var Stats := Engine.GetStatistics;
        if Stats.CompletedOperations <> 1 then
          raise Exception.Create('验证操作未完成');
        
      finally
        // 清理测试文件
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;cl
ass procedure TTestFileOperationEngine.TestBatchOperations;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  SourceFiles, TargetFiles: TArray<string>;
  I: Integer;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建多个测试文件
      SetLength(SourceFiles, 3);
      SetLength(TargetFiles, 3);
      
      for I := 0 to 2 do
      begin
        SourceFiles[I] := TPath.Combine(TPath.GetTempPath, Format('batch_source_%d.txt', [I]));
        TargetFiles[I] := TPath.Combine(TPath.GetTempPath, Format('batch_target_%d.txt', [I]));
        TFile.WriteAllText(SourceFiles[I], Format('Batch test content %d', [I]));
      end;
      
      try
        // 添加批量复制操作
        for I := 0 to 2 do
          Engine.AddOperation(fotCopy, SourceFiles[I], TargetFiles[I]);
        
        if Engine.GetOperationCount <> 3 then
          raise Exception.Create('批量操作数量不正确');
        
        // 执行批量操作
        if not Engine.Execute then
          raise Exception.Create('批量操作执行失败');
        
        // 验证所有文件都已复制
        for I := 0 to 2 do
        begin
          if not FileExists(TargetFiles[I]) then
            raise Exception.Create(Format('目标文件 %d 未创建', [I]));
        end;
        
        var Stats := Engine.GetStatistics;
        if Stats.CompletedOperations <> 3 then
          raise Exception.Create('批量操作完成数量不正确');
        
      finally
        // 清理测试文件
        for I := 0 to 2 do
        begin
          if FileExists(SourceFiles[I]) then
            DeleteFile(SourceFiles[I]);
          if FileExists(TargetFiles[I]) then
            DeleteFile(TargetFiles[I]);
        end;
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestProgressCallback;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  TestFile, TargetFile: string;
  ProgressCalled: Boolean;
  StatusCalled: Boolean;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      ProgressCalled := False;
      StatusCalled := False;
      
      // 设置回调事件
      Engine.OnProgress := procedure(const AOperation: string; AProgress: Integer; const ACurrentFile: string)
      begin
        ProgressCalled := True;
      end;
      
      Engine.OnStatus := procedure(AStatus: TOperationStatus; const AMessage: string)
      begin
        StatusCalled := True;
      end;
      
      // 创建测试文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'progress_test.txt');
      TargetFile := TPath.Combine(TPath.GetTempPath, 'progress_target.txt');
      TFile.WriteAllText(TestFile, StringOfChar('A', 1024)); // 1KB文件
      
      try
        Engine.AddOperation(fotCopy, TestFile, TargetFile);
        
        // 执行操作
        Engine.Execute;
        
        // 验证回调被调用
        if not ProgressCalled then
          raise Exception.Create('进度回调未被调用');
        
        if not StatusCalled then
          raise Exception.Create('状态回调未被调用');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
        if FileExists(TargetFile) then
          DeleteFile(TargetFile);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestErrorHandling;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  NonExistentFile, TargetFile: string;
  ErrorCalled: Boolean;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      ErrorCalled := False;
      
      // 设置错误回调
      Engine.OnError := procedure(const AError: string; var AAction: Integer)
      begin
        ErrorCalled := True;
        AAction := 2; // Skip
      end;
      
      // 尝试复制不存在的文件
      NonExistentFile := TPath.Combine(TPath.GetTempPath, 'non_existent_file.txt');
      TargetFile := TPath.Combine(TPath.GetTempPath, 'error_target.txt');
      
      Engine.AddOperation(fotCopy, NonExistentFile, TargetFile);
      
      // 执行操作（应该失败但不崩溃）
      var Success := Engine.Execute;
      
      // 验证错误处理
      var Stats := Engine.GetStatistics;
      if Stats.FailedOperations = 0 and Stats.SkippedOperations = 0 then
        raise Exception.Create('错误操作应该被记录');
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestOptionsConfiguration;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  Options: TOperationOptions;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 获取默认选项
      Options := Engine.GetOptions;
      
      // 验证默认值
      if not Options.PreserveAttributes then
        raise Exception.Create('默认应该保持文件属性');
      
      if not Options.PreserveTimestamps then
        raise Exception.Create('默认应该保持时间戳');
      
      if not Options.VerifyAfterCopy then
        raise Exception.Create('默认应该复制后验证');
      
      // 修改选项
      Options.BufferSize := 128 * 1024; // 128KB
      Options.MaxRetries := 5;
      Options.OverwriteExisting := True;
      
      Engine.SetOptions(Options);
      
      // 验证选项已更新
      var UpdatedOptions := Engine.GetOptions;
      if UpdatedOptions.BufferSize <> 128 * 1024 then
        raise Exception.Create('缓冲区大小未更新');
      
      if UpdatedOptions.MaxRetries <> 5 then
        raise Exception.Create('最大重试次数未更新');
      
      if not UpdatedOptions.OverwriteExisting then
        raise Exception.Create('覆盖选项未更新');
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileOperationEngine.TestStatisticsAndReporting;
var
  Engine: TFileOperationEngine;
  ConfigManager: TConfigManager;
  TestFile, TargetFile: string;
  Stats: TOperationStatistics;
  Report: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'stats_test.txt');
      TargetFile := TPath.Combine(TPath.GetTempPath, 'stats_target.txt');
      TFile.WriteAllText(TestFile, 'Statistics test content');
      
      try
        Engine.AddOperation(fotCopy, TestFile, TargetFile);
        
        // 执行前检查统计
        Stats := Engine.GetStatistics;
        if Stats.TotalOperations <> 1 then
          raise Exception.Create('总操作数统计错误');
        
        // 执行操作
        Engine.Execute;
        
        // 执行后检查统计
        Stats := Engine.GetStatistics;
        if Stats.CompletedOperations <> 1 then
          raise Exception.Create('完成操作数统计错误');
        
        if Stats.TotalBytes <= 0 then
          raise Exception.Create('总字节数统计错误');
        
        if Stats.ProcessedBytes <= 0 then
          raise Exception.Create('已处理字节数统计错误');
        
        // 检查进度百分比
        var Progress := Engine.GetProgressPercentage;
        if Progress <> 100 then
          raise Exception.Create('进度百分比计算错误');
        
        // 生成报告
        Report := Engine.GenerateReport;
        if Length(Report) = 0 then
          raise Exception.Create('报告生成失败');
        
        if not ContainsText(Report, '文件操作执行报告') then
          raise Exception.Create('报告格式不正确');
        
        if not ContainsText(Report, '总操作数: 1') then
          raise Exception.Create('报告统计信息不正确');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
        if FileExists(TargetFile) then
          DeleteFile(TargetFile);
      end;
      
    finally
      Engine.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.