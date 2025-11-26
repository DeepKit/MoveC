unit uNetworkConnectionMonitor;

interface

uses
  Winapi.Windows, Winapi.WinSock, Winapi.IpHlpApi, System.SysUtils, System.Classes,
  System.Generics.Collections, System.SyncObjs, System.Threading, System.Diagnostics;

type
  TNetworkEventType = (netConnect, netDisconnect, netReconnect, netError);
  TNetworkAdapterType = (natEthernet, natWiFi, natVPN, natMobile, natOther);
  
  TNetworkEvent = record
    EventType: TNetworkEventType;
    AdapterName: string;
    AdapterType: TNetworkAdapterType;
    EventTime: TDateTime;
    Description: string;
  end;
  
  TNetworkAdapterInfo = record
    Name: string;
    Description: string;
    AdapterType: TNetworkAdapterType;
    IsConnected: Boolean;
    Speed: Int64;
    IPAddress: string;
    SubnetMask: string;
    Gateway: string;
    DNSServers: TArray<string>;
    LastChange: TDateTime;
  end;
  
  TNetworkStatusChange = procedure(const AEvent: TNetworkEvent) of object;

type
  TNetworkConnectionMonitor = class
  private
    FAdapters: TDictionary<string, TNetworkAdapterInfo>;
    FEventHistory: TList<TNetworkEvent>;
    FLock: TCriticalSection;
    FActive: Boolean;
    FMonitorThread: TThread;
    FCheckInterval: Cardinal;
    FOnStatusChange: TNetworkStatusChange;
    FLastNetworkState: Boolean;
    
    procedure MonitorThreadProc;
    function GetCurrentAdapters: TArray<TNetworkAdapterInfo>;
    function GetAdapterType(const AAdapterType: DWORD): TNetworkAdapterType;
    function GetIPAddresses(const AAdapterName: string): TArray<string>;
    procedure DetectAdapterChanges(const ANewAdapters: TArray<TNetworkAdapterInfo>);
    procedure TriggerNetworkEvent(const AEventType: TNetworkEventType; const AAdapterName: string; 
      const AAdapterType: TNetworkAdapterType; const ADescription: string);
    function IsNetworkAvailable: Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 监控控制
    procedure StartMonitoring;
    procedure StopMonitoring;
    function IsMonitoring: Boolean;
    
    // 状态查询
    function GetConnectedAdapters: TArray<TNetworkAdapterInfo>;
    function GetAllAdapters: TArray<TNetworkAdapterInfo>;
    function GetAdapterInfo(const AAdapterName: string): TNetworkAdapterInfo;
    function IsAdapterConnected(const AAdapterName: string): Boolean;
    
    // 网络状态
    function HasInternetConnection: Boolean;
    function GetNetworkStatus: string;
    function GetEventHistory(const ACount: Integer = 10): TArray<TNetworkEvent>;
    
    // 事件
    property OnStatusChange: TNetworkStatusChange read FOnStatusChange write FOnStatusChange;
    property CheckInterval: Cardinal read FCheckInterval write FCheckInterval;
  end;

implementation

{ TNetworkConnectionMonitor }

constructor TNetworkConnectionMonitor.Create;
begin
  inherited Create;
  FAdapters := TDictionary<string, TNetworkAdapterInfo>.Create;
  FEventHistory := TList<TNetworkEvent>.Create;
  FLock := TCriticalSection.Create;
  FActive := False;
  FCheckInterval := 5000; // 5秒检查间隔
  FLastNetworkState := False;
end;

destructor TNetworkConnectionMonitor.Destroy;
begin
  StopMonitoring;
  FreeAndNil(FLock);
  FreeAndNil(FEventHistory);
  FreeAndNil(FAdapters);
  inherited Destroy;
end;

