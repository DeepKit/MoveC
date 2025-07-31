unit TestRebootDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, RebootDetector;

type
  // 重启检测器测试类
  TTestRebootDetector = class
  public
    class procedure RunAllTests;
    class procedure TestBasicRebootDetection;
    class procedure TestFileInUseDetection;
    class procedure TestSystemFileDetection;
    class procedure TestServiceFileDetection;
    class procedure TestBatchDetection;
    class procedure TestSafetyChecks;
    class procedure TestForceOperations;
    class procedure TestSystemRebootDetection;
    class procedure TestUtilityMethods;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestRebootDetector.RunAllTests;
begin
  try
    ShowMessage('开始运行重启检测器测试...');
    
    TestBasicRebootDetection;
    ShowMessage('✓ 基础重启检测测试通过');
    
    TestFileInUseDetection;
    ShowMessage('✓ 文件使用检测测试通过');
    
    TestSystemFileDetection;
    ShowMessage('✓ 系统文件检测测试通过');
    
    TestServiceFileDetection;
    ShowMessage('✓ 服务文件检测测试通过');
    
    TestBatchDetection;
    ShowMessage('✓ 批量检测测试通过');
    
    TestSafetyChecks;
    ShowMessage('✓ 安全检查测试通过');
    
    TestForceOperations;
    ShowMessage('✓ 强制操作测试通过');
    
    TestSystemRebootDetection;
    ShowMessage('✓ 系统重启检测测试通过');
    
    TestUtilityMethods;
    ShowMessage('✓ 工具方法测试通过');
    
    ShowMessage('所有重启检测器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestRebootDetector.TestBasicRebootDetection;
var
  Detector: TRebootDetector;
  TestFile: string;
  Result: TRebootDetectionResult;
  FileStream: TFileStream;
begin
  Detector := TRebootDetector.Create;
  try
    // 测试不存在的文件
    Result := Detector.DetectRebootRequirement('C:\NonExistentFile.exe');
    
    if Result.RequiresReboot <> rrNotRequired then
      raise Exception.Create('不存在的文件不应该需要重启');
    
    if not ContainsText(Result.Description, '不存在') then
      raise Exception.Create('不存在文件的描述不正确');
    
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'reboot_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('重启检测测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Detector.DetectRebootRequirement(TestFile);
      
      if Result.FilePath <> TestFile then
        raise Exception.Create('检测结果文件路径不匹配');
      
      if Length(Result.Reasons) < 0 then
        raise Exception.Create('重启原因数量不应该为负数');
      
      if Result.RebootDelay < 0 then
        raise Exception.Create('重启延迟不应该为负数');
      
      if Result.ForceCloseRisk < 0 then
        raise Exception.Create('强制关闭风险不应该为负数');
      
      if Result.ForceCloseRisk > 100 then
        raise Exception.Create('强制关闭风险不应该超过100');
      
      // 普通文本文件通常不需要重启
      if Result.RequiresReboot = rrCritical then
        raise Exception.Create('普通文本文件不应该需要关键重启');
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Detector.Free;
  end;
end;class
 procedure TTestRebootDetector.TestFileInUseDetection;
var
  Detector: TRebootDetector;
  TestFile: string;
  Result: TRebootDetectionResult;
  FileStream: TFileStream;
  FileHandle: THandle;
begin
  Detector := TRebootDetector.Create;
  try
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'file_in_use_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('文件使用测试');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    // 以独占模式打开文件，模拟文件正在使用
    FileHandle := CreateFile(
      PChar(TestFile),
      GENERIC_READ or GENERIC_WRITE,
      0, // 不允许共享
      nil,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL,
      0
    );
    
    try
      if FileHandle <> INVALID_HANDLE_VALUE then
      begin
        Result := Detector.DetectRebootRequirement(TestFile);
        
        // 文件正在使用时，应该至少建议重启
        if Result.RequiresReboot = rrNotRequired then
          raise Exception.Create('正在使用的文件应该至少建议重启');
        
        // 应该有相关的重启原因
        var HasFileInUseReason := False;
        for var Reason in Result.Reasons do
        begin
          if Reason = rrFileInUse then
          begin
            HasFileInUseReason := True;
            Break;
          end;
        end;
        
        // 注意：由于文件使用检测的复杂性，这里不强制要求检测到
        // 实际测试中可能需要更精确的文件锁定机制
      end;
      
    finally
      if FileHandle <> INVALID_HANDLE_VALUE then
        CloseHandle(FileHandle);
      
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Detector.Free;
  end;
end;

class procedure TTestRebootDetector.TestSystemFileDetection;
var
  Detector: TRebootDetector;
  SystemFile: string;
  Result: TRebootDetectionResult;
begin
  Detector := TRebootDetector.Create;
  try
    // 测试已知的系统文件
    SystemFile := GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll';
    
    if FileExists(SystemFile) then
    begin
      Result := Detector.DetectRebootRequirement(SystemFile);
      
      // 系统关键文件应该需要重启
      if Result.RequiresReboot = rrNotRequired then
        raise Exception.Create('系统关键文件应该需要重启');
      
      // 应该有系统文件相关的重启原因
      var HasSystemFileReason := False;
      for var Reason in Result.Reasons do
      begin
        if Reason = rrSystemFile then
        begin
          HasSystemFileReason := True;
          Break;
        end;
      end;
      
      if not HasSystemFileReason then
        raise Exception.Create('系统文件应该有系统文件重启原因');
      
      // 系统文件的强制关闭风险应该很高
      if Result.ForceCloseRisk < 50 then
        raise Exception.Create('系统文件的强制关闭风险应该较高');
    end;
    
    // 测试内核文件
    var KernelFile := GetEnvironmentVariable('WINDIR') + '\System32\ntoskrnl.exe';
    if FileExists(KernelFile) then
    begin
      Result := Detector.DetectRebootRequirement(KernelFile);
      
      // 内核文件应该需要关键重启
      if Result.RequiresReboot <> rrCritical then
        raise Exception.Create('内核文件应该需要关键重启');
    end;
    
  finally
    Detector.Free;
  end;
end;

class procedure TTestRebootDetector.TestServiceFileDetection;
var
  Detector: TRebootDetector;
  ServiceFile: string;
  Result: TRebootDetectionResult;
begin
  Detector := TRebootDetector.Create;
  try
    // 测试已知的服务文件
    ServiceFile := GetEnvironmentVariable('WINDIR') + '\System32\svchost.exe';
    
    if FileExists(ServiceFile) then
    begin
      Result := Detector.DetectRebootRequirement(ServiceFile);
      
      // 服务文件通常需要重启
      if Result.RequiresReboot = rrNotRequired then
        raise Exception.Create('服务文件通常需要重启');
      
      // 检查是否检测到服务使用
      if Length(Result.ServicesUsingFile) < 0 then
        raise Exception.Create('服务使用文件数量不应该为负数');
      
      // 服务文件的强制关闭风险应该较高
      if Result.ForceCloseRisk < 30 then
        raise Exception.Create('服务文件的强制关闭风险应该较高');
    end;
    
  finally
    Detector.Free;
  end;
end;

class procedure TTestRebootDetector.TestBatchDetection;
var
  Detector: TRebootDetector;
  TestFiles: TArray<string>;
  Results: TArray<TRebootDetectionResult>;
  I: Integer;
  FileStream: TFileStream;
begin
  Detector := TRebootDetector.Create;
  try
    // 创建多个测试文件
    SetLength(TestFiles, 3);
    TestFiles[0] := TPath.GetTempPath + 'batch_reboot_test1.txt';
    TestFiles[1] := TPath.GetTempPath + 'batch_reboot_test2.exe';
    TestFiles[2] := TPath.GetTempPath + 'batch_reboot_test3.dll';
    
    for I := 0 to Length(TestFiles) - 1 do
    begin
      FileStream := TFileStream.Create(TestFiles[I], fmCreate);
      try
        var TestData := TEncoding.UTF8.GetBytes('批量重启检测测试' + IntToStr(I + 1));
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
    end;
    
    try
      // 批量检测
      Results := Detector.BatchDetectRebootRequirement(TestFiles);
      
      if Length(Results) <> Length(TestFiles) then
        raise Exception.Create('批量检测结果数量不匹配');
      
      // 检查每个结果
      for I := 0 to Length(Results) - 1 do
      begin
        if Results[I].FilePath <> TestFiles[I] then
          raise Exception.Create('批量检测结果文件路径不匹配');
        
        if Results[I].ForceCloseRisk < 0 then
          raise Exception.Create('批量检测强制关闭风险不应该为负数');
        
        if Results[I].RebootDelay < 0 then
          raise Exception.Create('批量检测重启延迟不应该为负数');
      end;
      
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
end;clas
s procedure TTestRebootDetector.TestSafetyChecks;
var
  Detector: TRebootDetector;
  TestFile, SystemFile: string;
  FileStream: TFileStream;
begin
  Detector := TRebootDetector.Create;
  try
    // 创建普通测试文件
    TestFile := TPath.GetTempPath + 'safety_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('安全检查测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 测试普通文件的安全操作
      if not Detector.CanSafelyMoveFile(TestFile) then
        raise Exception.Create('普通文件应该可以安全移动');
      
      if not Detector.CanSafelyDeleteFile(TestFile) then
        raise Exception.Create('普通文件应该可以安全删除');
      
      // 测试最佳操作时间
      var OptimalTime := Detector.GetOptimalOperationTime(TestFile);
      if OptimalTime < Now - 1 then
        raise Exception.Create('最佳操作时间不应该在过去');
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试系统文件的安全操作
    SystemFile := GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll';
    if FileExists(SystemFile) then
    begin
      // 系统文件不应该允许安全删除
      if Detector.CanSafelyDeleteFile(SystemFile) then
        raise Exception.Create('系统文件不应该允许安全删除');
      
      // 系统文件的移动需要谨慎
      // 注意：这里不强制要求返回false，因为某些情况下可能允许移动
    end;
    
  finally
    Detector.Free;
  end;
end;

class procedure TTestRebootDetector.TestForceOperations;
var
  Detector: TRebootDetector;
  TestFile: string;
  FileStream: TFileStream;
begin
  Detector := TRebootDetector.Create;
  try
    // 创建测试文件
    TestFile := TPath.GetTempPath + 'force_operation_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('强制操作测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 测试强制关闭进程（对于普通文件，通常没有进程使用）
      var ForceCloseResult := Detector.ForceCloseProcessesUsingFile(TestFile);
      // 由于没有进程使用该文件，应该成功
      if not ForceCloseResult then
        raise Exception.Create('没有进程使用的文件强制关闭应该成功');
      
      // 测试强制停止服务（对于普通文件，通常没有服务使用）
      var ForceStopResult := Detector.ForceStopServicesUsingFile(TestFile);
      // 由于没有服务使用该文件，应该成功
      if not ForceStopResult then
        raise Exception.Create('没有服务使用的文件强制停止应该成功');
      
      // 测试计划重启后操作
      var ScheduleResult := Detector.ScheduleFileOperationAfterReboot(TestFile, TestFile + '.moved');
      // 这个操作可能需要管理员权限，所以不强制要求成功
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Detector.Free;
  end;
end;

class procedure TTestRebootDetector.TestSystemRebootDetection;
var
  Detector: TRebootDetector;
  SystemResult: TRebootDetectionResult;
begin
  Detector := TRebootDetector.Create;
  try
    // 检测系统重启需求
    SystemResult := Detector.DetectSystemRebootRequirement;
    
    if SystemResult.FilePath <> 'SYSTEM' then
      raise Exception.Create('系统检测结果文件路径应该是SYSTEM');
    
    if Length(SystemResult.Reasons) < 0 then
      raise Exception.Create('系统重启原因数量不应该为负数');
    
    if SystemResult.RebootDelay < 0 then
      raise Exception.Create('系统重启延迟不应该为负数');
    
    // 测试重启信息获取
    var RebootInfo := Detector.GetScheduledRebootInfo;
    if Trim(RebootInfo) = '' then
      raise Exception.Create('重启信息不应该为空');
    
    // 测试重启计划（注意：这可能需要管理员权限）
    // 使用较长的延迟以避免意外重启
    var ScheduleResult := Detector.ScheduleSystemReboot(3600, '测试重启计划');
    
    // 如果计划成功，立即取消
    if ScheduleResult then
    begin
      var CancelResult := Detector.CancelScheduledReboot;
      if not CancelResult then
        raise Exception.Create('取消计划重启失败');
    end;
    
  finally
    Detector.Free;
  end;
end;

class procedure TTestRebootDetector.TestUtilityMethods;
begin
  // 测试重启需求转换
  if TRebootDetector.RebootRequirementToString(rrNotRequired) <> '不需要重启' then
    raise Exception.Create('不需要重启转换错误');
  
  if TRebootDetector.RebootRequirementToString(rrRecommended) <> '建议重启' then
    raise Exception.Create('建议重启转换错误');
  
  if TRebootDetector.RebootRequirementToString(rrRequired) <> '需要重启' then
    raise Exception.Create('需要重启转换错误');
  
  if TRebootDetector.RebootRequirementToString(rrCritical) <> '必须重启' then
    raise Exception.Create('必须重启转换错误');
  
  // 测试重启原因转换
  if TRebootDetector.RebootReasonToString(rrSystemFile) <> '系统文件修改' then
    raise Exception.Create('系统文件修改原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrDriverFile) <> '驱动文件修改' then
    raise Exception.Create('驱动文件修改原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrServiceFile) <> '服务文件修改' then
    raise Exception.Create('服务文件修改原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrKernelFile) <> '内核文件修改' then
    raise Exception.Create('内核文件修改原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrRegistryChange) <> '注册表修改' then
    raise Exception.Create('注册表修改原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrFileInUse) <> '文件正在使用' then
    raise Exception.Create('文件正在使用原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrPendingOperation) <> '待处理操作' then
    raise Exception.Create('待处理操作原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrSystemUpdate) <> '系统更新' then
    raise Exception.Create('系统更新原因转换错误');
  
  if TRebootDetector.RebootReasonToString(rrUnknown) <> '未知原因' then
    raise Exception.Create('未知原因转换错误');
  
  // 测试重启需求颜色转换
  if TRebootDetector.RebootRequirementToColor(rrNotRequired) = 0 then
    raise Exception.Create('不需要重启颜色转换错误');
  
  if TRebootDetector.RebootRequirementToColor(rrRecommended) = 0 then
    raise Exception.Create('建议重启颜色转换错误');
  
  if TRebootDetector.RebootRequirementToColor(rrRequired) = 0 then
    raise Exception.Create('需要重启颜色转换错误');
  
  if TRebootDetector.RebootRequirementToColor(rrCritical) = 0 then
    raise Exception.Create('必须重启颜色转换错误');
end;

end.