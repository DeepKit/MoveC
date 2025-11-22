unit uNativeFileWatcher;

interface

uses
  Winapi.Windows, Winapi.ShlObj, System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, System.SyncObjs, System.Threading, System.StrUtils;

type
  // 本地动作枚举，避免与外部单元形成接口依赖
  TNativeFileAction = (nfaAdded, nfaModified, nfaDeleted, nfaRenamedOld, nfaRenamedNew);
  // 文件变更信息（增强版）
  TNativeFileChange = record
    Path: string;
    Action: TNativeFileAction;
    OldPath: string; // 用于重命名操作
    Size: Int64;
    Attributes: DWORD;
    CreationTime: TFileTime;
    LastAccessTime: TFileTime;
    LastWriteTime: TFileTime;
    ChangeTime: TDateTime;
    IsDirectory: Boolean;
  end;
  // 原生文件监控事件
  TNativeFileChangeEvent = procedure(const AChanges: TArray<TNativeFileChange>) of object;
  // 本地定义 FILE_NOTIFY_INFORMATION 结构（Delphi 某些版本未公开 PFileNotifyInformation）
  PFileNotifyInformation = ^TFileNotifyInformation;
  TFileNotifyInformation = record
    NextEntryOffset: DWORD;
    Action: DWORD;
    FileNameLength: DWORD;
    FileName: array[0..0] of WideChar;
  end;
  
  // 监控配置
  TWatchConfig = record
    WatchSubtree: Boolean;
    NotifyFilter: DWORD;
    BufferSize: DWORD;
    ReadInterval: Cardinal;
    MaxChangesPerBatch: Integer;
    IgnoreSelfChanges: Boolean;
    EnableRapidChangeDetection: Boolean;
    RapidChangeThreshold: Integer; // 每秒变更次数
  end;

type
  TNativeFileWatcher = class
  private
    FDirectoryHandle: THandle;
    FWatchConfig: TWatchConfig;
    FActive: Boolean;
    FBuffer: PByte;
    FCancelled: Boolean;
    FWatchThread: TThread;
    FChangeEvent: TNativeFileChangeEvent;
    FLock: TCriticalSection;
    FCurrentProcessId: DWORD;
    
    // 统计信息
    FTotalChanges: Int64;
    FFilteredChanges: Int64;
    FErrorCount: Int64;
    FLastChangeTime: TDateTime;
    FRapidChangeCount: Integer;
    
    // 内部方法
    function OpenDirectory(const APath: string): THandle;
    procedure CloseDirectory;
    procedure WatchThreadProc;
    procedure ProcessNotification(ABuffer: PByte; ABytesReturned: DWORD);
    procedure ProcessFileNotification(AInfo: PFileNotifyInformation);
    function ConvertActionToNativeAction(AAction: DWORD): TNativeFileAction;
    function GetFullPath(const AFileName: string): string;
    procedure NotifyChanges(const AChanges: TArray<TNativeFileChange>);
    function ShouldIgnoreChange(const AChange: TNativeFileChange): Boolean;
    procedure UpdateStatistics;
    function DetectRapidChanges: Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要功能
    function StartWatch(const APath: string): Boolean;
    procedure StopWatch;
    function IsWatching: Boolean;
    
    // 配置管理
    procedure SetWatchConfig(const AConfig: TWatchConfig);
    function GetWatchConfig: TWatchConfig;
    
    // 事件
    property OnChange: TNativeFileChangeEvent read FChangeEvent write FChangeEvent;
    
    // 统计信息
    property TotalChanges: Int64 read FTotalChanges;
    property FilteredChanges: Int64 read FFilteredChanges;
    property ErrorCount: Int64 read FErrorCount;
    property LastChangeTime: TDateTime read FLastChangeTime;
    
    // 静态方法
    class function IsNativeWatchAvailable: Boolean;
    class function GetDefaultWatchConfig: TWatchConfig;
  end;

implementation

uses
  System.Types;

{ TNativeFileWatcher }

