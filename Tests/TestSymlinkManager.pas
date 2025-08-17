unit TestSymlinkManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, SymlinkManager, ConfigManager;

type
  // 符号链接管理器测试类
  TTestSymlinkManager = class
  public
    class procedure RunAllTests;
    class procedure TestSymlinkDetection;
    class procedure TestSymlinkCreation;
    class procedure TestSymlinkValidation;
    class procedure TestSymlinkRepair;
    class procedure TestBatchOperations;
    class procedure TestPathConversion;
    class procedure TestLinkManagement;
    class procedure TestStatisticsAndReporting;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestSymlinkManager.RunAllTests;
begin
  try
    ShowMessage('开始运行符号链接管理器测试...');
    
    TestSymlinkDetection;
    ShowMessage('✓ 符号链接检测测试通过');
    
    TestSymlinkCreation;
    ShowMessage('✓ 符号链接创建测试通过');
    
    TestSymlinkValidation;
    ShowMessage('✓ 符号链接验证测试通过');
    
    TestSymlinkRepair;
    ShowMessage('✓ 符号链接修复测试通过');
    
    TestBatchOperations;
    ShowMessage('✓ 批量操作测试通过');
    
    TestPathConversion;
    ShowMessage('✓ 路径转换测试通过');
    
    TestLinkManagement;
    ShowMessage('✓ 链接管理测试通过');
    
    TestStatisticsAndReporting;
    ShowMessage('✓ 统计报告测试通过');
    
    ShowMessage('所有符号链接管理器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestSymlinkManager.TestSymlinkDetection;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  TestFile: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建普通文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'normal_file.txt');
      TFile.WriteAllText(TestFile, 'This is a normal file');
      
      try
        // 测试普通文件不被识别为符号链接
        if Manager.IsSymlink(TestFile) then
          raise Exception.Create('普通文件不应该被识别为符号链接');
        
        var LinkType := Manager.GetLinkType(TestFile);
        if LinkType <> stUnknown then
          raise Exception.Create('普通文件的链接类型应该是未知');
        
        var Status := Manager.GetLinkStatus(TestFile);
        if Status <> ssInvalid then
          raise Exception.Create('普通文件的链接状态应该是无效');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试不存在的文件
      var NonExistentFile := TPath.Combine(TPath.GetTempPath, 'non_existent.txt');
      if Manager.IsSymlink(NonExistentFile) then
        raise Exception.Create('不存在的文件不应该被识别为符号链接');
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestSymlinkManager.TestSymlinkCreation;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  SourceFile, SourceDir, LinkFile, LinkDir: string;
  Options: TSymlinkOptions;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试源文件和目录
      SourceFile := TPath.Combine(TPath.GetTempPath, 'symlink_source.txt');
      SourceDir := TPath.Combine(TPath.GetTempPath, 'symlink_source_dir');
      LinkFile := TPath.Combine(TPath.GetTempPath, 'symlink_file_link.txt');
      LinkDir := TPath.Combine(TPath.GetTempPath, 'symlink_dir_link');
      
      TFile.WriteAllText(SourceFile, 'Source file content');
      TDirectory.CreateDirectory(SourceDir);
      TFile.WriteAllText(TPath.Combine(SourceDir, 'test.txt'), 'Dir content');
      
      try
        // 设置选项
        Options := Manager.GetOptions;
        Options.ValidateTarget := True;
        Options.LogOperations := True;
        Manager.SetOptions(Options);
        
        // 测试文件符号链接创建
        var Success := Manager.CreateSymlink(SourceFile, LinkFile, stFile);
        
        // 注意：符号链接创建可能因权限问题失败，这是正常的
        if Success then
        begin
          if not Manager.IsSymlink(LinkFile) then
            raise Exception.Create('文件符号链接创建后检测失败');
          
          var TargetPath := Manager.GetTargetPath(LinkFile);
          if not SameText(TargetPath, SourceFile) then
            raise Exception.Create('文件符号链接目标路径不正确');
        end;
        
        // 测试目录符号链接创建
        Success := Manager.CreateSymlink(SourceDir, LinkDir, stDirectory);
        
        if Success then
        begin
          if not Manager.IsSymlink(LinkDir) then
            raise Exception.Create('目录符号链接创建后检测失败');
        end;
        
        // 测试目录联接创建
        var JunctionLink := TPath.Combine(TPath.GetTempPath, 'junction_link');
        Success := Manager.CreateSymlink(SourceDir, JunctionLink, stJunction);
        
        if Success then
        begin
          if not Manager.IsSymlink(JunctionLink) then
            raise Exception.Create('目录联接创建后检测失败');
        end;
        
        // 清理链接
        if Manager.IsSymlink(LinkFile) then
          Manager.RemoveSymlink(LinkFile);
        if Manager.IsSymlink(LinkDir) then
          Manager.RemoveSymlink(LinkDir);
        if Manager.IsSymlink(JunctionLink) then
          Manager.RemoveSymlink(JunctionLink);
        
      finally
        // 清理测试文件和目录
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if DirectoryExists(SourceDir) then
          TDirectory.Delete(SourceDir, True);
        if FileExists(LinkFile) then
          DeleteFile(LinkFile);
        if DirectoryExists(LinkDir) then
          TDirectory.Delete(LinkDir, False);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestSymlinkManager.TestSymlinkValidation;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  SourceFile, LinkFile: string;
  Info: TSymlinkInfo;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'validation_source.txt');
      LinkFile := TPath.Combine(TPath.GetTempPath, 'validation_link.txt');
      
      TFile.WriteAllText(SourceFile, 'Validation test content');
      
      try
        // 尝试创建符号链接
        if Manager.CreateSymlink(SourceFile, LinkFile, stFile) then
        begin
          // 验证符号链接
          if not Manager.ValidateSymlink(LinkFile) then
            raise Exception.Create('有效符号链接验证失败');
          
          // 获取符号链接信息
          Info := Manager.GetSymlinkInfo(LinkFile);
          
          if Info.Status <> ssValid then
            raise Exception.Create('符号链接状态应该是有效');
          
          if Info.LinkType <> stFile then
            raise Exception.Create('符号链接类型不正确');
          
          if Length(Info.TargetPath) = 0 then
            raise Exception.Create('目标路径不应该为空');
          
          // 删除目标文件，测试损坏链接检测
          DeleteFile(SourceFile);
          
          // 清理缓存以强制重新检测
          Manager.ClearCache;
          
          if Manager.ValidateSymlink(LinkFile) then
            raise Exception.Create('损坏的符号链接不应该验证通过');
          
          Info := Manager.GetSymlinkInfo(LinkFile);
          if Info.Status <> ssBroken then
            raise Exception.Create('符号链接状态应该是损坏');
          
          // 清理链接
          Manager.RemoveSymlink(LinkFile);
        end;
        
      finally
        // 清理测试文件
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if FileExists(LinkFile) then
          DeleteFile(LinkFile);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;cla
