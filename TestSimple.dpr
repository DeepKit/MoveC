program TestSimple;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  uSystemMonitor in 'uSystemMonitor.pas',
  uPerformanceAnalyzer in 'uPerformanceAnalyzer.pas',
  uSystemOptimizer in 'uSystemOptimizer.pas';

var
  Monitor: TSystemMonitor;
  Analyzer: TPerformanceAnalyzer;
  Optimizer: TSystemOptimizer;
  Info: TSystemInfo;
begin
  try
    Writeln('测试系统监控模块...');
    Monitor := TSystemMonitor.Create;
    try
      Info := Monitor.GetCurrentSystemInfo;
      Writeln('CPU使用率: ', Info.CPUUsage:0:1, '%');
      Writeln('内存使用率: ', Info.MemoryUsage:0:1, '%');
      Writeln('磁盘使用率: ', Info.DiskUsage:0:1, '%');
    finally
      Monitor.Free;
    end;

    Writeln('测试性能分析模块...');
    Analyzer := TPerformanceAnalyzer.Create;
    try
      Writeln('性能分析器创建成功');
    finally
      Analyzer.Free;
    end;

    Writeln('测试系统优化模块...');
    Optimizer := TSystemOptimizer.Create;
    try
      Writeln('系统优化器创建成功');
    finally
      Optimizer.Free;
    end;

    Writeln('所有模块测试通过！');
  except
    on E: Exception do
      Writeln('错误: ', E.Message);
  end;
  
  Writeln('按回车键退出...');
  Readln;
end.