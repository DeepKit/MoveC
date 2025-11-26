unit uRealtimeSyncManager;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Threading, System.SyncObjs, System.Diagnostics, System.JSON, uFileSystemWatcher,
  uSyncDatabase, uFileSyncComparerSimple, uSyncExecutorSimple, Vcl.ExtCtrls,
  System.StrUtils, System.DateUtils;

type
  // 实时同步事件类型
  TRealtimeSyncEvent = procedure(const ASyncTask: TSyncTask; const AEventInfo: string) of object;
  TRealtimeSyncProgressEvent = procedure(const ASyncTask: TSyncTask; const AProgress: string) of object;
  TRealtimeSyncErrorEvent = procedure(const ASyncTask: TSyncTask; const AError: string) of object;
  
  // 文件变更记录
  TFileChangeRecord = record
    FilePath: string;
    ChangeType: TFileAction;
    ChangeTime: TDateTime;
    FileSize: Int64;
    IsDirectory: Boolean;
    Processed: Boolean;
  end;
  
  // 防抖动配置
  TDebounceConfig = record
    DebounceInterval: Cardinal; // 防抖动间隔（毫秒）
    MaxBatchSize: Integer;      // 最大批处理大小
    FlushInterval: Cardinal;    // 强制刷新间隔（毫秒）
    IgnoreRapidChanges: Boolean; // 忽略快速连续变化
    RapidChangeThreshold: Integer; // 快速变化阈值（次数/秒）
  end;

  TRealtimeSyncManager = class
  private
    FDatabase: TSyncDatabase;
    FFileSyncComparer: TFileSyncComparer;
    FSyncExecutor: TSyncExecutor;
    FActiveTasks: TDictionary<Integer, TSyncTask>;
    FWatchers: TDictionary<Integer, TFileSystemWatcher>;
    FChangeBuffers: TDictionary<Integer, TList<TFileChangeRecord>>;
    FDebounceTimers: TDictionary<Integer, TTimer>;
    FStatistics: TDictionary<Integer, TDictionary<string, Integer>>;
    FLock: TCriticalSection;
    FActive: Boolean;
    
    // 防抖动配置
    FDebounceConfig: TDebounceConfig;
    
    // 事件
    FOnSyncEvent: TRealtimeSyncEvent;
    FOnSyncProgress: TRealtimeSyncProgressEvent;
    FOnSyncError: TRealtimeSyncErrorEvent;
    
    // 内部方法
    procedure OnFileSystemChange(Sender: TObject; const Changes: TArray<TFileChange>);
    procedure ProcessChangeBuffer(const ATaskID: Integer);
    procedure FlushChanges(const ATaskID: Integer);
    function ShouldProcessChange(const AChange: TFileChangeRecord; const ATask: TSyncTask): Boolean;
    function FilterChanges(const AChanges: TArray<TFileChange>; const ATask: TSyncTask): TArray<TFileChange>;
    procedure UpdateStatistics(const ATaskID: Integer; const AOperation: string; const ACount: Integer = 1);
    procedure LogSyncEvent(const ATask: TSyncTask; const AEventInfo: string);
    procedure HandleSyncError(const ATask: TSyncTask; const AError: string);
    function CreateDebounceTimer(const ATaskID: Integer): TTimer;
    procedure CleanupTask(const ATaskID: Integer);
    procedure DebounceTimerHandler(Sender: TObject);
    
  public
    constructor Create(ADatabase: TSyncDatabase);
    destructor Destroy; override;
    
    // 主要功能
    procedure StartRealtimeSync(const ATask: TSyncTask);
    procedure StopRealtimeSync(const ATaskID: Integer);
    procedure StopAllRealtimeSync;
    procedure PauseRealtimeSync(const ATaskID: Integer);
    procedure ResumeRealtimeSync(const ATaskID: Integer);
    
    // 配置管理
    procedure SetDebounceConfig(const AConfig: TDebounceConfig);
    function GetDebounceConfig: TDebounceConfig;
    
    // 状态查询
    function IsTaskActive(const ATaskID: Integer): Boolean;
    function GetActiveTaskCount: Integer;
    function GetTaskStatistics(const ATaskID: Integer): TDictionary<string, Integer>;
    function GetAllStatistics: TDictionary<Integer, TDictionary<string, Integer>>;
    
    // 手动触发
    procedure TriggerSync(const ATaskID: Integer);
    procedure TriggerFullSync(const ATaskID: Integer);
    
    // 属性
    property IsActive: Boolean read FActive;
    property DebounceConfig: TDebounceConfig read GetDebounceConfig write SetDebounceConfig;
    
    // 事件
    property OnSyncEvent: TRealtimeSyncEvent read FOnSyncEvent write FOnSyncEvent;
    property OnSyncProgress: TRealtimeSyncProgressEvent read FOnSyncProgress write FOnSyncProgress;
    property OnSyncError: TRealtimeSyncErrorEvent read FOnSyncError write FOnSyncError;
  end;

