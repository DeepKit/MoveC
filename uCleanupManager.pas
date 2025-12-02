unit uCleanupManager;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Winapi.ShlObj,
  System.SysUtils, System.Classes, System.IOUtils, System.Variants,
  System.Generics.Collections, System.Math, System.Win.Registry,
  Vcl.Forms, Vcl.Dialogs;

type
  // 清理结果记录
  TCleanupResult = record
    Success: Boolean;
    FilesDeleted: Integer;
    SpaceFreed: Int64; // 字节
    ErrorMessage: string;
    Details: TArray<string>; // 使用动态数组替代 TStringList，避免内存泄漏
    
    // 辅助方法
    procedure AddDetail(const ADetail: string);
    procedure AddDetails(const ADetails: TArray<string>);
    procedure ClearDetails;
  end;

  // 清理进度回调
  TCleanupProgressCallback = procedure(const AMessage: string; AProgress: Integer) of object;

  // 清理管理器类
  TCleanupManager = class
  private
    FProgressCallback: TCleanupProgressCallback;
    FCancel: Boolean;
    
    // 内部方法
    procedure UpdateProgress(const AMessage: string; AProgress: Integer = -1);
    function GetTempPath: string;
    function GetRecycleBinPath: string;
    function GetWindowsUpdatePath: string;
    function GetBrowserCachePaths: TArray<string>;
    function GetSystemTempPaths: TArray<string>;
    // 服务控制
    function StopServiceByName(const ServiceName: string; TimeoutMs: Cardinal = 15000): Boolean;
    function StartServiceByName(const ServiceName: string; TimeoutMs: Cardinal = 15000): Boolean;
    
    // 安全检查
    function IsSafeToDelete(const APath: string): Boolean;
    function IsSystemCriticalPath(const APath: string): Boolean;

    // 清理实现
    function CleanDirectoryRecursive(const ADirectory: string; var AResult: TCleanupResult): Boolean;
    function EmptyRecycleBinInternal: TCleanupResult;
    function CleanTempFilesInternal: TCleanupResult;
    function CleanBrowserCacheInternal: TCleanupResult;
    function CleanWindowsUpdateCacheInternal: TCleanupResult;
    function CleanSystemLogsInternal: TCleanupResult;
    function CleanPrefetchFilesInternal: TCleanupResult;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要清理方法
    function EmptyRecycleBin: TCleanupResult;
    function CleanTempFiles: TCleanupResult;
    function CleanBrowserCache: TCleanupResult;
    function CleanWindowsUpdateCache: TCleanupResult;
    function CleanSystemLogs: TCleanupResult;
    function CleanPrefetchFiles: TCleanupResult;
    function CleanRegistryJunk: TCleanupResult;
    
    // 综合清理
    function PerformSmartCleanup: TCleanupResult;
    
    // 分析方法
    function AnalyzeDiskUsage: TCleanupResult;
    function GetCleanableSize: Int64;
    
    // 控制方法
    procedure Cancel;
    function IsCancelled: Boolean;
    
    // 属性
    property OnProgress: TCleanupProgressCallback read FProgressCallback write FProgressCallback;
  end;

implementation

uses
  Winapi.WinSvc, System.StrUtils, uConstants;

{ TCleanupResult }

procedure TCleanupResult.AddDetail(const ADetail: string);
begin
  SetLength(Details, Length(Details) + 1);
  Details[High(Details)] := ADetail;
end;

procedure TCleanupResult.AddDetails(const ADetails: TArray<string>);
var
  I, OldLen: Integer;
begin
  OldLen := Length(Details);
  SetLength(Details, OldLen + Length(ADetails));
  for I := 0 to High(ADetails) do
    Details[OldLen + I] := ADetails[I];
end;

procedure TCleanupResult.ClearDetails;
begin
  SetLength(Details, 0);
end;

{ TCleanupManager }

constructor TCleanupManager.Create;
begin
  inherited Create;
  FCancel := False;
end;

destructor TCleanupManager.Destroy;
begin
  inherited Destroy;
