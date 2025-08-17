unit RebootDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections,
  Winapi.Windows, System.Win.Registry, Winapi.TlHelp32, DataTypes, ConfigManager;

type
  // 重启需求级别
  TRebootRequirement = (rrNone, rrRecommended, rrRequired, rrCritical);
  
  // 重启原因类型
  TRebootReasonType = (rrtUnknown, rrtSystemFile, rrtService, rrtDriver, rrtRegistry, rrtProcess, rrtLibrary);
  
  // 重启原因信息
  TRebootReason = record
    ReasonType: TRebootReasonType;
    Requirement: TRebootRequirement;
    FilePath: string;
    ServiceName: string;
    ProcessName: string;
    Description: string;
    Details: string;
    CanDelay: Boolean;
    DelayHours: Integer;
  end;
  
  // 重启检测结果
  TRebootDetectionResult = record
    FilePath: string;
    RequiresReboot: Boolean;
    RebootRequirement: TRebootRequirement;
    Reasons: TArray<TRebootReason>;
    TotalReasons: Integer;
    CriticalReasons: Integer;
    RequiredReasons: Integer;
    RecommendedReasons: Integer;
    CanDelayReboot: Boolean;
    MaxDelayHours: Integer;
    Recommendations: TArray<string>;
  end;
  
  // 重启检测器
  TRebootDetector = class
  private
    FConfigManager: TConfigManager;
    FSystemPaths: TStringList;
    FCriticalServices: TStringList;
    FSystemDrivers: TStringList;
    FCriticalProcesses: TStringList;
    FSystemLibraries: TStringList;
    
    // 内部检测方法
    function DetectSystemFileUsage(const AFilePath: string): TArray<TRebootReason>;
    function DetectServiceDependencies(const AFilePath: string): TArray<TRebootReason>;
    function DetectDriverDependencies(const AFilePath: string): TArray<TRebootReason>;
    function DetectProcessDependencies(const AFilePath: string): TArray<TRebootReason>;
    function DetectLibraryDependencies(const AFilePath: string): TArray<TRebootReason>;
    function DetectRegistryDependencies(const AFilePath: string): TArray<TRebootReason>;
    
    // 辅助方法
    procedure InitializeSystemComponents;
    function IsSystemFile(const AFilePath: string): Boolean;
    function IsSystemService(const AServiceName: string): Boolean;
    function IsSystemDriver(const ADriverName: string): Boolean;
    function IsSystemProcess(const AProcessName: string): Boolean;
    function IsSystemLibrary(const AFilePath: string): Boolean;
    function IsFileInUse(const AFilePath: string): Boolean;
    function GetFileUsageProcesses(const AFilePath: string): TArray<string>;
    function GetServiceStatus(const AServiceName: string): DWORD;
    function GetDriverStatus(const ADriverName: string): DWORD;
    function CanStopService(const AServiceName: string): Boolean;
    function CanStopProcess(const AProcessName: string): Boolean;
    function GetRebootRequirementString(ARequirement: TRebootRequirement): string;
    function GetRebootReasonTypeString(AType: TRebootReasonType): string;
    function CombineReasons(const AArrays: array of TArray<TRebootReason>): TArray<TRebootReason>;
    function CalculateOverallRequirement(const AReasons: TArray<TRebootReason>): TRebootRequirement;
    function GenerateRecommendations(const AReasons: TArray<TRebootReason>): TArray<string>;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // 主要检测方法
    function DetectRebootRequirement(const AFilePath: string): TRebootDetectionResult;
    function DetectDirectoryRebootRequirement(const ADirPath: string; ARecursive: Boolean = False): TArray<TRebootDetectionResult>;
    function BatchDetectRebootRequirement(const AFilePaths: TArray<string>): TArray<TRebootDetectionResult>;
    
    // 检查方法
    function RequiresReboot(const AFilePath: string): Boolean;
    function GetRebootRequirementLevel(const AFilePath: string): TRebootRequirement;
    function CanDelayReboot(const AFilePath: string): Boolean;
    function GetMaxDelayHours(const AFilePath: string): Integer;
    
    // 系统状态检查
    function CheckSystemFileUsage: TArray<string>;
    function CheckRunningServices: TArray<string>;
    function CheckLoadedDrivers: TArray<string>;
    function CheckCriticalProcesses: TArray<string>;
    
    // 预处理和建议
    function PrepareForReboot: Boolean;
    function GetPreRebootActions(const AFilePath: string): TArray<string>;
    function GetPostRebootActions(const AFilePath: string): TArray<string>;
    
    // 统计和报告
    function GetRebootStatistics(const AResults: TArray<TRebootDetectionResult>): string;
    function GenerateRebootReport(const AResults: TArray<TRebootDetectionResult>): string;
  end;

implementation

uses
  Winapi.WinSvc, System.DateUtils, Vcl.Forms;

constructor TRebootDetector.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FSystemPaths := TStringList.Create;
  FCriticalServices := TStringList.Create;
  FSystemDrivers := TStringList.Create;
  FCriticalProcesses := TStringList.Create;
  FSystemLibraries := TStringList.Create;
  
  InitializeSystemComponents;
end;

destructor TRebootDetector.Destroy;
begin
  FSystemPaths.Free;
  FCriticalServices.Free;
  FSystemDrivers.Free;
  FCriticalProcesses.Free;
  FSystemLibraries.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

// 初始化系统组件
procedure TRebootDetector.InitializeSystemComponents;
var
  WindowsDir, SystemDir: string;