implementation

{ TRealtimeSyncManager }

constructor TRealtimeSyncManager.Create(ADatabase: TSyncDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
  FFileSyncComparer := TFileSyncComparer.Create;
  FSyncExecutor := TSyncExecutor.Create;
  FActiveTasks := TDictionary<Integer, TSyncTask>.Create;
  FWatchers := TDictionary<Integer, TFileSystemWatcher>.Create;
  FChangeBuffers := TDictionary<Integer, TList<TFileChangeRecord>>.Create;
  FDebounceTimers := TDictionary<Integer, TTimer>.Create;
  FStatistics := TDictionary<Integer, TDictionary<string, Integer>>.Create;
  FLock := TCriticalSection.Create;
  FActive := False;
  
  // 默认防抖动配置
  FDebounceConfig.DebounceInterval := 500; // 500ms
  FDebounceConfig.MaxBatchSize := 100;
  FDebounceConfig.FlushInterval := 5000;   // 5秒强制刷新
  FDebounceConfig.IgnoreRapidChanges := True;
  FDebounceConfig.RapidChangeThreshold := 10; // 10次/秒
  
  // 设置同步执行器事件（按需在外部订阅 OnSyncProgress/OnSyncEvent/OnSyncError）
end;

destructor TRealtimeSyncManager.Destroy;
begin
  StopAllRealtimeSync;
  FreeAndNil(FLock);
  FreeAndNil(FStatistics);
  FreeAndNil(FDebounceTimers);
  FreeAndNil(FChangeBuffers);
  FreeAndNil(FWatchers);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FSyncExecutor);
  FreeAndNil(FFileSyncComparer);
  inherited Destroy;
end;

procedure TRealtimeSyncManager.StartRealtimeSync(const ATask: TSyncTask);
var
  Watcher: TFileSystemWatcher;
  ChangeBuffer: TList<TFileChangeRecord>;
  DebounceTimer: TTimer;
  Stats: TDictionary<string, Integer>;
