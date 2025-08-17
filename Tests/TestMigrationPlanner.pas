unit TestMigrationPlanner;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, MigrationPlanner, ConfigManager;

type
  // 迁移计划生成器测试类
  TTestMigrationPlanner = class
  public
    class procedure RunAllTests;
    class procedure TestPlanCreation;
    class procedure TestPlanValidation;
    class procedure TestPlanOptimization;
    class procedure TestPlanSaveLoad;
    class procedure TestPathConfiguration;
    class procedure TestRiskAssessment;
    class procedure TestReportGeneration;
    class procedure TestPlanComparison;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestMigrationPlanner.RunAllTests;
begin
  try
    ShowMessage('开始运行迁移计划生成器测试...');
    
    TestPlanCreation;
    ShowMessage('✓ 计划创建测试通过');
    
    TestPlanValidation;
    ShowMessage('✓ 计划验证测试通过');
    
    TestPlanOptimization;
    ShowMessage('✓ 计划优化测试通过');
    
    TestPlanSaveLoad;
    ShowMessage('✓ 计划保存加载测试通过');
    
    TestPathConfiguration;
    ShowMessage('✓ 路径配置测试通过');
    
    TestRiskAssessment;
    ShowMessage('✓ 风险评估测试通过');
    
    TestReportGeneration;
    ShowMessage('✓ 报告生成测试通过');
    
    TestPlanComparison;
    ShowMessage('✓ 计划比较测试通过');
    
    ShowMessage('所有迁移计划生成器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestMigrationPlanner.TestPlanCreation;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  TestPaths: TArray<string>;
  Plan: TMigrationPlan;
  TestDir1, TestDir2: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建测试目录
      TestDir1 := TPath.Combine(TPath.GetTempPath, 'test_migration_1');
      TestDir2 := TPath.Combine(TPath.GetTempPath, 'test_migration_2');
      
      TDirectory.CreateDirectory(TestDir1);
      TDirectory.CreateDirectory(TestDir2);
      
      // 创建测试文件
      TFile.WriteAllText(TPath.Combine(TestDir1, 'test1.txt'), 'test content 1');
      TFile.WriteAllText(TPath.Combine(TestDir2, 'test2.txt'), 'test content 2');
      
      try
        SetLength(TestPaths, 2);
        TestPaths[0] := TestDir1;
        TestPaths[1] := TestDir2;
        
        // 创建迁移计划
        Plan := Planner.CreateMigrationPlan('C:', 'D:', TestPaths);
        
        if Plan.TotalItems <> 2 then
          raise Exception.Create('迁移项目数量不正确');
        
        if Length(Plan.PlanId) = 0 then
          raise Exception.Create('计划ID未生成');
        
        if Plan.TotalSize <= 0 then
          raise Exception.Create('总大小计算错误');
        
        if Plan.EstimatedDuration < 0 then
          raise Exception.Create('预估时间计算错误');
        
        if Length(Plan.Prerequisites) = 0 then
          raise Exception.Create('先决条件未生成');
        
        if Length(Plan.PostActions) = 0 then
          raise Exception.Create('后续操作未生成');
        
        if Length(Plan.RollbackPlan) = 0 then
          raise Exception.Create('回退计划未生成');
        
      finally
        // 清理测试目录
        if TDirectory.Exists(TestDir1) then
          TDirectory.Delete(TestDir1, True);
        if TDirectory.Exists(TestDir2) then
          TDirectory.Delete(TestDir2, True);
      end;
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMigrationPlanner.TestPlanValidation;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  Plan: TMigrationPlan;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建一个有效的计划
      FillChar(Plan, SizeOf(Plan), 0);
      Plan.PlanId := 'TEST_PLAN';
      Plan.TotalItems := 1;
      Plan.SpaceSufficient := True;
      Plan.CriticalItems := 0;
      SetLength(Plan.Items, 1);
      Plan.Items[0].SourcePath := TPath.GetTempPath; // 使用存在的路径
      
      if not Planner.ValidateMigrationPlan(Plan) then
        raise Exception.Create('有效计划验证失败');
      
      // 测试无效计划
      Plan.TotalItems := 0;
      if Planner.ValidateMigrationPlan(Plan) then
        raise Exception.Create('无效计划应该验证失败');
      
      // 测试空间不足的计划
      Plan.TotalItems := 1;
      Plan.SpaceSufficient := False;
      if Planner.ValidateMigrationPlan(Plan) then
        raise Exception.Create('空间不足的计划应该验证失败');
      
      // 测试过多严重项目的计划
      Plan.SpaceSufficient := True;
      Plan.CriticalItems := 10;
      Plan.TotalItems := 10;
      if Planner.ValidateMigrationPlan(Plan) then
        raise Exception.Create('过多严重项目的计划应该验证失败');
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMigrationPlanner.TestPlanOptimization;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  Plan: TMigrationPlan;
  OriginalDuration: Integer;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建一个需要优化的计划
      FillChar(Plan, SizeOf(Plan), 0);
      Plan.PlanId := 'TEST_OPTIMIZATION';
      Plan.TotalItems := 3;
      Plan.EstimatedDuration := 1000;
      
      SetLength(Plan.Items, 3);
      
      // 设置不同优先级和风险的项目
      Plan.Items[0].Priority := mpLow;
      Plan.Items[0].Risk := mrHigh;
      Plan.Items[0].EstimatedTime := 300;
      Plan.Items[0].Size := 100 * 1024 * 1024; // 100MB
      
      Plan.Items[1].Priority := mpHigh;
      Plan.Items[1].Risk := mrLow;
      Plan.Items[1].EstimatedTime := 200;
      Plan.Items[1].Size := 50 * 1024 * 1024; // 50MB
      
      Plan.Items[2].Priority := mpCritical;
      Plan.Items[2].Risk := mrMedium;
      Plan.Items[2].EstimatedTime := 500;
      Plan.Items[2].Size := 2 * 1024 * 1024 * 1024; // 2GB
      
      OriginalDuration := Plan.EstimatedDuration;
      
      // 优化计划
      if not Planner.OptimizeMigrationPlan(Plan) then
        raise Exception.Create('计划优化失败');
      
      // 验证优化结果
      if Plan.Items[0].Priority <> mpCritical then
        raise Exception.Create('优化后排序不正确，严重优先级项目应该在前');
      
      if Plan.EstimatedDuration >= OriginalDuration then
        raise Exception.Create('优化后时间没有改善');
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMigrationPlanner.TestPlanSaveLoad;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  OriginalPlan, LoadedPlan: TMigrationPlan;
  TestFile: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建测试计划
      FillChar(OriginalPlan, SizeOf(OriginalPlan), 0);
      OriginalPlan.PlanId := 'TEST_SAVE_LOAD';
      OriginalPlan.CreatedTime := Now;
      OriginalPlan.SourceDrive := 'C:';
      OriginalPlan.TargetDrive := 'D:';
      OriginalPlan.TotalSize := 1024 * 1024 * 1024; // 1GB
      OriginalPlan.TotalFiles := 1000;
      OriginalPlan.EstimatedDuration := 300;
      OriginalPlan.TotalItems := 2;
      OriginalPlan.RequiresReboot := True;
      OriginalPlan.SpaceSufficient := True;
      OriginalPlan.OverallRisk := mrMedium;
      OriginalPlan.OverallSafety := 75;
      
      SetLength(OriginalPlan.Items, 2);
      OriginalPlan.Items[0].SourcePath := 'C:\Test1';
      OriginalPlan.Items[0].TargetPath := 'D:\Test1';
      OriginalPlan.Items[0].Strategy := msMove;
      OriginalPlan.Items[0].Priority := mpHigh;
      OriginalPlan.Items[0].Risk := mrLow;
      OriginalPlan.Items[0].Size := 500 * 1024 * 1024;
      OriginalPlan.Items[0].FileCount := 500;
      OriginalPlan.Items[0].EstimatedTime := 150;
      OriginalPlan.Items[0].SafetyScore := 80;
      
      OriginalPlan.Items[1].SourcePath := 'C:\Test2';
      OriginalPlan.Items[1].TargetPath := 'D:\Test2';
      OriginalPlan.Items[1].Strategy := msSymlink;
      OriginalPlan.Items[1].Priority := mpNormal;
      OriginalPlan.Items[1].Risk := mrMedium;
      OriginalPlan.Items[1].Size := 500 * 1024 * 1024;
      OriginalPlan.Items[1].FileCount := 500;
      OriginalPlan.Items[1].EstimatedTime := 150;
      OriginalPlan.Items[1].SafetyScore := 70;
      
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_plan.json');
      
      try
        // 保存计划
        if not Planner.SaveMigrationPlan(OriginalPlan, TestFile) then
          raise Exception.Create('计划保存失败');
        
        if not FileExists(TestFile) then
          raise Exception.Create('计划文件未创建');
        
        // 加载计划
        LoadedPlan := Planner.LoadMigrationPlan(TestFile);
        
        if LoadedPlan.PlanId <> OriginalPlan.PlanId then
          raise Exception.Create('加载的计划ID不匹配');
        
        if LoadedPlan.TotalItems <> OriginalPlan.TotalItems then
          raise Exception.Create('加载的项目数量不匹配');
        
        if LoadedPlan.TotalSize <> OriginalPlan.TotalSize then
          raise Exception.Create('加载的总大小不匹配');
        
        if LoadedPlan.Items[0].SourcePath <> OriginalPlan.Items[0].SourcePath then
          raise Exception.Create('加载的项目路径不匹配');
        
        if LoadedPlan.Items[0].Strategy <> OriginalPlan.Items[0].Strategy then
          raise Exception.Create('加载的迁移策略不匹配');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;class 
procedure TTestMigrationPlanner.TestPathConfiguration;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 测试添加排除路径
      Planner.AddExcludePath('C:\TestExclude');
      
      // 测试添加包含路径
      Planner.AddIncludePath('C:\TestInclude');
      
      // 测试移除路径
      Planner.RemoveExcludePath('C:\TestExclude');
      Planner.RemoveIncludePath('C:\TestInclude');
      
      // 测试清空路径
      Planner.ClearExcludePaths;
      Planner.ClearIncludePaths;
      
      // 这些操作不应该抛出异常
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMigrationPlanner.TestRiskAssessment;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  Plan: TMigrationPlan;
  RiskReport: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建包含不同风险级别的计划
      FillChar(Plan, SizeOf(Plan), 0);
      Plan.PlanId := 'TEST_RISK_ASSESSMENT';
      Plan.TotalItems := 4;
      Plan.OverallRisk := mrHigh;
      Plan.OverallSafety := 40;
      
      SetLength(Plan.Items, 4);
      Plan.Items[0].Risk := mrLow;
      Plan.Items[1].Risk := mrMedium;
      Plan.Items[2].Risk := mrHigh;
      Plan.Items[3].Risk := mrCritical;
      
      // 生成风险评估报告
      RiskReport := Planner.GenerateRiskAssessment(Plan);
      
      if Length(RiskReport) = 0 then
        raise Exception.Create('风险评估报告生成失败');
      
      if not ContainsText(RiskReport, '风险评估报告') then
        raise Exception.Create('风险评估报告格式不正确');
      
      if not ContainsText(RiskReport, '低风险: 1 项') then
        raise Exception.Create('风险统计不正确');
      
      if not ContainsText(RiskReport, '严重风险: 1 项') then
        raise Exception.Create('严重风险统计不正确');
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMigrationPlanner.TestReportGeneration;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  Plan: TMigrationPlan;
  Summary, DetailedReport: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建测试计划
      FillChar(Plan, SizeOf(Plan), 0);
      Plan.PlanId := 'TEST_REPORTS';
      Plan.CreatedTime := Now;
      Plan.SourceDrive := 'C:';
      Plan.TargetDrive := 'D:';
      Plan.TotalItems := 2;
      Plan.TotalSize := 2 * 1024 * 1024 * 1024; // 2GB
      Plan.TotalFiles := 1000;
      Plan.EstimatedDuration := 600;
      Plan.OverallRisk := mrMedium;
      Plan.OverallSafety := 65;
      Plan.RequiresReboot := True;
      Plan.SpaceSufficient := True;
      
      SetLength(Plan.Items, 2);
      Plan.Items[0].SourcePath := 'C:\Test1';
      Plan.Items[0].TargetPath := 'D:\Test1';
      Plan.Items[0].Size := 1024 * 1024 * 1024; // 1GB
      Plan.Items[0].FileCount := 500;
      Plan.Items[0].SafetyScore := 70;
      
      Plan.Items[1].SourcePath := 'C:\Test2';
      Plan.Items[1].TargetPath := 'D:\Test2';
      Plan.Items[1].Size := 1024 * 1024 * 1024; // 1GB
      Plan.Items[1].FileCount := 500;
      Plan.Items[1].SafetyScore := 60;
      
      SetLength(Plan.Prerequisites, 2);
      Plan.Prerequisites[0] := '确保目标磁盘有足够空间';
      Plan.Prerequisites[1] := '关闭相关程序';
      
      SetLength(Plan.PostActions, 2);
      Plan.PostActions[0] := '验证迁移结果';
      Plan.PostActions[1] := '重启系统';
      
      SetLength(Plan.RollbackPlan, 2);
      Plan.RollbackPlan[0] := '删除符号链接';
      Plan.RollbackPlan[1] := '恢复原始文件';
      
      // 测试摘要报告
      Summary := Planner.GeneratePlanSummary(Plan);
      
      if Length(Summary) = 0 then
        raise Exception.Create('计划摘要生成失败');
      
      if not ContainsText(Summary, '迁移计划摘要') then
        raise Exception.Create('摘要格式不正确');
      
      if not ContainsText(Summary, Plan.PlanId) then
        raise Exception.Create('摘要中缺少计划ID');
      
      if not ContainsText(Summary, '2 个') then
        raise Exception.Create('摘要中项目数量不正确');
      
      // 测试详细报告
      DetailedReport := Planner.GenerateDetailedReport(Plan);
      
      if Length(DetailedReport) = 0 then
        raise Exception.Create('详细报告生成失败');
      
      if not ContainsText(DetailedReport, '详细迁移计划报告') then
        raise Exception.Create('详细报告格式不正确');
      
      if not ContainsText(DetailedReport, '先决条件') then
        raise Exception.Create('详细报告中缺少先决条件');
      
      if not ContainsText(DetailedReport, '后续操作') then
        raise Exception.Create('详细报告中缺少后续操作');
      
      if not ContainsText(DetailedReport, '回退计划') then
        raise Exception.Create('详细报告中缺少回退计划');
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestMigrationPlanner.TestPlanComparison;
var
  Planner: TMigrationPlanner;
  ConfigManager: TConfigManager;
  Plan1, Plan2: TMigrationPlan;
  Comparison: string;
begin
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建第一个计划
      FillChar(Plan1, SizeOf(Plan1), 0);
      Plan1.PlanId := 'PLAN_1';
      Plan1.CreatedTime := Now - 1;
      Plan1.TotalItems := 3;
      Plan1.TotalSize := 3 * 1024 * 1024 * 1024; // 3GB
      Plan1.EstimatedDuration := 900;
      Plan1.HighRiskItems := 1;
      Plan1.CriticalItems := 0;
      Plan1.RequiresReboot := True;
      Plan1.OverallSafety := 80;
      
      // 创建第二个计划
      FillChar(Plan2, SizeOf(Plan2), 0);
      Plan2.PlanId := 'PLAN_2';
      Plan2.CreatedTime := Now;
      Plan2.TotalItems := 2;
      Plan2.TotalSize := 2 * 1024 * 1024 * 1024; // 2GB
      Plan2.EstimatedDuration := 600;
      Plan2.HighRiskItems := 0;
      Plan2.CriticalItems := 1;
      Plan2.RequiresReboot := False;
      Plan2.OverallSafety := 70;
      
      // 比较计划
      Comparison := Planner.ComparePlans(Plan1, Plan2);
      
      if Length(Comparison) = 0 then
        raise Exception.Create('计划比较结果生成失败');
      
      if not ContainsText(Comparison, '迁移计划比较') then
        raise Exception.Create('比较报告格式不正确');
      
      if not ContainsText(Comparison, 'PLAN_1') then
        raise Exception.Create('比较报告中缺少计划1信息');
      
      if not ContainsText(Comparison, 'PLAN_2') then
        raise Exception.Create('比较报告中缺少计划2信息');
      
      if not ContainsText(Comparison, '3 vs 2') then
        raise Exception.Create('项目数量比较不正确');
      
      if not ContainsText(Comparison, '建议') then
        raise Exception.Create('比较报告中缺少建议');
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.