constructor TNativeFileWatcher.Create;
begin
  inherited Create;
  FDirectoryHandle := INVALID_HANDLE_VALUE;
  FActive := False;
  FBuffer := nil;
  FCancelled := False;
  FLock := TCriticalSection.Create;
  FCurrentProcessId := GetCurrentProcessId;
  
  // 初始化统计信息
  FTotalChanges := 0;
  FFilteredChanges := 0;
  FErrorCount := 0;
  FLastChangeTime := 0;
  FRapidChangeCount := 0;
  
  // 设置默认配置
  FWatchConfig := GetDefaultWatchConfig;
end;

destructor TNativeFileWatcher.Destroy;
begin
  StopWatch;
  FreeAndNil(FLock);
  inherited Destroy;
end;

class function TNativeFileWatcher.IsNativeWatchAvailable: Boolean;
begin
  // Windows 2000 及以上版本都支持 ReadDirectoryChangesW
  Result := Win32Platform = VER_PLATFORM_WIN32_NT;
end;

class function TNativeFileWatcher.GetDefaultWatchConfig: TWatchConfig;
begin
  Result.WatchSubtree := True;
  Result.NotifyFilter := FILE_NOTIFY_CHANGE_FILE_NAME or
                        FILE_NOTIFY_CHANGE_DIR_NAME or
                        FILE_NOTIFY_CHANGE_ATTRIBUTES or
                        FILE_NOTIFY_CHANGE_SIZE or
                        FILE_NOTIFY_CHANGE_LAST_WRITE or
                        FILE_NOTIFY_CHANGE_CREATION;
  Result.BufferSize := 64 * 1024; // 64KB 缓冲区
  Result.ReadInterval := 100;     // 100ms 读取间隔
  Result.MaxChangesPerBatch := 100;
  Result.IgnoreSelfChanges := True;
  Result.EnableRapidChangeDetection := True;
  Result.RapidChangeThreshold := 50; // 50次/秒
end;

function TNativeFileWatcher.OpenDirectory(const APath: string): THandle;
begin
  Result := CreateFile(
    PChar(APath),
    GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
    nil,
    OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OVERLAPPED,
    0
  );
end;

procedure TNativeFileWatcher.CloseDirectory;
begin
  if FDirectoryHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FDirectoryHandle);
    FDirectoryHandle := INVALID_HANDLE_VALUE;
  end;
end;

function TNativeFileWatcher.StartWatch(const APath: string): Boolean;
begin
  Result := False;
  
  if FActive then
  begin
    StopWatch;
  end;
  
  if not TDirectory.Exists(APath) then
  begin
    Exit;
  end;
  
  // 打开目录句柄
  FDirectoryHandle := OpenDirectory(APath);
  if FDirectoryHandle = INVALID_HANDLE_VALUE then
  begin
    Inc(FErrorCount);
    Exit;
  end;
  
  // 分配缓冲区
  if Assigned(FBuffer) then
    FreeMem(FBuffer);
  GetMem(FBuffer, FWatchConfig.BufferSize);
  
  // 启动监控线程
  FCancelled := False;
  FWatchThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        WatchThreadProc;
      except
        on E: Exception do
        begin
          Inc(FErrorCount);
          // 可以记录错误日志
        end;
      end;
    end);
  
  FWatchThread.Start;
  FActive := True;
  Result := True;
end;

procedure TNativeFileWatcher.StopWatch;
begin
  if not FActive then
    Exit;
  
  FActive := False;
  
  // 取消线程
  FCancelled := True;
  
  // 等待线程结束
  if Assigned(FWatchThread) then
  begin
    FWatchThread.WaitFor;
    FreeAndNil(FWatchThread);
  end;
  
  // 关闭目录句柄
  CloseDirectory;
  
  // 释放缓冲区
  if Assigned(FBuffer) then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
  end;
end;

function TNativeFileWatcher.IsWatching: Boolean;
begin
  Result := FActive and Assigned(FWatchThread) and not FWatchThread.Finished;
end;