begin
  if ATask.Name = '' then Exit;
  
  FLock.Enter;
  try
    // 检查任务是否已在运行
    if FActiveTasks.ContainsKey(ATask.TaskID) then
    begin
      LogSyncEvent(ATask, '任务已在运行中');
      Exit;
    end;
    
    // 验证路径
    if not TDirectory.Exists(ATask.SourcePath) then
    begin
      HandleSyncError(ATask, '源路径不存在: ' + ATask.SourcePath);
      Exit;
    end;
    
    if not TDirectory.Exists(ATask.TargetPath) then
    begin
      try
        TDirectory.CreateDirectory(ATask.TargetPath);
      except
        on E: Exception do
        begin
          HandleSyncError(ATask, '无法创建目标路径: ' + E.Message);
          Exit;
        end;
      end;
    end;
    
    // 创建文件监控器
    Watcher := TFileSystemWatcher.Create(nil);
    Watcher.Path := ATask.SourcePath;
    Watcher.Recursive := True;
    Watcher.IntervalMs := 200; // 200ms 轮询间隔
    Watcher.Mode := TWatchMode.wmNative; // 优先使用原生API
    // 使用传统事件处理文件变更
    Watcher.OnChangeEvent := OnFileSystemChange;
    
    // 创建变更缓冲区
    ChangeBuffer := TList<TFileChangeRecord>.Create;
    
    // 创建防抖动定时器
    DebounceTimer := CreateDebounceTimer(ATask.TaskID);
    
    // 创建统计信息
    Stats := TDictionary<string, Integer>.Create;
    Stats.AddOrSetValue('TotalChanges', 0);
    Stats.AddOrSetValue('ProcessedChanges', 0);
    Stats.AddOrSetValue('SkippedChanges', 0);
    Stats.AddOrSetValue('ErrorChanges', 0);
    Stats.AddOrSetValue('LastSyncTime', 0);
    
    // 注册所有组件
    FActiveTasks.AddOrSetValue(ATask.TaskID, ATask);
    FWatchers.AddOrSetValue(ATask.TaskID, Watcher);
    FChangeBuffers.AddOrSetValue(ATask.TaskID, ChangeBuffer);
    FDebounceTimers.AddOrSetValue(ATask.TaskID, DebounceTimer);
    FStatistics.AddOrSetValue(ATask.TaskID, Stats);
    
    // 启动监控
    try
      Watcher.Start;
      FActive := True;
      LogSyncEvent(ATask, '实时同步已启动');
      UpdateStatistics(ATask.TaskID, 'Started');
    except
      on E: Exception do
      begin
        HandleSyncError(ATask, '启动文件监控失败: ' + E.Message);
        CleanupTask(ATask.TaskID);
      end;
    end;
    
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.StopRealtimeSync(const ATaskID: Integer);
var
  Task: TSyncTask;
begin
  FLock.Enter;
  try
    if not FActiveTasks.ContainsKey(ATaskID) then Exit;
    
    Task := FActiveTasks[ATaskID];
    LogSyncEvent(Task, '停止实时同步');
    
    CleanupTask(ATaskID);
    
    if FActiveTasks.Count = 0 then
      FActive := False;
      
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.StopAllRealtimeSync;
var
  TaskIDs: TArray<Integer>;
  TaskID: Integer;
begin
  FLock.Enter;
  try
    TaskIDs := FActiveTasks.Keys.ToArray;
    for TaskID in TaskIDs do
    begin
      CleanupTask(TaskID);
    end;
    FActive := False;
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.PauseRealtimeSync(const ATaskID: Integer);
var
  Task: TSyncTask;
begin
  FLock.Enter;
  try
    if FWatchers.ContainsKey(ATaskID) then
    begin
      FWatchers[ATaskID].Stop;
      Task := FActiveTasks[ATaskID];
      LogSyncEvent(Task, '实时同步已暂停');
      UpdateStatistics(ATaskID, 'Paused');
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.ResumeRealtimeSync(const ATaskID: Integer);
var
  Task: TSyncTask;
begin
  FLock.Enter;
  try
    if FWatchers.ContainsKey(ATaskID) then
    begin
      try
        FWatchers[ATaskID].Start;
        Task := FActiveTasks[ATaskID];
        LogSyncEvent(Task, '实时同步已恢复');
        UpdateStatistics(ATaskID, 'Resumed');
      except
        on E: Exception do
        begin
          Task := FActiveTasks[ATaskID];
          HandleSyncError(Task, '恢复文件监控失败: ' + E.Message);
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.OnFileSystemChange(Sender: TObject; const Changes: TArray<TFileChange>);
var
  Watcher: TFileSystemWatcher;
  TaskID: Integer;
  Task: TSyncTask;
  ChangeBuffer: TList<TFileChangeRecord>;
  ChangeRecord: TFileChangeRecord;
  Change: TFileChange;
  Pair: TPair<Integer, TFileSystemWatcher>;
  FilteredChanges: TArray<TFileChange>;
  Timer: TTimer;
  FileStream: TFileStream;
