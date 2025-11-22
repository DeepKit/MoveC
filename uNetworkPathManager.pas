unit uNetworkPathManager;

interface

uses
  Winapi.Windows, Winapi.WinSock, Winapi.WinInet, System.SysUtils, System.Classes,
  System.Generics.Collections, System.SyncObjs, System.Threading, System.Diagnostics;

type
  TNetworkConnectionStatus = (ncsUnknown, ncsConnected, ncsDisconnected, ncsConnecting, ncsError);
  TNetworkPathType = (nptLocal, nptLAN, nptVPN, nptInternet, nptCloud);
  
  TNetworkPathInfo = record
    Path: string;
    PathType: TNetworkPathType;
    ServerName: string;
    ShareName: string;
    IsAvailable: Boolean;
    LastChecked: TDateTime;
    ResponseTime: Integer;
    ErrorMsg: string;
  end;
  
  TNetworkConnectionEvent = procedure(const APath: string; const AStatus: TNetworkConnectionStatus) of object;
  TNetworkTestResult = record
    Success: Boolean;
    ResponseTime: Integer;
    ErrorMsg: string;
    ErrorCode: DWORD;
  end;

type
  TNetworkPathManager = class
  private
    FCachedPaths: TDictionary<string, TNetworkPathInfo>;
    FConnectionStatus: TDictionary<string, TNetworkConnectionStatus>;
    FMonitorThreads: TDictionary<string, TThread>;
    FLock: TCriticalSection;
    FActive: Boolean;
    FCheckInterval: Cardinal;
    FTimeout: Cardinal;
    FRetryCount: Integer;
    FOnConnectionChange: TNetworkConnectionEvent;
    
    function IsNetworkPath(const APath: string): Boolean;
    function GetPathType(const APath: string): TNetworkPathType;
    function ParseNetworkPath(const APath: string): TNetworkPathInfo;
    function TestConnection(const APath: string): TNetworkTestResult;
    function PingHost(const AHostName: string; const ATimeout: Cardinal): Integer;
    function TestSMBConnection(const AServer, AShare: string): TNetworkTestResult;
    procedure MonitorPath(const APath: string);
    procedure StopMonitoring(const APath: string);
    procedure UpdateConnectionStatus(const APath: string; const AStatus: TNetworkConnectionStatus);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要功能
    function ValidatePath(const APath: string): Boolean;
    function GetPathInfo(const APath: string): TNetworkPathInfo;
    function IsPathAvailable(const APath: string): Boolean;
    function TestPathConnection(const APath: string): TNetworkTestResult;
    
    // 监控功能
    procedure StartMonitoring(const APath: string);
    procedure StopMonitoring(const APath: string);
    procedure StartAllMonitoring;
    procedure StopAllMonitoring;
    
    // 自动重连
    function TryReconnect(const APath: string): Boolean;
    procedure EnableAutoReconnect(const APath: string; const AEnabled: Boolean);
    
    // 配置
    property CheckInterval: Cardinal read FCheckInterval write FCheckInterval;
    property Timeout: Cardinal read FTimeout write FTimeout;
    property RetryCount: Integer read FRetryCount write FRetryCount;
    
    // 事件
    property OnConnectionChange: TNetworkConnectionEvent read FOnConnectionChange write FOnConnectionChange;
  end;

implementation

{ TNetworkPathManager }

constructor TNetworkPathManager.Create;
begin
  inherited Create;
  FCachedPaths := TDictionary<string, TNetworkPathInfo>.Create;
  FConnectionStatus := TDictionary<string, TNetworkConnectionStatus>.Create;
  FMonitorThreads := TDictionary<string, TThread>.Create;
  FLock := TCriticalSection.Create;
  FActive := False;
  FCheckInterval := 30000; // 30秒
  FTimeout := 5000;       // 5秒
  FRetryCount := 3;
end;

destructor TNetworkPathManager.Destroy;
begin
  StopAllMonitoring;
  FreeAndNil(FLock);
  FreeAndNil(FMonitorThreads);
  FreeAndNil(FConnectionStatus);
  FreeAndNil(FCachedPaths);
  inherited Destroy;
end;

