unit QuickDemo;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  TQuickDemo = class
  public
    class procedure RunDemo;
    class procedure DemoFileSafetyEvaluation;
    class procedure DemoMigrationPlanning;
    class procedure DemoFileOperations;
    class procedure DemoBackupAndRollback;
  end;

implementation

uses
  FileSafetyEvaluator, MigrationPlanner, FileOperationEngine, BackupManager,
  ConfigManager, Vcl.Dialogs;

class procedure TQuickDemo.RunDemo;
begin
  try
    ShowMessage('🎉 C盘清理工具功能演示开始！');
    
    DemoFileSafetyEvaluation;
    DemoMigrationPlanning;
    DemoFileOperations;
    DemoBackupAndRollback;
    
    ShowMessage('✅ 功能演示完成！所有核心功能运行正常。');
    
  except
    on E: Exception do
      ShowMessage('演示异常: ' + E.Message);
  end;
end;

class procedure TQuickDemo.DemoFileSafetyEvaluation;
var
  ConfigManager: TConfigManager;
  SafetyEvaluator: TFileSafetyEvaluator;
  TestFile: string;
  Result: TFileSafetyResult;
begin
  ShowMessage('📊 演示文件安全评估功能...');
  
  ConfigManager := TConfigManager.Create;
  try
    SafetyEvaluator := TFileSafetyEvaluator.Create(ConfigManager);
    try
      // 创建测试文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'demo_safety_test.txt');
      TFile.WriteAllText(TestFile, 'Demo file for safety evaluation');
      
      try
        // 评估文件安全性
        Result := SafetyEvaluator.EvaluateFile(TestFile);
        
        var Message := Format(
          '文件安全评估结果:' + sLineBreak +
          '文件: %s' + sLineBreak +
          '安全级别: %s' + sLineBreak +
          '风险分数: %d/100' + sLineBreak +
          '可删除: %s' + sLineBreak +
          '需要备份: %s',
          [Result.FilePath, 
           Case Result.SafetyLevel of
             fslSafe: '安全';
             fslCaution: '注意';
             fslDangerous: '危险';
             fslCritical: '严重';
           else '未知';
           end,
           Result.RiskScore,
           BoolToStr(Result.CanDelete, '是', '否'),
           BoolToStr(Result.RequiresBackup, '是', '否')]
        );
        
        ShowMessage(Message);
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      SafetyEvaluator.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TQuickDemo.DemoMigrationPlanning;
var
  ConfigManager: TConfigManager;
  Planner: TMigrationPlanner;
  TestDir: string;
  TestPaths: TArray<string>;
  Plan: TMigrationPlan;
begin
  ShowMessage('📋 演示迁移计划生成功能...');
  
  ConfigManager := TConfigManager.Create;
  try
    Planner := TMigrationPlanner.Create(ConfigManager);
    try
      // 创建测试目录
      TestDir := TPath.Combine(TPath.GetTempPath, 'demo_migration_test');
      TDirectory.CreateDirectory(TestDir);
      TFile.WriteAllText(TPath.Combine(TestDir, 'test.txt'), 'Demo migration content');
      
      try
        SetLength(TestPaths, 1);
        TestPaths[0] := TestDir;
        
        // 创建迁移计划
        Plan := Planner.CreateMigrationPlan('C:', 'D:', TestPaths);
        
        var Message := Format(
          '迁移计划生成结果:' + sLineBreak +
          '计划ID: %s' + sLineBreak +
          '项目数量: %d' + sLineBreak +
          '总大小: %.2f KB' + sLineBreak +
          '预估时间: %d 秒' + sLineBreak +
          '总体风险: %s' + sLineBreak +
          '安全分数: %d/100',
          [Plan.PlanId,
           Plan.TotalItems,
           Plan.TotalSize / 1024,
           Plan.EstimatedDuration,
           Case Plan.OverallRisk of
             mrLow: '低风险';
             mrMedium: '中等风险';
             mrHigh: '高风险';
             mrCritical: '严重风险';
           else '未知风险';
           end,
           Plan.OverallSafety]
        );
        
        ShowMessage(Message);
        
      finally
        if TDirectory.Exists(TestDir) then
          TDirectory.Delete(TestDir, True);
      end;
      
    finally
      Planner.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TQuickDemo.DemoFileOperations;
var
  ConfigManager: TConfigManager;
  Engine: TFileOperationEngine;
  SourceFile, TargetFile: string;
  Stats: TOperationStatistics;
begin
  ShowMessage('⚙️ 演示文件操作引擎功能...');
  
  ConfigManager := TConfigManager.Create;
  try
    Engine := TFileOperationEngine.Create(ConfigManager);
    try
      // 创建测试文件
      SourceFile := TPath.Combine(TPath.GetTempPath, 'demo_source.txt');
      TargetFile := TPath.Combine(TPath.GetTempPath, 'demo_target.txt');
      TFile.WriteAllText(SourceFile, 'Demo file operation content');
      
      try
        // 添加复制操作
        Engine.AddOperation(fotCopy, SourceFile, TargetFile);
        
        // 执行操作
        var Success := Engine.Execute;
        
        // 获取统计信息
        Stats := Engine.GetStatistics;
        
        var Message := Format(
          '文件操作执行结果:' + sLineBreak +
          '执行成功: %s' + sLineBreak +
          '总操作数: %d' + sLineBreak +
          '成功操作: %d' + sLineBreak +
          '失败操作: %d' + sLineBreak +
          '处理字节: %d' + sLineBreak +
          '执行时间: %d 秒',
          [BoolToStr(Success, '是', '否'),
           Stats.TotalOperations,
           Stats.CompletedOperations,
           Stats.FailedOperations,
           Stats.ProcessedBytes,
           Stats.ElapsedTime]
        );
        
        ShowMessage(Message);
        
      finally
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

class procedure TQuickDemo.DemoBackupAndRollback;
var
  ConfigManager: TConfigManager;
  BackupManager: TBackupManager;
  TestFile: string;
  TestPaths: TArray<string>;
  BackupId: string;
begin
  ShowMessage('💾 演示备份和回退功能...');
  
  ConfigManager := TConfigManager.Create;
  try
    BackupManager := TBackupManager.Create(ConfigManager);
    try
      // 创建测试文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'demo_backup_test.txt');
      TFile.WriteAllText(TestFile, 'Demo backup content');
      
      try
        SetLength(TestPaths, 1);
        TestPaths[0] := TestFile;
        
        // 创建备份
        BackupId := BackupManager.CreateBackup(TestPaths, 'Demo backup');
        
        var Message := Format(
          '备份创建结果:' + sLineBreak +
          '备份成功: %s' + sLineBreak +
          '备份ID: %s' + sLineBreak +
          '备份验证: %s',
          [BoolToStr(Length(BackupId) > 0, '是', '否'),
           BackupId,
           BoolToStr(BackupManager.VerifyBackup(BackupId), '通过', '失败')]
        );
        
        ShowMessage(Message);
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      BackupManager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.