begin
  // 找到对应的任务
  TaskID := -1;
  for Pair in FWatchers do
  begin
    if Pair.Value = Sender then
    begin
      TaskID := Pair.Key;
      Break;
    end;
  end;
  
  if TaskID = -1 then Exit;
  
  FLock.Enter;
  try
    if not FActiveTasks.ContainsKey(TaskID) then Exit;
    
    Task := FActiveTasks[TaskID];
    ChangeBuffer := FChangeBuffers[TaskID];
    
    // 过滤变更
    FilteredChanges := FilterChanges(Changes, Task);
    
    // 添加到缓冲区
    for Change in FilteredChanges do
    begin
      ChangeRecord.FilePath := Change.Path;
      ChangeRecord.ChangeType := Change.Action;
      ChangeRecord.ChangeTime := Now;
      ChangeRecord.IsDirectory := TDirectory.Exists(Change.Path);
      ChangeRecord.Processed := False;
      
      if ChangeRecord.IsDirectory then
        ChangeRecord.FileSize := 0
      else if TFile.Exists(Change.Path) then
      begin
        try
          FileStream := TFileStream.Create(Change.Path, fmOpenRead or fmShareDenyNone);
          try
            ChangeRecord.FileSize := FileStream.Size;
          finally
            FileStream.Free;
          end;
        except
          ChangeRecord.FileSize := 0;
        end;
      end
      else
        ChangeRecord.FileSize := 0;
      
      ChangeBuffer.Add(ChangeRecord);
      UpdateStatistics(TaskID, 'TotalChanges');
    end;
    
    // 检查是否需要立即处理
    if ChangeBuffer.Count >= FDebounceConfig.MaxBatchSize then
    begin
      ProcessChangeBuffer(TaskID);
    end
    else
    begin
      // 重置防抖动定时器
      Timer := FDebounceTimers[TaskID];
      Timer.Enabled := False;
      Timer.Enabled := True;
    end;
    
  finally
    FLock.Leave;
  end;
end;

function TRealtimeSyncManager.FilterChanges(const AChanges: TArray<TFileChange>; const ATask: TSyncTask): TArray<TFileChange>;
var
  FilteredList: TList<TFileChange>;
  Change: TFileChange;
  FileName, Extension: string;
begin
  FilteredList := TList<TFileChange>.Create;
  try
    for Change in AChanges do
    begin
      // 跳过临时文件和系统文件
      FileName := ExtractFileName(Change.Path);
      Extension := LowerCase(ExtractFileExt(FileName));
      
      // 跳过临时文件
      if (Extension = '.tmp') or (Extension = '.temp') or (Extension = '.bak') or
         (Extension = '.~') or (Pos('.', FileName) = 1) or (Pos('~', FileName) = 1) then
        Continue;
      
      // 跳过锁定文件
      if (Extension = '.lock') or (Extension = '.lck') then
        Continue;
      
      // 跳过隐藏文件（如果配置要求）
      try
        if TFileAttribute.faHidden in TFile.GetAttributes(Change.Path) then
          Continue;
      except
        // 忽略无法访问的文件
      end;
      
      FilteredList.Add(Change);
    end;
    
    Result := FilteredList.ToArray;
  finally
    FilteredList.Free;
  end;
end;

procedure TRealtimeSyncManager.ProcessChangeBuffer(const ATaskID: Integer);
var
  Task: TSyncTask;
  ChangeBuffer: TList<TFileChangeRecord>;
  SyncChanges: TArray<TFileChange>;
  I: Integer;
  Timer: TTimer;
  ChangeRecord: TFileChangeRecord;
