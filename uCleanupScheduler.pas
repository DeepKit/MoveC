unit uCleanupScheduler;

{
  清理任务调度器 - Cleanup Task Scheduler
  
  功能：
  - 定时自动执行清理任务
  - 支持多种清理类型（回收站、临时文件等）
  - 任务配置持久化
  - 后台静默执行
  - 清理历史记录
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.IOUtils, System.IniFiles, System.DateUtils,
  System.Generics.Collections, Vcl.ExtCtrls,
  uCleanupManager, uLogManager;

type
  // 清理任务类型
  TScheduledCleanupType = (
    sctRecycleBin,      // 回收站
    sctTempFiles,       // 临时文件
    sctWindowsUpdate,   // Windows更新缓存
    sctBrowserCache,    // 浏览器缓存
    sctThumbnails,      // 缩略图缓存
    sctPrefetch,        // 预读取文件
    sctLogFiles         // 日志文件
  );
  
  TScheduledCleanupTypes = set of TScheduledCleanupType;
  
  // 任务执行频率
  TScheduleFrequency = (
    sfDisabled,         // 禁用
    sfDaily,            // 每天
    sfWeekly,           // 每周
    sfMonthly,          // 每月
    sfOnStartup         // 启动时
  );
  
  // 定时任务配置
  TScheduledTask = record
    ID: Integer;
    Name: string;
    CleanupTypes: TScheduledCleanupTypes;
    Frequency: TScheduleFrequency;
    ExecuteTime: TTime;          // 执行时间（时:分）
    DayOfWeek: Integer;          // 周几（1-7，仅周任务）
    DayOfMonth: Integer;         // 几号（1-31，仅月任务）
    MinFreeDiskMB: Integer;      // 最小剩余空间MB（低于此值才执行）
    Enabled: Boolean;
    LastExecuted: TDateTime;
    NextExecute: TDateTime;
    LastResult: string;
  end;
  
  // 任务执行结果
  TScheduledTaskResult = record
    TaskID: Integer;
    ExecuteTime: TDateTime;
    Success: Boolean;
    FilesDeleted: Integer;
    SpaceFreed: Int64;
    ErrorMessage: string;
  end;
  
  // 调度器事件
  TSchedulerEvent = procedure(const Task: TScheduledTask; 
    const Result: TScheduledTaskResult) of object;

  TCleanupScheduler = class
  private
    FTasks: TList<TScheduledTask>;
    FTimer: TTimer;
    FConfigFile: string;
    FCleanupManager: TCleanupManager;
    FEnabled: Boolean;
    FOnTaskComplete: TSchedulerEvent;
    FLastCheckTime: TDateTime;
    
    procedure TimerTick(Sender: TObject);
    procedure LoadConfig;
    procedure SaveConfig;
    function GetConfigFile: string;
    function ShouldExecuteTask(const Task: TScheduledTask): Boolean;
    function CalculateNextExecute(const Task: TScheduledTask): TDateTime;
    function ExecuteTask(var Task: TScheduledTask): TScheduledTaskResult;
    function CleanupTypeToString(AType: TScheduledCleanupType): string;
    function StringToCleanupType(const S: string): TScheduledCleanupType;
    function FrequencyToString(AFreq: TScheduleFrequency): string;
    function StringToFrequency(const S: string): TScheduleFrequency;
    function GetCDriveFreeSpaceMB: Integer;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 任务管理
    function AddTask(const AName: string; ATypes: TScheduledCleanupTypes;
      AFrequency: TScheduleFrequency; ATime: TTime): Integer;
    procedure UpdateTask(const Task: TScheduledTask);
    procedure DeleteTask(TaskID: Integer);
    function GetTask(TaskID: Integer): TScheduledTask;
    function GetAllTasks: TArray<TScheduledTask>;
    
    // 手动执行
    function ExecuteTaskNow(TaskID: Integer): TScheduledTaskResult;
    procedure ExecuteStartupTasks;
    
    // 调度器控制
    procedure Start;
    procedure Stop;
    
    // 属性
    property Enabled: Boolean read FEnabled;
    property OnTaskComplete: TSchedulerEvent read FOnTaskComplete write FOnTaskComplete;
  end;
  
  // 全局单例
  function CleanupScheduler: TCleanupScheduler;

implementation

var
  _CleanupScheduler: TCleanupScheduler = nil;

function CleanupScheduler: TCleanupScheduler;
begin
  if _CleanupScheduler = nil then
    _CleanupScheduler := TCleanupScheduler.Create;
  Result := _CleanupScheduler;
end;

{ TCleanupScheduler }

constructor TCleanupScheduler.Create;
begin
  inherited Create;
  FTasks := TList<TScheduledTask>.Create;
  FConfigFile := GetConfigFile;
  FCleanupManager := TCleanupManager.Create;
  FEnabled := False;
  FLastCheckTime := Now;
  
  // 创建定时器（每分钟检查一次）
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 60000;  // 60秒
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;
  
  LoadConfig;
end;

destructor TCleanupScheduler.Destroy;
begin
  Stop;
  SaveConfig;
  FTimer.Free;
  FCleanupManager.Free;
  FTasks.Free;
  inherited;
end;

function TCleanupScheduler.GetConfigFile: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'CleanupScheduler.ini');
end;