procedure TNetworkConnectionMonitor.StartMonitoring;
begin
  if FActive then Exit;
  
  FActive := True;
  
  // 初始化适配器状态
  var InitialAdapters := GetCurrentAdapters;
  FLock.Enter;
  try
    FAdapters.Clear;
    for var Adapter in InitialAdapters do
    begin
      FAdapters.AddOrSetValue(Adapter.Name, Adapter);
    end;
    FLastNetworkState := IsNetworkAvailable;
  finally
    FLock.Leave;
  end;
  
  // 启动监控线程
  FMonitorThread := TThread.CreateAnonymousThread(
    procedure
    begin
      MonitorThreadProc;
    end);
  FMonitorThread.Start;
end;

procedure TNetworkConnectionMonitor.StopMonitoring;
begin
  if not FActive then Exit;
  
  FActive := False;
  
  if Assigned(FMonitorThread) then
  begin
    FMonitorThread.WaitFor;
    FreeAndNil(FMonitorThread);
  end;
end;

function TNetworkConnectionMonitor.IsMonitoring: Boolean;
begin
  Result := FActive and Assigned(FMonitorThread) and not FMonitorThread.Finished;
end;

procedure TNetworkConnectionMonitor.MonitorThreadProc;
begin
  while FActive do
  begin
    try
      var NewAdapters := GetCurrentAdapters;
      DetectAdapterChanges(NewAdapters);
      
      // 检查整体网络状态变化
      var CurrentState := IsNetworkAvailable;
      if CurrentState <> FLastNetworkState then
      begin
        if CurrentState then
          TriggerNetworkEvent(netConnect, 'Network', natOther, '网络连接已恢复')
        else
          TriggerNetworkEvent(netDisconnect, 'Network', natOther, '网络连接已断开');
        FLastNetworkState := CurrentState;
      end;
      
    except
      on E: Exception do
      begin
        TriggerNetworkEvent(netError, 'System', natOther, '监控错误: ' + E.Message);
      end;
    end;
    
    Sleep(FCheckInterval);
  end;
end;

function TNetworkConnectionMonitor.GetCurrentAdapters: TArray<TNetworkAdapterInfo>;
var
  pAdapterInfo: PIP_ADAPTER_INFO;
  AdapterInfo: IP_ADAPTER_INFO;
  Buffer: TArray<Byte>;
  OutBufLen: ULONG;
  RetVal: DWORD;
  AdapterList: TList<TNetworkAdapterInfo>;
  Adapter: TNetworkAdapterInfo;
begin
  AdapterList := TList<TNetworkAdapterInfo>.Create;
  try
    OutBufLen := 0;
    
    // 获取所需缓冲区大小
    RetVal := GetAdaptersInfo(nil, OutBufLen);
    if RetVal = ERROR_BUFFER_OVERFLOW then
    begin
      SetLength(Buffer, OutBufLen);
      pAdapterInfo := PIP_ADAPTER_INFO(@Buffer[0]);
      RetVal := GetAdaptersInfo(pAdapterInfo, OutBufLen);
    end;
    
    if RetVal = NO_ERROR then
    begin
      var CurrentAdapter := pAdapterInfo;
      while Assigned(CurrentAdapter) do
      begin
        Adapter.Name := string(CurrentAdapter.AdapterName);
        Adapter.Description := string(CurrentAdapter.Description);
        Adapter.AdapterType := GetAdapterType(CurrentAdapter.Type);
        Adapter.IsConnected := (CurrentAdapter.Type <> MIB_IF_TYPE_LOOPBACK) and 
                              (CurrentAdapter.Type <> MIB_IF_TYPE_OTHER);
        Adapter.Speed := CurrentAdapter.Speed;
        Adapter.IPAddress := string(CurrentAdapter.IpAddressList.IpAddress.S);
        Adapter.SubnetMask := string(CurrentAdapter.IpAddressList.IpMask.S);
        Adapter.Gateway := string(CurrentAdapter.GatewayList.IpAddress.S);
        Adapter.LastChange := Now;
        
        // 获取DNS服务器
        var DNSServers: TArray<string>;
        var DnsList := CurrentAdapter.PrimaryWinsServer;
        // TODO: 实现DNS服务器获取
        Adapter.DNSServers := DNSServers;
        
        AdapterList.Add(Adapter);
        CurrentAdapter := CurrentAdapter.Next;
      end;
    end;
    
    Result := AdapterList.ToArray;
  finally
    AdapterList.Free;
  end;