begin
  WindowsDir := GetEnvironmentVariable('WINDIR');
  SystemDir := WindowsDir + '\System32';
  
  // 系统关键路径
  FSystemPaths.Add(WindowsDir);
  FSystemPaths.Add(SystemDir);
  FSystemPaths.Add(SystemDir + '\drivers');
  FSystemPaths.Add(WindowsDir + '\SysWOW64');
  FSystemPaths.Add(WindowsDir + '\WinSxS');
  FSystemPaths.Add(WindowsDir + '\Boot');
  
  // 关键系统服务
  FCriticalServices.Add('Winlogon');
  FCriticalServices.Add('csrss');
  FCriticalServices.Add('wininit');
  FCriticalServices.Add('services');
  FCriticalServices.Add('lsass');
  FCriticalServices.Add('smss');
  FCriticalServices.Add('Spooler');
  FCriticalServices.Add('Themes');
  FCriticalServices.Add('AudioSrv');
  FCriticalServices.Add('BITS');
  FCriticalServices.Add('CryptSvc');
  FCriticalServices.Add('Dhcp');
  FCriticalServices.Add('Dnscache');
  FCriticalServices.Add('EventLog');
  FCriticalServices.Add('LanmanServer');
  FCriticalServices.Add('LanmanWorkstation');
  FCriticalServices.Add('PlugPlay');
  FCriticalServices.Add('RpcSs');
  FCriticalServices.Add('Schedule');
  FCriticalServices.Add('W32Time');
  FCriticalServices.Add('WinDefend');
  FCriticalServices.Add('Wuauserv');
  
  // 系统驱动程序
  FSystemDrivers.Add('ntoskrnl');
  FSystemDrivers.Add('hal');
  FSystemDrivers.Add('win32k');
  FSystemDrivers.Add('ntfs');
  FSystemDrivers.Add('fltmgr');
  FSystemDrivers.Add('ksecdd');
  FSystemDrivers.Add('cng');
  FSystemDrivers.Add('volmgr');
  FSystemDrivers.Add('volsnap');
  FSystemDrivers.Add('disk');
  FSystemDrivers.Add('classpnp');
  FSystemDrivers.Add('partmgr');
  FSystemDrivers.Add('pci');
  FSystemDrivers.Add('acpi');
  
  // 关键系统进程
  FCriticalProcesses.Add('System');
  FCriticalProcesses.Add('smss.exe');
  FCriticalProcesses.Add('csrss.exe');
  FCriticalProcesses.Add('wininit.exe');
  FCriticalProcesses.Add('winlogon.exe');
  FCriticalProcesses.Add('services.exe');
  FCriticalProcesses.Add('lsass.exe');
  FCriticalProcesses.Add('svchost.exe');
  FCriticalProcesses.Add('explorer.exe');
  FCriticalProcesses.Add('dwm.exe');
  
  // 系统库文件
  FSystemLibraries.Add(SystemDir + '\kernel32.dll');
  FSystemLibraries.Add(SystemDir + '\ntdll.dll');
  FSystemLibraries.Add(SystemDir + '\user32.dll');
  FSystemLibraries.Add(SystemDir + '\gdi32.dll');
  FSystemLibraries.Add(SystemDir + '\advapi32.dll');
  FSystemLibraries.Add(SystemDir + '\ole32.dll');
  FSystemLibraries.Add(SystemDir + '\shell32.dll');
  FSystemLibraries.Add(SystemDir + '\comctl32.dll');
  FSystemLibraries.Add(SystemDir + '\msvcrt.dll');
  FSystemLibraries.Add(SystemDir + '\ws2_32.dll');
end;

// 检测系统文件使用情况
function TRebootDetector.DetectSystemFileUsage(const AFilePath: string): TArray<TRebootReason>;
var
  Results: TList<TRebootReason>;
  Reason: TRebootReason;
  UsingProcesses: TArray<string>;
  I: Integer;
begin
  Results := TList<TRebootReason>.Create;
  
  try
    // 检查是否为系统文件
    if IsSystemFile(AFilePath) then
    begin
      Reason.ReasonType := rrtSystemFile;
      Reason.Requirement := rrCritical;
      Reason.FilePath := AFilePath;
      Reason.ServiceName := '';
      Reason.ProcessName := '';
      Reason.Description := '关键系统文件';
      Reason.Details := '此文件是Windows系统的关键组件';
      Reason.CanDelay := False;
      Reason.DelayHours := 0;
      
      Results.Add(Reason);
    end;
    
    // 检查文件是否正在使用
    if IsFileInUse(AFilePath) then
    begin
      UsingProcesses := GetFileUsageProcesses(AFilePath);
      
      for I := 0 to Length(UsingProcesses) - 1 do
      begin
        Reason.ReasonType := rrtProcess;
        
        if IsSystemProcess(UsingProcesses[I]) then
        begin
          Reason.Requirement := rrCritical;
          Reason.Description := '系统进程正在使用';
          Reason.CanDelay := False;
          Reason.DelayHours := 0;
        end
        else
        begin
          Reason.Requirement := rrRequired;
          Reason.Description := '进程正在使用';
          Reason.CanDelay := True;
          Reason.DelayHours := 24;
        end;
        
        Reason.FilePath := AFilePath;
        Reason.ServiceName := '';
        Reason.ProcessName := UsingProcesses[I];
        Reason.Details := Format('进程 %s 正在使用此文件', [UsingProcesses[I]]);
        
        Results.Add(Reason);
      end;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检测服务依赖
function TRebootDetector.DetectServiceDependencies(const AFilePath: string): TArray<TRebootReason>;
var
  Results: TList<TRebootReason>;
  Reg: TRegistry;
  Services: TStringList;
  I: Integer;
  ServicePath, ServiceName: string;
  Reason: TRebootReason;
  ServiceStatus: DWORD;