procedure TCleanupScheduler.LoadConfig;
var
  IniFile: TIniFile;
  TaskCount, I, J: Integer;
  Task: TScheduledTask;
  Section: string;
  TypesStr: string;
  TypeParts: TArray<string>;
begin
  if not TFile.Exists(FConfigFile) then Exit;
  
  FTasks.Clear;
  
  IniFile := TIniFile.Create(FConfigFile);
  try
    TaskCount := IniFile.ReadInteger('General', 'TaskCount', 0);
    
    for I := 0 to TaskCount - 1 do
    begin
      Section := Format('Task_%d', [I]);
      
      Task.ID := IniFile.ReadInteger(Section, 'ID', I);
      Task.Name := IniFile.ReadString(Section, 'Name', '');
      Task.Frequency := StringToFrequency(IniFile.ReadString(Section, 'Frequency', 'Disabled'));
      Task.ExecuteTime := StrToTimeDef(IniFile.ReadString(Section, 'ExecuteTime', '03:00'), EncodeTime(3, 0, 0, 0));
      Task.DayOfWeek := IniFile.ReadInteger(Section, 'DayOfWeek', 1);
      Task.DayOfMonth := IniFile.ReadInteger(Section, 'DayOfMonth', 1);
      Task.MinFreeDiskMB := IniFile.ReadInteger(Section, 'MinFreeDiskMB', 0);
      Task.Enabled := IniFile.ReadBool(Section, 'Enabled', True);
      Task.LastExecuted := IniFile.ReadDateTime(Section, 'LastExecuted', 0);
      Task.LastResult := IniFile.ReadString(Section, 'LastResult', '');
      
      // 解析清理类型
      Task.CleanupTypes := [];
      TypesStr := IniFile.ReadString(Section, 'CleanupTypes', '');
      if TypesStr <> '' then
      begin
        TypeParts := TypesStr.Split([',']);
        for J := 0 to High(TypeParts) do
          Include(Task.CleanupTypes, StringToCleanupType(Trim(TypeParts[J])));
      end;
      
      Task.NextExecute := CalculateNextExecute(Task);
      
      if Task.Name <> '' then
        FTasks.Add(Task);
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TCleanupScheduler.SaveConfig;
var
  IniFile: TIniFile;
  I: Integer;
  Task: TScheduledTask;
  Section: string;
  TypesStr: string;
  CT: TScheduledCleanupType;
