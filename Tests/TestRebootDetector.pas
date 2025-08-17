unit TestRebootDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, RebootDetector, ConfigManager;

type
  // 重启检测器测试类
  TTestRebootDetector = class
  public
    class procedure RunAllTests;
    class procedure TestSystemFileDetection;
    class procedure TestServiceDependencyDetection;
    class procedure TestDriverDependencyDetection;
    class procedure TestProcessDependencyDetection;
    class procedure TestLibraryDependencyDetection;
    class procedure TestRegistryDependencyDetection;
    class procedure TestBatchDetection;
    class procedure TestRebootRequirementLevels;
    class procedure TestSystemStatusChecks;
    class procedure TestRebootPreparation;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestRebootDetector.RunAllTests;
begin
  try
    ShowMessage('开始运行重启检测器测试...');
    
    TestSystemFileDetection;
    ShowMessage('✓ 系统文件检测测试通过');
    
    TestServiceDependencyDetection;
    ShowMessage('✓ 服务依赖检测测试通过');
    
    TestDriverDependencyDetection;
    ShowMessage('✓ 驱动依赖检测测试通过');
    
    TestProcessDependencyDetection;
    ShowMessage('✓ 进程依赖检测测试通过');
    
    TestLibraryDependencyDetection;
    ShowMessage('✓ 库依赖检测测试通过');
    
    TestRegistryDependencyDetection;
    ShowMessage('✓ 注册表依赖检测测试通过');
    
    TestBatchDetection;
    ShowMessage('✓ 批量检测测试通过');
    
    TestRebootRequirementLevels;
    ShowMessage('✓ 重启需求级别测试通过');
    
    TestSystemStatusChecks;
    ShowMessage('✓ 系统状态检查测试通过');
    
    TestRebootPreparation;
    ShowMessage('✓ 重启准备测试通过');
    
    ShowMessage('所有重启检测器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestRebootDetector.TestSystemFileDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TRebootDetectionResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试系统文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll';
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        if not Result.RequiresReboot then
          raise Exception.Create('系统文件应该需要重启');
        
        if Result.RebootRequirement <> rrCritical then
          raise Exception.Create('系统文件应该是严重级别重启需求');
        
        if Result.CanDelayReboot then
          raise Exception.Create('系统文件不应该允许延迟重启');
      end;
      
      // 测试普通文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_normal_file.txt');
      TFile.WriteAllText(TestFile, 'test content');
      try
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 普通文件通常不需要重启
        if Result.RequiresReboot and (Result.RebootRequirement = rrCritical) then
          raise Exception.Create('普通文件不应该需要严重级别重启');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestServiceDependencyDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TRebootDetectionResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试系统服务文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\svchost.exe';
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        if not Result.RequiresReboot then
          raise Exception.Create('系统服务文件应该需要重启');
        
        // 检查是否检测到服务依赖
        var HasServiceReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtService then
          begin
            HasServiceReason := True;
            Break;
          end;
        end;
        
        if not HasServiceReason then
          raise Exception.Create('未检测到服务依赖');
      end;
      
      // 测试普通可执行文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_service.exe');
      TFile.WriteAllText(TestFile, 'test service content');
      try
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 普通文件不应该有服务依赖
        var HasServiceReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtService then
          begin
            HasServiceReason := True;
            Break;
          end;
        end;
        
        if HasServiceReason then
          raise Exception.Create('普通文件不应该有服务依赖');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestDriverDependencyDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TRebootDetectionResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试系统驱动文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\drivers\ntfs.sys';
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        if not Result.RequiresReboot then
          raise Exception.Create('系统驱动文件应该需要重启');
        
        if Result.RebootRequirement <> rrCritical then
          raise Exception.Create('系统驱动应该是严重级别重启需求');
        
        // 检查是否检测到驱动依赖
        var HasDriverReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtDriver then
          begin
            HasDriverReason := True;
            Break;
          end;
        end;
        
        if not HasDriverReason then
          raise Exception.Create('未检测到驱动依赖');
      end;
      
      // 测试普通sys文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_driver.sys');
      TFile.WriteAllText(TestFile, 'test driver content');
      try
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 在临时目录的sys文件可能需要重启，但不是严重级别
        if Result.RequiresReboot and (Result.RebootRequirement = rrCritical) then
          raise Exception.Create('临时目录的驱动文件不应该是严重级别');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestProcessDependencyDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TRebootDetectionResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试当前运行的程序
      TestFile := Application.ExeName;
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        if not Result.RequiresReboot then
          raise Exception.Create('正在运行的程序应该需要重启');
        
        // 检查是否检测到进程依赖
        var HasProcessReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtProcess then
          begin
            HasProcessReason := True;
            Break;
          end;
        end;
        
        if not HasProcessReason then
          raise Exception.Create('未检测到进程依赖');
      end;
      
      // 测试系统进程
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\csrss.exe';
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        if not Result.RequiresReboot then
          raise Exception.Create('系统进程应该需要重启');
        
        if Result.RebootRequirement <> rrCritical then
          raise Exception.Create('系统进程应该是严重级别重启需求');
      end;
      
      // 测试不存在的进程
      TestFile := TPath.Combine(TPath.GetTempPath, 'non_running_process.exe');
      TFile.WriteAllText(TestFile, 'test process content');
      try
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 未运行的进程不应该有进程依赖
        var HasProcessReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtProcess then
          begin
            HasProcessReason := True;
            Break;
          end;
        end;
        
        if HasProcessReason then
          raise Exception.Create('未运行的进程不应该有进程依赖');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestLibraryDependencyDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TRebootDetectionResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试系统库文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\user32.dll';
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        if not Result.RequiresReboot then
          raise Exception.Create('系统库文件应该需要重启');
        
        if Result.RebootRequirement <> rrCritical then
          raise Exception.Create('系统库应该是严重级别重启需求');
        
        // 检查是否检测到库依赖
        var HasLibraryReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtLibrary then
          begin
            HasLibraryReason := True;
            Break;
          end;
        end;
        
        if not HasLibraryReason then
          raise Exception.Create('未检测到库依赖');
      end;
      
      // 测试普通DLL文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_library.dll');
      TFile.WriteAllText(TestFile, 'test library content');
      try
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 普通DLL文件可能需要重启，但不是严重级别
        if Result.RequiresReboot and (Result.RebootRequirement = rrCritical) then
          raise Exception.Create('普通DLL文件不应该是严重级别');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestRegistryDependencyDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TRebootDetectionResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试可能有注册表依赖的文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\notepad.exe';
      if FileExists(TestFile) then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 记事本可能有注册表依赖，但这不是必须的
        // 只检查检测过程不出错
        if Length(Result.Recommendations) = 0 then
          raise Exception.Create('应该有重启建议');
      end;
      
      // 测试普通文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_registry.exe');
      TFile.WriteAllText(TestFile, 'test registry content');
      try
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 普通文件通常没有注册表依赖
        var HasRegistryReason := False;
        for var I := 0 to Length(Result.Reasons) - 1 do
        begin
          if Result.Reasons[I].ReasonType = rrtRegistry then
          begin
            HasRegistryReason := True;
            Break;
          end;
        end;
        
        if HasRegistryReason then
          raise Exception.Create('普通文件不应该有注册表依赖');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestBatchDetection;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFiles: TArray<string>;
  Results: TArray<TRebootDetectionResult>;
  I: Integer;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 创建测试文件
      SetLength(TestFiles, 3);
      TestFiles[0] := TPath.Combine(TPath.GetTempPath, 'batch_test1.exe');
      TestFiles[1] := TPath.Combine(TPath.GetTempPath, 'batch_test2.dll');
      TestFiles[2] := TPath.Combine(TPath.GetTempPath, 'batch_test3.sys');
      
      for I := 0 to Length(TestFiles) - 1 do
        TFile.WriteAllText(TestFiles[I], 'batch test content ' + IntToStr(I));
      
      try
        // 批量检测
        Results := Detector.BatchDetectRebootRequirement(TestFiles);
        
        if Length(Results) <> Length(TestFiles) then
          raise Exception.Create('批量检测结果数量不匹配');
        
        for I := 0 to Length(Results) - 1 do
        begin
          if Results[I].FilePath <> TestFiles[I] then
            raise Exception.Create('批量检测结果路径不匹配');
        end;
        
        // 测试统计功能
        var Stats := Detector.GetRebootStatistics(Results);
        if Length(Stats) = 0 then
          raise Exception.Create('重启统计生成失败');
        
        // 测试报告生成
        var Report := Detector.GenerateRebootReport(Results);
        if Length(Report) = 0 then
          raise Exception.Create('重启报告生成失败');
        
      finally
        // 清理测试文件
        for I := 0 to Length(TestFiles) - 1 do
        begin
          if FileExists(TestFiles[I]) then
            DeleteFile(TestFiles[I]);
        end;
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestRebootRequirementLevels;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  RequirementLevel: TRebootRequirement;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试系统文件的重启需求级别
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll';
      if FileExists(TestFile) then
      begin
        if not Detector.RequiresReboot(TestFile) then
          raise Exception.Create('系统文件应该需要重启');
        
        RequirementLevel := Detector.GetRebootRequirementLevel(TestFile);
        if RequirementLevel <> rrCritical then
          raise Exception.Create('系统文件应该是严重级别重启需求');
        
        if Detector.CanDelayReboot(TestFile) then
          raise Exception.Create('系统文件不应该允许延迟重启');
        
        var DelayHours := Detector.GetMaxDelayHours(TestFile);
        if DelayHours > 0 then
          raise Exception.Create('系统文件不应该有延迟时间');
      end;
      
      // 测试普通文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_requirement.txt');
      TFile.WriteAllText(TestFile, 'test content');
      try
        RequirementLevel := Detector.GetRebootRequirementLevel(TestFile);
        
        // 普通文件通常不需要重启或只是建议重启
        if RequirementLevel = rrCritical then
          raise Exception.Create('普通文件不应该是严重级别重启需求');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestSystemStatusChecks;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  SystemFiles, RunningServices, LoadedDrivers, CriticalProcesses: TArray<string>;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 检查系统文件使用情况
      SystemFiles := Detector.CheckSystemFileUsage;
      // 系统文件检查应该返回结果（可能为空）
      if Length(SystemFiles) < 0 then
        raise Exception.Create('系统文件检查结果异常');
      
      // 检查运行中的服务
      RunningServices := Detector.CheckRunningServices;
      if Length(RunningServices) = 0 then
        raise Exception.Create('应该有运行中的系统服务');
      
      // 检查加载的驱动
      LoadedDrivers := Detector.CheckLoadedDrivers;
      if Length(LoadedDrivers) = 0 then
        raise Exception.Create('应该有已知的系统驱动');
      
      // 检查关键进程
      CriticalProcesses := Detector.CheckCriticalProcesses;
      if Length(CriticalProcesses) = 0 then
        raise Exception.Create('应该有运行中的关键进程');
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestRebootDetector.TestRebootPreparation;
var
  Detector: TRebootDetector;
  ConfigManager: TConfigManager;
  TestFile: string;
  PreActions, PostActions: TArray<string>;
  PrepareResult: Boolean;
begin
  ConfigManager := TConfigManager.Create;
  try
    Detector := TRebootDetector.Create(ConfigManager);
    try
      // 测试重启准备
      PrepareResult := Detector.PrepareForReboot;
      if not PrepareResult then
        raise Exception.Create('重启准备应该成功');
      
      // 测试重启前操作
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\notepad.exe';
      if FileExists(TestFile) then
      begin
        PreActions := Detector.GetPreRebootActions(TestFile);
        if Length(PreActions) = 0 then
          raise Exception.Create('应该有重启前操作建议');
        
        PostActions := Detector.GetPostRebootActions(TestFile);
        if Length(PostActions) = 0 then
          raise Exception.Create('应该有重启后操作建议');
      end;
      
      // 测试普通文件的操作建议
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_preparation.txt');
      TFile.WriteAllText(TestFile, 'test content');
      try
        PreActions := Detector.GetPreRebootActions(TestFile);
        if Length(PreActions) = 0 then
          raise Exception.Create('应该有重启前操作建议');
        
        PostActions := Detector.GetPostRebootActions(TestFile);
        if Length(PostActions) = 0 then
          raise Exception.Create('应该有重启后操作建议');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Detector.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.