end;

procedure TCleanupManager.UpdateProgress(const AMessage: string; AProgress: Integer);
begin
  if Assigned(FProgressCallback) then
    FProgressCallback(AMessage, AProgress);
    
  Application.ProcessMessages;
end;

procedure TCleanupManager.Cancel;
begin
  FCancel := True;
end;

function TCleanupManager.IsCancelled: Boolean;
begin
  Result := FCancel;
end;

function TCleanupManager.GetTempPath: string;
var
  TempDir: array[0..MAX_PATH] of Char;
begin
  Winapi.Windows.GetTempPath(MAX_PATH, TempDir);
  Result := string(TempDir);
end;

function TCleanupManager.GetRecycleBinPath: string;
begin
  Result := uConstants.GetRecycleBinPath;
end;

function TCleanupManager.GetWindowsUpdatePath: string;
begin
  Result := uConstants.GetWindowsUpdateCachePath;
end;

function TCleanupManager.GetBrowserCachePaths: TArray<string>;
var
  UserProfile: string;
  Paths: TList<string>;
begin
  UserProfile := GetEnvironmentVariable('USERPROFILE');
  Paths := TList<string>.Create;
  try
    // Chrome缓存
    Paths.Add(TPath.Combine(UserProfile, 'AppData\Local\Google\Chrome\User Data\Default\Cache'));
    Paths.Add(TPath.Combine(UserProfile, 'AppData\Local\Google\Chrome\User Data\Default\Code Cache'));
    
    // Firefox缓存
    Paths.Add(TPath.Combine(UserProfile, 'AppData\Local\Mozilla\Firefox\Profiles'));
    
    // Edge缓存
    Paths.Add(TPath.Combine(UserProfile, 'AppData\Local\Microsoft\Edge\User Data\Default\Cache'));
    
    // IE缓存
    Paths.Add(TPath.Combine(UserProfile, 'AppData\Local\Microsoft\Windows\INetCache'));
    
    Result := Paths.ToArray;
  finally
    Paths.Free;
  end;
end;

function TCleanupManager.GetSystemTempPaths: TArray<string>;
var
  Paths: TList<string>;