begin
  IniFile := TIniFile.Create(FConfigFile);
  try
    IniFile.WriteInteger('General', 'TaskCount', FTasks.Count);
    
    for I := 0 to FTasks.Count - 1 do
    begin
      Task := FTasks[I];
      Section := Format('Task_%d', [I]);
      
      IniFile.WriteInteger(Section, 'ID', Task.ID);
      IniFile.WriteString(Section, 'Name', Task.Name);
      IniFile.WriteString(Section, 'Frequency', FrequencyToString(Task.Frequency));
      IniFile.WriteString(Section, 'ExecuteTime', TimeToStr(Task.ExecuteTime));
      IniFile.WriteInteger(Section, 'DayOfWeek', Task.DayOfWeek);
      IniFile.WriteInteger(Section, 'DayOfMonth', Task.DayOfMonth);
      IniFile.WriteInteger(Section, 'MinFreeDiskMB', Task.MinFreeDiskMB);
      IniFile.WriteBool(Section, 'Enabled', Task.Enabled);
      IniFile.WriteDateTime(Section, 'LastExecuted', Task.LastExecuted);
      IniFile.WriteString(Section, 'LastResult', Task.LastResult);
      
      // 序列化清理类型
      TypesStr := '';
      for CT := Low(TScheduledCleanupType) to High(TScheduledCleanupType) do
      begin
        if CT in Task.CleanupTypes then
        begin
          if TypesStr <> '' then TypesStr := TypesStr + ',';
          TypesStr := TypesStr + CleanupTypeToString(CT);
        end;
      end;
      IniFile.WriteString(Section, 'CleanupTypes', TypesStr);
    end;
    
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

function TCleanupScheduler.CleanupTypeToString(AType: TScheduledCleanupType): string;
begin
  case AType of
    sctRecycleBin: Result := 'RecycleBin';
    sctTempFiles: Result := 'TempFiles';
    sctWindowsUpdate: Result := 'WindowsUpdate';
    sctBrowserCache: Result := 'BrowserCache';
    sctThumbnails: Result := 'Thumbnails';
    sctPrefetch: Result := 'Prefetch';
    sctLogFiles: Result := 'LogFiles';
  else
    Result := 'Unknown';
  end;
end;

function TCleanupScheduler.StringToCleanupType(const S: string): TScheduledCleanupType;
begin
  if SameText(S, 'RecycleBin') then Result := sctRecycleBin
  else if SameText(S, 'TempFiles') then Result := sctTempFiles
  else if SameText(S, 'WindowsUpdate') then Result := sctWindowsUpdate
  else if SameText(S, 'BrowserCache') then Result := sctBrowserCache
  else if SameText(S, 'Thumbnails') then Result := sctThumbnails
  else if SameText(S, 'Prefetch') then Result := sctPrefetch
  else if SameText(S, 'LogFiles') then Result := sctLogFiles
  else Result := sctTempFiles;
end;

function TCleanupScheduler.FrequencyToString(AFreq: TScheduleFrequency): string;
begin
  case AFreq of
    sfDisabled: Result := 'Disabled';
    sfDaily: Result := 'Daily';
    sfWeekly: Result := 'Weekly';
    sfMonthly: Result := 'Monthly';
    sfOnStartup: Result := 'OnStartup';
  else
    Result := 'Disabled';
  end;
end;

function TCleanupScheduler.StringToFrequency(const S: string): TScheduleFrequency;
begin
  if SameText(S, 'Daily') then Result := sfDaily
  else if SameText(S, 'Weekly') then Result := sfWeekly
  else if SameText(S, 'Monthly') then Result := sfMonthly
  else if SameText(S, 'OnStartup') then Result := sfOnStartup
  else Result := sfDisabled;
end;

function TCleanupScheduler.GetCDriveFreeSpaceMB: Integer;
var
  FreeBytes, TotalBytes: Int64;