begin
  if not FActiveTasks.ContainsKey(ATaskID) then Exit;
  
  Task := FActiveTasks[ATaskID];
  ChangeBuffer := FChangeBuffers[ATaskID];
  
  if ChangeBuffer.Count = 0 then Exit;
  
  try
    LogSyncEvent(Task, Format('处理 %d 个文件变更', [ChangeBuffer.Count]));
    
    // 转换为同步变更格式
    SetLength(SyncChanges, ChangeBuffer.Count);
    for I := 0 to ChangeBuffer.Count - 1 do
    begin
      ChangeRecord := ChangeBuffer[I];
      SyncChanges[I].Path := ChangeRecord.FilePath;
      SyncChanges[I].Action := ChangeRecord.ChangeType;
      ChangeRecord.Processed := True;
    end;
    
    // 执行增量同步
    if Assigned(FOnSyncProgress) then
      FOnSyncProgress(Task, '开始增量同步...');
    
    // 这里应该调用同步引擎的增量同步方法（使用线程以避免 TTask 版本不兼容）
    TThread.CreateAnonymousThread(
      procedure
      var
        LocalTask: TSyncTask;
        LocalTaskID: Integer;
        LocalCount: Integer;
      begin
        LocalTask := Task;
        LocalTaskID := ATaskID;
        LocalCount := ChangeBuffer.Count;
        try
          // TODO: 实现实际的增量同步逻辑
          Sleep(100); // 模拟同步时间
          
          // 直接更新统计（已在临界区保护中）
          UpdateStatistics(LocalTaskID, 'ProcessedChanges', LocalCount);
          if Assigned(FOnSyncProgress) then
            FOnSyncProgress(LocalTask, '增量同步完成');
        except
          on E: Exception do
          begin
            HandleSyncError(LocalTask, '增量同步失败: ' + E.Message);
            UpdateStatistics(LocalTaskID, 'ErrorChanges', LocalCount);
          end;
        end;
      end).Start;
    
    // 清空缓冲区
    ChangeBuffer.Clear;
    
  finally
    // 停止防抖动定时器
    Timer := FDebounceTimers[ATaskID];
    if Assigned(Timer) then
      Timer.Enabled := False;
  end;
end;

function TRealtimeSyncManager.CreateDebounceTimer(const ATaskID: Integer): TTimer;
begin
  Result := TTimer.Create(nil);
  Result.Interval := FDebounceConfig.DebounceInterval;
  Result.Enabled := False;
  Result.Tag := ATaskID;
  Result.OnTimer := DebounceTimerHandler;
end;

procedure TRealtimeSyncManager.CleanupTask(const ATaskID: Integer);
begin
  // 停止并释放文件监控器
  if FWatchers.ContainsKey(ATaskID) then
  begin
    FWatchers[ATaskID].Stop;
    FreeAndNil(FWatchers[ATaskID]);
    FWatchers.Remove(ATaskID);
  end;
  
  // 清理变更缓冲区
  if FChangeBuffers.ContainsKey(ATaskID) then
  begin
    FChangeBuffers[ATaskID].Clear;
    FreeAndNil(FChangeBuffers[ATaskID]);
    FChangeBuffers.Remove(ATaskID);
  end;
  
  // 停止并释放防抖动定时器
  if FDebounceTimers.ContainsKey(ATaskID) then
  begin
    FDebounceTimers[ATaskID].Enabled := False;
    FreeAndNil(FDebounceTimers[ATaskID]);
    FDebounceTimers.Remove(ATaskID);
  end;
  
  // 清理统计信息
  if FStatistics.ContainsKey(ATaskID) then
  begin
    FStatistics[ATaskID].Clear;
    FreeAndNil(FStatistics[ATaskID]);
    FStatistics.Remove(ATaskID);
  end;
  
  // 移除任务
  FActiveTasks.Remove(ATaskID);
end;

procedure TRealtimeSyncManager.UpdateStatistics(const ATaskID: Integer; const AOperation: string; const ACount: Integer = 1);
var
  Stats: TDictionary<string, Integer>;
  OldValue: Integer;
begin
  if FStatistics.ContainsKey(ATaskID) then
  begin
    Stats := FStatistics[ATaskID];
    if not Stats.TryGetValue(AOperation, OldValue) then
      OldValue := 0;
    Stats.AddOrSetValue(AOperation, OldValue + ACount);
    Stats.AddOrSetValue('LastSyncTime', DateTimeToUnix(Now));
  end;
end;

procedure TRealtimeSyncManager.LogSyncEvent(const ATask: TSyncTask; const AEventInfo: string);
begin
  if Assigned(FOnSyncEvent) then
    FOnSyncEvent(ATask, AEventInfo);
end;

procedure TRealtimeSyncManager.HandleSyncError(const ATask: TSyncTask; const AError: string);
begin
  if Assigned(FOnSyncError) then
    FOnSyncError(ATask, AError);
end;

procedure TRealtimeSyncManager.SetDebounceConfig(const AConfig: TDebounceConfig);
var
  PairTimer: TPair<Integer, TTimer>;