end;

function TNetworkConnectionMonitor.GetAdapterType(const AAdapterType: DWORD): TNetworkAdapterType;
begin
  case AAdapterType of
    MIB_IF_TYPE_ETHERNET: Result := natEthernet;
    IF_TYPE_IEEE80211: Result := natWiFi;
    MIB_IF_TYPE_PPP: Result := natVPN;
    MIB_IF_TYPE_SLIP: Result := natMobile;
    else Result := natOther;
  end;
end;

function TNetworkConnectionMonitor.GetIPAddresses(const AAdapterName: string): TArray<string>;
begin
  // TODO: 实现获取适配器所有IP地址
  SetLength(Result, 0);
end;

procedure TNetworkConnectionMonitor.DetectAdapterChanges(const ANewAdapters: TArray<TNetworkAdapterInfo>);
var
  NewAdapterDict: TDictionary<string, TNetworkAdapterInfo>;
  OldAdapterDict: TDictionary<string, TNetworkAdapterInfo>;
  Adapter: TNetworkAdapterInfo;
begin
  NewAdapterDict := TDictionary<string, TNetworkAdapterInfo>.Create;
  try
    // 构建新适配器字典
    for Adapter in ANewAdapters do
    begin
      NewAdapterDict.AddOrSetValue(Adapter.Name, Adapter);
    end;
    
    FLock.Enter;
    try
      OldAdapterDict := TDictionary<string, TNetworkAdapterInfo>.Create(FAdapters);
      try
        // 检查新连接的适配器
        for var Pair in NewAdapterDict do
        begin
          if not OldAdapterDict.ContainsKey(Pair.Key) then
          begin
            // 新适配器
            TriggerNetworkEvent(netConnect, Pair.Key, Pair.Value.AdapterType, '适配器已连接');
          end
          else if OldAdapterDict[Pair.Key].IsConnected <> Pair.Value.IsConnected then
          begin
            // 状态变化
            if Pair.Value.IsConnected then
              TriggerNetworkEvent(netReconnect, Pair.Key, Pair.Value.AdapterType, '适配器已重新连接')
            else
              TriggerNetworkEvent(netDisconnect, Pair.Key, Pair.Value.AdapterType, '适配器已断开');
          end;
        end;
        
        // 检查断开的适配器
        for var Pair in OldAdapterDict do
        begin
          if not NewAdapterDict.ContainsKey(Pair.Key) then
          begin
            TriggerNetworkEvent(netDisconnect, Pair.Key, Pair.Value.AdapterType, '适配器已移除');
          end;
        end;
        
        // 更新适配器列表
        FAdapters.Clear;
        for var Pair in NewAdapterDict do
        begin
          FAdapters.AddOrSetValue(Pair.Key, Pair.Value);
        end;
        
      finally
        OldAdapterDict.Free;
      end;
    finally
      FLock.Leave;
    end;
  finally
    NewAdapterDict.Free;
  end;
end;

procedure TNetworkConnectionMonitor.TriggerNetworkEvent(const AEventType: TNetworkEventType; 
  const AAdapterName: string; const AAdapterType: TNetworkAdapterType; const ADescription: string);
var
  NetworkEvent: TNetworkEvent;