procedure TNativeFileWatcher.WatchThreadProc;
var
  Overlapped: TOverlapped;
  BytesReturned: DWORD;
  WaitResult: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, False, nil);
  
  try
    while FActive and not FCancelled do
    begin
      // 重置事件
      ResetEvent(Overlapped.hEvent);
      
      // 开始读取变更
      if ReadDirectoryChangesW(
        FDirectoryHandle,
        FBuffer,
        FWatchConfig.BufferSize,
        FWatchConfig.WatchSubtree,
        FWatchConfig.NotifyFilter,
        @BytesReturned,
        @Overlapped,
        nil
      ) then
      begin
        // 等待操作完成
        WaitResult := WaitForSingleObject(Overlapped.hEvent, FWatchConfig.ReadInterval);
        
        case WaitResult of
          WAIT_OBJECT_0:
            begin
              // 有变更发生
              if GetOverlappedResult(FDirectoryHandle, Overlapped, BytesReturned, False) then
              begin
                if BytesReturned > 0 then
                begin
                  ProcessNotification(FBuffer, BytesReturned);
                end;
              end
              else
              begin
                Inc(FErrorCount);
              end;
            end;
          
          WAIT_TIMEOUT:
            begin
              // 超时，继续等待
              Continue;
            end;
          
          WAIT_FAILED:
            begin
              Inc(FErrorCount);
              Break;
            end;
        end;
      end
      else
      begin
        Inc(FErrorCount);
        Sleep(FWatchConfig.ReadInterval);
      end;
      
      // 检查是否需要暂停（快速变更检测）
      if FWatchConfig.EnableRapidChangeDetection and DetectRapidChanges then
      begin
        Sleep(1000); // 暂停1秒以避免过度处理
      end;
    end;
  finally
    CloseHandle(Overlapped.hEvent);
  end;
end;

procedure TNativeFileWatcher.ProcessNotification(ABuffer: PByte; ABytesReturned: DWORD);
var
  Offset: DWORD;
  Info: PFileNotifyInformation;
begin
  Offset := 0;
  
  while Offset < ABytesReturned do
  begin
    Info := PFileNotifyInformation(ABuffer + Offset);
    ProcessFileNotification(Info);
    
    if Info.NextEntryOffset = 0 then
      Break;
    
    Inc(Offset, Info.NextEntryOffset);
  end;
end;

procedure TNativeFileWatcher.ProcessFileNotification(AInfo: PFileNotifyInformation);
var
  FileName: string;
  FullPath: string;
  Change: TNativeFileChange;
  Changes: TArray<TNativeFileChange>;
begin
  // 转换文件名
  SetLength(FileName, AInfo.FileNameLength div SizeOf(WideChar));
  Move(AInfo.FileName[0], FileName[1], AInfo.FileNameLength);
  
  FullPath := GetFullPath(FileName);
  
  // 构建变更信息
  Change.Path := FullPath;
  Change.Action := ConvertActionToNativeAction(AInfo.Action);
  Change.OldPath := ''; // 重命名需要特殊处理
  Change.ChangeTime := Now;
  Change.IsDirectory := False; // 简化：无法直接判断，留为 False
  
  // 获取文件信息
  if TFile.Exists(FullPath) then
  begin
    try
      Change.Size := TFile.GetSize(FullPath);
      Change.Attributes := GetFileAttributes(PChar(FullPath));
      FillChar(Change.CreationTime, SizeOf(Change.CreationTime), 0);
      FillChar(Change.LastAccessTime, SizeOf(Change.LastAccessTime), 0);
      FillChar(Change.LastWriteTime, SizeOf(Change.LastWriteTime), 0);
    except
      Change.Size := 0;
      Change.Attributes := 0;
      FillChar(Change.CreationTime, SizeOf(Change.CreationTime), 0);
      FillChar(Change.LastAccessTime, SizeOf(Change.LastAccessTime), 0);
      FillChar(Change.LastWriteTime, SizeOf(Change.LastWriteTime), 0);
    end;
  end
  else if Change.Action = nfaDeleted then
  begin
    // 已删除的文件
    Change.Size := 0;
    Change.Attributes := 0;
    FillChar(Change.CreationTime, SizeOf(Change.CreationTime), 0);
    FillChar(Change.LastAccessTime, SizeOf(Change.LastAccessTime), 0);
    FillChar(Change.LastWriteTime, SizeOf(Change.LastWriteTime), 0);
  end;
  
  // 检查是否应该忽略此变更
  if ShouldIgnoreChange(Change) then
  begin
    Inc(FFilteredChanges);
    Exit;
  end;
  
  // 通知变更
  SetLength(Changes, 1);
  Changes[0] := Change;
  NotifyChanges(Changes);
  
  Inc(FTotalChanges);
  FLastChangeTime := Now;
  UpdateStatistics;