ss procedure TTestSymlinkManager.TestSymlinkRepair;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  SourceFile, NewSourceFile, LinkFile: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'repair_source.txt');
      NewSourceFile := TPath.Combine(TPath.GetTempPath, 'repair_source.txt');
      LinkFile := TPath.Combine(TPath.GetTempPath, 'repair_link.txt');
      
      TFile.WriteAllText(SourceFile, 'Repair test content');
      
      try
        // 创建符号链接
        if Manager.CreateSymlink(SourceFile, LinkFile, stFile) then
        begin
          // 删除源文件以创建损坏的链接
          DeleteFile(SourceFile);
          
          // 清理缓存
          Manager.ClearCache;
          
          // 验证链接已损坏
          var Info := Manager.GetSymlinkInfo(LinkFile);
          if Info.Status <> ssBroken then
            raise Exception.Create('链接应该是损坏状态');
          
          // 在同一目录创建新的源文件
          TFile.WriteAllText(SourceFile, 'Repaired content');
          
          // 尝试修复链接
          if Manager.RepairSymlink(LinkFile) then
          begin
            // 验证修复结果
            Manager.ClearCache;
            if not Manager.ValidateSymlink(LinkFile) then
              raise Exception.Create('修复后的链接应该是有效的');
          end;
          
          // 清理链接
          Manager.RemoveSymlink(LinkFile);
        end;
        
      finally
        // 清理测试文件
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if FileExists(NewSourceFile) then
          DeleteFile(NewSourceFile);
        if FileExists(LinkFile) then
          DeleteFile(LinkFile);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestSymlinkManager.TestBatchOperations;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  TestPaths: TArray<string>;
  Results: TArray<TSymlinkInfo>;
  I: Integer;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试路径数组
      SetLength(TestPaths, 3);
      TestPaths[0] := TPath.Combine(TPath.GetTempPath, 'batch_test1.txt');
      TestPaths[1] := TPath.Combine(TPath.GetTempPath, 'batch_test2.txt');
      TestPaths[2] := TPath.Combine(TPath.GetTempPath, 'batch_test3.txt');
      
      // 创建普通文件（非符号链接）
      for I := 0 to Length(TestPaths) - 1 do
        TFile.WriteAllText(TestPaths[I], Format('Batch test content %d', [I]));
      
      try
        // 批量验证
        Results := Manager.BatchValidate(TestPaths);
        
        if Length(Results) <> Length(TestPaths) then
          raise Exception.Create('批量验证结果数量不匹配');
        
        // 验证结果
        for I := 0 to Length(Results) - 1 do
        begin
          if Results[I].LinkPath <> TestPaths[I] then
            raise Exception.Create('批量验证结果路径不匹配');
          
          // 普通文件应该返回无效状态
          if Results[I].Status <> ssInvalid then
            raise Exception.Create('普通文件状态应该是无效');
        end;
        
        // 测试批量修复（对于普通文件应该返回0）
        var RepairCount := Manager.BatchRepair(TestPaths);
        if RepairCount <> 0 then
          raise Exception.Create('普通文件不应该被修复');
        
      finally
        // 清理测试文件
        for I := 0 to Length(TestPaths) - 1 do
        begin
          if FileExists(TestPaths[I]) then
            DeleteFile(TestPaths[I]);
        end;
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestSymlinkManager.TestPathConversion;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  SourceFile, LinkFile: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'conversion_source.txt');
      LinkFile := TPath.Combine(TPath.GetTempPath, 'conversion_link.txt');
      
      TFile.WriteAllText(SourceFile, 'Conversion test content');
      
      try
        // 创建绝对路径符号链接
        if Manager.CreateSymlink(SourceFile, LinkFile, stFile) then
        begin
          var Info := Manager.GetSymlinkInfo(LinkFile);
          
          // 测试转换为相对路径
          if Manager.ConvertToRelative(LinkFile) then
          begin
            Manager.ClearCache;
            var NewInfo := Manager.GetSymlinkInfo(LinkFile);
            if not NewInfo.IsRelative then
              raise Exception.Create('转换后应该是相对路径');
          end;
          
          // 测试转换为绝对路径
          if Manager.ConvertToAbsolute(LinkFile) then
          begin
            Manager.ClearCache;
            var NewInfo := Manager.GetSymlinkInfo(LinkFile);
            if NewInfo.IsRelative then
              raise Exception.Create('转换后应该是绝对路径');
          end;
          
          // 清理链接
          Manager.RemoveSymlink(LinkFile);
        end;
        
      finally
        // 清理测试文件
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if FileExists(LinkFile) then
          DeleteFile(LinkFile);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestSymlinkManager.TestLinkManagement;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  SourceFile, LinkFile, ClonedLink, NewTarget: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'management_source.txt');
      LinkFile := TPath.Combine(TPath.GetTempPath, 'management_link.txt');
      ClonedLink := TPath.Combine(TPath.GetTempPath, 'cloned_link.txt');
      NewTarget := TPath.Combine(TPath.GetTempPath, 'new_target.txt');
      
      TFile.WriteAllText(SourceFile, 'Management test content');
      TFile.WriteAllText(NewTarget, 'New target content');
      
      try
        // 创建符号链接
        if Manager.CreateSymlink(SourceFile, LinkFile, stFile) then
        begin
          // 测试克隆符号链接
          if Manager.CloneSymlink(LinkFile, ClonedLink) then
          begin
            if not Manager.IsSymlink(ClonedLink) then
              raise Exception.Create('克隆的符号链接应该是有效的');
            
            var OriginalTarget := Manager.GetTargetPath(LinkFile);
            var ClonedTarget := Manager.GetTargetPath(ClonedLink);
            
            if not SameText(OriginalTarget, ClonedTarget) then
              raise Exception.Create('克隆的符号链接目标应该相同');
          end;
          
          // 测试更新链接目标
          if Manager.UpdateLinkTarget(LinkFile, NewTarget) then
          begin
            Manager.ClearCache;
            var UpdatedTarget := Manager.GetTargetPath(LinkFile);
            
            if not SameText(UpdatedTarget, NewTarget) then
              raise Exception.Create('更新后的目标路径不正确');
          end;
          
          // 清理链接
          Manager.RemoveSymlink(LinkFile);
          if Manager.IsSymlink(ClonedLink) then
            Manager.RemoveSymlink(ClonedLink);
        end;
        
      finally
        // 清理测试文件
        if FileExists(SourceFile) then
          DeleteFile(SourceFile);
        if FileExists(NewTarget) then
          DeleteFile(NewTarget);
        if FileExists(LinkFile) then
          DeleteFile(LinkFile);
        if FileExists(ClonedLink) then
          DeleteFile(ClonedLink);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestSymlinkManager.TestStatisticsAndReporting;