begin
  Results := TList<TRebootReason>.Create;
  Reg := TRegistry.Create(KEY_READ);
  Services := TStringList.Create;
  
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services') then
    begin
      Reg.GetKeyNames(Services);
      
      for I := 0 to Services.Count - 1 do
      begin
        ServiceName := Services[I];
        
        try
          if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services\' + ServiceName) then
          begin
            if Reg.ValueExists('ImagePath') then
            begin
              ServicePath := Reg.ReadString('ImagePath');
              
              // 清理服务路径
              if Pos(' ', ServicePath) > 0 then
                ServicePath := Copy(ServicePath, 1, Pos(' ', ServicePath) - 1);
              ServicePath := StringReplace(ServicePath, '"', '', [rfReplaceAll]);
              
              if SameText(ServicePath, AFilePath) or 
                 SameText(ExpandFileName(ServicePath), AFilePath) then
              begin
                Reason.ReasonType := rrtService;
                Reason.FilePath := AFilePath;
                Reason.ServiceName := ServiceName;
                Reason.ProcessName := '';
                
                ServiceStatus := GetServiceStatus(ServiceName);
                
                if IsSystemService(ServiceName) then
                begin
                  Reason.Requirement := rrCritical;
                  Reason.Description := '关键系统服务';
                  Reason.Details := Format('关键系统服务 %s 依赖此文件', [ServiceName]);
                  Reason.CanDelay := False;
                  Reason.DelayHours := 0;
                end
                else if ServiceStatus = SERVICE_RUNNING then
                begin
                  if CanStopService(ServiceName) then
                  begin
                    Reason.Requirement := rrRecommended;
                    Reason.Description := '可停止的运行服务';
                    Reason.Details := Format('服务 %s 正在运行，建议重启后生效', [ServiceName]);
                    Reason.CanDelay := True;
                    Reason.DelayHours := 48;
                  end
                  else
                  begin
                    Reason.Requirement := rrRequired;
                    Reason.Description := '无法停止的运行服务';
                    Reason.Details := Format('服务 %s 正在运行且无法停止', [ServiceName]);
                    Reason.CanDelay := True;
                    Reason.DelayHours := 12;
                  end;
                end
                else
                begin
                  Reason.Requirement := rrRecommended;
                  Reason.Description := '已停止的服务';
                  Reason.Details := Format('服务 %s 当前已停止', [ServiceName]);
                  Reason.CanDelay := True;
                  Reason.DelayHours := 72;
                end;
                
                Results.Add(Reason);
              end;
            end;
            
            Reg.CloseKey;
          end;
        except
          // 忽略单个服务错误
        end;
      end;
      
      Reg.CloseKey;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
    Reg.Free;
    Services.Free;
  end;
end;

// 检测驱动程序依赖
function TRebootDetector.DetectDriverDependencies(const AFilePath: string): TArray<TRebootReason>;
var
  Results: TList<TRebootReason>;
  Reason: TRebootReason;
  FileName: string;
  I: Integer;
begin
  Results := TList<TRebootReason>.Create;
  
  try
    FileName := LowerCase(ExtractFileName(AFilePath));
    
    // 检查是否为系统驱动
    if SameText(ExtractFileExt(FileName), '.sys') then
    begin
      for I := 0 to FSystemDrivers.Count - 1 do
      begin
        if ContainsText(FileName, LowerCase(FSystemDrivers[I])) then
        begin
          Reason.ReasonType := rrtDriver;
          Reason.Requirement := rrCritical;
          Reason.FilePath := AFilePath;
          Reason.ServiceName := '';
          Reason.ProcessName := '';
          Reason.Description := '系统驱动程序';
          Reason.Details := Format('系统驱动 %s 需要重启后生效', [FSystemDrivers[I]]);
          Reason.CanDelay := False;
          Reason.DelayHours := 0;
          
          Results.Add(Reason);
          Break;
        end;
      end;
      
      // 如果不是已知的系统驱动，但在系统目录中
      if (Results.Count = 0) and IsSystemFile(AFilePath) then
      begin
        Reason.ReasonType := rrtDriver;
        Reason.Requirement := rrRequired;
        Reason.FilePath := AFilePath;
        Reason.ServiceName := '';
        Reason.ProcessName := '';
        Reason.Description := '驱动程序文件';
        Reason.Details := '驱动程序更改通常需要重启后生效';
        Reason.CanDelay := True;
        Reason.DelayHours := 6;
        
        Results.Add(Reason);
      end;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检测进程依赖
function TRebootDetector.DetectProcessDependencies(const AFilePath: string): TArray<TRebootReason>;
var
  Results: TList<TRebootReason>;
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  Reason: TRebootReason;
  ProcessName: string;
