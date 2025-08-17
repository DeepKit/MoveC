unit TestRunner;

interface

uses
  System.SysUtils, System.Classes;

type
  TTestRunner = class
  public
    class procedure RunAllTests;
  end;

implementation

uses
  TestFileSafetyEvaluator, TestDependencyAnalyzer, TestRebootDetector, TestFileTypeIdentifier,
  TestMigrationPlanner, TestFileOperationEngine, TestSymlinkManager, TestBackupManager,
  Vcl.Dialogs;

class procedure TTestRunner.RunAllTests;
var
  TestsPassed: Integer;
  TestsFailed: Integer;
begin
  TestsPassed := 0;
  TestsFailed := 0;
  
  try
    ShowMessage('🚀 开始运行C盘清理工具完整测试套件...');
    
    // 文件分析引擎测试
    try
      TTestFileSafetyEvaluator.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    try
      TTestDependencyAnalyzer.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    try
      TTestRebootDetector.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    try
      TTestFileTypeIdentifier.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    // 迁移管理系统测试
    try
      TTestMigrationPlanner.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    try
      TTestFileOperationEngine.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    try
      TTestSymlinkManager.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    // 回退系统测试
    try
      TTestBackupManager.RunAllTests;
      Inc(TestsPassed);
    except
      Inc(TestsFailed);
    end;
    
    // 显示测试结果
    var ResultMsg := Format(
      '🎉 测试完成！' + sLineBreak + sLineBreak +
      '✅ 通过: %d 个测试模块' + sLineBreak +
      '❌ 失败: %d 个测试模块' + sLineBreak + sLineBreak +
      '总体成功率: %.1f%%',
      [TestsPassed, TestsFailed, (TestsPassed * 100.0) / (TestsPassed + TestsFailed)]
    );
    
    ShowMessage(ResultMsg);
    
  except
    on E: Exception do
      ShowMessage('测试运行器异常: ' + E.Message);
  end;
end;

end.