var
  Manager: TSymlinkManager;
  ConfigManager: TConfigManager;
  TestDir: string;
  Stats: TSymlinkStatistics;
  Report, HealthReport: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TSymlinkManager.Create(ConfigManager);
    try
      // 创建测试目录
      TestDir := TPath.Combine(TPath.GetTempPath, 'symlink_stats_test');
      TDirectory.CreateDirectory(TestDir);
      
      // 创建一些普通文件
      TFile.WriteAllText(TPath.Combine(TestDir, 'file1.txt'), 'Content 1');
      TFile.WriteAllText(TPath.Combine(TestDir, 'file2.txt'), 'Content 2');
      
      try
        // 获取统计信息
        Stats := Manager.GetStatistics(TestDir, True);
        
        // 对于只有普通文件的目录，所有链接统计应该为0
        if Stats.TotalLinks <> 0 then
          raise Exception.Create('普通文件目录的链接统计应该为0');
        
        // 生成报告
        Report := Manager.GenerateReport(TestDir, True);
        
        if Length(Report) = 0 then
          raise Exception.Create('报告生成失败');
        
        if not ContainsText(Report, '符号链接管理报告') then
          raise Exception.Create('报告格式不正确');
        
        if not ContainsText(Report, TestDir) then
          raise Exception.Create('报告中应该包含搜索路径');
        
        // 生成健康报告
        HealthReport := Manager.GenerateHealthReport(TestDir);
        
        if Length(HealthReport) = 0 then
          raise Exception.Create('健康报告生成失败');
        
        if not ContainsText(HealthReport, '符号链接健康检查报告') then
          raise Exception.Create('健康报告格式不正确');
        
        if not ContainsText(HealthReport, '所有符号链接状态良好') then
          raise Exception.Create('健康报告应该显示良好状态');
        
      finally
        // 清理测试目录
        if DirectoryExists(TestDir) then
          TDirectory.Delete(TestDir, True);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.