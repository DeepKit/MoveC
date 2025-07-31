unit TestMigrationPlanGenerator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  MigrationPlanGenerator;

type
  // 迁移计划生成器测试类
  TTestMigrationPlanGenerator = class
  public
    class procedure RunAllTests;
    class procedure TestBasicPlanGeneration;
    class procedure TestSpaceAnalysis;
    class procedure TestFeasibilityEvaluation;
    class procedure TestPlanOptimization;
    class procedure TestPlanSaveLoad;
    class procedure TestCustomPlanGeneration;
    class procedure TestUtilityMethods;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestMigrationPlanGenerator.RunAllTests;
begin
  try
    ShowMessage('开始运行迁移计划生成器测试...');
    
    TestBasicPlanGeneration;
    ShowMessage('✓ 基础计划生成测试通过');
    
    TestSpaceAnalysis;
    ShowMessage('✓ 空间分析测试通过');
    
    TestFeasibilityEvaluation;
    ShowMessage('✓ 可行性评估测试通过');
    
    TestPlanOptimization;
    ShowMessage('✓ 计划优化测试通过');
    
    TestPlanSaveLoad;
    ShowMessage('✓ 计划保存加载测试通过');
    
    TestCustomPlanGeneration;
    ShowMessage('✓ 自定义计划生成测试通过');
    
    TestUtilityMethods;
    ShowMessage('✓ 工具方法测试通过');
    
    ShowMessage('所有迁移计划生成器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestMigrationPlanGenerator.TestBasicPlanGeneration;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir: string;
  Plan: TMigrationPlan;
  I: Integer;
  FileStream: TFileStream;
begin
  Generator := TMigrationPlanGenerator.Create;
  try
    // 创建测试源目录
    TestSourceDir := TPath.GetTempPath + 'test_migration_source';
    TestTargetDir := TPath.GetTempPath + 'test_migration_target';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    // 创建测试文件
    var TestFiles: TArray<string> := [
      TestSourceDir + '\test1.txt',
      TestSourceDir + '\test2.exe',
      TestSourceDir + '\test3.dll',
      TestSourceDir + '\test4.tmp',
      TestSourceDir + '\test5.log'
    ];
    
    for I := 0 to Length(TestFiles) - 1 do
    begin
      FileStream := TFileStream.Create(TestFiles[I], fmCreate);
      try
        var TestData := TEncoding.UTF8.GetBytes('测试文件内容' + IntToStr(I + 1));
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
    end;
    
    try
      // 生成迁移计划
      Plan := Generator.GenerateMigrationPlan(TestSourceDir, TestTargetDir, '测试计划');
      
      // 验证计划基本信息
      if Plan.PlanName <> '测试计划' then
        raise Exception.Create('计划名称不正确');
      
      if Plan.SourceDirectory <> TestSourceDir then
        raise Exception.Create('源目录不正确');
      
      if Plan.TargetDirectory <> TestTargetDir then
        raise Exception.Create('目标目录不正确');
      
      if Plan.TotalItems <= 0 then
        raise Exception.Create('迁移项目数量应该大于0');
      
      if Plan.TotalSize < 0 then
        raise Exception.Create('总大小不应该为负数');
      
      if Plan.EstimatedDuration < 0 then
        raise Exception.Create('预计时间不应该为负数');
      
      // 验证迁移项目
      if Length(Plan.Items) <> Plan.TotalItems then
        raise Exception.Create('迁移项目数量不匹配');
      
      for var Item in Plan.Items do
      begin
        if Trim(Item.SourcePath) = '' then
          raise Exception.Create('源路径不应该为空');
        
        if Item.FileSize < 0 then
          raise Exception.Create('文件大小不应该为负数');
        
        if Item.EstimatedTime < 0 then
          raise Exception.Create('预计时间不应该为负数');
        
        if Item.RiskLevel < 0 then
          raise Exception.Create('风险级别不应该为负数');
        
        if Item.RiskLevel > 100 then
          raise Exception.Create('风险级别不应该超过100');
      end;
      
      // 验证前置条件、后续操作和回退计划
      if Length(Plan.Prerequisites) = 0 then
        raise Exception.Create('应该有前置条件');
      
      if Length(Plan.PostActions) = 0 then
        raise Exception.Create('应该有后续操作');
      
      if Length(Plan.RollbackPlan) = 0 then
        raise Exception.Create('应该有回退计划');
      
    finally
      // 清理测试文件和目录
      for I := 0 to Length(TestFiles) - 1 do
      begin
        if FileExists(TestFiles[I]) then
          DeleteFile(TestFiles[I]);
      end;
      
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    Generator.Free;
  end;
end;class proce
dure TTestMigrationPlanGenerator.TestSpaceAnalysis;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir: string;
  SpaceAnalysis: TSpaceAnalysisResult;
  FileStream: TFileStream;
begin
  Generator := TMigrationPlanGenerator.Create;
  try
    // 创建测试目录
    TestSourceDir := TPath.GetTempPath + 'test_space_source';
    TestTargetDir := TPath.GetTempPath + 'test_space_target';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    // 创建测试文件
    var TestFile := TestSourceDir + '\space_test.dat';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData: TBytes;
      SetLength(TestData, 1024 * 1024); // 1MB
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 分析空间需求
      SpaceAnalysis := Generator.AnalyzeSpaceRequirements(TestSourceDir, TestTargetDir);
      
      if SpaceAnalysis.SourcePath <> TestSourceDir then
        raise Exception.Create('源路径不正确');
      
      if SpaceAnalysis.TargetPath <> TestTargetDir then
        raise Exception.Create('目标路径不正确');
      
      if SpaceAnalysis.RequiredSpace <= 0 then
        raise Exception.Create('所需空间应该大于0');
      
      if SpaceAnalysis.AvailableSpace < 0 then
        raise Exception.Create('可用空间不应该为负数');
      
      if SpaceAnalysis.SpaceUtilization < 0 then
        raise Exception.Create('空间利用率不应该为负数');
      
      // 测试空间验证
      var IsSpaceSufficient := Generator.ValidateSpaceAvailability(TestTargetDir, 1024);
      // 通常临时目录应该有足够空间
      if not IsSpaceSufficient then
        raise Exception.Create('临时目录应该有足够空间');
      
      // 测试优化建议
      var Suggestions := Generator.GetSpaceOptimizationSuggestions(TestTargetDir);
      if Length(Suggestions) = 0 then
        raise Exception.Create('应该提供优化建议');
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    Generator.Free;
  end;
end;

class procedure TTestMigrationPlanGenerator.TestFeasibilityEvaluation;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir: string;
  Feasibility: TFeasibilityResult;
  Plan: TMigrationPlan;
  FileStream: TFileStream;
begin
  Generator := TMigrationPlanGenerator.Create;
  try
    // 创建测试目录
    TestSourceDir := TPath.GetTempPath + 'test_feasibility_source';
    TestTargetDir := TPath.GetTempPath + 'test_feasibility_target';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    // 创建测试文件
    var TestFile := TestSourceDir + '\feasibility_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('可行性测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 评估可行性
      Feasibility := Generator.EvaluateFeasibility(TestSourceDir, TestTargetDir);
      
      if Feasibility.ConfidenceLevel < 0 then
        raise Exception.Create('信心级别不应该为负数');
      
      if Feasibility.ConfidenceLevel > 100 then
        raise Exception.Create('信心级别不应该超过100');
      
      if Feasibility.EstimatedSuccessRate < 0 then
        raise Exception.Create('预计成功率不应该为负数');
      
      if Feasibility.EstimatedSuccessRate > 100 then
        raise Exception.Create('预计成功率不应该超过100');
      
      // 对于正常的测试目录，应该是可行的
      if not Feasibility.IsFeasible then
        raise Exception.Create('正常测试目录应该是可行的');
      
      // 测试计划验证
      Plan := Generator.GenerateMigrationPlan(TestSourceDir, TestTargetDir);
      var PlanFeasibility := Generator.ValidateMigrationPlan(Plan);
      
      if PlanFeasibility.ConfidenceLevel < 0 then
        raise Exception.Create('计划信心级别不应该为负数');
      
      // 测试成功率估算
      var SuccessRate := Generator.EstimateSuccessRate(Plan);
      if SuccessRate < 0 then
        raise Exception.Create('成功率不应该为负数');
      
      if SuccessRate > 100 then
        raise Exception.Create('成功率不应该超过100');
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    Generator.Free;
  end;
end;

class procedure TTestMigrationPlanGenerator.TestPlanOptimization;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir: string;
  Plan: TMigrationPlan;
  I: Integer;
  FileStream: TFileStream;
  OriginalOrder, OptimizedOrder: TArray<string>;
begin
  Generator := TMigrationPlanGenerator.Create;
  try
    // 创建测试目录
    TestSourceDir := TPath.GetTempPath + 'test_optimization_source';
    TestTargetDir := TPath.GetTempPath + 'test_optimization_target';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    // 创建不同类型的测试文件
    var TestFiles: TArray<string> := [
      TestSourceDir + '\critical.sys',    // 关键系统文件
      TestSourceDir + '\normal.txt',      // 普通文件
      TestSourceDir + '\temp.tmp',        // 临时文件
      TestSourceDir + '\program.exe',     // 程序文件
      TestSourceDir + '\config.ini'       // 配置文件
    ];
    
    for I := 0 to Length(TestFiles) - 1 do
    begin
      FileStream := TFileStream.Create(TestFiles[I], fmCreate);
      try
        var TestData := TEncoding.UTF8.GetBytes('优化测试文件' + IntToStr(I + 1));
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
    end;
    
    try
      // 生成迁移计划
      Plan := Generator.GenerateMigrationPlan(TestSourceDir, TestTargetDir);
      
      if Length(Plan.Items) = 0 then
        raise Exception.Create('计划应该包含迁移项目');
      
      // 验证优化结果
      // 1. 检查阶段分配
      var HasPreparation, HasAnalysis, HasExecution := False, False, False;
      for var Item in Plan.Items do
      begin
        case Item.Phase of
          mpPreparation: HasPreparation := True;
          mpAnalysis: HasAnalysis := True;
          mpExecution: HasExecution := True;
        end;
      end;
      
      // 至少应该有执行阶段
      if not HasExecution then
        raise Exception.Create('计划应该包含执行阶段');
      
      // 2. 检查优先级分配
      var HasCritical, HasHigh, HasNormal := False, False, False;
      for var Item in Plan.Items do
      begin
        case Item.Priority of
          mpCritical: HasCritical := True;
          mpHigh: HasHigh := True;
          mpNormal: HasNormal := True;
        end;
      end;
      
      // 应该有不同的优先级
      if not (HasNormal or HasHigh) then
        raise Exception.Create('计划应该包含不同优先级的项目');
      
      // 3. 检查策略分配
      var HasMove, HasDelete, HasSymLink := False, False, False;
      for var Item in Plan.Items do
      begin
        case Item.Strategy of
          msMove: HasMove := True;
          msDelete: HasDelete := True;
          msSymbolicLink: HasSymLink := True;
        end;
      end;
      
      // 应该有不同的策略
      if not HasMove then
        raise Exception.Create('计划应该包含移动策略');
      
    finally
      // 清理测试文件
      for I := 0 to Length(TestFiles) - 1 do
      begin
        if FileExists(TestFiles[I]) then
          DeleteFile(TestFiles[I]);
      end;
      
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    Generator.Free;
  end;
end;class
 procedure TTestMigrationPlanGenerator.TestPlanSaveLoad;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir, PlanFile: string;
  OriginalPlan, LoadedPlan: TMigrationPlan;
  FileStream: TFileStream;
begin
  Generator := TMigrationPlanGenerator.Create;
  try
    // 创建测试目录
    TestSourceDir := TPath.GetTempPath + 'test_saveload_source';
    TestTargetDir := TPath.GetTempPath + 'test_saveload_target';
    PlanFile := TPath.GetTempPath + 'test_plan.json';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    // 创建测试文件
    var TestFile := TestSourceDir + '\saveload_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('保存加载测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 生成原始计划
      OriginalPlan := Generator.GenerateMigrationPlan(TestSourceDir, TestTargetDir, '保存加载测试计划');
      
      // 保存计划
      if not Generator.SavePlan(OriginalPlan, PlanFile) then
        raise Exception.Create('保存计划失败');
      
      if not FileExists(PlanFile) then
        raise Exception.Create('计划文件未创建');
      
      // 加载计划
      LoadedPlan := Generator.LoadPlan(PlanFile);
      
      // 验证加载的计划
      if LoadedPlan.PlanName <> OriginalPlan.PlanName then
        raise Exception.Create('计划名称不匹配');
      
      if LoadedPlan.SourceDirectory <> OriginalPlan.SourceDirectory then
        raise Exception.Create('源目录不匹配');
      
      if LoadedPlan.TargetDirectory <> OriginalPlan.TargetDirectory then
        raise Exception.Create('目标目录不匹配');
      
      if LoadedPlan.TotalItems <> OriginalPlan.TotalItems then
        raise Exception.Create('项目总数不匹配');
      
      if LoadedPlan.TotalSize <> OriginalPlan.TotalSize then
        raise Exception.Create('总大小不匹配');
      
      if LoadedPlan.EstimatedDuration <> OriginalPlan.EstimatedDuration then
        raise Exception.Create('预计时间不匹配');
      
      if LoadedPlan.RiskAssessment <> OriginalPlan.RiskAssessment then
        raise Exception.Create('风险评估不匹配');
      
      // 验证迁移项目
      if Length(LoadedPlan.Items) <> Length(OriginalPlan.Items) then
        raise Exception.Create('迁移项目数量不匹配');
      
      for var I := 0 to Length(OriginalPlan.Items) - 1 do
      begin
        if LoadedPlan.Items[I].SourcePath <> OriginalPlan.Items[I].SourcePath then
          raise Exception.Create('项目源路径不匹配');
        
        if LoadedPlan.Items[I].TargetPath <> OriginalPlan.Items[I].TargetPath then
          raise Exception.Create('项目目标路径不匹配');
        
        if LoadedPlan.Items[I].FileSize <> OriginalPlan.Items[I].FileSize then
          raise Exception.Create('项目文件大小不匹配');
        
        if LoadedPlan.Items[I].EstimatedTime <> OriginalPlan.Items[I].EstimatedTime then
          raise Exception.Create('项目预计时间不匹配');
        
        if LoadedPlan.Items[I].RequiresReboot <> OriginalPlan.Items[I].RequiresReboot then
          raise Exception.Create('项目重启需求不匹配');
        
        if LoadedPlan.Items[I].RiskLevel <> OriginalPlan.Items[I].RiskLevel then
          raise Exception.Create('项目风险级别不匹配');
        
        if LoadedPlan.Items[I].Description <> OriginalPlan.Items[I].Description then
          raise Exception.Create('项目描述不匹配');
        
        if LoadedPlan.Items[I].BackupRequired <> OriginalPlan.Items[I].BackupRequired then
          raise Exception.Create('项目备份需求不匹配');
        
        if LoadedPlan.Items[I].VerificationMethod <> OriginalPlan.Items[I].VerificationMethod then
          raise Exception.Create('项目验证方法不匹配');
      end;
      
      // 测试加载不存在的文件
      var EmptyPlan := Generator.LoadPlan('NonExistentPlan.json');
      if EmptyPlan.PlanName <> '' then
        raise Exception.Create('不存在的计划文件应该返回空计划');
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if FileExists(PlanFile) then
        DeleteFile(PlanFile);
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    Generator.Free;
  end;
end;

class procedure TTestMigrationPlanGenerator.TestCustomPlanGeneration;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir: string;
  CustomRules: TDictionary<string, TMigrationStrategy>;
  Plan: TMigrationPlan;
  FileStream: TFileStream;
begin
  Generator := TMigrationPlanGenerator.Create;
  CustomRules := TDictionary<string, TMigrationStrategy>.Create;
  try
    // 创建测试目录
    TestSourceDir := TPath.GetTempPath + 'test_custom_source';
    TestTargetDir := TPath.GetTempPath + 'test_custom_target';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    // 创建测试文件
    var TestFile := TestSourceDir + '\custom_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('自定义规则测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      // 设置自定义规则
      CustomRules.Add('*.txt', msCopy);
      CustomRules.Add('*.exe', msSymbolicLink);
      
      // 生成自定义计划
      Plan := Generator.GenerateCustomPlan(TestSourceDir, TestTargetDir, CustomRules);
      
      if Plan.TotalItems <= 0 then
        raise Exception.Create('自定义计划应该包含项目');
      
      if Trim(Plan.SourceDirectory) = '' then
        raise Exception.Create('自定义计划应该有源目录');
      
      if Trim(Plan.TargetDirectory) = '' then
        raise Exception.Create('自定义计划应该有目标目录');
      
      // 验证计划内容
      if Length(Plan.Items) = 0 then
        raise Exception.Create('自定义计划应该包含迁移项目');
      
      for var Item in Plan.Items do
      begin
        if Trim(Item.SourcePath) = '' then
          raise Exception.Create('迁移项目应该有源路径');
        
        if Item.FileSize < 0 then
          raise Exception.Create('文件大小不应该为负数');
        
        if Item.RiskLevel < 0 then
          raise Exception.Create('风险级别不应该为负数');
      end;
      
    finally
      // 清理测试文件
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    CustomRules.Free;
    Generator.Free;
  end;
end;

class procedure TTestMigrationPlanGenerator.TestUtilityMethods;
var
  Generator: TMigrationPlanGenerator;
  TestSourceDir, TestTargetDir: string;
  Plan1, Plan2: TMigrationPlan;
  Comparison: string;
  FileStream: TFileStream;
begin
  Generator := TMigrationPlanGenerator.Create;
  try
    // 测试策略转换
    if TMigrationPlanGenerator.StrategyToString(msMove) <> '移动' then
      raise Exception.Create('移动策略转换错误');
    
    if TMigrationPlanGenerator.StrategyToString(msCopy) <> '复制' then
      raise Exception.Create('复制策略转换错误');
    
    if TMigrationPlanGenerator.StrategyToString(msSymbolicLink) <> '符号链接' then
      raise Exception.Create('符号链接策略转换错误');
    
    if TMigrationPlanGenerator.StrategyToString(msHardLink) <> '硬链接' then
      raise Exception.Create('硬链接策略转换错误');
    
    if TMigrationPlanGenerator.StrategyToString(msSkip) <> '跳过' then
      raise Exception.Create('跳过策略转换错误');
    
    if TMigrationPlanGenerator.StrategyToString(msDelete) <> '删除' then
      raise Exception.Create('删除策略转换错误');
    
    // 测试优先级转换
    if TMigrationPlanGenerator.PriorityToString(mpLow) <> '低' then
      raise Exception.Create('低优先级转换错误');
    
    if TMigrationPlanGenerator.PriorityToString(mpNormal) <> '普通' then
      raise Exception.Create('普通优先级转换错误');
    
    if TMigrationPlanGenerator.PriorityToString(mpHigh) <> '高' then
      raise Exception.Create('高优先级转换错误');
    
    if TMigrationPlanGenerator.PriorityToString(mpCritical) <> '关键' then
      raise Exception.Create('关键优先级转换错误');
    
    // 测试阶段转换
    if TMigrationPlanGenerator.PhaseToString(mpPreparation) <> '准备阶段' then
      raise Exception.Create('准备阶段转换错误');
    
    if TMigrationPlanGenerator.PhaseToString(mpAnalysis) <> '分析阶段' then
      raise Exception.Create('分析阶段转换错误');
    
    if TMigrationPlanGenerator.PhaseToString(mpExecution) <> '执行阶段' then
      raise Exception.Create('执行阶段转换错误');
    
    if TMigrationPlanGenerator.PhaseToString(mpVerification) <> '验证阶段' then
      raise Exception.Create('验证阶段转换错误');
    
    if TMigrationPlanGenerator.PhaseToString(mpCleanup) <> '清理阶段' then
      raise Exception.Create('清理阶段转换错误');
    
    // 测试文件大小格式化
    if not ContainsText(TMigrationPlanGenerator.FormatFileSize(1024), 'KB') then
      raise Exception.Create('文件大小格式化错误');
    
    if not ContainsText(TMigrationPlanGenerator.FormatFileSize(1024 * 1024), 'MB') then
      raise Exception.Create('文件大小格式化错误');
    
    if not ContainsText(TMigrationPlanGenerator.FormatFileSize(1024 * 1024 * 1024), 'GB') then
      raise Exception.Create('文件大小格式化错误');
    
    // 测试时间格式化
    if not ContainsText(TMigrationPlanGenerator.FormatDuration(60), '分钟') then
      raise Exception.Create('时间格式化错误');
    
    if not ContainsText(TMigrationPlanGenerator.FormatDuration(3600), '小时') then
      raise Exception.Create('时间格式化错误');
    
    if not ContainsText(TMigrationPlanGenerator.FormatDuration(30), '秒') then
      raise Exception.Create('时间格式化错误');
    
    // 测试计划比较
    TestSourceDir := TPath.GetTempPath + 'test_compare_source';
    TestTargetDir := TPath.GetTempPath + 'test_compare_target';
    
    ForceDirectories(TestSourceDir);
    ForceDirectories(TestTargetDir);
    
    var TestFile := TestSourceDir + '\compare_test.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('比较测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Plan1 := Generator.GenerateMigrationPlan(TestSourceDir, TestTargetDir, '计划1');
      Plan2 := Generator.GenerateMigrationPlan(TestSourceDir, TestTargetDir, '计划2');
      
      Comparison := Generator.ComparePlans(Plan1, Plan2);
      
      if Trim(Comparison) = '' then
        raise Exception.Create('计划比较结果不应该为空');
      
      if not ContainsText(Comparison, '计划1') then
        raise Exception.Create('比较结果应该包含计划1');
      
      if not ContainsText(Comparison, '计划2') then
        raise Exception.Create('比较结果应该包含计划2');
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
      if DirectoryExists(TestSourceDir) then
        TDirectory.Delete(TestSourceDir, True);
      if DirectoryExists(TestTargetDir) then
        TDirectory.Delete(TestTargetDir, True);
    end;
    
  finally
    Generator.Free;
  end;
end;

end.