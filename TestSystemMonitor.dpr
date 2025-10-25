program TestSystemMonitor;

{
  系统监控测试程序 - Phase 2.2
  
  功能演示：
  - 系统监控功能
  - 性能分析
  - 系统优化
  - 实时数据显示
  
  作者: AI助手
  版本: 2.2.0
  日期: 2024
}

uses
  Vcl.Forms,
  uSystemMonitor in 'uSystemMonitor.pas',
  uPerformanceAnalyzer in 'uPerformanceAnalyzer.pas',
  uSystemOptimizer in 'uSystemOptimizer.pas',
  uSystemMonitorForm in 'uSystemMonitorForm.pas' {frmSystemMonitor};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '系统监控测试程序 v2.2.0';
  Application.CreateForm(TfrmSystemMonitor, frmSystemMonitor);
  Application.Run;
end.