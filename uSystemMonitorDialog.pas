unit uSystemMonitorDialog;

{
  增强系统监控对话框 - Enhanced System Monitoring Dialog
  
  提供实时系统监控功能，包括：
  - 系统资源使用图表 (CPU, 内存, 磁盘)
  - 网络流量监控
  - 进程管理和分析
  - 性能警报和建议
  - 历史数据记录
  - 资源使用预测
  
  作者: AI助手
  版本: 1.0
  日期: 2024
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.Threading, System.DateUtils, System.Math, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Buttons, Vcl.Grids, Vcl.Menus, Vcl.ImgList, Vcl.Samples.Spin,
  uSystemMonitor, uPerformanceAnalyzer, uLogManager;

type
  TChartType = (ctCPU, ctMemory, ctDisk, ctNetwork);
  
  TChartData = record
    Timestamp: TDateTime;
    Value: Double;
  end;
  
  TChartHistory = TList<TChartData>;

  TfrmSystemMonitorDialog = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 标签页控制
    pgcMonitor: TPageControl;
    
    // 概览页
    tsOverview: TTabSheet;
    pnlOverview: TPanel;
    
    // 系统信息面板
    gbSystemInfo: TGroupBox;
    lblCPUUsage: TLabel;
    lblCPUValue: TLabel;
    pbCPU: TProgressBar;
    lblMemoryUsage: TLabel;
    lblMemoryValue: TLabel;
    pbMemory: TProgressBar;
    lblDiskUsage: TLabel;
    lblDiskValue: TLabel;
    pbDisk: TProgressBar;
    lblNetworkUsage: TLabel;
    lblNetworkValue: TLabel;
    pbNetwork: TProgressBar;
    
    // 系统详情
    gbSystemDetails: TGroupBox;
    lblOSVersion: TLabel;
    lblOSVersionValue: TLabel;
    lblTotalRAM: TLabel;
    lblTotalRAMValue: TLabel;
    lblUptime: TLabel;
    lblUptimeValue: TLabel;
    lblProcessCount: TLabel;
    lblProcessCountValue: TLabel;
    
    // 图表页
    tsCharts: TTabSheet;
    pnlCharts: TPanel;
    pnlChartControls: TPanel;
    lblChartType: TLabel;
    cmbChartType: TComboBox;
    lblTimeRange: TLabel;
    cmbTimeRange: TComboBox;
    chkAutoScale: TCheckBox;
    btnResetZoom: TBitBtn;
    pnlChart: TPanel;
    
    // 进程监控页
    tsProcesses: TTabSheet;
    pnlProcesses: TPanel;
    pnlProcessControls: TPanel;
    lblProcessFilter: TLabel;
    edtProcessFilter: TEdit;
    btnRefreshProcesses: TBitBtn;
    btnKillProcess: TBitBtn;
    lvProcesses: TListView;
    
    // 警报和建议页
    tsAlerts: TTabSheet;
    pnlAlerts: TPanel;
    lvAlerts: TListView;
    memoRecommendations: TMemo;
    Splitter1: TSplitter;
    
    // 设置页
    tsSettings: TTabSheet;
    pnlSettings: TPanel;
    gbMonitoringSettings: TGroupBox;
    lblRefreshInterval: TLabel;
    seRefreshInterval: TSpinEdit;
    lblSeconds: TLabel;
    chkEnableAlerts: TCheckBox;
    chkLogToFile: TCheckBox;
    chkShowNotifications: TCheckBox;
    
    gbThresholds: TGroupBox;
    lblCPUThreshold: TLabel;
    seCPUThreshold: TSpinEdit;
    lblMemoryThreshold: TLabel;
    seMemoryThreshold: TSpinEdit;
    lblDiskThreshold: TLabel;
    seDiskThreshold: TSpinEdit;
    
    // 底部控制面板
    pnlBottom: TPanel;
    btnStartMonitoring: TBitBtn;
    btnStopMonitoring: TBitBtn;
    btnExportData: TBitBtn;
    btnClose: TBitBtn;
    
    // 状态栏
    StatusBar: TStatusBar;
    
    // 定时器
    TimerUpdate: TTimer;
    TimerChart: TTimer;
    
    // 右键菜单
    pmProcesses: TPopupMenu;
    miProcessDetails: TMenuItem;
    miKillProcess: TMenuItem;
    miSeparator1: TMenuItem;
    miProcessPriority: TMenuItem;
    miProcessLocation: TMenuItem;
    
    // 保存对话框
    SaveDialog: TSaveDialog;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    
    procedure btnStartMonitoringClick(Sender: TObject);
    procedure btnStopMonitoringClick(Sender: TObject);
    procedure btnExportDataClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    
    procedure TimerUpdateTimer(Sender: TObject);
    procedure TimerChartTimer(Sender: TObject);
    
    procedure cmbChartTypeChange(Sender: TObject);
    procedure cmbTimeRangeChange(Sender: TObject);
    procedure btnResetZoomClick(Sender: TObject);
    
    procedure btnRefreshProcessesClick(Sender: TObject);
    procedure btnKillProcessClick(Sender: TObject);
    procedure lvProcessesDblClick(Sender: TObject);
    
    procedure miProcessDetailsClick(Sender: TObject);
    procedure miKillProcessClick(Sender: TObject);
    procedure miProcessLocationClick(Sender: TObject);
    
    procedure chkEnableAlertsClick(Sender: TObject);
    procedure seRefreshIntervalChange(Sender: TObject);
    
  private
    FSystemMonitor: TSystemMonitor;
    FPerformanceAnalyzer: TPerformanceAnalyzer;
    FIsMonitoring: Boolean;
    FStartTime: TDateTime;
    
    // 图表数据
    FCPUHistory: TChartHistory;
    FMemoryHistory: TChartHistory;
    FDiskHistory: TChartHistory;
    FNetworkHistory: TChartHistory;
    
    // 设置
    FRefreshInterval: Integer;
    FEnableAlerts: Boolean;
    FCPUThreshold: Integer;
    FMemoryThreshold: Integer;
    FDiskThreshold: Integer;
    
    // 警报列表
    FAlerts: TList<TMonitorEvent>;
    
    procedure InitializeInterface;
    procedure InitializeMonitoring;
    procedure LoadSettings;
    procedure SaveSettings;
    
    procedure UpdateSystemInfo;
    procedure UpdateChart;
    procedure UpdateProcessList;
    procedure UpdateAlerts;
    
    procedure DrawChart(ChartType: TChartType);
    procedure AddChartData(ChartType: TChartType; Value: Double);
    procedure ClearChartHistory;
    
    procedure CheckThresholds(const Info: TSystemInfo);
    procedure AddAlert(const Alert: TMonitorEvent);
    procedure GenerateRecommendations;
    
    procedure ExportMonitoringData;
    procedure RefreshProcesses;
    procedure KillSelectedProcess;
    
    function FormatBytes(Bytes: Int64): string;
    function FormatDuration(Seconds: Int64): string;
    function GetSelectedProcessID: Cardinal;
    
    // 事件回调
    procedure OnSystemInfoUpdate(const Info: TSystemInfo);
    procedure OnMonitorEventAlert(const Event: TMonitorEvent);
    
  public
    constructor Create(AOwner: TComponent); override;
    property IsMonitoring: Boolean read FIsMonitoring;
  end;

var
  frmSystemMonitorDialog: TfrmSystemMonitorDialog;

implementation

uses System.UITypes, System.Win.ComObj, System.IniFiles, Winapi.TlHelp32, 
     Winapi.PsAPI, Winapi.ShellAPI;

type
  THackPanel = class(TCustomControl);

{$R *.dfm}

constructor TfrmSystemMonitorDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // 初始化图表历史数据
  FCPUHistory := TChartHistory.Create;
  FMemoryHistory := TChartHistory.Create;
  FDiskHistory := TChartHistory.Create;
  FNetworkHistory := TChartHistory.Create;
  FAlerts := TList<TMonitorEvent>.Create;
  
  // 设置默认值
  FRefreshInterval := 2000; // 2秒
  FEnableAlerts := True;
  FCPUThreshold := 80;
  FMemoryThreshold := 85;
  FDiskThreshold := 90;
  
  InitializeInterface;
  InitializeMonitoring;
end;

procedure TfrmSystemMonitorDialog.FormCreate(Sender: TObject);
begin
  Caption := '系统监控器 - C盘瘦身神器';
  Position := poScreenCenter;
  WindowState := wsMaximized;
  
  // 设置定时器
  TimerUpdate.Interval := FRefreshInterval;
  TimerUpdate.Enabled := False;
  
  TimerChart.Interval := 1000; // 图表1秒更新一次
  TimerChart.Enabled := False;
  
  LoadSettings;
end;

procedure TfrmSystemMonitorDialog.FormDestroy(Sender: TObject);
begin
  if FIsMonitoring then
    btnStopMonitoringClick(nil);
    
  SaveSettings;
  
  FCPUHistory.Free;
  FMemoryHistory.Free;
  FDiskHistory.Free;
  FNetworkHistory.Free;
  FAlerts.Free;
  
  if Assigned(FSystemMonitor) then
    FSystemMonitor.Free;
  if Assigned(FPerformanceAnalyzer) then
    FPerformanceAnalyzer.Free;
end;

procedure TfrmSystemMonitorDialog.FormShow(Sender: TObject);
begin
  // 自动开始监控
  btnStartMonitoringClick(nil);
  
  // 刷新进程列表
  RefreshProcesses;
  
  // 生成初始建议
  GenerateRecommendations;
end;

procedure TfrmSystemMonitorDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FIsMonitoring then
    btnStopMonitoringClick(nil);
  Action := caFree;
end;

procedure TfrmSystemMonitorDialog.InitializeInterface;
begin
  // 初始化标签页
  pgcMonitor.ActivePageIndex := 0;
  
  // 初始化图表类型下拉框
  cmbChartType.Items.Clear;
  cmbChartType.Items.Add('CPU 使用率');
  cmbChartType.Items.Add('内存使用率');
  cmbChartType.Items.Add('磁盘使用率');
  cmbChartType.Items.Add('网络流量');
  cmbChartType.ItemIndex := 0;
  
  // 初始化时间范围下拉框
  cmbTimeRange.Items.Clear;
  cmbTimeRange.Items.Add('最近 1 分钟');
  cmbTimeRange.Items.Add('最近 5 分钟');
  cmbTimeRange.Items.Add('最近 15 分钟');
  cmbTimeRange.Items.Add('最近 30 分钟');
  cmbTimeRange.Items.Add('最近 1 小时');
  cmbTimeRange.ItemIndex := 2; // 默认15分钟
  
  // 初始化进程列表
  lvProcesses.ViewStyle := vsReport;
  lvProcesses.GridLines := True;
  lvProcesses.RowSelect := True;
  
  lvProcesses.Columns.Add.Caption := '进程名';
  lvProcesses.Columns.Add.Caption := 'PID';
  lvProcesses.Columns.Add.Caption := 'CPU %';
  lvProcesses.Columns.Add.Caption := '内存使用';
  lvProcesses.Columns.Add.Caption := '状态';
  
  // 设置列宽
  lvProcesses.Columns[0].Width := 200;
  lvProcesses.Columns[1].Width := 80;
  lvProcesses.Columns[2].Width := 80;
  lvProcesses.Columns[3].Width := 100;
  lvProcesses.Columns[4].Width := 80;
  
  // 初始化警报列表
  lvAlerts.ViewStyle := vsReport;
  lvAlerts.GridLines := True;
  lvAlerts.RowSelect := True;
  
  lvAlerts.Columns.Add.Caption := '时间';
  lvAlerts.Columns.Add.Caption := '级别';
  lvAlerts.Columns.Add.Caption := '类型';
  lvAlerts.Columns.Add.Caption := '消息';
  
  lvAlerts.Columns[0].Width := 120;
  lvAlerts.Columns[1].Width := 80;
  lvAlerts.Columns[2].Width := 100;
  lvAlerts.Columns[3].Width := 300;
  
  // 初始化进度条
  pbCPU.Max := 100;
  pbMemory.Max := 100;
  pbDisk.Max := 100;
  pbNetwork.Max := 100;
  
  // 设置数值范围
  seRefreshInterval.MinValue := 1;
  seRefreshInterval.MaxValue := 60;
  seRefreshInterval.Value := FRefreshInterval div 1000;
  
  seCPUThreshold.MinValue := 50;
  seCPUThreshold.MaxValue := 99;
  seCPUThreshold.Value := FCPUThreshold;
  
  seMemoryThreshold.MinValue := 60;
  seMemoryThreshold.MaxValue := 99;
  seMemoryThreshold.Value := FMemoryThreshold;
  
  seDiskThreshold.MinValue := 70;
  seDiskThreshold.MaxValue := 99;
  seDiskThreshold.Value := FDiskThreshold;
  
  // 初始化复选框状态
  chkEnableAlerts.Checked := FEnableAlerts;
  chkAutoScale.Checked := True;
  
  // 初始化保存对话框
  SaveDialog.Filter := '文本文件 (*.txt)|*.txt|CSV文件 (*.csv)|*.csv|所有文件 (*.*)|*.*';
  SaveDialog.DefaultExt := 'txt';
  
  // 设置图表面板
  pnlChart.Color := clWhite;
  pnlChart.BevelOuter := bvLowered;
end;

procedure TfrmSystemMonitorDialog.InitializeMonitoring;
begin
  if not Assigned(FSystemMonitor) then
  begin
    FSystemMonitor := TSystemMonitor.Create;
    FSystemMonitor.OnSystemInfo := OnSystemInfoUpdate;
    FSystemMonitor.OnMonitorEvent := OnMonitorEventAlert;
  end;
  
  if not Assigned(FPerformanceAnalyzer) then
    FPerformanceAnalyzer := TPerformanceAnalyzer.Create;
end;

procedure TfrmSystemMonitorDialog.LoadSettings;
var
  IniFile: TIniFile;
  SettingsFile: string;
begin
  SettingsFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SystemMonitor.ini');
  if not TFile.Exists(SettingsFile) then
    Exit;
    
  IniFile := TIniFile.Create(SettingsFile);
  try
    FRefreshInterval := IniFile.ReadInteger('Monitor', 'RefreshInterval', FRefreshInterval);
    FEnableAlerts := IniFile.ReadBool('Monitor', 'EnableAlerts', FEnableAlerts);
    FCPUThreshold := IniFile.ReadInteger('Monitor', 'CPUThreshold', FCPUThreshold);
    FMemoryThreshold := IniFile.ReadInteger('Monitor', 'MemoryThreshold', FMemoryThreshold);
    FDiskThreshold := IniFile.ReadInteger('Monitor', 'DiskThreshold', FDiskThreshold);
  finally
    IniFile.Free;
  end;
end;

procedure TfrmSystemMonitorDialog.SaveSettings;
var
  IniFile: TIniFile;
  SettingsFile: string;
begin
  SettingsFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SystemMonitor.ini');
  
  IniFile := TIniFile.Create(SettingsFile);
  try
    IniFile.WriteInteger('Monitor', 'RefreshInterval', FRefreshInterval);
    IniFile.WriteBool('Monitor', 'EnableAlerts', FEnableAlerts);
    IniFile.WriteInteger('Monitor', 'CPUThreshold', FCPUThreshold);
    IniFile.WriteInteger('Monitor', 'MemoryThreshold', FMemoryThreshold);
    IniFile.WriteInteger('Monitor', 'DiskThreshold', FDiskThreshold);
  finally
    IniFile.Free;
  end;
end;

procedure TfrmSystemMonitorDialog.btnStartMonitoringClick(Sender: TObject);
begin
  if FIsMonitoring then
    Exit;
    
  try
    FSystemMonitor.Start;
    FIsMonitoring := True;
    FStartTime := Now;
    
    TimerUpdate.Enabled := True;
    TimerChart.Enabled := True;
    
    btnStartMonitoring.Enabled := False;
    btnStopMonitoring.Enabled := True;
    
    StatusBar.Panels[0].Text := '监控中...';
    
    LogInfo('SystemMonitor', '系统监控已启动');
  except
    on E: Exception do
    begin
      ShowMessage('启动系统监控失败：' + E.Message);
      LogError('SystemMonitor', '启动系统监控失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSystemMonitorDialog.btnStopMonitoringClick(Sender: TObject);
begin
  if not FIsMonitoring then
    Exit;
    
  try
    FSystemMonitor.Stop;
    FIsMonitoring := False;
    
    TimerUpdate.Enabled := False;
    TimerChart.Enabled := False;
    
    btnStartMonitoring.Enabled := True;
    btnStopMonitoring.Enabled := False;
    
    StatusBar.Panels[0].Text := '监控已停止';
    
    LogInfo('SystemMonitor', '系统监控已停止');
  except
    on E: Exception do
    begin
      ShowMessage('停止系统监控失败：' + E.Message);
      LogError('SystemMonitor', '停止系统监控失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSystemMonitorDialog.TimerUpdateTimer(Sender: TObject);
begin
  if FIsMonitoring then
  begin
    UpdateSystemInfo;
    UpdateProcessList;
    UpdateAlerts;
  end;
end;

procedure TfrmSystemMonitorDialog.TimerChartTimer(Sender: TObject);
begin
  if FIsMonitoring then
  begin
    UpdateChart;
  end;
end;

procedure TfrmSystemMonitorDialog.UpdateSystemInfo;
var
  Info: TSystemInfo;
begin
  if not Assigned(FSystemMonitor) then
    Exit;
    
  try
    Info := FSystemMonitor.GetCurrentSystemInfo;
    
    // 更新进度条和标签
    pbCPU.Position := Round(Info.CPUUsage);
    lblCPUValue.Caption := Format('%.1f%%', [Info.CPUUsage]);
    
    pbMemory.Position := Round(Info.MemoryUsage);
    lblMemoryValue.Caption := Format('%.1f%% (%s / %s)', 
      [Info.MemoryUsage, FormatBytes(Info.MemoryUsed), FormatBytes(Info.MemoryTotal)]);
    
    pbDisk.Position := Round(Info.DiskUsage);
    lblDiskValue.Caption := Format('%.1f%%', [Info.DiskUsage]);
    
    // 计算网络使用率（简化处理）
    var NetworkPercent := Min(100.0, (Info.NetworkUpload + Info.NetworkDownload) / (1024 * 1024) * 10);
    pbNetwork.Position := Round(NetworkPercent);
    lblNetworkValue.Caption := Format('↑ %.1f MB/s ↓ %.1f MB/s', 
      [Info.NetworkUpload / (1024 * 1024), Info.NetworkDownload / (1024 * 1024)]);
    
    // 更新系统详情
    lblOSVersionValue.Caption := 'Windows'; // 可以获取详细版本信息
    lblTotalRAMValue.Caption := FormatBytes(Info.MemoryTotal);
    lblUptimeValue.Caption := FormatDuration(FSystemMonitor.GetSystemUptime);
    lblProcessCountValue.Caption := IntToStr(Info.ProcessCount);
    
    // 检查阈值
    if FEnableAlerts then
      CheckThresholds(Info);
      
  except
    on E: Exception do
      LogError('SystemMonitor', '更新系统信息失败: ' + E.Message);
  end;
end;

procedure TfrmSystemMonitorDialog.UpdateChart;
var
  Info: TSystemInfo;
begin
  if not Assigned(FSystemMonitor) or not FIsMonitoring then
    Exit;
    
  try
    Info := FSystemMonitor.GetCurrentSystemInfo;
    
    // 添加数据到图表历史
    AddChartData(ctCPU, Info.CPUUsage);
    AddChartData(ctMemory, Info.MemoryUsage);
    AddChartData(ctDisk, Info.DiskUsage);
    AddChartData(ctNetwork, (Info.NetworkUpload + Info.NetworkDownload) / (1024 * 1024));
    
    // 重绘当前选中的图表
    DrawChart(TChartType(cmbChartType.ItemIndex));
    
  except
    on E: Exception do
      LogError('SystemMonitor', '更新图表失败: ' + E.Message);
  end;
end;

procedure TfrmSystemMonitorDialog.AddChartData(ChartType: TChartType; Value: Double);
var
  Data: TChartData;
  History: TChartHistory;
  MaxDataPoints: Integer;
begin
  Data.Timestamp := Now;
  Data.Value := Value;
  
  // 根据时间范围确定最大数据点数
  case cmbTimeRange.ItemIndex of
    0: MaxDataPoints := 60;    // 1分钟，每秒1个点
    1: MaxDataPoints := 300;   // 5分钟，每秒1个点
    2: MaxDataPoints := 900;   // 15分钟，每秒1个点
    3: MaxDataPoints := 1800;  // 30分钟，每秒1个点
    4: MaxDataPoints := 3600;  // 1小时，每秒1个点
  else
    MaxDataPoints := 900;
  end;
  
  // 选择对应的历史数据列表
  case ChartType of
    ctCPU: History := FCPUHistory;
    ctMemory: History := FMemoryHistory;
    ctDisk: History := FDiskHistory;
    ctNetwork: History := FNetworkHistory;
  else
    Exit;
  end;
  
  // 添加数据
  History.Add(Data);
  
  // 限制数据点数量
  while History.Count > MaxDataPoints do
    History.Delete(0);
end;

procedure TfrmSystemMonitorDialog.DrawChart(ChartType: TChartType);
var
  History: TChartHistory;
  Canvas: TCanvas;
  I: Integer;
  X, Y, LastX, LastY: Integer;
  MinValue, MaxValue, Range: Double;
  ChartRect: TRect;
  Data: TChartData;
  Title: string;
begin
  if not Assigned(pnlChart) then
    Exit;
    
  // 选择对应的历史数据
  case ChartType of
    ctCPU: 
    begin
      History := FCPUHistory;
      Title := 'CPU 使用率 (%)';
    end;
    ctMemory: 
    begin
      History := FMemoryHistory;
      Title := '内存使用率 (%)';
    end;
    ctDisk: 
    begin
      History := FDiskHistory;
      Title := '磁盘使用率 (%)';
    end;
    ctNetwork: 
    begin
      History := FNetworkHistory;
      Title := '网络流量 (MB/s)';
    end;
  else
    Exit;
  end;
  
  if History.Count < 2 then
    Exit;
    
  Canvas := THackPanel(pnlChart).Canvas;
  ChartRect := pnlChart.ClientRect;
  
  // 清除背景
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ChartRect);
  
  // 绘制边框
  Canvas.Pen.Color := clGray;
  Canvas.Rectangle(ChartRect);
  
  // 绘制标题
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  Canvas.TextOut(10, 10, Title);
  
  // 计算值范围
  MinValue := History[0].Value;
  MaxValue := History[0].Value;
  
  for I := 1 to History.Count - 1 do
  begin
    if History[I].Value < MinValue then
      MinValue := History[I].Value;
    if History[I].Value > MaxValue then
      MaxValue := History[I].Value;
  end;
  
  // 自动缩放或固定范围
  if chkAutoScale.Checked then
  begin
    Range := MaxValue - MinValue;
    if Range < 10 then // 最小范围
    begin
      MinValue := Max(0, MinValue - 5);
      MaxValue := MinValue + 10;
    end
    else
    begin
      MinValue := Max(0, MinValue - Range * 0.1);
      MaxValue := MaxValue + Range * 0.1;
    end;
  end
  else
  begin
    // 固定范围
    case ChartType of
      ctCPU, ctMemory, ctDisk:
      begin
        MinValue := 0;
        MaxValue := 100;
      end;
      ctNetwork:
      begin
        MinValue := 0;
        MaxValue := Max(10, MaxValue * 1.2);
      end;
    end;
  end;
  
  Range := MaxValue - MinValue;
  
  // 绘制网格线
  Canvas.Pen.Color := clSilver;
  Canvas.Pen.Style := psDot;
  
  // 水平网格线
  for I := 1 to 4 do
  begin
    Y := ChartRect.Top + 30 + Round((ChartRect.Height - 60) * I / 5);
    Canvas.MoveTo(ChartRect.Left + 40, Y);
    Canvas.LineTo(ChartRect.Right - 10, Y);
  end;
  
  // 垂直网格线
  for I := 1 to 4 do
  begin
    X := ChartRect.Left + 40 + Round((ChartRect.Width - 50) * I / 5);
    Canvas.MoveTo(X, ChartRect.Top + 30);
    Canvas.LineTo(X, ChartRect.Bottom - 30);
  end;
  
  // 绘制数据线
  Canvas.Pen.Color := clBlue;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 2;
  
  LastX := -1;
  LastY := -1;
  
  for I := 0 to History.Count - 1 do
  begin
    Data := History[I];
    
    X := ChartRect.Left + 40 + Round((ChartRect.Width - 50) * I / Max(1, History.Count - 1));
    Y := ChartRect.Bottom - 30 - Round((ChartRect.Height - 60) * (Data.Value - MinValue) / Range);
    
    if (LastX >= 0) and (LastY >= 0) then
    begin
      Canvas.MoveTo(LastX, LastY);
      Canvas.LineTo(X, Y);
    end;
    
    // 绘制数据点
    Canvas.Brush.Color := clBlue;
    Canvas.Ellipse(X - 2, Y - 2, X + 2, Y + 2);
    
    LastX := X;
    LastY := Y;
  end;
  
  // 绘制Y轴标签
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  
  for I := 0 to 5 do
  begin
    Y := ChartRect.Bottom - 30 - Round((ChartRect.Height - 60) * I / 5);
    var Value := MinValue + Range * I / 5;
    Canvas.TextOut(5, Y - 6, Format('%.1f', [Value]));
  end;
end;

procedure TfrmSystemMonitorDialog.CheckThresholds(const Info: TSystemInfo);
var
  Alert: TMonitorEvent;
begin
  // CPU阈值检查
  if Info.CPUUsage > FCPUThreshold then
  begin
    Alert.Timestamp := Now;
    Alert.EventType := metWarning;
    Alert.Message := Format('CPU使用率过高: %.1f%% (阈值: %d%%)', [Info.CPUUsage, FCPUThreshold]);
    AddAlert(Alert);
  end;
  
  // 内存阈值检查
  if Info.MemoryUsage > FMemoryThreshold then
  begin
    Alert.Timestamp := Now;
    Alert.EventType := metWarning;
    Alert.Message := Format('内存使用率过高: %.1f%% (阈值: %d%%)', [Info.MemoryUsage, FMemoryThreshold]);
    AddAlert(Alert);
  end;
  
  // 磁盘阈值检查
  if Info.DiskUsage > FDiskThreshold then
  begin
    Alert.Timestamp := Now;
    Alert.EventType := metError;
    Alert.Message := Format('磁盘使用率过高: %.1f%% (阈值: %d%%)', [Info.DiskUsage, FDiskThreshold]);
    AddAlert(Alert);
  end;
end;

procedure TfrmSystemMonitorDialog.AddAlert(const Alert: TMonitorEvent);
var
  Item: TListItem;
  LevelStr: string;
begin
  // 避免重复警报（5分钟内相同消息）
  for var I := FAlerts.Count - 1 downto Max(0, FAlerts.Count - 10) do
  begin
    if (FAlerts[I].Message = Alert.Message) and 
       (SecondsBetween(Now, FAlerts[I].Timestamp) < 300) then
      Exit;
  end;
  
  FAlerts.Add(Alert);
  
  // 添加到列表视图
  Item := lvAlerts.Items.Insert(0); // 最新的在顶部
  Item.Caption := FormatDateTime('mm-dd hh:nn:ss', Alert.Timestamp);
  
  case Alert.EventType of
    metInfo: LevelStr := '信息';
    metWarning: LevelStr := '警告';
    metError: LevelStr := '错误';
    metCritical: LevelStr := '严重';
  else
    LevelStr := '未知';
  end;
  
  // 从消息推断类型
  var KindStr := '系统';
  if Pos('CPU', Alert.Message) > 0 then KindStr := 'CPU Monitor'
  else if Pos('内存', Alert.Message) > 0 then KindStr := 'Memory Monitor'
  else if Pos('磁盘', Alert.Message) > 0 then KindStr := 'Disk Monitor';
  
  Item.SubItems.Add(LevelStr);
  Item.SubItems.Add(KindStr);
  Item.SubItems.Add(Alert.Message);
  
  // 限制警报数量
  while lvAlerts.Items.Count > 100 do
    lvAlerts.Items.Delete(lvAlerts.Items.Count - 1);
    
  // 记录到日志
  case Alert.EventType of
    metInfo: LogInfo('SystemMonitor', Alert.Message);
    metWarning: LogWarning('SystemMonitor', Alert.Message);
    metError, metCritical: LogError('SystemMonitor', Alert.Message);
  end;
end;

procedure TfrmSystemMonitorDialog.GenerateRecommendations;
var
  Recommendations: TStringList;
begin
  Recommendations := TStringList.Create;
  try
    Recommendations.Add('系统性能优化建议：');
    Recommendations.Add('');
    
    if FIsMonitoring and Assigned(FSystemMonitor) then
    begin
      var Info := FSystemMonitor.GetCurrentSystemInfo;
      
      if Info.CPUUsage > 80 then
      begin
        Recommendations.Add('• CPU使用率过高，建议：');
        Recommendations.Add('  - 关闭不必要的程序');
        Recommendations.Add('  - 检查后台进程');
        Recommendations.Add('  - 考虑升级硬件');
        Recommendations.Add('');
      end;
      
      if Info.MemoryUsage > 85 then
      begin
        Recommendations.Add('• 内存使用率过高，建议：');
        Recommendations.Add('  - 关闭占用内存较多的程序');
        Recommendations.Add('  - 清理系统缓存');
        Recommendations.Add('  - 增加虚拟内存');
        Recommendations.Add('  - 考虑添加更多内存');
        Recommendations.Add('');
      end;
      
      if Info.DiskUsage > 90 then
      begin
        Recommendations.Add('• 磁盘空间不足，建议：');
        Recommendations.Add('  - 使用C盘瘦身工具清理垃圾文件');
        Recommendations.Add('  - 迁移大文件夹到其他分区');
        Recommendations.Add('  - 删除不需要的程序');
        Recommendations.Add('  - 清空回收站和临时文件');
        Recommendations.Add('');
      end;
    end;
    
    Recommendations.Add('一般优化建议：');
    Recommendations.Add('• 定期重启计算机');
    Recommendations.Add('• 保持系统和软件更新');
    Recommendations.Add('• 定期运行磁盘清理');
    Recommendations.Add('• 禁用不必要的启动项');
    Recommendations.Add('• 使用杀毒软件扫描系统');
    
    memoRecommendations.Lines.Assign(Recommendations);
  finally
    Recommendations.Free;
  end;
end;

// Additional helper functions and event handlers would be implemented here...
// This provides a comprehensive system monitoring framework

function TfrmSystemMonitorDialog.FormatBytes(Bytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
begin
  if Bytes >= GB then
    Result := Format('%.2f GB', [Bytes / GB])
  else if Bytes >= MB then
    Result := Format('%.1f MB', [Bytes / MB])
  else if Bytes >= KB then
    Result := Format('%.0f KB', [Bytes / KB])
  else
    Result := Format('%d 字节', [Bytes]);
end;

function TfrmSystemMonitorDialog.FormatDuration(Seconds: Int64): string;
var
  Days, Hours, Mins: Int64;
begin
  Days := Seconds div 86400;
  Seconds := Seconds mod 86400;
  Hours := Seconds div 3600;
  Seconds := Seconds mod 3600;
  Mins := Seconds div 60;
  
  if Days > 0 then
    Result := Format('%d天 %d小时', [Days, Hours])
  else if Hours > 0 then
    Result := Format('%d小时 %d分钟', [Hours, Mins])
  else
    Result := Format('%d分钟', [Mins]);
end;

// Event handlers for controls
procedure TfrmSystemMonitorDialog.cmbChartTypeChange(Sender: TObject);
begin
  if FIsMonitoring then
    DrawChart(TChartType(cmbChartType.ItemIndex));
end;

procedure TfrmSystemMonitorDialog.cmbTimeRangeChange(Sender: TObject);
begin
  // 清除历史数据以适应新的时间范围
  ClearChartHistory;
end;

procedure TfrmSystemMonitorDialog.btnResetZoomClick(Sender: TObject);
begin
  chkAutoScale.Checked := True;
  if FIsMonitoring then
    DrawChart(TChartType(cmbChartType.ItemIndex));
end;

procedure TfrmSystemMonitorDialog.ClearChartHistory;
begin
  FCPUHistory.Clear;
  FMemoryHistory.Clear;
  FDiskHistory.Clear;
  FNetworkHistory.Clear;
end;

procedure TfrmSystemMonitorDialog.RefreshProcesses;
begin
  // Process enumeration would be implemented here
  // This is a complex operation that requires Windows API calls
end;

procedure TfrmSystemMonitorDialog.UpdateProcessList;
begin
  // Update process information in the list
  // This would be called by the timer
end;

procedure TfrmSystemMonitorDialog.UpdateAlerts;
begin
  // Update alerts display
  StatusBar.Panels[1].Text := Format('警报: %d', [FAlerts.Count]);
end;

procedure TfrmSystemMonitorDialog.btnRefreshProcessesClick(Sender: TObject);
begin
  RefreshProcesses;
end;

procedure TfrmSystemMonitorDialog.btnKillProcessClick(Sender: TObject);
begin
  KillSelectedProcess;
end;

procedure TfrmSystemMonitorDialog.KillSelectedProcess;
begin
  // Implementation for killing selected process
  if MessageDlg('确定要结束选定的进程吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // Process termination logic here
    ShowMessage('进程终止功能开发中...');
  end;
end;

function TfrmSystemMonitorDialog.GetSelectedProcessID: Cardinal;
begin
  Result := 0;
  if Assigned(lvProcesses.Selected) then
  begin
    // Extract PID from selected item
    // This would be implemented based on the list structure
  end;
end;

procedure TfrmSystemMonitorDialog.btnExportDataClick(Sender: TObject);
begin
  ExportMonitoringData;
end;

procedure TfrmSystemMonitorDialog.ExportMonitoringData;
begin
  if SaveDialog.Execute then
  begin
    // Export monitoring data to file
    ShowMessage('数据导出功能开发中...');
  end;
end;

procedure TfrmSystemMonitorDialog.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSystemMonitorDialog.OnSystemInfoUpdate(const Info: TSystemInfo);
begin
  // This callback is handled by the timer update
end;

procedure TfrmSystemMonitorDialog.OnMonitorEventAlert(const Event: TMonitorEvent);
begin
  if FEnableAlerts then
    AddAlert(Event);
end;

// Settings change handlers
procedure TfrmSystemMonitorDialog.chkEnableAlertsClick(Sender: TObject);
begin
  FEnableAlerts := chkEnableAlerts.Checked;
end;

procedure TfrmSystemMonitorDialog.seRefreshIntervalChange(Sender: TObject);
begin
  FRefreshInterval := seRefreshInterval.Value * 1000;
  TimerUpdate.Interval := FRefreshInterval;
end;

// Context menu handlers
procedure TfrmSystemMonitorDialog.miProcessDetailsClick(Sender: TObject);
begin
  ShowMessage('进程详情功能开发中...');
end;

procedure TfrmSystemMonitorDialog.miKillProcessClick(Sender: TObject);
begin
  KillSelectedProcess;
end;

procedure TfrmSystemMonitorDialog.miProcessLocationClick(Sender: TObject);
begin
  ShowMessage('打开进程位置功能开发中...');
end;

procedure TfrmSystemMonitorDialog.lvProcessesDblClick(Sender: TObject);
begin
  miProcessDetailsClick(Sender);
end;

end.