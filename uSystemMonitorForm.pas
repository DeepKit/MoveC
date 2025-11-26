unit uSystemMonitorForm;

{
  系统监控界面表单 - Phase 2.2
  
  功能包括：
  - 实时系统监控显示
  - 性能分析报告
  - 系统优化工具
  - 图表和趋势显示
  
  作者: AI助手
  版本: 2.2.0
  日期: 2024
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, 
  System.Classes, System.TypInfo, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, System.Threading,
  uSystemMonitor, uPerformanceAnalyzer, uSystemOptimizer;

type
  TfrmSystemMonitor = class(TForm)
    pgcMain: TPageControl;
    tsMonitoring: TTabSheet;
    tsAnalysis: TTabSheet;
    tsOptimization: TTabSheet;
    
    // 监控页面
    pnlMonitorTop: TPanel;
    lblCPUUsage: TLabel;
    pbCPU: TProgressBar;
    lblMemoryUsage: TLabel;
    pbMemory: TProgressBar;
    lblDiskUsage: TLabel;
    pbDisk: TProgressBar;
    
    pnlMonitorBottom: TPanel;
    memoSystemInfo: TMemo;
    
    // 分析页面
    pnlAnalysisTop: TPanel;
    btnRunAnalysis: TBitBtn;
    btnGenerateReport: TBitBtn;
    memoAnalysisResult: TMemo;
    
    // 优化页面
    pnlOptimizationTop: TPanel;
    btnRunCleanup: TBitBtn;
    btnOptimizeMemory: TBitBtn;
    btnFlushDNS: TBitBtn;
    memoOptimizationResult: TMemo;
    
    // 通用控件
    pnlBottom: TPanel;
    btnStart: TBitBtn;
    btnStop: TBitBtn;
    lblStatus: TLabel;
    Timer1: TTimer;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnRunAnalysisClick(Sender: TObject);
    procedure btnGenerateReportClick(Sender: TObject);
    procedure btnRunCleanupClick(Sender: TObject);
    procedure btnOptimizeMemoryClick(Sender: TObject);
    procedure btnFlushDNSClick(Sender: TObject);
    
  private
    FSystemMonitor: TSystemMonitor;
    FPerformanceAnalyzer: TPerformanceAnalyzer;
    FSystemOptimizer: TSystemOptimizer;
    FRunning: Boolean;
    
    procedure UpdateSystemInfo(const Info: TSystemInfo);
    procedure OnMonitorEvent(const Event: TMonitorEvent);
    procedure OnOptimizationProgress(const Task: TOptimizationTask);
    procedure InitializeInterface;
    
  public
    { Public declarations }
  end;

var
  frmSystemMonitor: TfrmSystemMonitor;

implementation

{$R *.dfm}

procedure TfrmSystemMonitor.FormCreate(Sender: TObject);
begin
  // 创建核心组件
  FSystemMonitor := TSystemMonitor.Create;
  FPerformanceAnalyzer := TPerformanceAnalyzer.Create(FSystemMonitor);
  FSystemOptimizer := TSystemOptimizer.Create(FSystemMonitor, FPerformanceAnalyzer);
  
  // 设置事件处理
  FSystemMonitor.OnSystemInfo := UpdateSystemInfo;
  FSystemMonitor.OnMonitorEvent := OnMonitorEvent;
  FSystemOptimizer.OnProgress := OnOptimizationProgress;
  
  FRunning := False;
  InitializeInterface;
end;

procedure TfrmSystemMonitor.FormDestroy(Sender: TObject);
begin
  if FRunning then
    btnStopClick(nil);
    
  FSystemOptimizer.Free;
  FPerformanceAnalyzer.Free;
  FSystemMonitor.Free;
end;

procedure TfrmSystemMonitor.InitializeInterface;
begin
  Caption := '系统监控工具 v2.2.0';
  Position := poScreenCenter;
  WindowState := wsMaximized;
  
  // 设置进度条
  pbCPU.Min := 0;
  pbCPU.Max := 100;
  pbMemory.Min := 0;
  pbMemory.Max := 100;
  pbDisk.Min := 0;
  pbDisk.Max := 100;
  
  // 设置默认页面
  pgcMain.ActivePageIndex := 0;
  
  lblStatus.Caption := '就绪 - 点击开始监控';
  Timer1.Enabled := False;
  Timer1.Interval := 2000; // 2秒更新间隔
end;

procedure TfrmSystemMonitor.btnStartClick(Sender: TObject);
begin
  if not FRunning then
  begin
    FSystemMonitor.Start;
    Timer1.Enabled := True;
    FRunning := True;
    
    btnStart.Enabled := False;
    btnStop.Enabled := True;
    lblStatus.Caption := '监控运行中...';
  end;
end;

procedure TfrmSystemMonitor.btnStopClick(Sender: TObject);
begin
  if FRunning then
  begin
    Timer1.Enabled := False;
    FSystemMonitor.Stop;
    FRunning := False;
    
    btnStart.Enabled := True;
    btnStop.Enabled := False;
    lblStatus.Caption := '监控已停止';
  end;
end;

procedure TfrmSystemMonitor.Timer1Timer(Sender: TObject);
var
  Info: TSystemInfo;
begin
  if FRunning then
  begin
    Info := FSystemMonitor.GetCurrentSystemInfo;
    UpdateSystemInfo(Info);
  end;
end;

procedure TfrmSystemMonitor.UpdateSystemInfo(const Info: TSystemInfo);
var
  InfoText: string;
begin
  // 更新进度条
  pbCPU.Position := Round(Info.CPUUsage);
  pbMemory.Position := Round(Info.MemoryUsage);
  pbDisk.Position := Round(Info.DiskUsage);
  
  // 更新标签
  lblCPUUsage.Caption := Format('CPU使用率: %.1f%%', [Info.CPUUsage]);
  lblMemoryUsage.Caption := Format('内存使用率: %.1f%% (%s/%s)', 
    [Info.MemoryUsage, 
     FSystemMonitor.FormatBytes(Info.MemoryUsed),
     FSystemMonitor.FormatBytes(Info.MemoryTotal)]);
  lblDiskUsage.Caption := Format('磁盘使用率: %.1f%% (%s/%s)', 
    [Info.DiskUsage,
     FSystemMonitor.FormatBytes(Info.DiskUsed),
     FSystemMonitor.FormatBytes(Info.DiskTotal)]);
  
  // 更新详细信息
  InfoText := Format(
    '系统信息 - %s'#13#10 +
    '============================='#13#10 +
    'CPU使用率: %.2f%%'#13#10 +
    '内存总量: %s'#13#10 +
    '内存已用: %s'#13#10 +
    '内存使用率: %.2f%%'#13#10 +
    '磁盘总量: %s'#13#10 +
    '磁盘已用: %s'#13#10 +
    '磁盘使用率: %.2f%%'#13#10 +
    '进程数量: %d'#13#10 +
    '线程数量: %d'#13#10 +
    '网络上传: %s/s'#13#10 +
    '网络下载: %s/s'#13#10,
    [DateTimeToStr(Info.Timestamp),
     Info.CPUUsage,
     FSystemMonitor.FormatBytes(Info.MemoryTotal),
     FSystemMonitor.FormatBytes(Info.MemoryUsed),
     Info.MemoryUsage,
     FSystemMonitor.FormatBytes(Info.DiskTotal),
     FSystemMonitor.FormatBytes(Info.DiskUsed),
     Info.DiskUsage,
     Info.ProcessCount,
     Info.ThreadCount,
     FSystemMonitor.FormatBytesPerSecond(Info.NetworkUpload),
     FSystemMonitor.FormatBytesPerSecond(Info.NetworkDownload)]);
     
  memoSystemInfo.Text := InfoText;
end;

procedure TfrmSystemMonitor.OnMonitorEvent(const Event: TMonitorEvent);
var
  EventText: string;
begin
  // 在系统信息中显示监控事件
  case Event.EventType of
    metInfo: EventText := '[信息]';
    metWarning: EventText := '[警告]';
    metError: EventText := '[错误]';
    metCritical: EventText := '[严重]';
  end;
  
  EventText := Format('%s %s - %s (%.1f/%.1f)', 
    [EventText, DateTimeToStr(Event.Timestamp), Event.Message, 
     Event.Value, Event.Threshold]);
     
  memoSystemInfo.Lines.Add(EventText);
end;

procedure TfrmSystemMonitor.btnRunAnalysisClick(Sender: TObject);
var
  Report: TPerformanceReport;
  ReportText: string;
  I: Integer;
begin
  btnRunAnalysis.Enabled := False;
  try
    lblStatus.Caption := '正在分析系统性能...';
    Application.ProcessMessages;
    
    Report := FPerformanceAnalyzer.GeneratePerformanceReport;
    
    ReportText := Format(
      '性能分析报告'#13#10 +
      '============================='#13#10 +
      '生成时间: %s'#13#10 +
      '总体评分: %.1f分'#13#10 +
      '性能等级: %s'#13#10 +
      '系统运行时间: %s'#13#10 +
      '摘要: %s'#13#10#13#10 +
      '检测到的瓶颈 (%d个):'#13#10,
      [DateTimeToStr(Report.GeneratedAt),
       Report.OverallScore,
       GetEnumName(TypeInfo(TPerformanceLevel), Ord(Report.PerformanceLevel)),
       FSystemMonitor.FormatBytesPerSecond(Report.SystemUptime),
       Report.Summary,
       Length(Report.Bottlenecks)]);
       
    for I := 0 to High(Report.Bottlenecks) do
    begin
      ReportText := ReportText + Format(
        '- %s: %s (当前值: %.1f, 建议值: %.1f)'#13#10,
        [GetEnumName(TypeInfo(TBottleneckType), Ord(Report.Bottlenecks[I].BottleneckType)),
         Report.Bottlenecks[I].Description,
         Report.Bottlenecks[I].CurrentValue,
         Report.Bottlenecks[I].RecommendedValue]);
    end;
    
    if Length(Report.Suggestions) > 0 then
    begin
      ReportText := ReportText + #13#10'优化建议:'#13#10;
      for I := 0 to High(Report.Suggestions) do
      begin
        ReportText := ReportText + Format('- %s (优先级: %d)'#13#10,
          [Report.Suggestions[I].Title, Report.Suggestions[I].Priority]);
      end;
    end;
    
    memoAnalysisResult.Text := ReportText;
    lblStatus.Caption := '性能分析完成';
    
  finally
    btnRunAnalysis.Enabled := True;
  end;
end;

procedure TfrmSystemMonitor.btnGenerateReportClick(Sender: TObject);
var
  Benchmarks: TArray<TPerformanceBenchmark>;
  ReportText: string;
  I: Integer;
begin
  btnGenerateReport.Enabled := False;
  try
    lblStatus.Caption := '正在运行基准测试...';
    Application.ProcessMessages;
    
    Benchmarks := FPerformanceAnalyzer.RunComprehensiveBenchmark;
    
    ReportText := '基准测试报告'#13#10 +
                  '============================='#13#10;
                  
    for I := 0 to High(Benchmarks) do
    begin
      ReportText := ReportText + Format(
        '%s'#13#10 +
        '  评分: %.1f/%.1f'#13#10 +
        '  耗时: %d毫秒'#13#10 +
        '  详情: %s'#13#10#13#10,
        [Benchmarks[I].TestName,
         Benchmarks[I].Score,
         Benchmarks[I].MaxScore,
         Benchmarks[I].Duration,
         Benchmarks[I].TestDetails]);
    end;
    
    memoAnalysisResult.Text := ReportText;
    lblStatus.Caption := '基准测试完成';
    
  finally
    btnGenerateReport.Enabled := True;
  end;
end;

procedure TfrmSystemMonitor.btnRunCleanupClick(Sender: TObject);
var
  Result: TOptimizationResult;
begin
  btnRunCleanup.Enabled := False;
  try
    lblStatus.Caption := '正在执行系统清理...';
    memoOptimizationResult.Text := '开始系统清理...'#13#10;
    Application.ProcessMessages;
    
    if FSystemOptimizer.RunSingleTask('cleanup_temp_files') then
      memoOptimizationResult.Lines.Add('临时文件清理完成');
      
    if FSystemOptimizer.RunSingleTask('cleanup_browser_cache') then
      memoOptimizationResult.Lines.Add('浏览器缓存清理完成');
    
    memoOptimizationResult.Lines.Add('系统清理任务完成');
    lblStatus.Caption := '系统清理完成';
    
  finally
    btnRunCleanup.Enabled := True;
  end;
end;

procedure TfrmSystemMonitor.btnOptimizeMemoryClick(Sender: TObject);
begin
  btnOptimizeMemory.Enabled := False;
  try
    lblStatus.Caption := '正在优化内存...';
    memoOptimizationResult.Text := '开始内存优化...'#13#10;
    Application.ProcessMessages;
    
    if FSystemOptimizer.RunSingleTask('optimize_memory') then
    begin
      memoOptimizationResult.Lines.Add('内存优化完成');
      memoOptimizationResult.Lines.Add('建议重启应用程序以获得最佳效果');
    end;
    
    lblStatus.Caption := '内存优化完成';
    
  finally
    btnOptimizeMemory.Enabled := True;
  end;
end;

procedure TfrmSystemMonitor.btnFlushDNSClick(Sender: TObject);
begin
  btnFlushDNS.Enabled := False;
  try
    lblStatus.Caption := '正在刷新DNS缓存...';
    memoOptimizationResult.Text := '开始DNS缓存清理...'#13#10;
    Application.ProcessMessages;
    
    if FSystemOptimizer.RunSingleTask('flush_dns') then
      memoOptimizationResult.Lines.Add('DNS缓存清理完成');
    
    lblStatus.Caption := 'DNS缓存清理完成';
    
  finally
    btnFlushDNS.Enabled := True;
  end;
end;

procedure TfrmSystemMonitor.OnOptimizationProgress(const Task: TOptimizationTask);
var
  StatusText: string;
begin
  StatusText := Format('%s - %s (%d%%)', 
    [Task.Name, 
     GetEnumName(TypeInfo(TOptimizationStatus), Ord(Task.Status)),
     Task.Progress]);
     
  memoOptimizationResult.Lines.Add(StatusText);
  
  if Task.Status = osCompleted then
    memoOptimizationResult.Lines.Add('结果: ' + Task.Result);
end;

end.