unit uSyncEngine;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  System.SyncObjs, System.Masks, uFileSystemWatcher, uSyncDatabase;

type
  TSyncProgress = record
    CurrentFile: string;
    Percent: Double;
    BytesTransferred: Int64;
    FilesProcessed: Integer;
  end;

  TSyncProgressEvent = procedure(const P: TSyncProgress) of object;
  TSyncCompleteEvent = procedure(Success: Boolean; const Msg: string) of object;

  TSyncTask = class(TPersistent)
  private
    FName: string;
    FSourcePath: string;
    FTargetPath: string;
    FMode: uSyncDatabase.TSyncMode;
    FStatus: uSyncDatabase.TSyncStatus;
    FCategory: uSyncDatabase.TSyncCategory;
    FEnabled: Boolean;
    FOnProgress: TSyncProgressEvent;
    FOnComplete: TSyncCompleteEvent;
    FDatabase: TSyncDatabase;
    FTaskID: Integer;
    FConflictStrategy: uSyncDatabase.TConflictStrategy;
    FFilterRules: string;
    FPresetID: Integer;
    // Realtime
    FWatcher: TFileSystemWatcher;
    FDebounceLock: TCriticalSection;
    FPendingChange: Boolean;
    FDebounceThread: TThread;
    FDebounceIntervalMs: Cardinal;
    FChangeBuffer: TList<TFileChange>;
    // Realtime params
    FRealtimeIntervalMs: Cardinal;
    FRealtimeRecursive: Boolean;
    FWatchMode: uFileSystemWatcher.TWatchMode;
    // Ignore rules (comma/semicolon separated masks)
    FIgnoreRulesText: string;
    FIgnoreMasks: TArray<string>;
    procedure HandleFsChangesInternal(const Changes: TArray<TFileChange>);
    procedure StartRealtime;
    procedure StopRealtime;
    procedure ExecuteIncremental(const Changes: TArray<TFileChange>);
    function ShouldIgnore(const APath: string): Boolean;
    procedure ParseIgnoreRules;
    procedure SaveToDatabase;
    procedure LoadFromDatabase;
  public
    constructor Create; virtual;
    constructor CreateWithDatabase(ADatabase: TSyncDatabase); virtual;
    destructor Destroy; override;
    procedure Execute; virtual;
    procedure Start; virtual;
    procedure Stop; virtual;
    procedure Pause; virtual;
    procedure Resume; virtual;
    procedure Save;
    procedure Load;
    property TaskID: Integer read FTaskID write FTaskID;
    property Name: string read FName write FName;
    property SourcePath: string read FSourcePath write FSourcePath;
    property TargetPath: string read FTargetPath write FTargetPath;
    property Mode: uSyncDatabase.TSyncMode read FMode write FMode;
    property Status: uSyncDatabase.TSyncStatus read FStatus write FStatus;
    property Category: uSyncDatabase.TSyncCategory read FCategory write FCategory;
    property Enabled: Boolean read FEnabled write FEnabled;
    property OnProgress: TSyncProgressEvent read FOnProgress write FOnProgress;
    property OnComplete: TSyncCompleteEvent read FOnComplete write FOnComplete;
    property Database: TSyncDatabase read FDatabase write FDatabase;
    property ConflictStrategy: uSyncDatabase.TConflictStrategy read FConflictStrategy write FConflictStrategy;
    property FilterRules: string read FFilterRules write FFilterRules;
    property PresetID: Integer read FPresetID write FPresetID;
    property RealtimeIntervalMs: Cardinal read FRealtimeIntervalMs write FRealtimeIntervalMs;
    property RealtimeRecursive: Boolean read FRealtimeRecursive write FRealtimeRecursive;
    property WatchMode: uFileSystemWatcher.TWatchMode read FWatchMode write FWatchMode;
    property IgnoreRulesText: string read FIgnoreRulesText write FIgnoreRulesText;
  end;

  TSyncEngine = class(TComponent)
  private
    FTasks: TObjectList<TSyncTask>;
    FDatabase: TSyncDatabase;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateWithDatabase(AOwner: TComponent; ADatabase: TSyncDatabase);
    destructor Destroy; override;
    function AddTask(ATask: TSyncTask): Integer;
    procedure RemoveTask(ATask: TSyncTask);
    property Tasks: TObjectList<TSyncTask> read FTasks;
    property Database: TSyncDatabase read FDatabase write FDatabase;
    procedure EnsurePresets;
    procedure LoadTasksFromDatabase;
    procedure SaveTasksToDatabase;