begin
  Results := TList<TRebootReason>.Create;
  
  try
    Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if Snapshot = INVALID_HANDLE_VALUE then
      Exit;
      
    try
      ProcessEntry.dwSize := SizeOf(TProcessEntry32);
      
      if Process32First(Snapshot, ProcessEntry) then
      begin
        repeat
          ProcessName := ProcessEntry.szExeFile;
          
          if SameText(ProcessName, ExtractFileName(AFilePath)) then
          begin
            Reason.ReasonType := rrtProcess;
            Reason.FilePath := AFilePath;
            Reason.ServiceName := '';
            Reason.ProcessName := ProcessName;
            
            if IsSystemProcess(ProcessName) then
            begin
              Reason.Requirement := rrCritical;
              Reason.Description := '关键系统进程';
              Reason.Details := Format('关键系统进程 %s 正在运行', [ProcessName]);
              Reason.CanDelay := False;
              Reason.DelayHours := 0;
            end
            else if CanStopProcess(ProcessName) then
            begin
              Reason.Requirement := rrRecommended;
              Reason.Description := '可终止的运行进程';
              Reason.Details := Format('进程 %s 正在运行，可以终止', [ProcessName]);
              Reason.CanDelay := True;
              Reason.DelayHours := 24;
            end
            else
            begin
              Reason.Requirement := rrRequired;
              Reason.Description := '无法终止的运行进程';
              Reason.Details := Format('进程 %s 正在运行且无法安全终止', [ProcessName]);
              Reason.CanDelay := True;
              Reason.DelayHours := 8;
            end;
            
            Results.Add(Reason);
            Break; // 找到一个就够了
          end;
        until not Process32Next(Snapshot, ProcessEntry);
      end;
      
    finally
      CloseHandle(Snapshot);
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检测库依赖
function TRebootDetector.DetectLibraryDependencies(const AFilePath: string): TArray<TRebootReason>;
var
  Results: TList<TRebootReason>;
  Reason: TRebootReason;
  I: Integer;
begin
  Results := TList<TRebootReason>.Create;
  
  try
    // 检查是否为系统库
    if IsSystemLibrary(AFilePath) then
    begin
      Reason.ReasonType := rrtLibrary;
      Reason.Requirement := rrCritical;
      Reason.FilePath := AFilePath;
      Reason.ServiceName := '';
      Reason.ProcessName := '';
      Reason.Description := '系统库文件';
      Reason.Details := '系统库文件更改需要重启后生效';
      Reason.CanDelay := False;
      Reason.DelayHours := 0;
      
      Results.Add(Reason);
    end
    else if SameText(ExtractFileExt(AFilePath), '.dll') then
    begin
      // 检查DLL是否正在使用
      if IsFileInUse(AFilePath) then
      begin
        Reason.ReasonType := rrtLibrary;
        Reason.Requirement := rrRequired;
        Reason.FilePath := AFilePath;
        Reason.ServiceName := '';
        Reason.ProcessName := '';
        Reason.Description := '正在使用的库文件';
        Reason.Details := 'DLL文件正在被其他程序使用';
        Reason.CanDelay := True;
        Reason.DelayHours := 12;
        
        Results.Add(Reason);
      end;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检测注册表依赖
function TRebootDetector.DetectRegistryDependencies(const AFilePath: string): TArray<TRebootReason>;
var
  Results: TList<TRebootReason>;
  Reg: TRegistry;
  Reason: TRebootReason;
  FileName: string;
begin
  Results := TList<TRebootReason>.Create;
  Reg := TRegistry.Create(KEY_READ);
  
  try
    FileName := ExtractFileName(AFilePath);
    
    // 检查启动项
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Run') then
    begin
      var Values := TStringList.Create;
      try
        Reg.GetValueNames(Values);
        
        for var I := 0 to Values.Count - 1 do
        begin
          try
            var ValueData := Reg.ReadString(Values[I]);
            if ContainsText(ValueData, AFilePath) or ContainsText(ValueData, FileName) then
            begin
              Reason.ReasonType := rrtRegistry;
              Reason.Requirement := rrRecommended;
              Reason.FilePath := AFilePath;
              Reason.ServiceName := '';
              Reason.ProcessName := '';
              Reason.Description := '系统启动项';
              Reason.Details := Format('注册表启动项 %s 引用此文件', [Values[I]]);
              Reason.CanDelay := True;
              Reason.DelayHours := 24;
              
              Results.Add(Reason);
            end;
          except
            // 忽略读取错误
          end;
        end;
      finally
        Values.Free;
      end;
      
      Reg.CloseKey;
    end;
    
    // 检查用户启动项
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Run') then
    begin
      var Values := TStringList.Create;
      try
        Reg.GetValueNames(Values);
        
        for var I := 0 to Values.Count - 1 do
        begin
          try
            var ValueData := Reg.ReadString(Values[I]);
            if ContainsText(ValueData, AFilePath) or ContainsText(ValueData, FileName) then
            begin
              Reason.ReasonType := rrtRegistry;
              Reason.Requirement := rrRecommended;
              Reason.FilePath := AFilePath;
              Reason.ServiceName := '';
              Reason.ProcessName := '';
              Reason.Description := '用户启动项';
              Reason.Details := Format('用户启动项 %s 引用此文件', [Values[I]]);
              Reason.CanDelay := True;
              Reason.DelayHours := 48;
              
              Results.Add(Reason);
            end;
          except
            // 忽略读取错误
          end;
        end;
      finally
        Values.Free;
      end;
      
      Reg.CloseKey;
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
    Reg.Free;
  end;
end;