end;

function TNativeFileWatcher.ConvertActionToNativeAction(AAction: DWORD): TNativeFileAction;
begin
  case AAction of
    FILE_ACTION_ADDED:
      Result := nfaAdded;
    FILE_ACTION_REMOVED:
      Result := nfaDeleted;
    FILE_ACTION_MODIFIED:
      Result := nfaModified;
    FILE_ACTION_RENAMED_OLD_NAME:
      Result := nfaRenamedOld; // 重命名旧文件名
    FILE_ACTION_RENAMED_NEW_NAME:
      Result := nfaRenamedNew; // 重命名新文件名
    else
      Result := nfaModified;
  end;
end;

function TNativeFileWatcher.GetFullPath(const AFileName: string): string;
begin
  // 这里需要保存监控的根路径，暂时简化处理
  Result := AFileName;
end;

function TNativeFileWatcher.ShouldIgnoreChange(const AChange: TNativeFileChange): Boolean;
var
  FileName, Extension: string;
begin
  Result := False;
  
  FileName := ExtractFileName(AChange.Path);
  Extension := LowerCase(ExtractFileExt(FileName));
  
  // 忽略临时文件
  if (Extension = '.tmp') or (Extension = '.temp') or (Extension = '.bak') or
     (Extension = '.~') or StartsText('~', FileName) then
  begin
    Result := True;
    Exit;
  end;
  
  // 忽略系统文件
  if SameText(FileName, 'Thumbs.db') or SameText(FileName, 'desktop.ini') or SameText(FileName, '.DS_Store') then
  begin
    Result := True;
    Exit;
  end;
  
  // 忽略自身的变更（如果启用）
  if FWatchConfig.IgnoreSelfChanges then
  begin
    // 检查是否是当前进程创建的文件
    // 这里可以实现更复杂的逻辑
  end;
end;

procedure TNativeFileWatcher.NotifyChanges(const AChanges: TArray<TNativeFileChange>);
begin
  if not Assigned(FChangeEvent) then Exit;
  try
    FChangeEvent(AChanges);
  except
    // 忽略通知错误
  end;
end;

procedure TNativeFileWatcher.UpdateStatistics;
begin
  // 更新快速变更计数
  if (Now - FLastChangeTime) < (1.0 / 24.0 / 3600.0) then // 1秒内
    Inc(FRapidChangeCount)
  else
    FRapidChangeCount := 1;
end;

function TNativeFileWatcher.DetectRapidChanges: Boolean;
begin
  Result := (FRapidChangeCount > FWatchConfig.RapidChangeThreshold);
end;

procedure TNativeFileWatcher.SetWatchConfig(const AConfig: TWatchConfig);
begin
  FLock.Enter;
  try
    FWatchConfig := AConfig;
    
    // 如果正在监控，重启以应用新配置
    if FActive then
    begin
      // 这里需要保存当前路径并重启监控
      // 暂时简化处理
    end;
  finally
    FLock.Leave;
  end;
end;

function TNativeFileWatcher.GetWatchConfig: TWatchConfig;
begin
  FLock.Enter;
  try
    Result := FWatchConfig;
  finally
    FLock.Leave;
  end;
end;

end.
