unit uMigrationScheduler;

{
  迁移计划任务调度器 - Migration Task Scheduler
  
  功能：
  - 定时自动执行迁移任务
  - 支持多个迁移任务配置
  - 条件触发（磁盘空间阈值）
  - 任务配置持久化
  - 执行前安全检查
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.DateUtils, System.Generics.Collections, Vcl.ExtCtrls,
  uLogManager;

type
  // 任务执行频率
  TMigrationFrequency = (
    mfDisabled,         // 禁用
    mfOnce,             // 一次性
    mfDaily,            // 每天
    mfWeekly,           // 每周
    mfMonthly,          // 每月
    mfOnLowDisk         // 磁盘空间不足时
  );
  
  // 迁移任务状态
  TMigrationTaskStatus = (
    mtsIdle,            // 空闲
    mtsPending,         // 等待执行
    mtsRunning,         // 执行中
    mtsCompleted,       // 已完成
    mtsFailed,          // 失败
    mtsCancelled        // 已取消
  );
  
  // 迁移任务配置
  TScheduledMigration = record
    ID: Integer;
    Name: string;
    SourcePath: string;
    TargetPath: string;
    Frequency: TMigrationFrequency;
    ExecuteTime: TTime;
    DayOfWeek: Integer;
    DayOfMonth: Integer;
    DiskThresholdMB: Integer;    // 磁盘空间阈值（低于此值触发）
    Enabled: Boolean;
    CreateBackup: Boolean;
    VerifyFiles: Boolean;
    Status: TMigrationTaskStatus;
    LastExecuted: TDateTime;
    NextExecute: TDateTime;
    LastResult: string;
    LastError: string;
  end;
  
  // 任务执行结果
  TScheduledMigrationResult = record
    TaskID: Integer;
    ExecuteTime: TDateTime;
    Success: Boolean;
    FilesCopied: Integer;
    BytesCopied: Int64;
    ElapsedSeconds: Integer;
    ErrorMessage: string;
  end;
  
  // 调度器事件
  TMigrationSchedulerEvent = procedure(const Task: TScheduledMigration;
    const Result: TScheduledMigrationResult) of object;
  TMigrationProgressEvent = procedure(const Task: TScheduledMigration;
    Progress: Integer; const Status: string) of object;

  TMigrationScheduler = class
  private
    FTasks: TList<TScheduledMigration>;
    FTimer: TTimer;
    FConfigFile: string;
    FEnabled: Boolean;
    FOnTaskComplete: TMigrationSchedulerEvent;
    FOnProgress: TMigrationProgressEvent;
    FLastCheckTime: TDateTime;
    FRunningTaskID: Integer;
    
    procedure TimerTick(Sender: TObject);
    procedure LoadConfig;
    procedure SaveConfig;
    function GetConfigFile: string;
    function ShouldExecuteTask(const Task: TScheduledMigration): Boolean;
    function CalculateNextExecute(const Task: TScheduledMigration): TDateTime;
    function ExecuteTask(var Task: TScheduledMigration): TScheduledMigrationResult;
    function FrequencyToString(AFreq: TMigrationFrequency): string;
    function StringToFrequency(const S: string): TMigrationFrequency;
    function StatusToString(AStatus: TMigrationTaskStatus): string;
    function GetCDriveFreeSpaceMB: Integer;
    
    // 安全检查
    function IsSourceValid(const APath: string): Boolean;
    function IsTargetValid(const APath: string): Boolean;
    function HasEnoughSpace(const ASourcePath, ATargetPath: string): Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 任务管理
    function AddTask(const AName, ASourcePath, ATargetPath: string;
      AFrequency: TMigrationFrequency; ATime: TTime): Integer;
    procedure UpdateTask(const Task: TScheduledMigration);
    procedure DeleteTask(TaskID: Integer);
    function GetTask(TaskID: Integer): TScheduledMigration;
    function GetAllTasks: TArray<TScheduledMigration>;
    function GetPendingTasks: TArray<TScheduledMigration>;
    
    // 手动执行
    function ExecuteTaskNow(TaskID: Integer): TScheduledMigrationResult;
    procedure CancelRunningTask;
    
    // 调度器控制
    procedure Start;
    procedure Stop;
    
    // 属性
    property Enabled: Boolean read FEnabled;
    property RunningTaskID: Integer read FRunningTaskID;
    property OnTaskComplete: TMigrationSchedulerEvent read FOnTaskComplete write FOnTaskComplete;
    property OnProgress: TMigrationProgressEvent read FOnProgress write FOnProgress;
  end;
  
  // 全局单例
  function MigrationScheduler: TMigrationScheduler;

implementation

var
  _MigrationScheduler: TMigrationScheduler = nil;

function MigrationScheduler: TMigrationScheduler;
begin
  if _MigrationScheduler = nil then
    _MigrationScheduler := TMigrationScheduler.Create;
  Result := _MigrationScheduler;
end;

{ TMigrationScheduler }

constructor TMigrationScheduler.Create;
begin
  inherited Create;
  FTasks := TList<TScheduledMigration>.Create;
  FConfigFile := GetConfigFile;
  FEnabled := False;
  FLastCheckTime := Now;
  FRunningTaskID := -1;
  
  // 创建定时器（每分钟检查一次）
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 60000;
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;
  
  LoadConfig;
end;

destructor TMigrationScheduler.Destroy;
begin
  Stop;
  SaveConfig;
  FTimer.Free;
  FTasks.Free;
  inherited;
end;

function TMigrationScheduler.GetConfigFile: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MigrationScheduler.ini');
end;

procedure TMigrationScheduler.LoadConfig;
var
  IniFile: TIniFile;
  TaskCount, I: Integer;
  Task: TScheduledMigration;
  Section: string;
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
      Task.SourcePath := IniFile.ReadString(Section, 'SourcePath', '');
      Task.TargetPath := IniFile.ReadString(Section, 'TargetPath', '');
      Task.Frequency := StringToFrequency(IniFile.ReadString(Section, 'Frequency', 'Disabled'));
      Task.ExecuteTime := StrToTimeDef(IniFile.ReadString(Section, 'ExecuteTime', '03:00'), 
        EncodeTime(3, 0, 0, 0));
      Task.DayOfWeek := IniFile.ReadInteger(Section, 'DayOfWeek', 1);
      Task.DayOfMonth := IniFile.ReadInteger(Section, 'DayOfMonth', 1);
      Task.DiskThresholdMB := IniFile.ReadInteger(Section, 'DiskThresholdMB', 5120);
      Task.Enabled := IniFile.ReadBool(Section, 'Enabled', True);
      Task.CreateBackup := IniFile.ReadBool(Section, 'CreateBackup', True);
      Task.VerifyFiles := IniFile.ReadBool(Section, 'VerifyFiles', True);
      Task.Status := mtsIdle;
      Task.LastExecuted := IniFile.ReadDateTime(Section, 'LastExecuted', 0);
      Task.LastResult := IniFile.ReadString(Section, 'LastResult', '');
      Task.LastError := IniFile.ReadString(Section, 'LastError', '');
      
      Task.NextExecute := CalculateNextExecute(Task);
      
      if (Task.Name <> '') and (Task.SourcePath <> '') then
        FTasks.Add(Task);
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TMigrationScheduler.SaveConfig;
var
  IniFile: TIniFile;
  I: Integer;
  Task: TScheduledMigration;
  Section: string;
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
      IniFile.WriteString(Section, 'SourcePath', Task.SourcePath);
      IniFile.WriteString(Section, 'TargetPath', Task.TargetPath);
      IniFile.WriteString(Section, 'Frequency', FrequencyToString(Task.Frequency));
      IniFile.WriteString(Section, 'ExecuteTime', TimeToStr(Task.ExecuteTime));
      IniFile.WriteInteger(Section, 'DayOfWeek', Task.DayOfWeek);
      IniFile.WriteInteger(Section, 'DayOfMonth', Task.DayOfMonth);
      IniFile.WriteInteger(Section, 'DiskThresholdMB', Task.DiskThresholdMB);
      IniFile.WriteBool(Section, 'Enabled', Task.Enabled);
      IniFile.WriteBool(Section, 'CreateBackup', Task.CreateBackup);
      IniFile.WriteBool(Section, 'VerifyFiles', Task.VerifyFiles);
      IniFile.WriteDateTime(Section, 'LastExecuted', Task.LastExecuted);
      IniFile.WriteString(Section, 'LastResult', Task.LastResult);
      IniFile.WriteString(Section, 'LastError', Task.LastError);
    end;
    
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

function TMigrationScheduler.FrequencyToString(AFreq: TMigrationFrequency): string;
begin
  case AFreq of
    mfDisabled: Result := 'Disabled';
    mfOnce: Result := 'Once';
    mfDaily: Result := 'Daily';
    mfWeekly: Result := 'Weekly';
    mfMonthly: Result := 'Monthly';
    mfOnLowDisk: Result := 'OnLowDisk';
  else
    Result := 'Disabled';
  end;
end;

function TMigrationScheduler.StringToFrequency(const S: string): TMigrationFrequency;
begin
  if SameText(S, 'Once') then Result := mfOnce
  else if SameText(S, 'Daily') then Result := mfDaily
  else if SameText(S, 'Weekly') then Result := mfWeekly
  else if SameText(S, 'Monthly') then Result := mfMonthly
  else if SameText(S, 'OnLowDisk') then Result := mfOnLowDisk
  else Result := mfDisabled;
end;

function TMigrationScheduler.StatusToString(AStatus: TMigrationTaskStatus): string;
begin
  case AStatus of
    mtsIdle: Result := '空闲';
    mtsPending: Result := '等待执行';
    mtsRunning: Result := '执行中';
    mtsCompleted: Result := '已完成';
    mtsFailed: Result := '失败';
    mtsCancelled: Result := '已取消';
  else
    Result := '未知';
  end;
end;

function TMigrationScheduler.GetCDriveFreeSpaceMB: Integer;
var
  FreeBytes, TotalBytes: Int64;
begin
  Result := 0;
  if GetDiskFreeSpaceEx('C:\', FreeBytes, TotalBytes, nil) then
    Result := FreeBytes div (1024 * 1024);
end;

function TMigrationScheduler.CalculateNextExecute(const Task: TScheduledMigration): TDateTime;
var
  Now_: TDateTime;
  TaskTime: TDateTime;
  DaysDiff: Integer;
begin
  Result := 0;
  if Task.Frequency in [mfDisabled, mfOnLowDisk] then Exit;
  
  Now_ := Now;
  TaskTime := Trunc(Now_) + Frac(Task.ExecuteTime);
  
  case Task.Frequency of
    mfOnce:
    begin
      if Task.LastExecuted = 0 then
        Result := TaskTime
      else
        Result := 0;  // 已执行过
    end;
    
    mfDaily:
    begin
      if TaskTime > Now_ then
        Result := TaskTime
      else
        Result := TaskTime + 1;
    end;
    
    mfWeekly:
    begin
      DaysDiff := Task.DayOfWeek - DayOfWeek(Now_);
      if DaysDiff < 0 then DaysDiff := DaysDiff + 7;
      Result := Trunc(Now_) + DaysDiff + Frac(Task.ExecuteTime);
      if Result <= Now_ then
        Result := Result + 7;
    end;
    
    mfMonthly:
    begin
      Result := EncodeDate(YearOf(Now_), MonthOf(Now_),
        Min(Task.DayOfMonth, DaysInMonth(Now_))) + Frac(Task.ExecuteTime);
      if Result <= Now_ then
        Result := IncMonth(Result, 1);
    end;
  end;
end;

function TMigrationScheduler.IsSourceValid(const APath: string): Boolean;
begin
  Result := TDirectory.Exists(APath);
end;

function TMigrationScheduler.IsTargetValid(const APath: string): Boolean;
var
  ParentDir: string;
begin
  Result := False;
  if APath = '' then Exit;
  
  // 目标目录不存在也可以，只要父目录存在
  if TDirectory.Exists(APath) then
  begin
    Result := True;
    Exit;
  end;
  
  ParentDir := ExtractFilePath(ExcludeTrailingPathDelimiter(APath));
  Result := TDirectory.Exists(ParentDir);
end;

function TMigrationScheduler.HasEnoughSpace(const ASourcePath, ATargetPath: string): Boolean;
var
  SourceSize: Int64;
  FreeBytes, TotalBytes: Int64;
  TargetDrive: string;
begin
  Result := False;
  
  // 简单估算源目录大小（不递归，仅顶层）
  SourceSize := 0;
  try
    for var F in TDirectory.GetFiles(ASourcePath) do
      SourceSize := SourceSize + TFile.GetSize(F);
  except
  end;
  
  // 获取目标盘剩余空间
  TargetDrive := ExtractFileDrive(ATargetPath);
  if TargetDrive = '' then TargetDrive := 'C:';
  
  if GetDiskFreeSpaceEx(PChar(TargetDrive + '\'), FreeBytes, TotalBytes, nil) then
    Result := FreeBytes > SourceSize * 2;  // 保留2倍空间余量
end;

function TMigrationScheduler.ShouldExecuteTask(const Task: TScheduledMigration): Boolean;
var
  FreeSpaceMB: Integer;
begin
  Result := False;
  
  if not Task.Enabled then Exit;
  if Task.Frequency = mfDisabled then Exit;
  if Task.Status = mtsRunning then Exit;
  if FRunningTaskID >= 0 then Exit;  // 已有任务在运行
  
  // 磁盘空间触发
  if Task.Frequency = mfOnLowDisk then
  begin
    FreeSpaceMB := GetCDriveFreeSpaceMB;
    if FreeSpaceMB < Task.DiskThresholdMB then
      Result := True;
    Exit;
  end;
  
  // 时间触发
  if Task.NextExecute <= Now then
    Result := True;
end;

function TMigrationScheduler.ExecuteTask(var Task: TScheduledMigration): TScheduledMigrationResult;
var
  StartTime: TDateTime;
  FileCount: Integer;
  TotalSize: Int64;
begin
  Result.TaskID := Task.ID;
  Result.ExecuteTime := Now;
  Result.Success := False;
  Result.FilesCopied := 0;
  Result.BytesCopied := 0;
  Result.ErrorMessage := '';
  
  StartTime := Now;
  Task.Status := mtsRunning;
  FRunningTaskID := Task.ID;
  
  LogInfo('MigrationScheduler', Format('开始执行迁移任务: %s', [Task.Name]));
  
  try
    // 前置检查
    if not IsSourceValid(Task.SourcePath) then
    begin
      Result.ErrorMessage := '源目录不存在: ' + Task.SourcePath;
      Task.Status := mtsFailed;
      Exit;
    end;
    
    if not IsTargetValid(Task.TargetPath) then
    begin
      Result.ErrorMessage := '目标目录无效: ' + Task.TargetPath;
      Task.Status := mtsFailed;
      Exit;
    end;
    
    if not HasEnoughSpace(Task.SourcePath, Task.TargetPath) then
    begin
      Result.ErrorMessage := '目标磁盘空间不足';
      Task.Status := mtsFailed;
      Exit;
    end;
    
    // 执行迁移
    // 注意：实际迁移需要调用 uMigrationService
    // 这里只是框架，需要集成实际迁移逻辑
    
    if Assigned(FOnProgress) then
      FOnProgress(Task, 0, '准备迁移...');
    
    // 创建目标目录
    if not TDirectory.Exists(Task.TargetPath) then
      TDirectory.CreateDirectory(Task.TargetPath);
    
    // 复制文件
    FileCount := 0;
    TotalSize := 0;
    
    for var F in TDirectory.GetFiles(Task.SourcePath, '*', TSearchOption.soAllDirectories) do
    begin
      if FRunningTaskID < 0 then  // 检查是否被取消
      begin
        Task.Status := mtsCancelled;
        Result.ErrorMessage := '任务被取消';
        Exit;
      end;
      
      try
        var RelPath := ExtractRelativePath(Task.SourcePath, F);
        var TargetFile := TPath.Combine(Task.TargetPath, RelPath);
        var TargetDir := ExtractFilePath(TargetFile);
        
        if not TDirectory.Exists(TargetDir) then
          TDirectory.CreateDirectory(TargetDir);
        
        TFile.Copy(F, TargetFile, True);
        Inc(FileCount);
        TotalSize := TotalSize + TFile.GetSize(F);
        
        if (FileCount mod 10 = 0) and Assigned(FOnProgress) then
          FOnProgress(Task, 50, Format('已复制 %d 个文件...', [FileCount]));
      except
        on E: Exception do
          LogWarning('MigrationScheduler', '复制文件失败: ' + E.Message);
      end;
    end;
    
    Result.FilesCopied := FileCount;
    Result.BytesCopied := TotalSize;
    Result.Success := True;
    Task.Status := mtsCompleted;
    Task.LastExecuted := Now;
    Task.NextExecute := CalculateNextExecute(Task);
    Task.LastResult := Format('成功: 复制 %d 文件, %.2f MB',
      [FileCount, TotalSize / (1024 * 1024)]);
    Task.LastError := '';
    
    LogInfo('MigrationScheduler', Task.LastResult);
    
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      Task.Status := mtsFailed;
      Task.LastError := E.Message;
      Task.LastResult := '失败: ' + E.Message;
      LogError('MigrationScheduler', '任务执行失败: ' + E.Message);
    end;
  end;
  
  Result.ElapsedSeconds := SecondsBetween(Now, StartTime);
  FRunningTaskID := -1;
end;

procedure TMigrationScheduler.TimerTick(Sender: TObject);
var
  I: Integer;
  Task: TScheduledMigration;
  TaskResult: TScheduledMigrationResult;
begin
  if not FEnabled then Exit;
  if FRunningTaskID >= 0 then Exit;  // 已有任务在运行
  
  FLastCheckTime := Now;
  
  for I := 0 to FTasks.Count - 1 do
  begin
    Task := FTasks[I];
    if ShouldExecuteTask(Task) then
    begin
      TaskResult := ExecuteTask(Task);
      FTasks[I] := Task;
      
      if Assigned(FOnTaskComplete) then
        FOnTaskComplete(Task, TaskResult);
      
      SaveConfig;
      Break;  // 一次只执行一个任务
    end;
  end;
end;

function TMigrationScheduler.AddTask(const AName, ASourcePath, ATargetPath: string;
  AFrequency: TMigrationFrequency; ATime: TTime): Integer;
var
  Task: TScheduledMigration;
  MaxID: Integer;
  I: Integer;
begin
  MaxID := 0;
  for I := 0 to FTasks.Count - 1 do
    if FTasks[I].ID > MaxID then
      MaxID := FTasks[I].ID;
  
  Task.ID := MaxID + 1;
  Task.Name := AName;
  Task.SourcePath := ASourcePath;
  Task.TargetPath := ATargetPath;
  Task.Frequency := AFrequency;
  Task.ExecuteTime := ATime;
  Task.DayOfWeek := 1;
  Task.DayOfMonth := 1;
  Task.DiskThresholdMB := 5120;  // 默认5GB
  Task.Enabled := True;
  Task.CreateBackup := True;
  Task.VerifyFiles := True;
  Task.Status := mtsIdle;
  Task.LastExecuted := 0;
  Task.LastResult := '';
  Task.LastError := '';
  Task.NextExecute := CalculateNextExecute(Task);
  
  FTasks.Add(Task);
  SaveConfig;
  
  Result := Task.ID;
end;

procedure TMigrationScheduler.UpdateTask(const Task: TScheduledMigration);
var
  I: Integer;
  UpdatedTask: TScheduledMigration;
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

procedure TMigrationScheduler.DeleteTask(TaskID: Integer);
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

function TMigrationScheduler.GetTask(TaskID: Integer): TScheduledMigration;
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

function TMigrationScheduler.GetAllTasks: TArray<TScheduledMigration>;
begin
  Result := FTasks.ToArray;
end;

function TMigrationScheduler.GetPendingTasks: TArray<TScheduledMigration>;
var
  Pending: TList<TScheduledMigration>;
  Task: TScheduledMigration;
begin
  Pending := TList<TScheduledMigration>.Create;
  try
    for Task in FTasks do
      if Task.Enabled and (Task.Frequency <> mfDisabled) then
        Pending.Add(Task);
    Result := Pending.ToArray;
  finally
    Pending.Free;
  end;
end;

function TMigrationScheduler.ExecuteTaskNow(TaskID: Integer): TScheduledMigrationResult;
var
  I: Integer;
  Task: TScheduledMigration;
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

procedure TMigrationScheduler.CancelRunningTask;
begin
  if FRunningTaskID >= 0 then
  begin
    LogInfo('MigrationScheduler', '取消运行中的任务');
    FRunningTaskID := -1;
  end;
end;

procedure TMigrationScheduler.Start;
begin
  FEnabled := True;
  FTimer.Enabled := True;
  LogInfo('MigrationScheduler', '迁移任务调度器已启动');
end;

procedure TMigrationScheduler.Stop;
begin
  FTimer.Enabled := False;
  FEnabled := False;
  CancelRunningTask;
  LogInfo('MigrationScheduler', '迁移任务调度器已停止');
end;

initialization

finalization
  if _MigrationScheduler <> nil then
  begin
    _MigrationScheduler.Free;
    _MigrationScheduler := nil;
  end;

end.