begin
  NetworkEvent.EventType := AEventType;
  NetworkEvent.AdapterName := AAdapterName;
  NetworkEvent.AdapterType := AAdapterType;
  NetworkEvent.EventTime := Now;
  NetworkEvent.Description := ADescription;
  
  FLock.Enter;
  try
    FEventHistory.Add(NetworkEvent);
    // 保持历史记录在合理范围内
    while FEventHistory.Count > 100 do
      FEventHistory.Delete(0);
  finally
    FLock.Leave;
  end;
  
  if Assigned(FOnStatusChange) then
  begin
    try
      FOnStatusChange(NetworkEvent);
    except
      // 忽略回调错误
    end;
  end;
end;

function TNetworkConnectionMonitor.IsNetworkAvailable: Boolean;
var
  Adapters: TArray<TNetworkAdapterInfo>;
begin
  Adapters := GetConnectedAdapters;
  Result := Length(Adapters) > 0;
end;

function TNetworkConnectionMonitor.GetConnectedAdapters: TArray<TNetworkAdapterInfo>;
var
  ConnectedList: TList<TNetworkAdapterInfo>;
  Adapter: TNetworkAdapterInfo;
begin
  ConnectedList := TList<TNetworkAdapterInfo>.Create;
  try
    FLock.Enter;
    try
      for Adapter in FAdapters.Values do
      begin
        if Adapter.IsConnected then
          ConnectedList.Add(Adapter);
      end;
    finally
      FLock.Leave;
    end;
    Result := ConnectedList.ToArray;
  finally
    ConnectedList.Free;
  end;
end;

function TNetworkConnectionMonitor.GetAllAdapters: TArray<TNetworkAdapterInfo>;
var
  AdapterList: TList<TNetworkAdapterInfo>;
begin
  AdapterList := TList<TNetworkAdapterInfo>.Create;
  try
    FLock.Enter;
    try
      for Adapter in FAdapters.Values do
      begin
        AdapterList.Add(Adapter);
      end;
    finally
      FLock.Leave;
    end;
    Result := AdapterList.ToArray;
  finally
    AdapterList.Free;
  end;
end;

function TNetworkConnectionMonitor.GetAdapterInfo(const AAdapterName: string): TNetworkAdapterInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  FLock.Enter;
  try
    if FAdapters.ContainsKey(AAdapterName) then
      Result := FAdapters[AAdapterName];
  finally
    FLock.Leave;
  end;
end;

function TNetworkConnectionMonitor.IsAdapterConnected(const AAdapterName: string): Boolean;
begin
  var AdapterInfo := GetAdapterInfo(AAdapterName);
  Result := AdapterInfo.IsConnected;
end;

function TNetworkConnectionMonitor.HasInternetConnection: Boolean;
begin
  // 简单的网络连接测试
  var Client := THttpClient.Create;
  try
    try
      var Response := Client.Get('http://www.msftncsi.com/ncsi.txt');
      Result := Response.StatusCode = 200;
    except
      Result := False;
    end;
  finally
    Client.Free;
  end;
end;

function TNetworkConnectionMonitor.GetNetworkStatus: string;
begin
  if not IsNetworkAvailable then
    Exit('网络不可用');
    
  if HasInternetConnection then
    Exit('网络连接正常')
  else
    Exit('局域网连接正常，无互联网访问');
end;

function TNetworkConnectionMonitor.GetEventHistory(const ACount: Integer = 10): TArray<TNetworkEvent>;
var
  EventList: TList<TNetworkEvent>;
  StartIndex: Integer;
  I: Integer;
begin
  EventList := TList<TNetworkEvent>.Create;
  try
    FLock.Enter;
    try
      if FEventHistory.Count <= ACount then
      begin
        Result := FEventHistory.ToArray;
      end
      else
      begin
        StartIndex := FEventHistory.Count - ACount;
        for I := StartIndex to FEventHistory.Count - 1 do
        begin
          EventList.Add(FEventHistory[I]);
        end;
        Result := EventList.ToArray;
      end;
    finally
      FLock.Leave;
    end;
  finally
    EventList.Free;
  end;
end;

end.