end;

// Standalone handler for file system changes
procedure FileSystemChangeHandler(const Changes: TArray<TFileChange>; Task: TSyncTask);

implementation

{ TSyncTask }

constructor TSyncTask.Create;
begin
  inherited Create;
  FName := '';
  FSourcePath := '';
  FTargetPath := '';
  FMode := uSyncDatabase.smManual;
  FStatus := uSyncDatabase.ssIdle;
  FCategory := uSyncDatabase.scCustom;
  FEnabled := True;
  FConflictStrategy := uSyncDatabase.csAskUser;
  FFilterRules := '';
  FPresetID := -1;
  FTaskID := -1;
  // Realtime
  FDebounceLock := TCriticalSection.Create;
  FDebounceIntervalMs := 2000;
  FChangeBuffer := TList<TFileChange>.Create;
  FRealtimeIntervalMs := 500;
  FRealtimeRecursive := True;
  FWatchMode := uFileSystemWatcher.wmNative;
  FIgnoreRulesText := '';
  SetLength(FIgnoreMasks, 0);
end;

constructor TSyncTask.CreateWithDatabase(ADatabase: TSyncDatabase);
begin
  Create;
  FDatabase := ADatabase;
end;

destructor TSyncTask.Destroy;
begin
  try
    StopRealtime;
  except end;
  FreeAndNil(FWatcher);
  FreeAndNil(FDebounceLock);
  FreeAndNil(FChangeBuffer);
  inherited Destroy;
end;

procedure TSyncTask.Execute;
var
  Files: TArray<string>;
  I: Integer;
  Src, Dst, Rel: string;
  Dir: string;
  Info: TSyncProgress;
  Success: Boolean;
  ErrMsg: string;