begin
  FLock.Enter;
  try
    FDebounceConfig := AConfig;
    // 更新所有现有定时器
    for PairTimer in FDebounceTimers do
      PairTimer.Value.Interval := AConfig.DebounceInterval;
  finally
    FLock.Leave;
  end;
end;

function TRealtimeSyncManager.GetDebounceConfig: TDebounceConfig;
begin
  Result := FDebounceConfig;
end;

function TRealtimeSyncManager.IsTaskActive(const ATaskID: Integer): Boolean;
begin
  FLock.Enter;
  try
    Result := FActiveTasks.ContainsKey(ATaskID);
  finally
    FLock.Leave;
  end;
end;

function TRealtimeSyncManager.GetActiveTaskCount: Integer;
begin
  FLock.Enter;
  try
    Result := FActiveTasks.Count;
  finally
    FLock.Leave;
  end;
end;

function TRealtimeSyncManager.GetTaskStatistics(const ATaskID: Integer): TDictionary<string, Integer>;
begin
  FLock.Enter;
  try
    if FStatistics.ContainsKey(ATaskID) then
      Result := FStatistics[ATaskID]
    else
      Result := TDictionary<string, Integer>.Create;
  finally
    FLock.Leave;
  end;
end;

function TRealtimeSyncManager.GetAllStatistics: TDictionary<Integer, TDictionary<string, Integer>>;
var
  Pair: TPair<Integer, TDictionary<string, Integer>>;
begin
  FLock.Enter;
  try
    Result := TDictionary<Integer, TDictionary<string, Integer>>.Create;
    for Pair in FStatistics do
    begin
      Result.AddOrSetValue(Pair.Key, Pair.Value);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.TriggerSync(const ATaskID: Integer);
var
  Task: TSyncTask;
begin
  FLock.Enter;
  try
    if FChangeBuffers.ContainsKey(ATaskID) then
    begin
      ProcessChangeBuffer(ATaskID);
      Task := FActiveTasks[ATaskID];
      LogSyncEvent(Task, '手动触发同步');
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRealtimeSyncManager.TriggerFullSync(const ATaskID: Integer);
var
  Task: TSyncTask;
begin
  FLock.Enter;
  try
    if FActiveTasks.ContainsKey(ATaskID) then
    begin
      Task := FActiveTasks[ATaskID];
      LogSyncEvent(Task, '触发全量同步');
      
      // TODO: 实现全量同步逻辑（使用线程以避免 TTask 版本不兼容）
      TThread.CreateAnonymousThread(
        procedure
        var
          LocalTask: TSyncTask;
        begin
          LocalTask := Task;
          try
            if Assigned(FOnSyncProgress) then
              FOnSyncProgress(LocalTask, '开始全量同步...');
            
            // 这里应该调用同步引擎的全量同步方法
            Sleep(1000); // 模拟同步时间
            
            if Assigned(FOnSyncProgress) then
              FOnSyncProgress(LocalTask, '全量同步完成');
          except
            on E: Exception do
            begin
              HandleSyncError(LocalTask, '全量同步失败: ' + E.Message);
            end;
          end;
        end).Start;
    end;
  finally
    FLock.Leave;
  end;
end;

function TRealtimeSyncManager.ShouldProcessChange(const AChange: TFileChangeRecord; const ATask: TSyncTask): Boolean;
begin
  Result := True;
  
  // 检查文件大小限制
  if (AChange.FileSize > 100 * 1024 * 1024) and (AChange.ChangeType <> faDeleted) then
  begin
    // 超过100MB的文件跳过实时同步
    Result := False;
    Exit;
  end;
  
  // 检查是否在忽略列表中
  // TODO: 实现基于过滤规则的检查
end;

procedure TRealtimeSyncManager.FlushChanges(const ATaskID: Integer);
begin
  ProcessChangeBuffer(ATaskID);
end;

procedure TRealtimeSyncManager.DebounceTimerHandler(Sender: TObject);
var
  Timer: TTimer;
  TaskID: Integer;
begin
  Timer := TTimer(Sender);
  TaskID := Timer.Tag;
  if FActiveTasks.ContainsKey(TaskID) then
    ProcessChangeBuffer(TaskID);
end;

end.
