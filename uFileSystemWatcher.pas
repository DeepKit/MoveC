unit uFileSystemWatcher;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  System.IOUtils, System.SyncObjs, uNativeFileWatcher;

type
  TFileAction = (faAdded, faModified, faDeleted, faRenamed);
  TWatchMode = (wmPolling, wmNative);

  TFileChange = record
    Path: string;
    Action: TFileAction;
  end;

  TFileSystemWatcher = class(TComponent)
  private
    FPath: string;
    FRecursive: Boolean;
    FOnChange: TProc<TArray<TFileChange>>;
    FActive: Boolean;
    FThread: TThread;
    FStopEvent: TEvent;
    FSnapshot: TDictionary<string, Int64>; // file -> ticks (LastWriteTimeUtc)
    FLock: TCriticalSection;
    FIntervalMs: Cardinal;
    FMode: TWatchMode;
    FNativeWatcher: TNativeFileWatcher;
    function TakeSnapshot: TDictionary<string, Int64>;
    procedure DiffAndNotify(const OldSnap, NewSnap: TDictionary<string, Int64>);
    procedure RunPolling;
    procedure RunNative;
    procedure OnNativeChange(const AChanges: TArray<TNativeFileChange>);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property Path: string read FPath write FPath;
    property Recursive: Boolean read FRecursive write FRecursive;
    property Active: Boolean read FActive;
    property OnChange: TProc<TArray<TFileChange>> read FOnChange write FOnChange;
    property IntervalMs: Cardinal read FIntervalMs write FIntervalMs;
    property Mode: TWatchMode read FMode write FMode;
  end;

implementation

constructor TFileSystemWatcher.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRecursive := True;
  FActive := False;
  FIntervalMs := 500;
  FMode := wmPolling;
  FStopEvent := TEvent.Create(nil, True, False, '');
  FSnapshot := TDictionary<string, Int64>.Create;
  FLock := TCriticalSection.Create;
  FNativeWatcher := TNativeFileWatcher.Create;
end;

destructor TFileSystemWatcher.Destroy;
begin
  Stop;
  FreeAndNil(FNativeWatcher);
  FreeAndNil(FLock);
  FreeAndNil(FSnapshot);
  FreeAndNil(FStopEvent);
  inherited Destroy;
end;

function GetUtcTicks(const DT: TDateTime): Int64;
const
  UnixStartDate: TDateTime = 25569.0; // 1970-01-01
begin
  Result := Trunc((DT - UnixStartDate) * 24 * 60 * 60 * 1000); // ms
end;

function TFileSystemWatcher.TakeSnapshot: TDictionary<string, Int64>;
var
  Files: TArray<string>;
  F: string;
  Key: string;
begin
  Result := TDictionary<string, Int64>.Create;
  if (FPath = '') or (not TDirectory.Exists(FPath)) then Exit;
  if FRecursive then
    Files := TDirectory.GetFiles(FPath, '*', TSearchOption.soAllDirectories)
  else
    Files := TDirectory.GetFiles(FPath, '*', TSearchOption.soTopDirectoryOnly);
  for F in Files do
  begin
    try
      Key := F.ToLower;
      Result.AddOrSetValue(Key, GetUtcTicks(TFile.GetLastWriteTimeUtc(F)) xor TFile.GetSize(F));
    except
    end;
  end;
end;

procedure TFileSystemWatcher.DiffAndNotify(const OldSnap, NewSnap: TDictionary<string, Int64>);
var
  Changes: TList<TFileChange>;
  K: string;
  VOld, VNew: Int64;
  Change: TFileChange;
begin
  Changes := TList<TFileChange>.Create;
  try
    // deletions and modifications
    for K in OldSnap.Keys do
    begin
      if NewSnap.TryGetValue(K, VNew) then
      begin
        VOld := OldSnap[K];
        if VOld <> VNew then
        begin
          Change.Path := K;
          Change.Action := faModified;
          Changes.Add(Change);
        end;
      end
      else
      begin
        Change.Path := K;
        Change.Action := faDeleted;
        Changes.Add(Change);
      end;
    end;
    // additions
    for K in NewSnap.Keys do
      if not OldSnap.ContainsKey(K) then
      begin
        Change.Path := K;
        Change.Action := faAdded;
        Changes.Add(Change);
      end;

    if (Changes.Count > 0) and Assigned(FOnChange) then
      FOnChange(Changes.ToArray);
  finally
    Changes.Free;
  end;
end;

procedure TFileSystemWatcher.Start;
begin
  if FActive then Exit;
  FActive := True;
  FStopEvent.ResetEvent;
  // take initial snapshot
  FLock.Enter;
  try
    FreeAndNil(FSnapshot);
    FSnapshot := TakeSnapshot;
  finally
    FLock.Leave;
  end;
  // start thread
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      if FMode = wmPolling then
        RunPolling
      else
        RunNative;
    end);
  FThread.FreeOnTerminate := True;
  FThread.Start;
end;

procedure TFileSystemWatcher.Stop;
begin
  if not FActive then Exit;
  FActive := False;
  if Assigned(FStopEvent) then
    FStopEvent.SetEvent;
  if Assigned(FThread) then
  begin
    FThread.WaitFor;
    FThread := nil;
  end;
end;

procedure TFileSystemWatcher.RunPolling;
var
  OldSnap, NewSnap: TDictionary<string, Int64>;
begin
  while FActive do
  begin
    if FStopEvent.WaitFor(FIntervalMs) = wrSignaled then
      Break;
    
    FLock.Enter;
    try
      OldSnap := TDictionary<string, Int64>.Create;
      // 手动拷贝快照
      for var Pair in FSnapshot do
        OldSnap.AddOrSetValue(Pair.Key, Pair.Value);
      NewSnap := TakeSnapshot;
      try
        DiffAndNotify(OldSnap, NewSnap);
        FreeAndNil(FSnapshot);
        FSnapshot := NewSnap;
      finally
        OldSnap.Free;
      end;
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TFileSystemWatcher.RunNative;
begin
  // 使用原生文件监控
  if Assigned(FNativeWatcher) then
  begin
    try
      FNativeWatcher.OnChange := OnNativeChange;
      if FNativeWatcher.StartWatch(FPath) then
      begin
        // 等待停止信号
        while FActive do
        begin
          if FStopEvent.WaitFor(1000) = wrSignaled then
            Break;
        end;
        FNativeWatcher.StopWatch;
      end
      else
      begin
        // 原生监控失败，回退到轮询模式
        RunPolling;
      end;
    except
      // 出错时回退到轮询模式
      RunPolling;
    end;
  end
  else
  begin
    // 原生监控器不可用，使用轮询模式
    RunPolling;
  end;
end;

procedure TFileSystemWatcher.OnNativeChange(const AChanges: TArray<TNativeFileChange>);
var
  Converted: TArray<TFileChange>;
  I: Integer;
begin
  // 转发原生监控的变更事件
  if Assigned(FOnChange) and FActive then
  begin
    try
      SetLength(Converted, Length(AChanges));
      for I := 0 to High(AChanges) do
      begin
        Converted[I].Path := AChanges[I].Path;
        case AChanges[I].Action of
          nfaAdded:    Converted[I].Action := faAdded;
          nfaDeleted:  Converted[I].Action := faDeleted;
        else
          Converted[I].Action := faModified;
        end;
      end;
      FOnChange(Converted);
    except
      // 忽略回调错误
    end;
  end;
end;

end.