begin
  Success := True;
  ErrMsg := '';
  if not TDirectory.Exists(FSourcePath) then
  begin
    Success := False;
    ErrMsg := 'Source path not found: ' + FSourcePath;
  end
  else
  begin
    if not TDirectory.Exists(FTargetPath) then
    begin
      try
        TDirectory.CreateDirectory(FTargetPath);
      except
        on E: Exception do
        begin
          Success := False;
          ErrMsg := 'Failed to create target path: ' + E.Message;
        end;
      end;
    end;
  end;

  if not Success then
  begin
    if Assigned(FOnComplete) then FOnComplete(False, '任务[' + FName + '] 同步失败：' + ErrMsg);
    Exit;
  end;

  FStatus := uSyncDatabase.ssRunning;
  ParseIgnoreRules;
  Files := TDirectory.GetFiles(FSourcePath, '*', TSearchOption.soAllDirectories);
  FillChar(Info, SizeOf(Info), 0);
  for I := 0 to High(Files) do
  begin
    Src := Files[I];
    if ShouldIgnore(Src) then Continue;
    Rel := Src.Substring(Length(FSourcePath));
    if (Length(Rel) > 0) and ((Rel[1] = '\') or (Rel[1] = '/')) then
      Rel := Rel.Substring(1);
    Dst := TPath.Combine(FTargetPath, Rel);
    Dir := TPath.GetDirectoryName(Dst);
    if (Dir <> '') and (not TDirectory.Exists(Dir)) then
      TDirectory.CreateDirectory(Dir);

    // 复制或更新（若目标不存在或源较新/大小不同）
    try
      if (not TFile.Exists(Dst)) or
         (TFile.GetSize(Src) <> TFile.GetSize(Dst)) or
         (TFile.GetLastWriteTime(Src) > TFile.GetLastWriteTime(Dst)) then
      begin
        TFile.Copy(Src, Dst, True);
      end;
    except
      on E: Exception do
      begin
        Success := False;
        ErrMsg := E.Message;
      end;
    end;

    // 进度回调（简化：按文件个数比例）
    Info.CurrentFile := Src;
    Info.FilesProcessed := I + 1;
    if Length(Files) > 0 then
      Info.Percent := (I + 1) * 100.0 / Length(Files)
    else
      Info.Percent := 100.0;
    if Assigned(FOnProgress) then FOnProgress(Info);
  end;

  if Success then
    FStatus := uSyncDatabase.ssCompleted
  else
    FStatus := uSyncDatabase.ssError;

  if Assigned(FOnComplete) then FOnComplete(Success, ErrMsg);
end;

procedure TSyncTask.Start;
begin
  if not FEnabled then Exit;
  if FMode = uSyncDatabase.smRealtime then
    StartRealtime
  else
    Execute;
end;

procedure TSyncTask.Stop;
begin
  if FMode = uSyncDatabase.smRealtime then
    StopRealtime;
end;

procedure TSyncTask.Pause;
begin
end;

procedure TSyncTask.Resume;
begin
end;

procedure TSyncTask.Save;
begin
  if Assigned(FDatabase) then
    SaveToDatabase;
end;

procedure TSyncTask.Load;
begin
  if Assigned(FDatabase) and (FTaskID > 0) then
    LoadFromDatabase;
end;

procedure TSyncTask.SaveToDatabase;
var
  DBTask: uSyncDatabase.TSyncTask;
begin
  if not Assigned(FDatabase) then Exit;
  
  DBTask.TaskID := FTaskID;
  DBTask.Name := FName;
  DBTask.SourcePath := FSourcePath;
  DBTask.TargetPath := FTargetPath;
  DBTask.SyncMode := FMode;
  DBTask.ConflictStrategy := FConflictStrategy;
  DBTask.IsEnabled := FEnabled;
  DBTask.FilterRules := FFilterRules;
  DBTask.PresetID := FPresetID;
  
  if FTaskID > 0 then
  begin
    FDatabase.UpdateSyncTask(DBTask);
  end
  else
  begin
    FTaskID := FDatabase.CreateSyncTask(DBTask);
  end;
end;

procedure TSyncTask.LoadFromDatabase;
var
  DBTask: uSyncDatabase.TSyncTask;
begin
  if not Assigned(FDatabase) or (FTaskID <= 0) then Exit;
  
  DBTask := FDatabase.GetSyncTask(FTaskID);
  if DBTask.TaskID > 0 then
  begin
    FName := DBTask.Name;
    FSourcePath := DBTask.SourcePath;
    FTargetPath := DBTask.TargetPath;
    FMode := DBTask.SyncMode;
    FConflictStrategy := DBTask.ConflictStrategy;
    FEnabled := DBTask.IsEnabled;
    FFilterRules := DBTask.FilterRules;
    FPresetID := DBTask.PresetID;
  end;
end;

procedure TSyncTask.HandleFsChangesInternal(const Changes: TArray<TFileChange>);
begin
  // 标记有新变更，交给防抖线程合并处理
  FDebounceLock.Enter;
  try
    // 缓存变化集
    for var C in Changes do
      FChangeBuffer.Add(C);
    FPendingChange := True;
    if not Assigned(FDebounceThread) then
    begin
      FDebounceThread := TThread.CreateAnonymousThread(
        procedure
        var
          LocalPending: Boolean;
          LocalChanges: TArray<TFileChange>;
        begin
          while True do
          begin
            // 等待一段时间，若期间无新变更，则触发一次完整同步
            TThread.Sleep(FDebounceIntervalMs);
            FDebounceLock.Enter;
            try
              LocalPending := FPendingChange;
              FPendingChange := False;
              if FChangeBuffer.Count > 0 then
              begin
                SetLength(LocalChanges, FChangeBuffer.Count);
                for var I := 0 to FChangeBuffer.Count - 1 do
                  LocalChanges[I] := FChangeBuffer[I];
                FChangeBuffer.Clear;
              end
              else
                SetLength(LocalChanges, 0);
            finally
              FDebounceLock.Leave;
            end;
            if not LocalPending then
            begin
              // 没有新增事件，应用增量同步并退出线程
              if Length(LocalChanges) > 0 then
                ExecuteIncremental(LocalChanges)
              else
                Execute; // 容错：极少数情况下无变化集则执行一次
              Break;
            end;
          end;
          // 退出时将线程句柄清空
          FDebounceLock.Enter;
          try
            FDebounceThread := nil;
          finally
            FDebounceLock.Leave;
          end;
        end);
      FDebounceThread.FreeOnTerminate := True;
      FDebounceThread.Start;
    end;
  finally
    FDebounceLock.Leave;
  end;
end;

procedure TSyncTask.StartRealtime;
begin
  if Assigned(FWatcher) and FWatcher.Active then Exit;
  if not TDirectory.Exists(FSourcePath) then Exit;
  if not Assigned(FWatcher) then
  begin
    FWatcher := TFileSystemWatcher.Create(nil);
  end;
  FWatcher.Path := FSourcePath;
  FWatcher.Recursive := FRealtimeRecursive;
  FWatcher.IntervalMs := FRealtimeIntervalMs;
  FWatcher.Mode := FWatchMode;
  FWatcher.OnChange := TProc<TArray<TFileChange>>(procedure(const Changes: TArray<TFileChange>)
  begin
    HandleFsChangesInternal(Changes);
  end);
  FWatcher.Start;
  FStatus := uSyncDatabase.ssRunning;
end;

procedure TSyncTask.StopRealtime;
var
  T: TThread;
begin
  if Assigned(FWatcher) and FWatcher.Active then
    FWatcher.Stop;
  FStatus := uSyncDatabase.ssIdle;
  // 若仍有防抖线程在等待，直接让其退出（不会再触发 Execute）
  FDebounceLock.Enter;
  try
    T := FDebounceThread;
    FDebounceThread := nil;
  finally
    FDebounceLock.Leave;
  end;
  if Assigned(T) then
  begin
    // 无直接终止API，等待自然结束；缩短等待：重置Pending以促使其尽快退出而不执行
    FPendingChange := False;
    T.WaitFor;
  end;
end;

procedure TSyncTask.ExecuteIncremental(const Changes: TArray<TFileChange>);
var
  SrcLower, SrcRootLower, Rel, Src, Dst, Dir: string;
  C: TFileChange;
begin
  if (FSourcePath = '') or (FTargetPath = '') then Exit;
  SrcRootLower := FSourcePath.ToLower;
  ParseIgnoreRules;
  for C in Changes do
  begin
    SrcLower := C.Path.ToLower;
    // 计算相对路径（基于小写比较）
    if SrcLower.StartsWith(SrcRootLower) then
    begin
      Rel := Copy(SrcLower, Length(SrcRootLower) + 1, MaxInt);
      while (Length(Rel) > 0) and ((Rel[1] = '\') or (Rel[1] = '/')) do
        Rel := Copy(Rel, 2, MaxInt);
      // 尽力还原实际大小写路径：用原始C.Path作为源，目标按相对路径组合
      Src := C.Path; // 可能是小写，但文件系统不区分大小写
      Dst := TPath.Combine(FTargetPath, Rel);
      if (C.Action <> faDeleted) and ShouldIgnore(Src) then
        Continue;
      case C.Action of
        faAdded, faModified:
        begin
          Dir := TPath.GetDirectoryName(Dst);
          if (Dir <> '') and (not TDirectory.Exists(Dir)) then
            TDirectory.CreateDirectory(Dir);
          try
            if TFile.Exists(Src) then
              TFile.Copy(Src, Dst, True);
          except
          end;
        end;
        faDeleted:
        begin
          try
            if TFile.Exists(Dst) then
              TFile.Delete(Dst);
          except
          end;
        end;
      else
        // faRenamed 已由新增/删除体现
      end;
    end;
  end;
  // 简化回调：增量完成后给一次完成事件
  if Assigned(FOnComplete) then FOnComplete(True, '任务[' + FName + '] 增量同步完成');
end;

function TSyncTask.ShouldIgnore(const APath: string): Boolean;
var
  M: string;
  FileNameOnly: string;
begin
  Result := False;
  if Length(FIgnoreMasks) = 0 then Exit;
  FileNameOnly := ExtractFileName(APath);
  for M in FIgnoreMasks do
  begin
    if (M <> '') and (MatchesMask(FileNameOnly, M) or MatchesMask(APath, M)) then
      Exit(True);
  end;
end;

procedure TSyncTask.ParseIgnoreRules;
var
  Parts: TArray<string>;
  S: string;
  L: TList<string>;
begin
  Parts := FIgnoreRulesText.Split([',',';'], TStringSplitOptions.ExcludeEmpty);
  L := TList<string>.Create;
  try
    for S in Parts do
    begin
      var Trimmed := Trim(S);
      if Trimmed <> '' then L.Add(Trimmed);
    end;
    FIgnoreMasks := L.ToArray;
  finally
    L.Free;
  end;
end;

{ TSyncEngine }

constructor TSyncEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTasks := TObjectList<TSyncTask>.Create(True);
end;

constructor TSyncEngine.CreateWithDatabase(AOwner: TComponent; ADatabase: TSyncDatabase);
begin
  Create(AOwner);
  FDatabase := ADatabase;
end;

destructor TSyncEngine.Destroy;
begin
  FTasks.Free;
  inherited Destroy;
end;

function TSyncEngine.AddTask(ATask: TSyncTask): Integer;
begin
  Result := FTasks.Add(ATask);
end;

procedure TSyncEngine.RemoveTask(ATask: TSyncTask);
begin
  FTasks.Remove(ATask);
end;

procedure TSyncEngine.EnsurePresets;
  function NewTask(const AName, Src, Dst: string; Cat: uSyncDatabase.TSyncCategory): TSyncTask;
  begin
    if Assigned(FDatabase) then
      Result := TSyncTask.CreateWithDatabase(FDatabase)
    else
      Result := TSyncTask.Create;
    Result.Name := AName;
    Result.SourcePath := Src;
    Result.TargetPath := Dst;
    Result.Mode := uSyncDatabase.smManual;
    Result.Category := Cat;
    Result.Enabled := True;
  end;
begin
  if FTasks.Count > 0 then Exit;
  // 6个预置任务，分布于5个分类
  FTasks.Add(NewTask('文档备份', 'C:\Users\Public\Documents', 'D:\Backup\Documents', uSyncDatabase.scDocuments));
  FTasks.Add(NewTask('代码同步-Delphi', 'D:\SynologyDrive\Progs\_Delphi', 'F:\Backup\Delphi', uSyncDatabase.scCode));
  FTasks.Add(NewTask('代码同步-Python', 'D:\Code\Python', 'F:\Backup\Python', uSyncDatabase.scCode));
  FTasks.Add(NewTask('媒体整理-图片', 'D:\Pictures', 'F:\MediaBackup\Pictures', uSyncDatabase.scMedia));
  FTasks.Add(NewTask('媒体整理-视频', 'D:\Videos', 'F:\MediaBackup\Videos', uSyncDatabase.scMedia));
  FTasks.Add(NewTask('项目归档', 'D:\Projects', 'F:\Archives\Projects', uSyncDatabase.scBackup));
end;

procedure TSyncEngine.LoadTasksFromDatabase;
var
  DBTasks: TArray<uSyncDatabase.TSyncTask>;
  DBTask: uSyncDatabase.TSyncTask;
  Task: TSyncTask;
begin
  if not Assigned(FDatabase) then Exit;
  
  FTasks.Clear;
  DBTasks := FDatabase.GetAllSyncTasks;
  
  for DBTask in DBTasks do
  begin
    Task := TSyncTask.CreateWithDatabase(FDatabase);
    Task.FTaskID := DBTask.TaskID;
    Task.LoadFromDatabase;
    FTasks.Add(Task);
  end;
end;

procedure TSyncEngine.SaveTasksToDatabase;
var
  Task: TSyncTask;
begin
  if not Assigned(FDatabase) then Exit;
  
  for Task in FTasks do
  begin
    Task.Save;
  end;
end;

// Standalone handler for file system changes
procedure FileSystemChangeHandler(const Changes: TArray<TFileChange>; Task: TSyncTask);
begin
  if Assigned(Task) then
    Task.HandleFsChangesInternal(Changes);
end;

end.