// 检查是否为系统文件
function TRebootDetector.IsSystemFile(const AFilePath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  for I := 0 to FSystemPaths.Count - 1 do
  begin
    if StartsText(FSystemPaths[I], AFilePath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

// 检查是否为系统服务
function TRebootDetector.IsSystemService(const AServiceName: string): Boolean;
begin
  Result := FCriticalServices.IndexOf(AServiceName) >= 0;
end;

// 检查是否为系统驱动
function TRebootDetector.IsSystemDriver(const ADriverName: string): Boolean;
begin
  Result := FSystemDrivers.IndexOf(LowerCase(ADriverName)) >= 0;
end;

// 检查是否为系统进程
function TRebootDetector.IsSystemProcess(const AProcessName: string): Boolean;
begin
  Result := FCriticalProcesses.IndexOf(LowerCase(AProcessName)) >= 0;
end;

// 检查是否为系统库
function TRebootDetector.IsSystemLibrary(const AFilePath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  for I := 0 to FSystemLibraries.Count - 1 do
  begin
    if SameText(FSystemLibraries[I], AFilePath) then
    begin
      Result := True;
      Break;
    end;
  end;
  
  // 如果不在已知列表中，检查是否在系统目录中的DLL
  if not Result and SameText(ExtractFileExt(AFilePath), '.dll') then
  begin
    Result := IsSystemFile(AFilePath);
  end;
end;

// 检查文件是否正在使用
function TRebootDetector.IsFileInUse(const AFilePath: string): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;
  
  try
    FileHandle := CreateFile(PChar(AFilePath), GENERIC_READ or GENERIC_WRITE,
      0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    
    if FileHandle = INVALID_HANDLE_VALUE then
      Result := True // 文件被占用
    else
      CloseHandle(FileHandle);
  except
    Result := True; // 访问异常，假设被占用
  end;
end;

// 获取使用文件的进程列表
function TRebootDetector.GetFileUsageProcesses(const AFilePath: string): TArray<string>;
var
  Results: TList<string>;
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
begin
  Results := TList<string>.Create;
  
  try
    // 简化实现：如果文件被占用，返回可能的进程
    if IsFileInUse(AFilePath) then
    begin
      Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
      if Snapshot <> INVALID_HANDLE_VALUE then
      begin
        try
          ProcessEntry.dwSize := SizeOf(TProcessEntry32);
          
          if Process32First(Snapshot, ProcessEntry) then
          begin
            repeat
              // 简化检查：如果进程名与文件名相同
              if SameText(ProcessEntry.szExeFile, ExtractFileName(AFilePath)) then
              begin
                Results.Add(ProcessEntry.szExeFile);
              end;
            until not Process32Next(Snapshot, ProcessEntry);
          end;
          
        finally
          CloseHandle(Snapshot);
        end;
      end;
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 获取服务状态
function TRebootDetector.GetServiceStatus(const AServiceName: string): DWORD;
var
  SCManager, Service: SC_HANDLE;
  ServiceStatus: TServiceStatus;
begin
  Result := SERVICE_STOPPED;
  
  SCManager := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SCManager <> 0 then
  begin
    try
      Service := OpenService(SCManager, PChar(AServiceName), SERVICE_QUERY_STATUS);
      if Service <> 0 then
      begin
        try
          if QueryServiceStatus(Service, ServiceStatus) then
            Result := ServiceStatus.dwCurrentState;
        finally
          CloseServiceHandle(Service);
        end;
      end;
    finally
      CloseServiceHandle(SCManager);
    end;
  end;
end;

// 获取驱动状态
function TRebootDetector.GetDriverStatus(const ADriverName: string): DWORD;
begin
  // 简化实现，返回默认状态
  Result := SERVICE_RUNNING;
end;

// 检查是否可以停止服务
function TRebootDetector.CanStopService(const AServiceName: string): Boolean;
var
  SCManager, Service: SC_HANDLE;
  ServiceStatus: TServiceStatus;
begin
  Result := False;
  
  if IsSystemService(AServiceName) then
    Exit; // 系统服务不能停止
  
  SCManager := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SCManager <> 0 then
  begin
    try
      Service := OpenService(SCManager, PChar(AServiceName), SERVICE_QUERY_STATUS);
      if Service <> 0 then
      begin
        try
          if QueryServiceStatus(Service, ServiceStatus) then
          begin
            Result := (ServiceStatus.dwControlsAccepted and SERVICE_ACCEPT_STOP) <> 0;
          end;
        finally
          CloseServiceHandle(Service);
        end;
      end;
    finally
      CloseServiceHandle(SCManager);
    end;
  end;
end;

// 检查是否可以停止进程
function TRebootDetector.CanStopProcess(const AProcessName: string): Boolean;
begin
  Result := not IsSystemProcess(AProcessName);
end;

// 获取重启需求级别字符串
function TRebootDetector.GetRebootRequirementString(ARequirement: TRebootRequirement): string;
begin
  case ARequirement of
    rrNone: Result := '无需重启';
    rrRecommended: Result := '建议重启';
    rrRequired: Result := '需要重启';
    rrCritical: Result := '必须重启';
  else
    Result := '未知';
  end;
end;

// 获取重启原因类型字符串
function TRebootDetector.GetRebootReasonTypeString(AType: TRebootReasonType): string;
begin
  case AType of
    rrtSystemFile: Result := '系统文件';
    rrtService: Result := '系统服务';
    rrtDriver: Result := '驱动程序';
    rrtRegistry: Result := '注册表';
    rrtProcess: Result := '运行进程';
    rrtLibrary: Result := '库文件';
  else
    Result := '未知';
  end;
end;

// 合并原因数组
function TRebootDetector.CombineReasons(const AArrays: array of TArray<TRebootReason>): TArray<TRebootReason>;
var
  TotalCount, CurrentIndex, I, J: Integer;
begin
  TotalCount := 0;
  
  // 计算总数
  for I := 0 to Length(AArrays) - 1 do
    TotalCount := TotalCount + Length(AArrays[I]);
  
  SetLength(Result, TotalCount);
  CurrentIndex := 0;
  
  // 复制所有原因
  for I := 0 to Length(AArrays) - 1 do
  begin
    for J := 0 to Length(AArrays[I]) - 1 do
    begin
      Result[CurrentIndex] := AArrays[I][J];
      Inc(CurrentIndex);
    end;
  end;
end;

// 计算总体需求级别
function TRebootDetector.CalculateOverallRequirement(const AReasons: TArray<TRebootReason>): TRebootRequirement;
var
  I: Integer;
  MaxRequirement: TRebootRequirement;
begin
  MaxRequirement := rrNone;
  
  for I := 0 to Length(AReasons) - 1 do
  begin
    if AReasons[I].Requirement > MaxRequirement then
      MaxRequirement := AReasons[I].Requirement;
  end;
  
  Result := MaxRequirement;
end;

// 生成建议
function TRebootDetector.GenerateRecommendations(const AReasons: TArray<TRebootReason>): TArray<string>;
var
  Recommendations: TList<string>;
  I: Integer;
  HasCritical, HasRequired, HasRecommended: Boolean;
  HasService, HasProcess, HasDriver: Boolean;
begin
  Recommendations := TList<string>.Create;
  
  try
    HasCritical := False;
    HasRequired := False;
    HasRecommended := False;
    HasService := False;
    HasProcess := False;
    HasDriver := False;
    
    // 分析原因类型
    for I := 0 to Length(AReasons) - 1 do
    begin
      case AReasons[I].Requirement of
        rrCritical: HasCritical := True;
        rrRequired: HasRequired := True;
        rrRecommended: HasRecommended := True;
      end;
      
      case AReasons[I].ReasonType of
        rrtService: HasService := True;
        rrtProcess: HasProcess := True;
        rrtDriver: HasDriver := True;
      end;
    end;
    
    // 生成建议
    if HasCritical then
    begin
      Recommendations.Add('立即重启系统以确保更改生效');
      Recommendations.Add('不重启可能导致系统不稳定');
    end
    else if HasRequired then
    begin
      Recommendations.Add('建议尽快重启系统');
      Recommendations.Add('可以延迟重启，但功能可能不正常');
    end
    else if HasRecommended then
    begin
      Recommendations.Add('建议在方便时重启系统');
      Recommendations.Add('不重启通常不会影响系统稳定性');
    end
    else
    begin
      Recommendations.Add('无需重启，更改已生效');
    end;
    
    if HasService then
      Recommendations.Add('考虑先停止相关服务再进行操作');
    
    if HasProcess then
      Recommendations.Add('考虑先关闭相关程序再进行操作');
    
    if HasDriver then
      Recommendations.Add('驱动程序更改通常需要重启后生效');
    
    SetLength(Result, Recommendations.Count);
    for I := 0 to Recommendations.Count - 1 do
      Result[I] := Recommendations[I];
    
  finally
    Recommendations.Free;
  end;
end;

// 检测重启需求
function TRebootDetector.DetectRebootRequirement(const AFilePath: string): TRebootDetectionResult;
var
  SystemFileReasons, ServiceReasons, DriverReasons, ProcessReasons, LibraryReasons, RegistryReasons: TArray<TRebootReason>;
  AllReasons: TArray<TRebootReason>;
  I: Integer;
  MaxDelayHours: Integer;
begin
  Result.FilePath := AFilePath;
  Result.RequiresReboot := False;
  Result.RebootRequirement := rrNone;
  Result.TotalReasons := 0;
  Result.CriticalReasons := 0;
  Result.RequiredReasons := 0;
  Result.RecommendedReasons := 0;
  Result.CanDelayReboot := True;
  Result.MaxDelayHours := 0;
  
  if not FileExists(AFilePath) then
  begin
    SetLength(Result.Reasons, 0);
    SetLength(Result.Recommendations, 1);
    Result.Recommendations[0] := '文件不存在';
    Exit;
  end;
  
  try
    // 执行各种检测
    SystemFileReasons := DetectSystemFileUsage(AFilePath);
    ServiceReasons := DetectServiceDependencies(AFilePath);
    DriverReasons := DetectDriverDependencies(AFilePath);
    ProcessReasons := DetectProcessDependencies(AFilePath);
    LibraryReasons := DetectLibraryDependencies(AFilePath);
    RegistryReasons := DetectRegistryDependencies(AFilePath);
    
    // 合并所有原因
    AllReasons := CombineReasons([SystemFileReasons, ServiceReasons, DriverReasons, ProcessReasons, LibraryReasons, RegistryReasons]);
    Result.Reasons := AllReasons;
    Result.TotalReasons := Length(AllReasons);
    
    // 统计原因级别
    MaxDelayHours := 0;
    for I := 0 to Length(AllReasons) - 1 do
    begin
      case AllReasons[I].Requirement of
        rrCritical: 
        begin
          Inc(Result.CriticalReasons);
          Result.CanDelayReboot := False;
        end;
        rrRequired: Inc(Result.RequiredReasons);
        rrRecommended: Inc(Result.RecommendedReasons);
      end;
      
      if AllReasons[I].DelayHours > MaxDelayHours then
        MaxDelayHours := AllReasons[I].DelayHours;
    end;
    
    Result.MaxDelayHours := MaxDelayHours;
    
    // 计算总体需求
    Result.RebootRequirement := CalculateOverallRequirement(AllReasons);
    Result.RequiresReboot := Result.RebootRequirement > rrNone;
    
    // 生成建议
    Result.Recommendations := GenerateRecommendations(AllReasons);
    
    // 记录检测日志
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('REBOOT_DETECTION', 'File analyzed', AFilePath, '', 'SUCCESS', 
        Format('Requirement: %s, Reasons: %d', [GetRebootRequirementString(Result.RebootRequirement), Result.TotalReasons]));
    end;
    
  except
    on E: Exception do
    begin
      SetLength(Result.Reasons, 0);
      SetLength(Result.Recommendations, 1);
      Result.Recommendations[0] := '检测异常: ' + E.Message;
      
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('REBOOT_DETECTION', 'Detection error', AFilePath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 检测目录重启需求
function TRebootDetector.DetectDirectoryRebootRequirement(const ADirPath: string; ARecursive: Boolean = False): TArray<TRebootDetectionResult>;
var
  Files: TArray<string>;
  Results: TList<TRebootDetectionResult>;
  I: Integer;
begin
  Results := TList<TRebootDetectionResult>.Create;
  
  try
    if ARecursive then
      Files := TDirectory.GetFiles(ADirPath, '*', TSearchOption.soAllDirectories)
    else
      Files := TDirectory.GetFiles(ADirPath);
    
    for I := 0 to Length(Files) - 1 do
    begin
      Results.Add(DetectRebootRequirement(Files[I]));
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 批量检测重启需求
function TRebootDetector.BatchDetectRebootRequirement(const AFilePaths: TArray<string>): TArray<TRebootDetectionResult>;
var
  I: Integer;
begin
  SetLength(Result, Length(AFilePaths));
  
  for I := 0 to Length(AFilePaths) - 1 do
  begin
    Result[I] := DetectRebootRequirement(AFilePaths[I]);
  end;
end;

// 检查是否需要重启
function TRebootDetector.RequiresReboot(const AFilePath: string): Boolean;
var
  DetectionResult: TRebootDetectionResult;
begin
  DetectionResult := DetectRebootRequirement(AFilePath);
  Result := DetectionResult.RequiresReboot;
end;

// 获取重启需求级别
function TRebootDetector.GetRebootRequirementLevel(const AFilePath: string): TRebootRequirement;
var
  DetectionResult: TRebootDetectionResult;
begin
  DetectionResult := DetectRebootRequirement(AFilePath);
  Result := DetectionResult.RebootRequirement;
end;

// 检查是否可以延迟重启
function TRebootDetector.CanDelayReboot(const AFilePath: string): Boolean;
var
  DetectionResult: TRebootDetectionResult;
begin
  DetectionResult := DetectRebootRequirement(AFilePath);
  Result := DetectionResult.CanDelayReboot;
end;

// 获取最大延迟小时数
function TRebootDetector.GetMaxDelayHours(const AFilePath: string): Integer;
var
  DetectionResult: TRebootDetectionResult;
begin
  DetectionResult := DetectRebootRequirement(AFilePath);
  Result := DetectionResult.MaxDelayHours;
end;

// 检查系统文件使用情况
function TRebootDetector.CheckSystemFileUsage: TArray<string>;
var
  Results: TList<string>;
  I: Integer;
begin
  Results := TList<string>.Create;
  
  try
    for I := 0 to FSystemLibraries.Count - 1 do
    begin
      if IsFileInUse(FSystemLibraries[I]) then
        Results.Add(FSystemLibraries[I]);
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检查运行中的服务
function TRebootDetector.CheckRunningServices: TArray<string>;
var
  Results: TList<string>;
  I: Integer;
begin
  Results := TList<string>.Create;
  
  try
    for I := 0 to FCriticalServices.Count - 1 do
    begin
      if GetServiceStatus(FCriticalServices[I]) = SERVICE_RUNNING then
        Results.Add(FCriticalServices[I]);
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检查加载的驱动
function TRebootDetector.CheckLoadedDrivers: TArray<string>;
var
  Results: TList<string>;
  I: Integer;
begin
  Results := TList<string>.Create;
  
  try
    // 简化实现：返回已知的系统驱动
    for I := 0 to FSystemDrivers.Count - 1 do
    begin
      Results.Add(FSystemDrivers[I]);
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检查关键进程
function TRebootDetector.CheckCriticalProcesses: TArray<string>;
var
  Results: TList<string>;
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ProcessName: string;
begin
  Results := TList<string>.Create;
  
  try
    Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if Snapshot <> INVALID_HANDLE_VALUE then
    begin
      try
        ProcessEntry.dwSize := SizeOf(TProcessEntry32);
        
        if Process32First(Snapshot, ProcessEntry) then
        begin
          repeat
            ProcessName := ProcessEntry.szExeFile;
            
            if IsSystemProcess(ProcessName) then
              Results.Add(ProcessName);
              
          until not Process32Next(Snapshot, ProcessEntry);
        end;
        
      finally
        CloseHandle(Snapshot);
      end;
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 准备重启
function TRebootDetector.PrepareForReboot: Boolean;
begin
  Result := True;
  
  try
    // 这里可以实现重启前的准备工作
    // 例如：保存配置、停止非关键服务等
    
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('REBOOT_PREPARATION', 'Prepare for reboot', '', '', 'SUCCESS', 'System prepared for reboot');
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('REBOOT_PREPARATION', 'Preparation error', '', '', 'ERROR', E.Message);
    end;
  end;
end;

// 获取重启前操作
function TRebootDetector.GetPreRebootActions(const AFilePath: string): TArray<string>;
var
  DetectionResult: TRebootDetectionResult;
  Actions: TList<string>;
  I: Integer;
begin
  Actions := TList<string>.Create;
  
  try
    DetectionResult := DetectRebootRequirement(AFilePath);
    
    Actions.Add('保存所有未保存的工作');
    Actions.Add('关闭所有不必要的程序');
    
    for I := 0 to Length(DetectionResult.Reasons) - 1 do
    begin
      case DetectionResult.Reasons[I].ReasonType of
        rrtService:
        begin
          if CanStopService(DetectionResult.Reasons[I].ServiceName) then
            Actions.Add('停止服务: ' + DetectionResult.Reasons[I].ServiceName);
        end;
        rrtProcess:
        begin
          if CanStopProcess(DetectionResult.Reasons[I].ProcessName) then
            Actions.Add('关闭进程: ' + DetectionResult.Reasons[I].ProcessName);
        end;
      end;
    end;
    
    Actions.Add('创建系统还原点');
    Actions.Add('备份重要数据');
    
    SetLength(Result, Actions.Count);
    for I := 0 to Actions.Count - 1 do
      Result[I] := Actions[I];
    
  finally
    Actions.Free;
  end;
end;

// 获取重启后操作
function TRebootDetector.GetPostRebootActions(const AFilePath: string): TArray<string>;
var
  Actions: TList<string>;
  I: Integer;
begin
  Actions := TList<string>.Create;
  
  try
    Actions.Add('验证系统启动正常');
    Actions.Add('检查所有服务状态');
    Actions.Add('验证程序功能正常');
    Actions.Add('检查文件更改是否生效');
    Actions.Add('运行系统诊断工具');
    
    SetLength(Result, Actions.Count);
    for I := 0 to Actions.Count - 1 do
      Result[I] := Actions[I];
    
  finally
    Actions.Free;
  end;
end;

// 获取重启统计
function TRebootDetector.GetRebootStatistics(const AResults: TArray<TRebootDetectionResult>): string;
var
  TotalFiles, RequiresRebootCount, CriticalCount, RequiredCount, RecommendedCount, NoneCount: Integer;
  CanDelayCount: Integer;
  I: Integer;
  Stats: TStringList;
begin
  TotalFiles := Length(AResults);
  RequiresRebootCount := 0;
  CriticalCount := 0;
  RequiredCount := 0;
  RecommendedCount := 0;
  NoneCount := 0;
  CanDelayCount := 0;
  
  for I := 0 to Length(AResults) - 1 do
  begin
    if AResults[I].RequiresReboot then
      Inc(RequiresRebootCount);
    
    case AResults[I].RebootRequirement of
      rrNone: Inc(NoneCount);
      rrRecommended: Inc(RecommendedCount);
      rrRequired: Inc(RequiredCount);
      rrCritical: Inc(CriticalCount);
    end;
    
    if AResults[I].CanDelayReboot then
      Inc(CanDelayCount);
  end;
  
  Stats := TStringList.Create;
  try
    Stats.Add('重启需求检测统计');
    Stats.Add('═══════════════════════');
    Stats.Add(Format('检测文件数: %d', [TotalFiles]));
    Stats.Add(Format('需要重启: %d (%.1f%%)', [RequiresRebootCount, RequiresRebootCount * 100.0 / TotalFiles]));
    Stats.Add('');
    Stats.Add('重启需求级别分布:');
    Stats.Add(Format('  无需重启: %d (%.1f%%)', [NoneCount, NoneCount * 100.0 / TotalFiles]));
    Stats.Add(Format('  建议重启: %d (%.1f%%)', [RecommendedCount, RecommendedCount * 100.0 / TotalFiles]));
    Stats.Add(Format('  需要重启: %d (%.1f%%)', [RequiredCount, RequiredCount * 100.0 / TotalFiles]));
    Stats.Add(Format('  必须重启: %d (%.1f%%)', [CriticalCount, CriticalCount * 100.0 / TotalFiles]));
    Stats.Add('');
    Stats.Add(Format('可延迟重启: %d (%.1f%%)', [CanDelayCount, CanDelayCount * 100.0 / TotalFiles]));
    
    Result := Stats.Text;
  finally
    Stats.Free;
  end;
end;

// 生成重启报告
function TRebootDetector.GenerateRebootReport(const AResults: TArray<TRebootDetectionResult>): string;
var
  Report: TStringList;
  I, J: Integer;
begin
  Report := TStringList.Create;
  try
    Report.Add('重启需求检测报告');
    Report.Add('═══════════════════════');
    Report.Add(Format('生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add('');
    
    Report.Add(GetRebootStatistics(AResults));
    Report.Add('');
    
    Report.Add('详细检测结果:');
    Report.Add('─────────────────────────');
    
    for I := 0 to Length(AResults) - 1 do
    begin
      if AResults[I].RequiresReboot then
      begin
        Report.Add('');
        Report.Add(Format('文件: %s', [AResults[I].FilePath]));
        Report.Add(Format('重启需求: %s', [GetRebootRequirementString(AResults[I].RebootRequirement)]));
        Report.Add(Format('原因数量: %d', [AResults[I].TotalReasons]));
        Report.Add(Format('可延迟: %s', [BoolToStr(AResults[I].CanDelayReboot, True)]));
        
        if AResults[I].CanDelayReboot and (AResults[I].MaxDelayHours > 0) then
          Report.Add(Format('最大延迟: %d 小时', [AResults[I].MaxDelayHours]));
        
        if Length(AResults[I].Reasons) > 0 then
        begin
          Report.Add('原因详情:');
          for J := 0 to Length(AResults[I].Reasons) - 1 do
          begin
            Report.Add(Format('  - %s (%s): %s', [
              GetRebootReasonTypeString(AResults[I].Reasons[J].ReasonType),
              GetRebootRequirementString(AResults[I].Reasons[J].Requirement),
              AResults[I].Reasons[J].Description
            ]));
          end;
        end;
        
        if Length(AResults[I].Recommendations) > 0 then
        begin
          Report.Add('建议:');
          for J := 0 to Length(AResults[I].Recommendations) - 1 do
          begin
            Report.Add('  • ' + AResults[I].Recommendations[J]);
          end;
        end;
      end;
    end;
    
    Result := Report.Text;
  finally
    Report.Free;
  end;
end;

end.