function TNetworkPathManager.IsNetworkPath(const APath: string): Boolean;
begin
  Result := (Length(APath) >= 2) and 
            ((APath[1] = '\') and (APath[2] = '\')) or  // UNC路径
            (ExtractFileDrive(APath).Length > 2);       // 映射网络驱动器
end;

function TNetworkPathManager.GetPathType(const APath: string): TNetworkPathType;
begin
  if not IsNetworkPath(APath) then
    Exit(nptLocal);
    
  if APath.StartsWith('\\') then
  begin
    if APath.Contains('vpn') or APath.Contains('tunnel') then
      Exit(nptVPN)
    else
      Exit(nptLAN);
  end;
  
  if APath.Contains('cloud') or APath.Contains('onedrive') or APath.Contains('dropbox') then
    Exit(nptCloud);
    
  Exit(nptInternet);
end;

function TNetworkPathManager.ParseNetworkPath(const APath: string): TNetworkPathInfo;
var
  Parts: TArray<string>;
begin
  Result.Path := APath;
  Result.PathType := GetPathType(APath);
  Result.IsAvailable := False;
  Result.LastChecked := 0;
  Result.ResponseTime := 0;
  Result.ErrorMsg := '';
  
  if APath.StartsWith('\\') then
  begin
    // UNC路径: \\server\share\path
    Parts := APath.Split(['\'], TStringSplitOptions.ExcludeEmpty);
    if Length(Parts) >= 2 then
    begin
      Result.ServerName := Parts[0];
      Result.ShareName := Parts[1];
    end;
  end
  else
  begin
    // 映射驱动器
    var Drive := ExtractFileDrive(APath);
    Result.ServerName := Drive;
    Result.ShareName := '';
  end;
end;

function TNetworkPathManager.ValidatePath(const APath: string): Boolean;
begin
  if APath.IsEmpty then
    Exit(False);
    
  if IsNetworkPath(APath) then
  begin
    var TestResult := TestConnection(APath);
    Result := TestResult.Success;
  end
  else
  begin
    Result := TDirectory.Exists(APath);
  end;
end;

function TNetworkPathManager.TestConnection(const APath: string): TNetworkTestResult;
var
  PathInfo: TNetworkPathInfo;
begin
  Result.Success := False;
  Result.ResponseTime := 0;
  Result.ErrorMsg := '';
  Result.ErrorCode := 0;
  
  try
    PathInfo := ParseNetworkPath(APath);
    
    case PathInfo.PathType of
      nptLAN:
        begin
          if PathInfo.ServerName <> '' then
          begin
            // 先Ping服务器
            var PingTime := PingHost(PathInfo.ServerName, FTimeout);
            if PingTime >= 0 then
            begin
              Result.ResponseTime := PingTime;
              if PathInfo.ShareName <> '' then
              begin
                // 测试SMB连接
                var SMBResult := TestSMBConnection(PathInfo.ServerName, PathInfo.ShareName);
                Result := SMBResult;
                Result.ResponseTime := PingTime + SMBResult.ResponseTime;
              end
              else
              begin
                Result.Success := True;
              end;
            end
            else
            begin
              Result.ErrorMsg := '无法连接到服务器';
              Result.ErrorCode := GetLastError;
            end;
          end;
        end;
        
      nptLocal:
        begin
          Result.Success := TDirectory.Exists(APath);
          if not Result.Success then
            Result.ErrorMsg := '本地路径不存在';
        end;
        
      else
        begin
          // 其他类型网络路径的测试
          Result.Success := TDirectory.Exists(APath);
          if not Result.Success then
            Result.ErrorMsg := '网络路径不可访问';
        end;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMsg := E.Message;
      Result.ErrorCode := GetLastError;
    end;
  end;
end;

function TNetworkPathManager.PingHost(const AHostName: string; const ATimeout: Cardinal): Integer;
var
  hIcmp: THandle;
  pIpe: PIP_OPTION_INFORMATION;
  pIeno: PIP_ECHO_REPLY;
  dwRet: DWORD;
  dwSize: DWORD;
begin
  Result := -1;
  
  hIcmp := IcmpCreateFile;
  if hIcmp = INVALID_HANDLE_VALUE then
    Exit;
    
  try
    dwSize := SizeOf(IP_ECHO_REPLY) + 8;
    GetMem(pIeno, dwSize);
    try
      pIpe := AllocMem(SizeOf(IP_OPTION_INFORMATION));
      try
        dwRet := IcmpSendEcho(hIcmp, inet_addr(PChar(AHostName)), nil, 0, pIpe^, pIeno^, dwSize, ATimeout);
        if dwRet > 0 then
          Result := pIeno.RoundTripTime;
      finally
        FreeMem(pIpe);
      end;
    finally
      FreeMem(pIeno);
    end;
  finally
    IcmpCloseHandle(hIcmp);
  end;
end;

function TNetworkPathManager.TestSMBConnection(const AServer, AShare: string): TNetworkTestResult;
var
  SharePath: string;
  Stopwatch: TStopwatch;
begin
  Result.Success := False;
  Result.ResponseTime := 0;
  Result.ErrorMsg := '';
  
  SharePath := '\\' + AServer + '\' + AShare;
  Stopwatch := TStopwatch.StartNew;
  
  try
    // 尝试枚举共享目录
    var FindHandle := FindFirstFile(PChar(SharePath + '\*'), TWin32FindData);
    if FindHandle <> INVALID_HANDLE_VALUE then
    begin
      Windows.FindClose(FindHandle);
      Result.Success := True;
    end
    else
    begin
      Result.ErrorCode := GetLastError;
      case Result.ErrorCode of
        ERROR_BAD_NETPATH: Result.ErrorMsg := '网络路径不存在';
        ERROR_ACCESS_DENIED: Result.ErrorMsg := '访问被拒绝';
        ERROR_NETWORK_ACCESS_DENIED: Result.ErrorMsg := '网络访问被拒绝';
        ERROR_BAD_NET_NAME: Result.ErrorMsg := '网络名称无效';
        else Result.ErrorMsg := 'SMB连接失败';
      end;
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMsg := E.Message;
    end;
  end;
  
  Stopwatch.Stop;
  Result.ResponseTime := Trunc(Stopwatch.Elapsed.TotalMilliseconds);
end;

function TNetworkPathManager.GetPathInfo(const APath: string): TNetworkPathInfo;
begin
  FLock.Enter;
  try
    if FCachedPaths.ContainsKey(APath) then
    begin
      Result := FCachedPaths[APath];
    end
    else
    begin
      Result := ParseNetworkPath(APath);
      var TestResult := TestConnection(APath);
      Result.IsAvailable := TestResult.Success;
      Result.ResponseTime := TestResult.ResponseTime;
      Result.ErrorMsg := TestResult.ErrorMsg;
      Result.LastChecked := Now;
      FCachedPaths.AddOrSetValue(APath, Result);
    end;
  finally
    FLock.Leave;
  end;
end;

function TNetworkPathManager.IsPathAvailable(const APath: string): Boolean;
begin
  var PathInfo := GetPathInfo(APath);
  Result := PathInfo.IsAvailable;
end;

function TNetworkPathManager.TestPathConnection(const APath: string): TNetworkTestResult;
begin
  Result := TestConnection(APath);
  
  // 更新缓存
  FLock.Enter;
  try
    if FCachedPaths.ContainsKey(APath) then
    begin
      var PathInfo := FCachedPaths[APath];
      PathInfo.IsAvailable := Result.Success;
      PathInfo.ResponseTime := Result.ResponseTime;
      PathInfo.ErrorMsg := Result.ErrorMsg;
      PathInfo.LastChecked := Now;
      FCachedPaths[APath] := PathInfo;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkPathManager.StartMonitoring(const APath: string);
begin
  if not IsNetworkPath(APath) then Exit;
  
  FLock.Enter;
  try
    if FMonitorThreads.ContainsKey(APath) then Exit;
    
    var MonitorThread := TThread.CreateAnonymousThread(
      procedure
      begin
        MonitorPath(APath);
      end);
      
    FMonitorThreads.AddOrSetValue(APath, MonitorThread);
    MonitorThread.Start;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkPathManager.StopMonitoring(const APath: string);
begin
  FLock.Enter;
  try
    if FMonitorThreads.ContainsKey(APath) then
    begin
      StopMonitoring(APath);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkPathManager.MonitorPath(const APath: string);
var
  LastStatus: TNetworkConnectionStatus;
  CurrentStatus: TNetworkConnectionStatus;
begin
  LastStatus := ncsUnknown;
  
  while FActive do
  begin
    try
      var TestResult := TestPathConnection(APath);
      
      if TestResult.Success then
        CurrentStatus := ncsConnected
      else
        CurrentStatus := ncsDisconnected;
      
      if CurrentStatus <> LastStatus then
      begin
        UpdateConnectionStatus(APath, CurrentStatus);
        LastStatus := CurrentStatus;
      end;
      
    except
      CurrentStatus := ncsError;
      UpdateConnectionStatus(APath, CurrentStatus);
    end;
    
    Sleep(FCheckInterval);
  end;
end;

procedure TNetworkPathManager.UpdateConnectionStatus(const APath: string; const AStatus: TNetworkConnectionStatus);
begin
  FLock.Enter;
  try
    FConnectionStatus.AddOrSetValue(APath, AStatus);
  finally
    FLock.Leave;
  end;
  
  if Assigned(FOnConnectionChange) then
  begin
    try
      FOnConnectionChange(APath, AStatus);
    except
      // 忽略回调错误
    end;
  end;
end;

function TNetworkPathManager.TryReconnect(const APath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  for I := 1 to FRetryCount do
  begin
    var TestResult := TestPathConnection(APath);
    if TestResult.Success then
    begin
      Result := True;
      UpdateConnectionStatus(APath, ncsConnected);
      Exit;
    end;
    
    Sleep(1000 * I); // 递增延迟
  end;
  
  UpdateConnectionStatus(APath, ncsError);
end;

procedure TNetworkPathManager.StartAllMonitoring;
begin
  FActive := True;
end;

procedure TNetworkPathManager.StopAllMonitoring;
begin
  FActive := False;
  
  FLock.Enter;
  try
    for var Thread in FMonitorThreads.Values do
    begin
      if Assigned(Thread) then
        Thread.WaitFor;
    end;
    FMonitorThreads.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkPathManager.EnableAutoReconnect(const APath: string; const AEnabled: Boolean);
begin
  // TODO: 实现自动重连逻辑
end;

end.