begin
  Paths := TList<string>.Create;
  try
    // 用户临时文件
    Paths.Add(GetTempPath);
    
    // 系统临时文件
    Paths.Add('C:\Windows\Temp');
    
    // 预取文件
    Paths.Add('C:\Windows\Prefetch');
    
    // 缩略图缓存
    Paths.Add(TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local\Microsoft\Windows\Explorer'));
    
    Result := Paths.ToArray;
  finally
    Paths.Free;
  end;
end;

function TCleanupManager.IsSafeToDelete(const APath: string): Boolean;
const
  // 安全文件扩展名白名单
  SAFE_EXTENSIONS: array[0..15] of string = (
    '.tmp', '.temp', '.log', '.cache', '.bak', '.old',
    '.dmp', '.chk', '.gid', '.fts', '.ftg',  // 系统临时文件
    '.thumbs', '.db-journal', '.etl',        // 缓存/日志
    '.part', '.download'                     // 下载临时文件
  );
  // 安全目录名关键字白名单
  SAFE_DIR_KEYWORDS: array[0..10] of string = (
    'cache', 'temp', 'tmp', 'logs', 'thumbnails',
    'crashreports', 'installer', 'webcache', 'gpucache',
    'shadercache', 'codecache'
  );
var
  PathLower: string;
  FileName: string;
  Ext: string;
  I: Integer;
  IsSafeExt, IsSafeDir: Boolean;
begin
  Result := False;
  
  if not TFile.Exists(APath) and not TDirectory.Exists(APath) then
    Exit;
    
  PathLower := LowerCase(APath);
  FileName := LowerCase(ExtractFileName(APath));
  
  // 检查是否是系统关键路径（黑名单优先）
  if IsSystemCriticalPath(APath) then
    Exit;
    
  // 检查文件扩展名白名单
  if TFile.Exists(APath) then
  begin
    // 检查以~开头的临时文件
    if FileName.StartsWith('~') then
    begin
      Result := True;
      Exit;
    end;
    
    // 检查扩展名
    Ext := LowerCase(ExtractFileExt(APath));
    IsSafeExt := False;
    for I := Low(SAFE_EXTENSIONS) to High(SAFE_EXTENSIONS) do
    begin
      if Ext = SAFE_EXTENSIONS[I] then
      begin
        IsSafeExt := True;
        Break;
      end;
    end;
    Result := IsSafeExt;
  end
  else if TDirectory.Exists(APath) then
  begin
    // 检查目录名关键字白名单
    IsSafeDir := False;
    for I := Low(SAFE_DIR_KEYWORDS) to High(SAFE_DIR_KEYWORDS) do
    begin
      if PathLower.Contains(SAFE_DIR_KEYWORDS[I]) then
      begin
        IsSafeDir := True;
        Break;
      end;
    end;
    Result := IsSafeDir;
  end;
end;

function TCleanupManager.IsSystemCriticalPath(const APath: string): Boolean;
const
  // 系统关键路径黑名单（绝对禁止删除）
  CRITICAL_PATHS: array[0..23] of string = (
    // Windows 系统目录
    'c:\windows\system32',
    'c:\windows\syswow64',
    'c:\windows\boot',
    'c:\windows\drivers',
    'c:\windows\fonts',
    'c:\windows\winsxs',
    'c:\windows\servicing',
    'c:\windows\assembly',
    // 程序目录
    'c:\program files',
    'c:\program files (x86)',
    'c:\programdata\microsoft',
    // 用户关键目录
    'c:\users\all users',
    'c:\users\default',
    'c:\users\public',
    // NTFS 系统文件
    'c:\$mft',
    'c:\$logfile',
    'c:\$volume',
    'c:\$recycle.bin',
    'c:\system volume information',
    // 用户关键配置
    'appdata\roaming\microsoft\windows\start menu',
    'appdata\roaming\microsoft\windows\recent',
    'appdata\local\microsoft\windows\explorer',
    'ntuser.dat',
    'usrclass.dat'
  );
var
  PathLower: string;
  I: Integer;
begin
  Result := False;
  PathLower := LowerCase(APath);
  
  // 检查是否匹配任何关键路径
  for I := Low(CRITICAL_PATHS) to High(CRITICAL_PATHS) do
  begin
    if PathLower.StartsWith(CRITICAL_PATHS[I]) or 
       PathLower.Contains(CRITICAL_PATHS[I]) then
    begin
      Result := True;
      Exit;
    end;
  end;
  
  // 禁止删除根目录
  if (Length(PathLower) <= 3) and (Pos(':\', PathLower) = 2) then
  begin
    Result := True;
    Exit;
  end;
  
  // 禁止删除用户根目录
  if PathLower.EndsWith('\users') or 
     (Pos('\users\', PathLower) > 0) and (PathLower.CountChar('\') <= 3) then
  begin
    Result := True;
    Exit;
  end;
end;

function TCleanupManager.CleanDirectoryRecursive(const ADirectory: string; var AResult: TCleanupResult): Boolean;
var
  Files: TArray<string>;
  SubDirs: TArray<string>;
  FilePath: string;
  FileSize: Int64;
  I: Integer;
begin
  Result := True;
  
  if FCancel then
    Exit;
    
  if not TDirectory.Exists(ADirectory) then
    Exit;
    
  try
    UpdateProgress('正在清理: ' + ADirectory);
    
    // 清理文件
    Files := TDirectory.GetFiles(ADirectory);
    for I := 0 to High(Files) do
    begin
      if FCancel then Break;
      
      FilePath := Files[I];
      if IsSafeToDelete(FilePath) then
      begin
        try
          FileSize := TFile.GetSize(FilePath);
          TFile.Delete(FilePath);
          Inc(AResult.FilesDeleted);
          AResult.SpaceFreed := AResult.SpaceFreed + FileSize;
          AResult.AddDetail('已删除文件: ' + FilePath);
        except
          on E: Exception do
          begin
            AResult.AddDetail('删除文件失败: ' + FilePath + ' - ' + E.Message);
          end;
        end;
      end;
    end;
    
    // 递归清理子目录
    SubDirs := TDirectory.GetDirectories(ADirectory);
    for I := 0 to High(SubDirs) do
    begin
      if FCancel then Break;
      
      if IsSafeToDelete(SubDirs[I]) then
      begin
        CleanDirectoryRecursive(SubDirs[I], AResult);
        
        // 尝试删除空目录
        try
          if TDirectory.IsEmpty(SubDirs[I]) then
          begin
            TDirectory.Delete(SubDirs[I]);
            AResult.AddDetail('已删除空目录: ' + SubDirs[I]);
          end;
        except
          // 忽略删除目录失败的错误
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      AResult.ErrorMessage := AResult.ErrorMessage + E.Message + '; ';
      Result := False;
    end;
  end;
end;

function TCleanupManager.EmptyRecycleBinInternal: TCleanupResult;
begin
  Result.Success := False;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  try
    UpdateProgress('正在清空回收站...', 0);
    
    // 使用Windows API清空回收站
    if SHEmptyRecycleBin(0, nil, SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI or SHERB_NOSOUND) = S_OK then
    begin
      Result.Success := True;
      Result.AddDetail('回收站已成功清空');
      UpdateProgress('回收站清空完成', 100);
    end
    else
    begin
      Result.ErrorMessage := '清空回收站失败';
      UpdateProgress('清空回收站失败', 100);
    end;
    
  except
    on E: Exception do
    begin
      Result.ErrorMessage := '清空回收站时发生异常: ' + E.Message;
      UpdateProgress('清空回收站异常: ' + E.Message, 100);
    end;
  end;
end;

function TCleanupManager.CleanTempFilesInternal: TCleanupResult;
var
  TempPaths: TArray<string>;
  TempPath: string;
  I: Integer;
begin
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  try
    UpdateProgress('正在清理临时文件...', 0);
    
    TempPaths := GetSystemTempPaths;
    for I := 0 to High(TempPaths) do
    begin
      if FCancel then Break;
      
      TempPath := TempPaths[I];
      UpdateProgress('清理临时目录: ' + TempPath, Round((I + 1) * 100 / Length(TempPaths)));
      
      if TDirectory.Exists(TempPath) then
      begin
        if not CleanDirectoryRecursive(TempPath, Result) then
          Result.Success := False;
      end;
    end;
    
    if Result.Success then
      UpdateProgress('临时文件清理完成', 100)
    else
      UpdateProgress('临时文件清理完成(部分失败)', 100);
      
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := '清理临时文件时发生异常: ' + E.Message;
      UpdateProgress('临时文件清理异常: ' + E.Message, 100);
    end;
  end;
end;

function TCleanupManager.CleanBrowserCacheInternal: TCleanupResult;
var
  CachePaths: TArray<string>;
  CachePath: string;
  I: Integer;
begin
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  try
    UpdateProgress('正在清理浏览器缓存...', 0);
    
    CachePaths := GetBrowserCachePaths;
    for I := 0 to High(CachePaths) do
    begin
      if FCancel then Break;
      
      CachePath := CachePaths[I];
      UpdateProgress('清理浏览器缓存: ' + CachePath, Round((I + 1) * 100 / Length(CachePaths)));
      
      if TDirectory.Exists(CachePath) then
      begin
        if not CleanDirectoryRecursive(CachePath, Result) then
          Result.Success := False;
      end;
    end;
    
    if Result.Success then
      UpdateProgress('浏览器缓存清理完成', 100)
    else
      UpdateProgress('浏览器缓存清理完成(部分失败)', 100);
      
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := '清理浏览器缓存时发生异常: ' + E.Message;
      UpdateProgress('浏览器缓存清理异常: ' + E.Message, 100);
    end;
  end;
end;

function TCleanupManager.CleanWindowsUpdateCacheInternal: TCleanupResult;
var
  UpdatePath: string;
  StoppedWU, StoppedBITS: Boolean;
begin
  Result.Success := False;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  try
    UpdateProgress('正在准备清理Windows更新缓存...', 0);
    // 停止 Windows Update 相关服务
    StoppedWU := StopServiceByName('wuauserv');
    StoppedBITS := StopServiceByName('bits');
    if StoppedWU or StoppedBITS then
      UpdateProgress('已停止相关服务，开始清理...', 10)
    else
      UpdateProgress('未能停止部分服务，尝试继续清理...', 10);
    
    UpdatePath := GetWindowsUpdatePath;
    if TDirectory.Exists(UpdatePath) then
    begin
      UpdateProgress('清理更新缓存: ' + UpdatePath, 50);
      
      if CleanDirectoryRecursive(UpdatePath, Result) then
      begin
        Result.Success := True;
        UpdateProgress('Windows更新缓存清理完成', 90);
      end
      else
      begin
        UpdateProgress('Windows更新缓存清理完成(部分失败)', 90);
      end;
    end
    else
    begin
      Result.Success := True;
      Result.AddDetail('Windows更新缓存目录不存在');
      UpdateProgress('Windows更新缓存目录不存在', 90);
    end;
    
    // 尝试恢复服务
    if StoppedWU then StartServiceByName('wuauserv');
    if StoppedBITS then StartServiceByName('bits');
    UpdateProgress('服务状态已恢复', 100);
    
  except
    on E: Exception do
    begin
      Result.ErrorMessage := '清理Windows更新缓存时发生异常: ' + E.Message;
      UpdateProgress('Windows更新缓存清理异常: ' + E.Message, 100);
    end;
  end;
end;

function TCleanupManager.CleanSystemLogsInternal: TCleanupResult;
var
  LogPaths: TArray<string>;
  LogPath: string;
  I: Integer;
begin
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  try
    UpdateProgress('正在清理系统日志...', 0);
    
    // 定义日志文件路径
    LogPaths := [
      'C:\Windows\Logs',
      'C:\Windows\Debug',
      'C:\Windows\Panther',
      TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local\Microsoft\Windows\WebCache')
    ];
    
    for I := 0 to High(LogPaths) do
    begin
      if FCancel then Break;
      
      LogPath := LogPaths[I];
      UpdateProgress('清理系统日志: ' + LogPath, Round((I + 1) * 100 / Length(LogPaths)));
      
      if TDirectory.Exists(LogPath) then
      begin
        if not CleanDirectoryRecursive(LogPath, Result) then
          Result.Success := False;
      end;
    end;
    
    if Result.Success then
      UpdateProgress('系统日志清理完成', 100)
    else
      UpdateProgress('系统日志清理完成(部分失败)', 100);
      
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := '清理系统日志时发生异常: ' + E.Message;
      UpdateProgress('系统日志清理异常: ' + E.Message, 100);
    end;
  end;
end;

function TCleanupManager.CleanPrefetchFilesInternal: TCleanupResult;
var
  PrefetchPath: string;
begin
  Result.Success := False;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  try
    UpdateProgress('正在清理预取文件...', 0);
    
    PrefetchPath := 'C:\Windows\Prefetch';
    if TDirectory.Exists(PrefetchPath) then
    begin
      UpdateProgress('清理预取文件: ' + PrefetchPath, 50);
      
      if CleanDirectoryRecursive(PrefetchPath, Result) then
      begin
        Result.Success := True;
        UpdateProgress('预取文件清理完成', 100);
      end
      else
      begin
        UpdateProgress('预取文件清理完成(部分失败)', 100);
      end;
    end
    else
    begin
      Result.Success := True;
      Result.AddDetail('预取文件目录不存在');
      UpdateProgress('预取文件目录不存在', 100);
    end;
    
  except
    on E: Exception do
    begin
      Result.ErrorMessage := '清理预取文件时发生异常: ' + E.Message;
      UpdateProgress('预取文件清理异常: ' + E.Message, 100);
    end;
  end;
end;

// 公共方法实现

function TCleanupManager.EmptyRecycleBin: TCleanupResult;
begin
  FCancel := False;
  Result := EmptyRecycleBinInternal;
end;

function TCleanupManager.CleanTempFiles: TCleanupResult;
begin
  FCancel := False;
  Result := CleanTempFilesInternal;
end;

function TCleanupManager.CleanBrowserCache: TCleanupResult;
begin
  FCancel := False;
  Result := CleanBrowserCacheInternal;
end;

function TCleanupManager.CleanWindowsUpdateCache: TCleanupResult;
begin
  FCancel := False;
  Result := CleanWindowsUpdateCacheInternal;
end;

function TCleanupManager.CleanSystemLogs: TCleanupResult;
begin
  FCancel := False;
  Result := CleanSystemLogsInternal;
end;

function TCleanupManager.CleanPrefetchFiles: TCleanupResult;
begin
  FCancel := False;
  Result := CleanPrefetchFilesInternal;
end;

function TCleanupManager.CleanRegistryJunk: TCleanupResult;
begin
  // 注册表清理需要更复杂的实现，这里先提供基础框架
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  UpdateProgress('注册表清理功能正在开发中...', 100);
  Result.AddDetail('注册表清理功能将在未来版本中提供');
end;

function TCleanupManager.PerformSmartCleanup: TCleanupResult;
var
  TempResult: TCleanupResult;
  TotalFiles: Integer;
  TotalSpace: Int64;
begin
  FCancel := False;
  TotalFiles := 0;
  TotalSpace := 0;
  Result.ClearDetails;
  
  try
    UpdateProgress('开始智能清理...', 0);
    
    // 1. 清空回收站
    if not FCancel then
    begin
      UpdateProgress('步骤 1/5: 清空回收站', 20);
      TempResult := EmptyRecycleBinInternal;
      TotalFiles := TotalFiles + TempResult.FilesDeleted;
      TotalSpace := TotalSpace + TempResult.SpaceFreed;
      Result.AddDetails(TempResult.Details);
    end;
    
    // 2. 清理临时文件
    if not FCancel then
    begin
      UpdateProgress('步骤 2/5: 清理临时文件', 40);
      TempResult := CleanTempFilesInternal;
      TotalFiles := TotalFiles + TempResult.FilesDeleted;
      TotalSpace := TotalSpace + TempResult.SpaceFreed;
      Result.AddDetails(TempResult.Details);
    end;
    
    // 3. 清理浏览器缓存
    if not FCancel then
    begin
      UpdateProgress('步骤 3/5: 清理浏览器缓存', 60);
      TempResult := CleanBrowserCacheInternal;
      TotalFiles := TotalFiles + TempResult.FilesDeleted;
      TotalSpace := TotalSpace + TempResult.SpaceFreed;
      Result.AddDetails(TempResult.Details);
    end;
    
    // 4. 清理系统日志
    if not FCancel then
    begin
      UpdateProgress('步骤 4/5: 清理系统日志', 80);
      TempResult := CleanSystemLogsInternal;
      TotalFiles := TotalFiles + TempResult.FilesDeleted;
      TotalSpace := TotalSpace + TempResult.SpaceFreed;
      Result.AddDetails(TempResult.Details);
    end;
    
    // 5. 清理预取文件
    if not FCancel then
    begin
      UpdateProgress('步骤 5/5: 清理预取文件', 90);
      TempResult := CleanPrefetchFilesInternal;
      TotalFiles := TotalFiles + TempResult.FilesDeleted;
      TotalSpace := TotalSpace + TempResult.SpaceFreed;
      Result.AddDetails(TempResult.Details);
    end;
    
    // 汇总结果
    Result.Success := not FCancel;
    Result.FilesDeleted := TotalFiles;
    Result.SpaceFreed := TotalSpace;
    
    if FCancel then
    begin
      Result.ErrorMessage := '清理操作被用户取消';
      UpdateProgress('清理操作已取消', 100);
    end
    else
    begin
      UpdateProgress(Format('智能清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [TotalFiles, TotalSpace / (1024 * 1024)]), 100);
    end;
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := '智能清理时发生异常: ' + E.Message;
      Result.FilesDeleted := TotalFiles;
      Result.SpaceFreed := TotalSpace;
      UpdateProgress('智能清理异常: ' + E.Message, 100);
    end;
  end;
end;

function TCleanupManager.AnalyzeDiskUsage: TCleanupResult;
begin
  // 磁盘使用分析功能
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.ClearDetails;
  
  UpdateProgress('磁盘使用分析功能正在开发中...', 100);
  Result.AddDetail('磁盘使用分析功能将在未来版本中提供');
end;

function TCleanupManager.GetCleanableSize: Int64;
begin
  // 计算可清理的文件大小
  Result := 0;
  // TODO: 实现可清理大小计算逻辑
end;

function TCleanupManager.StopServiceByName(const ServiceName: string; TimeoutMs: Cardinal = SERVICE_STOP_TIMEOUT_MS): Boolean;
var
  hSCM, hSvc: SC_HANDLE;
  SvcStatus: SERVICE_STATUS_PROCESS;
  BytesNeeded: DWORD;
  StartTick: Cardinal;
  SvcStatusLegacy: SERVICE_STATUS;
begin
  Result := False;
  hSCM := Winapi.WinSvc.OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if hSCM = 0 then Exit;
  try
    hSvc := Winapi.WinSvc.OpenService(hSCM, PChar(ServiceName), SERVICE_STOP or SERVICE_QUERY_STATUS);
    if hSvc = 0 then Exit;
    try
      Winapi.WinSvc.ControlService(hSvc, SERVICE_CONTROL_STOP, SvcStatusLegacy);
      StartTick := GetTickCount;
      repeat
        if not Winapi.WinSvc.QueryServiceStatusEx(hSvc, SC_STATUS_PROCESS_INFO, @SvcStatus, SizeOf(SvcStatus), BytesNeeded) then Break;
        if SvcStatus.dwCurrentState = SERVICE_STOPPED then
        begin
          Result := True;
          Break;
        end;
        Sleep(200);
      until (GetTickCount - StartTick >= TimeoutMs);
    finally
      Winapi.WinSvc.CloseServiceHandle(hSvc);
    end;
  finally
    Winapi.WinSvc.CloseServiceHandle(hSCM);
  end;
end;

function TCleanupManager.StartServiceByName(const ServiceName: string; TimeoutMs: Cardinal): Boolean;
var
  hSCM, hSvc: SC_HANDLE;
  SvcStatus: SERVICE_STATUS_PROCESS;
  BytesNeeded: DWORD;
  StartTick: Cardinal;
  Args: PWideChar;

begin
  Result := False;
  hSCM := Winapi.WinSvc.OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if hSCM = 0 then Exit;
  try
    hSvc := Winapi.WinSvc.OpenService(hSCM, PChar(ServiceName), SERVICE_START or SERVICE_QUERY_STATUS);
    if hSvc = 0 then Exit;
    try
      Args := nil;
      Winapi.WinSvc.StartService(hSvc, 0, Args);
      StartTick := GetTickCount;
      repeat
        if not Winapi.WinSvc.QueryServiceStatusEx(hSvc, SC_STATUS_PROCESS_INFO, @SvcStatus, SizeOf(SvcStatus), BytesNeeded) then Break;
        if SvcStatus.dwCurrentState = SERVICE_RUNNING then
        begin
          Result := True;
          Break;
        end;
        Sleep(200);
      until (GetTickCount - StartTick >= TimeoutMs);
    finally
      Winapi.WinSvc.CloseServiceHandle(hSvc);
    end;
  finally
    Winapi.WinSvc.CloseServiceHandle(hSCM);
  end;
end;



end.