begin
  Result := 0;
  if GetDiskFreeSpaceEx('C:\', FreeBytes, TotalBytes, nil) then
    Result := FreeBytes div (1024 * 1024);
end;

function TCleanupScheduler.CalculateNextExecute(const Task: TScheduledTask): TDateTime;
var
  Now_: TDateTime;
  NextDate: TDateTime;
  TaskTime: TDateTime;
  DaysDiff: Integer;
begin
  Result := 0;
  if Task.Frequency = sfDisabled then Exit;
  if Task.Frequency = sfOnStartup then Exit;  // 启动时任务不需要计算下次时间
  
  Now_ := Now;
  TaskTime := Trunc(Now_) + Frac(Task.ExecuteTime);
  
  case Task.Frequency of
    sfDaily:
    begin
      if TaskTime > Now_ then
        Result := TaskTime
      else
        Result := TaskTime + 1;
    end;
    
    sfWeekly:
    begin
      DaysDiff := Task.DayOfWeek - DayOfWeek(Now_);
      if DaysDiff < 0 then DaysDiff := DaysDiff + 7;
      NextDate := Trunc(Now_) + DaysDiff;
      Result := NextDate + Frac(Task.ExecuteTime);
      if Result <= Now_ then
        Result := Result + 7;
    end;
    
    sfMonthly:
    begin
      NextDate := EncodeDate(YearOf(Now_), MonthOf(Now_), 
                             Min(Task.DayOfMonth, DaysInMonth(Now_)));
      Result := NextDate + Frac(Task.ExecuteTime);
      if Result <= Now_ then
        Result := IncMonth(Result, 1);
    end;
  end;
end;

function TCleanupScheduler.ShouldExecuteTask(const Task: TScheduledTask): Boolean;
var
  Now_: TDateTime;
  FreeSpaceMB: Integer;
begin
  Result := False;
  
  if not Task.Enabled then Exit;
  if Task.Frequency = sfDisabled then Exit;
  if Task.Frequency = sfOnStartup then Exit;  // 启动任务由单独方法处理
  
  Now_ := Now;
  
  // 检查是否到了执行时间
  if Task.NextExecute > Now_ then Exit;
  
  // 检查最小磁盘空间限制
  if Task.MinFreeDiskMB > 0 then
  begin
    FreeSpaceMB := GetCDriveFreeSpaceMB;
    if FreeSpaceMB >= Task.MinFreeDiskMB then Exit;  // 空间足够，不需要清理
  end;
  
  Result := True;
end;

function TCleanupScheduler.ExecuteTask(var Task: TScheduledTask): TScheduledTaskResult;
var
  CleanResult: TCleanupResult;
  CT: TScheduledCleanupType;
begin
  Result.TaskID := Task.ID;
  Result.ExecuteTime := Now;
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  
  LogInfo('CleanupScheduler', Format('开始执行定时任务: %s', [Task.Name]));
  
  try
    for CT := Low(TScheduledCleanupType) to High(TScheduledCleanupType) do
    begin
      if CT in Task.CleanupTypes then
      begin
        case CT of
          sctRecycleBin:
          begin
            CleanResult := FCleanupManager.EmptyRecycleBin;
            Inc(Result.FilesDeleted, CleanResult.FilesDeleted);
            Inc(Result.SpaceFreed, CleanResult.SpaceFreed);
          end;
          
          sctTempFiles:
          begin
            CleanResult := FCleanupManager.CleanTempFiles;
            Inc(Result.FilesDeleted, CleanResult.FilesDeleted);
            Inc(Result.SpaceFreed, CleanResult.SpaceFreed);
          end;
          
          sctWindowsUpdate:
          begin
            CleanResult := FCleanupManager.CleanWindowsUpdateCache;
            Inc(Result.FilesDeleted, CleanResult.FilesDeleted);
            Inc(Result.SpaceFreed, CleanResult.SpaceFreed);
          end;
          
          sctBrowserCache:
          begin
            CleanResult := FCleanupManager.CleanBrowserCache;
            Inc(Result.FilesDeleted, CleanResult.FilesDeleted);
            Inc(Result.SpaceFreed, CleanResult.SpaceFreed);
          end;
          
          sctThumbnails:
          begin
            CleanResult := FCleanupManager.CleanThumbnailCache;
            Inc(Result.FilesDeleted, CleanResult.FilesDeleted);
            Inc(Result.SpaceFreed, CleanResult.SpaceFreed);
          end;
          
          // Prefetch和LogFiles暂不实现
        end;
      end;
    end;
    
    // 更新任务状态
    Task.LastExecuted := Now;
    Task.NextExecute := CalculateNextExecute(Task);
    Task.LastResult := Format('成功: 删除 %d 文件, 释放 %.2f MB',
      [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]);
    
    LogInfo('CleanupScheduler', Task.LastResult);
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Task.LastResult := '失败: ' + E.Message;
      LogError('CleanupScheduler', '任务执行失败: ' + E.Message);
    end;
  end;
end;

procedure TCleanupScheduler.TimerTick(Sender: TObject);
var
  I: Integer;
  Task: TScheduledTask;
  TaskResult: TScheduledTaskResult;
begin
  if not FEnabled then Exit;
  
  FLastCheckTime := Now;
  
  for I := 0 to FTasks.Count - 1 do
  begin
    Task := FTasks[I];
    if ShouldExecuteTask(Task) then
    begin
      TaskResult := ExecuteTask(Task);
      FTasks[I] := Task;  // 更新列表中的任务
      
      // 触发事件
      if Assigned(FOnTaskComplete) then
        FOnTaskComplete(Task, TaskResult);
      
      SaveConfig;
    end;
  end;
end;

function TCleanupScheduler.AddTask(const AName: string; ATypes: TScheduledCleanupTypes;
  AFrequency: TScheduleFrequency; ATime: TTime): Integer;
var
  Task: TScheduledTask;
  MaxID: Integer;
  I: Integer;
begin
  // 生成新ID
  MaxID := 0;
  for I := 0 to FTasks.Count - 1 do
    if FTasks[I].ID > MaxID then
      MaxID := FTasks[I].ID;
  
  Task.ID := MaxID + 1;
  Task.Name := AName;
  Task.CleanupTypes := ATypes;
  Task.Frequency := AFrequency;
  Task.ExecuteTime := ATime;
  Task.DayOfWeek := 1;
  Task.DayOfMonth := 1;
  Task.MinFreeDiskMB := 0;
  Task.Enabled := True;
  Task.LastExecuted := 0;
  Task.LastResult := '';
  Task.NextExecute := CalculateNextExecute(Task);
  
  FTasks.Add(Task);
  SaveConfig;
  
  Result := Task.ID;
end;

procedure TCleanupScheduler.UpdateTask(const Task: TScheduledTask);
var
  I: Integer;
  UpdatedTask: TScheduledTask;
begin
  for I := 0 to FTasks.Count - 1 do
  begin
    if FTasks[I].ID = Task.ID then
    begin
      UpdatedTask := Task;
      UpdatedTask.NextExecute := CalculateNextExecute(UpdatedTask);
      FTasks[I] := UpdatedTask;
      SaveConfig;
      Exit;
    end;
  end;
end;

procedure TCleanupScheduler.DeleteTask(TaskID: Integer);
var
  I: Integer;
begin
  for I := FTasks.Count - 1 downto 0 do
  begin
    if FTasks[I].ID = TaskID then
    begin
      FTasks.Delete(I);
      SaveConfig;
      Exit;
    end;
  end;
end;

function TCleanupScheduler.GetTask(TaskID: Integer): TScheduledTask;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for I := 0 to FTasks.Count - 1 do
  begin
    if FTasks[I].ID = TaskID then
    begin
      Result := FTasks[I];
      Exit;
    end;
  end;
end;

function TCleanupScheduler.GetAllTasks: TArray<TScheduledTask>;
begin
  Result := FTasks.ToArray;
end;

function TCleanupScheduler.ExecuteTaskNow(TaskID: Integer): TScheduledTaskResult;
var
  I: Integer;
  Task: TScheduledTask;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  for I := 0 to FTasks.Count - 1 do
  begin
    if FTasks[I].ID = TaskID then
    begin
      Task := FTasks[I];
      Result := ExecuteTask(Task);
      FTasks[I] := Task;
      SaveConfig;
      
      if Assigned(FOnTaskComplete) then
        FOnTaskComplete(Task, Result);
      
      Exit;
    end;
  end;
end;

procedure TCleanupScheduler.ExecuteStartupTasks;
var
  I: Integer;
  Task: TScheduledTask;
  TaskResult: TScheduledTaskResult;
begin
  for I := 0 to FTasks.Count - 1 do
  begin
    Task := FTasks[I];
    if Task.Enabled and (Task.Frequency = sfOnStartup) then
    begin
      TaskResult := ExecuteTask(Task);
      FTasks[I] := Task;
      
      if Assigned(FOnTaskComplete) then
        FOnTaskComplete(Task, TaskResult);
    end;
  end;
  
  SaveConfig;
end;

procedure TCleanupScheduler.Start;
begin
  FEnabled := True;
  FTimer.Enabled := True;
  LogInfo('CleanupScheduler', '清理任务调度器已启动');
end;

procedure TCleanupScheduler.Stop;
begin
  FTimer.Enabled := False;
  FEnabled := False;
  LogInfo('CleanupScheduler', '清理任务调度器已停止');
end;

initialization

finalization
  if _CleanupScheduler <> nil then
  begin
    _CleanupScheduler.Free;
    _CleanupScheduler := nil;
  end;

end.
