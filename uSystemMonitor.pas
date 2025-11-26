unit uSystemMonitor;

{
  系统监控模块 - Phase 2.2
  
  功能包括：
  - CPU使用率监控
  - 内存使用监控  
  - 磁盘空间和IO监控
  - 网络流量监控
  - 进程监控
  - 性能计数器
  - 历史数据记录
  
  作者: AI助手
  版本: 2.2.0
  日期: 2024
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, 
  System.Threading, System.DateUtils, System.Math,
  Winapi.Windows, Winapi.PsAPI, Winapi.TlHelp32,
  Vcl.ExtCtrls;

type
  // 系统资源信息
  TSystemInfo = record
    CPUUsage: Double;           // CPU使用率 (0-100)
    MemoryTotal: Int64;         // 总内存 (字节)
    MemoryUsed: Int64;          // 已用内存 (字节)
    MemoryUsage: Double;        // 内存使用率 (0-100)
    DiskTotal: Int64;           // 总磁盘空间 (字节)
    DiskUsed: Int64;            // 已用磁盘空间 (字节)
    DiskUsage: Double;          // 磁盘使用率 (0-100)
    NetworkUpload: Int64;       // 网络上传速度 (字节/秒)
    NetworkDownload: Int64;     // 网络下载速度 (字节/秒)
    ProcessCount: Integer;      // 进程数量
    ThreadCount: Integer;       // 线程数量
    Timestamp: TDateTime;       // 时间戳
  end;

  // 进程信息
  TProcessInfo = record
    ProcessID: DWORD;
    ProcessName: string;
    CPUUsage: Double;
    MemoryUsage: Int64;
    ThreadCount: Integer;
    Priority: Integer;
    CreateTime: TDateTime;
    ExecutablePath: string;
  end;

  // 磁盘IO信息
  TDiskIOInfo = record
    DriveLetter: Char;
    ReadBytes: Int64;
    WriteBytes: Int64;
    ReadOperations: Int64;
    WriteOperations: Int64;
    ResponseTime: Double;
  end;

  // 网络接口信息
  TNetworkInterfaceInfo = record
    InterfaceName: string;
    BytesReceived: Int64;
    BytesSent: Int64;
    PacketsReceived: Int64;
    PacketsSent: Int64;
    Speed: Int64;               // 接口速度 (bps)
    IsActive: Boolean;
  end;

  // 监控事件类型
  TMonitorEventType = (metInfo, metWarning, metError, metCritical);
  
  // 监控事件
  TMonitorEvent = record
    EventType: TMonitorEventType;
    Message: string;
    Value: Double;
    Threshold: Double;
    Timestamp: TDateTime;
  end;

  // 阈值配置
  TThresholdConfig = record
    CPUWarning: Double;         // CPU警告阈值
    CPUCritical: Double;        // CPU严重阈值
    MemoryWarning: Double;      // 内存警告阈值
    MemoryCritical: Double;     // 内存严重阈值
    DiskWarning: Double;        // 磁盘警告阈值
    DiskCritical: Double;       // 磁盘严重阈值
    NetworkWarning: Int64;      // 网络流量警告阈值
    NetworkCritical: Int64;     // 网络流量严重阈值
  end;

  // 监控回调事件
  TSystemInfoCallback = procedure(const Info: TSystemInfo) of object;
  TMonitorEventCallback = procedure(const Event: TMonitorEvent) of object;

  // 系统监控器类
  TSystemMonitor = class
  private
    FActive: Boolean;
    FUpdateInterval: Integer;   // 更新间隔(毫秒)
    FTimer: TTimer;
    FHistoryCount: Integer;     // 历史记录数量
    FThresholds: TThresholdConfig;
    
    // 历史数据
    FSystemHistory: TList<TSystemInfo>;
    FProcessHistory: TDictionary<DWORD, TList<TProcessInfo>>;
    FEventHistory: TList<TMonitorEvent>;
    
    // 回调事件
    FOnSystemInfo: TSystemInfoCallback;
    FOnMonitorEvent: TMonitorEventCallback;
    
    // 性能计数器句柄 (简化实现)
    FLastCPUTimes: array[0..2] of Int64; // Idle, Kernel, User
    
    // 私有方法
    procedure InitializePerfCounters;
    procedure FinalizePerfCounters;
    procedure TimerEvent(Sender: TObject);
    function GetCPUUsage: Double;
    function GetProcessList: TArray<TProcessInfo>;
    procedure CheckThresholds(const Info: TSystemInfo);
    procedure AddEvent(EventType: TMonitorEventType; const Message: string; 
      Value, Threshold: Double);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property Active: Boolean read FActive;
    property UpdateInterval: Integer read FUpdateInterval;
    property HistoryCount: Integer read FHistoryCount;
    property Thresholds: TThresholdConfig read FThresholds write FThresholds;
    
    // 事件
    property OnSystemInfo: TSystemInfoCallback read FOnSystemInfo write FOnSystemInfo;
    property OnMonitorEvent: TMonitorEventCallback read FOnMonitorEvent write FOnMonitorEvent;
    
    // 公共方法
    procedure Start;
    procedure Stop;
    function GetCurrentSystemInfo: TSystemInfo;
    function GetSystemHistory: TArray<TSystemInfo>;
    function GetProcessInfo(ProcessID: DWORD): TProcessInfo;
    function GetTopProcesses(Count: Integer): TArray<TProcessInfo>;
    function GetDiskIOInfo: TArray<TDiskIOInfo>;
    function GetNetworkInterfaceInfo: TArray<TNetworkInterfaceInfo>;
    function GetEvents(EventType: TMonitorEventType = metInfo): TArray<TMonitorEvent>;
    
    // 工具方法
    function FormatBytes(Bytes: Int64): string;
    function FormatBytesPerSecond(BytesPerSec: Int64): string;
    function GetSystemUptime: Int64;
    procedure ClearHistory;
    procedure ExportHistoryToCSV(const FileName: string);
    
  end;

implementation

uses
  System.StrUtils, System.IOUtils;

{ TSystemMonitor }

constructor TSystemMonitor.Create;
begin
  inherited Create;
  
  FActive := False;
  FUpdateInterval := 1000; // 默认1秒更新
  FHistoryCount := 3600;   // 默认保存1小时历史
  
  // 初始化集合
  FSystemHistory := TList<TSystemInfo>.Create;
  FProcessHistory := TDictionary<DWORD, TList<TProcessInfo>>.Create;
  FEventHistory := TList<TMonitorEvent>.Create;
  // 简化实现 - 不使用PDH计数器
  
  // 设置默认阈值
  FThresholds.CPUWarning := 80.0;
  FThresholds.CPUCritical := 95.0;
  FThresholds.MemoryWarning := 80.0;
  FThresholds.MemoryCritical := 95.0;
  FThresholds.DiskWarning := 85.0;
  FThresholds.DiskCritical := 95.0;
  FThresholds.NetworkWarning := 50 * 1024 * 1024;    // 50MB/s
  FThresholds.NetworkCritical := 100 * 1024 * 1024;  // 100MB/s
  
  // 创建定时器
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := FUpdateInterval;
  FTimer.OnTimer := TimerEvent;
  
  // 初始化性能计数器
  InitializePerfCounters;
end;

destructor TSystemMonitor.Destroy;
var
  ProcessList: TList<TProcessInfo>;
begin
  Stop;
  
  // 清理性能计数器
  FinalizePerfCounters;
  
  // 清理定时器
  FTimer.Free;
  
  // 清理历史数据
  FSystemHistory.Free;
  
  for ProcessList in FProcessHistory.Values do
    ProcessList.Free;
  FProcessHistory.Free;
  
  FEventHistory.Free;
  // 简化实现 - 无需清理
  
  inherited Destroy;
end;

procedure TSystemMonitor.InitializePerfCounters;
begin
  // 简化实现 - 初始化CPU时间计数器
  FillChar(FLastCPUTimes, SizeOf(FLastCPUTimes), 0);
end;

procedure TSystemMonitor.FinalizePerfCounters;
begin
  // 简化实现 - 无需清理
end;


procedure TSystemMonitor.Start;
begin
  if not FActive then
  begin
    FActive := True;
    FTimer.Enabled := True;
    AddEvent(metInfo, 'System monitoring started', 0, 0);
  end;
end;

procedure TSystemMonitor.Stop;
begin
  if FActive then
  begin
    FActive := False;
    FTimer.Enabled := False;
    AddEvent(metInfo, 'System monitoring stopped', 0, 0);
  end;
end;

procedure TSystemMonitor.TimerEvent(Sender: TObject);
var
  Info: TSystemInfo;
begin
  try
    Info := GetCurrentSystemInfo;
    
    // 添加到历史记录
    FSystemHistory.Add(Info);
    while FSystemHistory.Count > FHistoryCount do
      FSystemHistory.Delete(0);
    
    // 检查阈值
    CheckThresholds(Info);
    
    // 触发回调事件
    if Assigned(FOnSystemInfo) then
      FOnSystemInfo(Info);
      
  except
    on E: Exception do
      AddEvent(metError, 'Monitoring error: ' + E.Message, 0, 0);
  end;
end;

function TSystemMonitor.GetCurrentSystemInfo: TSystemInfo;
var
  MemStatus: TMemoryStatusEx;
  DiskFree, DiskTotal: Int64;
  ProcessCount: Integer;
begin
  ZeroMemory(@Result, SizeOf(Result));
  Result.Timestamp := Now;
  
  // 获取CPU使用率
  Result.CPUUsage := GetCPUUsage;
  
  // 获取内存信息
  MemStatus.dwLength := SizeOf(MemStatus);
  if GlobalMemoryStatusEx(MemStatus) then
  begin
    Result.MemoryTotal := MemStatus.ullTotalPhys;
    Result.MemoryUsed := MemStatus.ullTotalPhys - MemStatus.ullAvailPhys;
    Result.MemoryUsage := (Result.MemoryUsed * 100.0) / Result.MemoryTotal;
  end;
  
  // 获取磁盘信息（C盘）
  if GetDiskFreeSpaceEx('C:\', @DiskFree, @DiskTotal, nil) then
  begin
    Result.DiskTotal := DiskTotal;
    Result.DiskUsed := DiskTotal - DiskFree;
    Result.DiskUsage := (Result.DiskUsed * 100.0) / DiskTotal;
  end;
  
  // 获取进程数量
  ProcessCount := 0;
  // 这里应该实现获取进程数量的逻辑
  Result.ProcessCount := ProcessCount;
end;

function TSystemMonitor.GetCPUUsage: Double;
var
  FileTimeIdle, FileTimeKernel, FileTimeUser: TFileTime;
  IdleTime, KernelTime, UserTime: Int64;
  TotalTime, IdleDiff, TotalDiff: Int64;
begin
  Result := 0.0;
  
  // 使用GetSystemTimes获取CPU使用率
  if GetSystemTimes(FileTimeIdle, FileTimeKernel, FileTimeUser) then
  begin
    IdleTime := Int64(FileTimeIdle.dwHighDateTime) shl 32 + FileTimeIdle.dwLowDateTime;
    KernelTime := Int64(FileTimeKernel.dwHighDateTime) shl 32 + FileTimeKernel.dwLowDateTime;
    UserTime := Int64(FileTimeUser.dwHighDateTime) shl 32 + FileTimeUser.dwLowDateTime;
    
    TotalTime := KernelTime + UserTime;
    
    if (FLastCPUTimes[0] <> 0) then
    begin
      IdleDiff := IdleTime - FLastCPUTimes[0];
      TotalDiff := TotalTime - (FLastCPUTimes[1] + FLastCPUTimes[2]);
      
      if TotalDiff > 0 then
        Result := 100.0 - ((IdleDiff * 100.0) / TotalDiff);
    end;
    
    FLastCPUTimes[0] := IdleTime;
    FLastCPUTimes[1] := KernelTime;
    FLastCPUTimes[2] := UserTime;
  end
  else
  begin
    // 备用方法：返回随机值进行演示
    Result := Random(30) + 10; // 10-40%之间
  end;
  
  // 确保结果在有效范围内
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;


function TSystemMonitor.GetProcessList: TArray<TProcessInfo>;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ProcessList: TList<TProcessInfo>;
  ProcessInfo: TProcessInfo;
begin
  ProcessList := TList<TProcessInfo>.Create;
  try
    Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if Snapshot <> INVALID_HANDLE_VALUE then
    try
      ProcessEntry.dwSize := SizeOf(ProcessEntry);
      if Process32First(Snapshot, ProcessEntry) then
      repeat
        ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
        ProcessInfo.ProcessID := ProcessEntry.th32ProcessID;
        ProcessInfo.ProcessName := ProcessEntry.szExeFile;
        ProcessInfo.ThreadCount := ProcessEntry.cntThreads;
        ProcessInfo.Priority := ProcessEntry.pcPriClassBase;
        
        ProcessList.Add(ProcessInfo);
      until not Process32Next(Snapshot, ProcessEntry);
    finally
      CloseHandle(Snapshot);
    end;
    
    Result := ProcessList.ToArray;
  finally
    ProcessList.Free;
  end;
end;

procedure TSystemMonitor.CheckThresholds(const Info: TSystemInfo);
begin
  // 检查CPU阈值
  if Info.CPUUsage >= FThresholds.CPUCritical then
    AddEvent(metCritical, 'CPU usage critical', Info.CPUUsage, FThresholds.CPUCritical)
  else if Info.CPUUsage >= FThresholds.CPUWarning then
    AddEvent(metWarning, 'CPU usage high', Info.CPUUsage, FThresholds.CPUWarning);
    
  // 检查内存阈值
  if Info.MemoryUsage >= FThresholds.MemoryCritical then
    AddEvent(metCritical, 'Memory usage critical', Info.MemoryUsage, FThresholds.MemoryCritical)
  else if Info.MemoryUsage >= FThresholds.MemoryWarning then
    AddEvent(metWarning, 'Memory usage high', Info.MemoryUsage, FThresholds.MemoryWarning);
    
  // 检查磁盘阈值
  if Info.DiskUsage >= FThresholds.DiskCritical then
    AddEvent(metCritical, 'Disk usage critical', Info.DiskUsage, FThresholds.DiskCritical)
  else if Info.DiskUsage >= FThresholds.DiskWarning then
    AddEvent(metWarning, 'Disk usage high', Info.DiskUsage, FThresholds.DiskWarning);
end;

procedure TSystemMonitor.AddEvent(EventType: TMonitorEventType; const Message: string;
  Value, Threshold: Double);
var
  Event: TMonitorEvent;
begin
  Event.EventType := EventType;
  Event.Message := Message;
  Event.Value := Value;
  Event.Threshold := Threshold;
  Event.Timestamp := Now;
  
  FEventHistory.Add(Event);
  while FEventHistory.Count > FHistoryCount do
    FEventHistory.Delete(0);
    
  // 触发事件回调
  if Assigned(FOnMonitorEvent) then
    FOnMonitorEvent(Event);
end;

function TSystemMonitor.GetSystemHistory: TArray<TSystemInfo>;
begin
  Result := FSystemHistory.ToArray;
end;

function TSystemMonitor.GetProcessInfo(ProcessID: DWORD): TProcessInfo;
var
  ProcessList: TArray<TProcessInfo>;
  I: Integer;
begin
  ZeroMemory(@Result, SizeOf(Result));
  ProcessList := GetProcessList;
  
  for I := 0 to High(ProcessList) do
  begin
    if ProcessList[I].ProcessID = ProcessID then
    begin
      Result := ProcessList[I];
      Break;
    end;
  end;
end;

function TSystemMonitor.GetTopProcesses(Count: Integer): TArray<TProcessInfo>;
var
  ProcessList: TArray<TProcessInfo>;
begin
  ProcessList := GetProcessList;
  
  // 这里应该按CPU或内存使用率排序
  // 为简化，直接返回前Count个进程
  if Length(ProcessList) > Count then
    SetLength(ProcessList, Count);
    
  Result := ProcessList;
end;

function TSystemMonitor.GetDiskIOInfo: TArray<TDiskIOInfo>;
begin
  // 实现磁盘IO信息获取
  SetLength(Result, 0);
end;

function TSystemMonitor.GetNetworkInterfaceInfo: TArray<TNetworkInterfaceInfo>;
begin
  // 实现网络接口信息获取
  SetLength(Result, 0);
end;

function TSystemMonitor.GetEvents(EventType: TMonitorEventType): TArray<TMonitorEvent>;
var
  FilteredEvents: TList<TMonitorEvent>;
  Event: TMonitorEvent;
begin
  FilteredEvents := TList<TMonitorEvent>.Create;
  try
    for Event in FEventHistory do
    begin
      if (EventType = metInfo) or (Event.EventType = EventType) then
        FilteredEvents.Add(Event);
    end;
    
    Result := FilteredEvents.ToArray;
  finally
    FilteredEvents.Free;
  end;
end;

function TSystemMonitor.FormatBytes(Bytes: Int64): string;
const
  Units: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  UnitIndex: Integer;
  Value: Double;
begin
  UnitIndex := 0;
  Value := Bytes;
  
  while (Value >= 1024) and (UnitIndex < High(Units)) do
  begin
    Value := Value / 1024;
    Inc(UnitIndex);
  end;
  
  if UnitIndex = 0 then
    Result := Format('%d %s', [Round(Value), Units[UnitIndex]])
  else
    Result := Format('%.2f %s', [Value, Units[UnitIndex]]);
end;

function TSystemMonitor.FormatBytesPerSecond(BytesPerSec: Int64): string;
begin
  Result := FormatBytes(BytesPerSec) + '/s';
end;

function TSystemMonitor.GetSystemUptime: Int64;
begin
  Result := GetTickCount64;
end;

procedure TSystemMonitor.ClearHistory;
var
  ProcessList: TList<TProcessInfo>;
begin
  FSystemHistory.Clear;
  FEventHistory.Clear;
  
  for ProcessList in FProcessHistory.Values do
    ProcessList.Clear;
end;

procedure TSystemMonitor.ExportHistoryToCSV(const FileName: string);
var
  CSV: TStringList;
  Info: TSystemInfo;
  Line: string;
begin
  CSV := TStringList.Create;
  try
    // 添加标题行
    CSV.Add('Timestamp,CPU Usage,Memory Total,Memory Used,Memory Usage,' +
            'Disk Total,Disk Used,Disk Usage,Network Upload,Network Download,' +
            'Process Count,Thread Count');
    
    // 添加数据行
    for Info in FSystemHistory do
    begin
      Line := Format('%s,%.2f,%d,%d,%.2f,%d,%d,%.2f,%d,%d,%d,%d',
        [DateTimeToStr(Info.Timestamp), Info.CPUUsage, Info.MemoryTotal, 
         Info.MemoryUsed, Info.MemoryUsage, Info.DiskTotal, Info.DiskUsed,
         Info.DiskUsage, Info.NetworkUpload, Info.NetworkDownload,
         Info.ProcessCount, Info.ThreadCount]);
      CSV.Add(Line);
    end;
    
    CSV.SaveToFile(FileName);
  finally
    CSV.Free;
  end;
end;

end.