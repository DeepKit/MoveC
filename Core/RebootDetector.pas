unit RebootDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, 
  System.Generics.Collections, System.Win.Registry, Winapi.Windows,
  Winapi.TlHelp32, Winapi.PsAPI, DataTypes, BasicProtection;

type
  // 重启需求类型
  TRebootRequirement = (
    rrNotRequired,      // 不需要重启
    rrRecommended,      // 建议重启
    rrRequired,         // 需要重启
    rrCritical          // 必须重启
  );

  // 重启原因
  TRebootReason = (
    rrUnknown,          // 未知原因
    rrSystemFile,       // 系统文件被修改
    rrDriverFile,       // 驱动文件被修改
    rrServiceFile,      // 服务文件被修改
    rrKernelFile,       // 内核文件被修改
    rrRegistryChange,   // 注册表修改
    rrFileInUse,        // 文件正在使用
    rrPendingOperation, // 待处理操作
    rrSecurityUpdate,   // 安全更新
    rrSystemUpdate      // 系统更新
  );

  // 重启检测结果
  TRebootDetectionResult = record
    FilePath: string;
    RequiresReboot: TRebootRequirement;
    Reasons: TArray<TRebootReason>;
    Description: string;
    ProcessesUsingFile: TArray<string>;
    ServicesUsingFile: TArray<string>;
    CanForceClose: Boolean;
    ForceCloseRisk: Integer;
    RebootDelay: Integer; // 建议重启延迟（秒）
    AlternativeSolutions: TArray<string>;
  end;

  // 重启检测器
  TRebootDetector = class
  private
    FSystemFilePatterns: TStringList;
    FDriverFilePatterns: TStringList;
    FKernelFilePatterns: TStringList;
    FCriticalProcesses: TStringList;
    FCriticalServices: TStringList;
    
    // 文件使用检测
    function IsFileInUse(const AFilePath: string): Boolean;
    function GetProcessesUsingFile(const AFilePath: string): TArray<string>;
    function GetServicesUsingFile(const AFilePath: string): TArray<string>;
    function CanTerminateProcess(const AProcessName: string): Boolean;
    function CanStopService(const AServiceName: string): Boolean;
    
    // 系统文件检测
    function IsSystemCriticalFile(const AFilePath: string): Boolean;
    function IsDriverFile(const AFilePath: string): Boolean;
    function IsKernelFile(const AFilePath: string): Boolean;
    function IsServiceExecutable(const AFilePath: string): Boolean;
    
    // 注册表检测
    function HasPendingFileOperations: Boolean;
    function HasPendingRegistryOperations: Boolean;
    function CheckRegistryForRebootFlags: Boolean;
    
    // 系统状态检测
    function GetSystemUptime: Int64;
    function HasRecentSystemUpdates: Boolean;
    function HasPendingWindowsUpdates: Boolean;
    
    // 风险评估
    function CalculateForceCloseRisk(const AProcesses: TArray<string>; 
      const AServices: TArray<string>): Integer;
    function DetermineRebootRequirement(const AFilePath: string; 
      const AReasons: TArray<TRebootReason>): TRebootRequirement;
    function GenerateAlternativeSolutions(const AFilePath: string; 
      const AProcesses, AServices: TArray<string>): TArray<string>;
    
    procedure InitializeKnowledgeBase;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要检测方法
    function DetectRebootRequirement(const AFilePath: string): TRebootDetectionResult;
    function BatchDetectRebootRequirement(const AFilePaths: TArray<string>): TArray<TRebootDetectionResult>;
    function DetectSystemRebootRequirement: TRebootDetectionResult;
    
    // 文件操作前检测
    function CanSafelyMoveFile(const AFilePath: string): Boolean;
    function CanSafelyDeleteFile(const AFilePath: string): Boolean;
    function GetOptimalOperationTime(const AFilePath: string): TDateTime;
    
    // 强制操作支持
    function ForceCloseProcessesUsingFile(const AFilePath: string): Boolean;
    function ForceStopServicesUsingFile(const AFilePath: string): Boolean;
    function ScheduleFileOperationAfterReboot(const AOldPath, ANewPath: string): Boolean;
    
    // 系统重启管理
    function ScheduleSystemReboot(const ADelaySeconds: Integer; const AReason: string): Boolean;
    function CancelScheduledReboot: Boolean;
    function GetScheduledRebootInfo: string;
    
    // 工具方法
    class function RebootRequirementToString(ARequirement: TRebootRequirement): string;
    class function RebootReasonToString(AReason: TRebootReason): string;
    class function RebootRequirementToColor(ARequirement: TRebootRequirement): Integer;
  end;

implementation

uses
  Vcl.Graphics, System.DateUtils;cons
tructor TRebootDetector.Create;
begin
  inherited Create;
  
  FSystemFilePatterns := TStringList.Create;
  FDriverFilePatterns := TStringList.Create;
  FKernelFilePatterns := TStringList.Create;
  FCriticalProcesses := TStringList.Create;
  FCriticalServices := TStringList.Create;
  
  InitializeKnowledgeBase;
end;

destructor TRebootDetector.Destroy;
begin
  FSystemFilePatterns.Free;
  FDriverFilePatterns.Free;
  FKernelFilePatterns.Free;
  FCriticalProcesses.Free;
  FCriticalServices.Free;
  
  inherited;
end;

procedure TRebootDetector.InitializeKnowledgeBase;
begin
  // 系统文件模式
  FSystemFilePatterns.Clear;
  FSystemFilePatterns.Add('ntoskrnl.exe');
  FSystemFilePatterns.Add('kernel32.dll');
  FSystemFilePatterns.Add('user32.dll');
  FSystemFilePatterns.Add('gdi32.dll');
  FSystemFilePatterns.Add('ntdll.dll');
  FSystemFilePatterns.Add('advapi32.dll');
  FSystemFilePatterns.Add('shell32.dll');
  FSystemFilePatterns.Add('ole32.dll');
  FSystemFilePatterns.Add('comctl32.dll');
  FSystemFilePatterns.Add('msvcrt.dll');
  
  // 驱动文件模式
  FDriverFilePatterns.Clear;
  FDriverFilePatterns.Add('*.sys');
  FDriverFilePatterns.Add('*.drv');
  FDriverFilePatterns.Add('*.vxd');
  
  // 内核文件模式
  FKernelFilePatterns.Clear;
  FKernelFilePatterns.Add('ntoskrnl.exe');
  FKernelFilePatterns.Add('ntkrnlpa.exe');
  FKernelFilePatterns.Add('ntkrnlmp.exe');
  FKernelFilePatterns.Add('hal.dll');
  FKernelFilePatterns.Add('halmacpi.dll');
  FKernelFilePatterns.Add('halaacpi.dll');
  
  // 关键进程
  FCriticalProcesses.Clear;
  FCriticalProcesses.Add('csrss.exe');
  FCriticalProcesses.Add('winlogon.exe');
  FCriticalProcesses.Add('services.exe');
  FCriticalProcesses.Add('lsass.exe');
  FCriticalProcesses.Add('smss.exe');
  FCriticalProcesses.Add('wininit.exe');
  FCriticalProcesses.Add('explorer.exe');
  
  // 关键服务
  FCriticalServices.Clear;
  FCriticalServices.Add('EventLog');
  FCriticalServices.Add('PlugPlay');
  FCriticalServices.Add('RpcSs');
  FCriticalServices.Add('Spooler');
  FCriticalServices.Add('Themes');
  FCriticalServices.Add('AudioSrv');
  FCriticalServices.Add('BITS');
  FCriticalServices.Add('CryptSvc');
  FCriticalServices.Add('Dhcp');
  FCriticalServices.Add('Dnscache');
end;

function TRebootDetector.DetectRebootRequirement(const AFilePath: string): TRebootDetectionResult;
var
  ReasonList: TList<TRebootReason>;
  Processes, Services: TArray<string>;
  AlternativeSolutions: TArray<string>;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.FilePath := AFilePath;
  Result.RequiresReboot := rrNotRequired;
  
  if not FileExists(AFilePath) then
  begin
    Result.Description := '文件不存在，无需重启';
    Exit;
  end;
  
  ReasonList := TList<TRebootReason>.Create;
  try
    // 检查文件是否正在使用
    if IsFileInUse(AFilePath) then
    begin
      ReasonList.Add(rrFileInUse);
      Processes := GetProcessesUsingFile(AFilePath);
      Services := GetServicesUsingFile(AFilePath);
      
      Result.ProcessesUsingFile := Processes;
      Result.ServicesUsingFile := Services;
    end;
    
    // 检查是否为系统关键文件
    if IsSystemCriticalFile(AFilePath) then
    begin
      ReasonList.Add(rrSystemFile);
    end;
    
    // 检查是否为驱动文件
    if IsDriverFile(AFilePath) then
    begin
      ReasonList.Add(rrDriverFile);
    end;
    
    // 检查是否为内核文件
    if IsKernelFile(AFilePath) then
    begin
      ReasonList.Add(rrKernelFile);
    end;
    
    // 检查是否为服务可执行文件
    if IsServiceExecutable(AFilePath) then
    begin
      ReasonList.Add(rrServiceFile);
    end;
    
    // 检查是否有待处理的文件操作
    if HasPendingFileOperations then
    begin
      ReasonList.Add(rrPendingOperation);
    end;
    
    // 检查注册表重启标志
    if CheckRegistryForRebootFlags then
    begin
      ReasonList.Add(rrRegistryChange);
    end;
    
    // 转换为数组
    SetLength(Result.Reasons, ReasonList.Count);
    for var I := 0 to ReasonList.Count - 1 do
      Result.Reasons[I] := ReasonList[I];
    
    // 确定重启需求级别
    Result.RequiresReboot := DetermineRebootRequirement(AFilePath, Result.Reasons);
    
    // 计算强制关闭风险
    Result.ForceCloseRisk := CalculateForceCloseRisk(Processes, Services);
    
    // 判断是否可以强制关闭
    Result.CanForceClose := (Result.ForceCloseRisk < 70) and (Length(Processes) > 0);
    
    // 设置重启延迟
    case Result.RequiresReboot of
      rrNotRequired: Result.RebootDelay := 0;
      rrRecommended: Result.RebootDelay := 300; // 5分钟
      rrRequired: Result.RebootDelay := 60;     // 1分钟
      rrCritical: Result.RebootDelay := 10;     // 10秒
    end;
    
    // 生成描述
    case Result.RequiresReboot of
      rrNotRequired:
        Result.Description := '文件操作不需要重启系统';
      rrRecommended:
        Result.Description := '建议重启系统以确保操作完全生效';
      rrRequired:
        Result.Description := '需要重启系统才能完成文件操作';
      rrCritical:
        Result.Description := '涉及系统关键文件，必须重启系统';
    end;
    
    // 生成替代解决方案
    Result.AlternativeSolutions := GenerateAlternativeSolutions(AFilePath, Processes, Services);
    
  finally
    ReasonList.Free;
  end;
end;

function TRebootDetector.IsFileInUse(const AFilePath: string): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;
  
  if not FileExists(AFilePath) then
    Exit;
  
  // 尝试以独占模式打开文件
  FileHandle := CreateFile(
    PChar(AFilePath),
    GENERIC_READ or GENERIC_WRITE,
    0, // 不允许共享
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );
  
  if FileHandle = INVALID_HANDLE_VALUE then
  begin
    // 如果无法独占打开，说明文件正在使用
    var LastError := GetLastError;
    Result := (LastError = ERROR_SHARING_VIOLATION) or 
              (LastError = ERROR_ACCESS_DENIED);
  end
  else
  begin
    CloseHandle(FileHandle);
  end;
end;

function TRebootDetector.GetProcessesUsingFile(const AFilePath: string): TArray<string>;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ProcessHandle: THandle;
  ModuleHandles: array[0..1023] of HMODULE;
  ModuleCount: DWORD;
  ModuleName: array[0..MAX_PATH-1] of Char;
  ResultList: TList<string>;
  I: Integer;
begin
  ResultList := TList<string>.Create;
  try
    // 创建进程快照
    Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if Snapshot <> INVALID_HANDLE_VALUE then
    begin
      try
        ProcessEntry.dwSize := SizeOf(TProcessEntry32);
        
        if Process32First(Snapshot, ProcessEntry) then
        begin
          repeat
            // 打开进程
            ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, 
              False, ProcessEntry.th32ProcessID);
            
            if ProcessHandle <> 0 then
            begin
              try
                // 枚举进程模块
                if EnumProcessModules(ProcessHandle, @ModuleHandles[0], 
                  SizeOf(ModuleHandles), ModuleCount) then
                begin
                  ModuleCount := ModuleCount div SizeOf(HMODULE);
                  
                  for I := 0 to Integer(ModuleCount) - 1 do
                  begin
                    if GetModuleFileNameEx(ProcessHandle, ModuleHandles[I], 
                      ModuleName, MAX_PATH) > 0 then
                    begin
                      if SameText(ModuleName, AFilePath) then
                      begin
                        ResultList.Add(ProcessEntry.szExeFile);
                        Break;
                      end;
                    end;
                  end;
                end;
              finally
                CloseHandle(ProcessHandle);
              end;
            end;
            
          until not Process32Next(Snapshot, ProcessEntry);
        end;
        
      finally
        CloseHandle(Snapshot);
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;func
tion TRebootDetector.GetServicesUsingFile(const AFilePath: string): TArray<string>;
var
  Reg: TRegistry;
  ServiceKeys: TStringList;
  ResultList: TList<string>;
  ImagePath: string;
  I: Integer;
begin
  ResultList := TList<string>.Create;
  ServiceKeys := TStringList.Create;
  
  try
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      
      if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services') then
      begin
        try
          Reg.GetKeyNames(ServiceKeys);
          
          for I := 0 to ServiceKeys.Count - 1 do
          begin
            if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services\' + ServiceKeys[I]) then
            begin
              try
                if Reg.ValueExists('ImagePath') then
                begin
                  ImagePath := Reg.ReadString('ImagePath');
                  
                  // 清理路径中的参数和引号
                  if StartsText('"', ImagePath) then
                  begin
                    var QuotePos := Pos('"', Copy(ImagePath, 2, Length(ImagePath)));
                    if QuotePos > 0 then
                      ImagePath := Copy(ImagePath, 2, QuotePos - 1);
                  end
                  else
                  begin
                    var SpacePos := Pos(' ', ImagePath);
                    if SpacePos > 0 then
                      ImagePath := Copy(ImagePath, 1, SpacePos - 1);
                  end;
                  
                  // 展开环境变量
                  if ContainsText(ImagePath, '%') then
                  begin
                    var Buffer: array[0..MAX_PATH-1] of Char;
                    if ExpandEnvironmentStrings(PChar(ImagePath), Buffer, MAX_PATH) > 0 then
                      ImagePath := Buffer;
                  end;
                  
                  // 检查是否匹配目标文件
                  if SameText(ImagePath, AFilePath) then
                    ResultList.Add(ServiceKeys[I]);
                end;
              finally
                Reg.CloseKey;
              end;
            end;
          end;
          
        finally
          Reg.CloseKey;
        end;
      end;
      
    finally
      Reg.Free;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
    ServiceKeys.Free;
  end;
end;

function TRebootDetector.IsSystemCriticalFile(const AFilePath: string): Boolean;
var
  FileName: string;
  FilePath: string;
begin
  FileName := LowerCase(ExtractFileName(AFilePath));
  FilePath := LowerCase(AFilePath);
  
  // 检查是否在系统文件列表中
  Result := FSystemFilePatterns.IndexOf(FileName) >= 0;
  
  // 检查是否在系统目录中
  if not Result then
  begin
    var WinDir := LowerCase(GetEnvironmentVariable('WINDIR'));
    Result := StartsText(WinDir + '\system32', FilePath) or
              StartsText(WinDir + '\syswow64', FilePath) or
              StartsText(WinDir + '\boot', FilePath);
  end;
end;

function TRebootDetector.IsDriverFile(const AFilePath: string): Boolean;
var
  Extension: string;
  FilePath: string;
begin
  Extension := LowerCase(ExtractFileExt(AFilePath));
  FilePath := LowerCase(AFilePath);
  
  // 检查扩展名
  Result := (Extension = '.sys') or (Extension = '.drv') or (Extension = '.vxd');
  
  // 检查是否在驱动目录中
  if not Result then
  begin
    var WinDir := LowerCase(GetEnvironmentVariable('WINDIR'));
    Result := StartsText(WinDir + '\system32\drivers', FilePath) or
              StartsText(WinDir + '\syswow64\drivers', FilePath);
  end;
end;

function TRebootDetector.IsKernelFile(const AFilePath: string): Boolean;
var
  FileName: string;
begin
  FileName := LowerCase(ExtractFileName(AFilePath));
  Result := FKernelFilePatterns.IndexOf(FileName) >= 0;
end;

function TRebootDetector.IsServiceExecutable(const AFilePath: string): Boolean;
var
  Services: TArray<string>;
begin
  Services := GetServicesUsingFile(AFilePath);
  Result := Length(Services) > 0;
end;

function TRebootDetector.CanTerminateProcess(const AProcessName: string): Boolean;
var
  ProcessName: string;
begin
  ProcessName := LowerCase(AProcessName);
  
  // 检查是否为关键进程
  Result := FCriticalProcesses.IndexOf(ProcessName) < 0;
  
  // 系统进程通常不能终止
  if Result then
  begin
    Result := not (StartsText('system', ProcessName) or
                   StartsText('csrss', ProcessName) or
                   StartsText('winlogon', ProcessName) or
                   StartsText('services', ProcessName) or
                   StartsText('lsass', ProcessName));
  end;
end;

function TRebootDetector.CanStopService(const AServiceName: string): Boolean;
var
  ServiceName: string;
begin
  ServiceName := LowerCase(AServiceName);
  
  // 检查是否为关键服务
  Result := FCriticalServices.IndexOf(ServiceName) < 0;
  
  // 某些服务不能停止
  if Result then
  begin
    Result := not (StartsText('rpcss', ServiceName) or
                   StartsText('eventlog', ServiceName) or
                   StartsText('plugplay', ServiceName));
  end;
end;

function TRebootDetector.HasPendingFileOperations: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    // 检查待处理的文件重命名操作
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Control\Session Manager') then
    begin
      try
        Result := Reg.ValueExists('PendingFileRenameOperations');
      finally
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
  end;
end;

function TRebootDetector.HasPendingRegistryOperations: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    // 检查待处理的注册表操作
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Control\Session Manager') then
    begin
      try
        Result := Reg.ValueExists('PendingRegistryOperations');
      finally
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
  end;
end;

function TRebootDetector.CheckRegistryForRebootFlags: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    // 检查Windows Update重启标志
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') then
    begin
      Result := True;
      Reg.CloseKey;
    end;
    
    // 检查其他重启标志
    if not Result then
    begin
      if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Updates\UpdateExeVolatile') then
      begin
        Result := True;
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
  end;
end;f
unction TRebootDetector.GetSystemUptime: Int64;
begin
  Result := GetTickCount64 div 1000; // 转换为秒
end;

function TRebootDetector.HasRecentSystemUpdates: Boolean;
var
  Reg: TRegistry;
  LastUpdateTime: TDateTime;
  UpdateTimeStr: string;
begin
  Result := False;
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install') then
    begin
      try
        if Reg.ValueExists('LastSuccessTime') then
        begin
          UpdateTimeStr := Reg.ReadString('LastSuccessTime');
          // 简化处理：检查是否在最近24小时内
          if TryStrToDateTime(UpdateTimeStr, LastUpdateTime) then
          begin
            Result := HoursBetween(Now, LastUpdateTime) < 24;
          end;
        end;
      finally
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
  end;
end;

function TRebootDetector.HasPendingWindowsUpdates: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update') then
    begin
      try
        Result := Reg.ValueExists('RebootRequired');
      finally
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
  end;
end;

function TRebootDetector.CalculateForceCloseRisk(const AProcesses: TArray<string>; 
  const AServices: TArray<string>): Integer;
var
  Risk: Integer;
begin
  Risk := 0;
  
  // 基于进程数量增加风险
  Risk := Risk + Length(AProcesses) * 10;
  
  // 基于服务数量增加风险
  Risk := Risk + Length(AServices) * 20;
  
  // 检查关键进程
  for var ProcessName in AProcesses do
  begin
    if not CanTerminateProcess(ProcessName) then
      Risk := Risk + 50;
  end;
  
  // 检查关键服务
  for var ServiceName in AServices do
  begin
    if not CanStopService(ServiceName) then
      Risk := Risk + 60;
  end;
  
  // 限制在0-100范围内
  Result := Max(0, Min(100, Risk));
end;

function TRebootDetector.DetermineRebootRequirement(const AFilePath: string; 
  const AReasons: TArray<TRebootReason>): TRebootRequirement;
var
  MaxRequirement: TRebootRequirement;
begin
  MaxRequirement := rrNotRequired;
  
  for var Reason in AReasons do
  begin
    case Reason of
      rrKernelFile:
        MaxRequirement := rrCritical;
      rrSystemFile, rrDriverFile:
        if MaxRequirement < rrRequired then
          MaxRequirement := rrRequired;
      rrServiceFile, rrRegistryChange:
        if MaxRequirement < rrRecommended then
          MaxRequirement := rrRecommended;
      rrFileInUse, rrPendingOperation:
        if MaxRequirement < rrRecommended then
          MaxRequirement := rrRecommended;
    end;
    
    // 如果已经是最高级别，直接返回
    if MaxRequirement = rrCritical then
      Break;
  end;
  
  Result := MaxRequirement;
end;

function TRebootDetector.GenerateAlternativeSolutions(const AFilePath: string; 
  const AProcesses, AServices: TArray<string>): TArray<string>;
var
  SolutionList: TList<string>;
begin
  SolutionList := TList<string>.Create;
  try
    // 如果有进程使用文件
    if Length(AProcesses) > 0 then
    begin
      SolutionList.Add('尝试关闭使用该文件的应用程序');
      SolutionList.Add('使用任务管理器结束相关进程');
      
      var CanTerminateAll := True;
      for var ProcessName in AProcesses do
      begin
        if not CanTerminateProcess(ProcessName) then
        begin
          CanTerminateAll := False;
          Break;
        end;
      end;
      
      if CanTerminateAll then
        SolutionList.Add('可以安全地强制结束所有相关进程');
    end;
    
    // 如果有服务使用文件
    if Length(AServices) > 0 then
    begin
      SolutionList.Add('尝试停止相关的系统服务');
      SolutionList.Add('使用服务管理器停止服务');
      
      var CanStopAll := True;
      for var ServiceName in AServices do
      begin
        if not CanStopService(ServiceName) then
        begin
          CanStopAll := False;
          Break;
        end;
      end;
      
      if CanStopAll then
        SolutionList.Add('可以安全地停止所有相关服务');
    end;
    
    // 通用解决方案
    if IsSystemCriticalFile(AFilePath) then
    begin
      SolutionList.Add('使用安全模式进行文件操作');
      SolutionList.Add('创建系统还原点后再操作');
    end;
    
    if IsFileInUse(AFilePath) then
    begin
      SolutionList.Add('等待文件使用完毕后再操作');
      SolutionList.Add('计划在系统重启后执行操作');
    end;
    
    // 如果没有其他解决方案
    if SolutionList.Count = 0 then
    begin
      SolutionList.Add('文件可以安全操作，无需特殊处理');
    end;
    
    // 转换为数组
    SetLength(Result, SolutionList.Count);
    for var I := 0 to SolutionList.Count - 1 do
      Result[I] := SolutionList[I];
      
  finally
    SolutionList.Free;
  end;
end;

// 批量检测和系统检测方法
function TRebootDetector.BatchDetectRebootRequirement(const AFilePaths: TArray<string>): TArray<TRebootDetectionResult>;
var
  ResultList: TList<TRebootDetectionResult>;
begin
  ResultList := TList<TRebootDetectionResult>.Create;
  try
    for var FilePath in AFilePaths do
    begin
      var Detection := DetectRebootRequirement(FilePath);
      ResultList.Add(Detection);
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TRebootDetector.DetectSystemRebootRequirement: TRebootDetectionResult;
var
  ReasonList: TList<TRebootReason>;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.FilePath := 'SYSTEM';
  Result.RequiresReboot := rrNotRequired;
  
  ReasonList := TList<TRebootReason>.Create;
  try
    // 检查待处理的文件操作
    if HasPendingFileOperations then
      ReasonList.Add(rrPendingOperation);
    
    // 检查待处理的注册表操作
    if HasPendingRegistryOperations then
      ReasonList.Add(rrRegistryChange);
    
    // 检查Windows更新
    if HasPendingWindowsUpdates then
      ReasonList.Add(rrSystemUpdate);
    
    // 检查注册表重启标志
    if CheckRegistryForRebootFlags then
      ReasonList.Add(rrRegistryChange);
    
    // 转换为数组
    SetLength(Result.Reasons, ReasonList.Count);
    for var I := 0 to ReasonList.Count - 1 do
      Result.Reasons[I] := ReasonList[I];
    
    // 确定重启需求级别
    if Length(Result.Reasons) > 0 then
    begin
      Result.RequiresReboot := rrRecommended;
      
      // 如果有系统更新，提升到必需级别
      for var Reason in Result.Reasons do
      begin
        if Reason = rrSystemUpdate then
        begin
          Result.RequiresReboot := rrRequired;
          Break;
        end;
      end;
    end;
    
    // 生成描述
    case Result.RequiresReboot of
      rrNotRequired:
        Result.Description := '系统当前不需要重启';
      rrRecommended:
        Result.Description := '系统建议重启以完成待处理的操作';
      rrRequired:
        Result.Description := '系统需要重启以完成更新或配置更改';
      rrCritical:
        Result.Description := '系统必须重启以确保稳定性';
    end;
    
  finally
    ReasonList.Free;
  end;
end;// 文件操作
安全检查
function TRebootDetector.CanSafelyMoveFile(const AFilePath: string): Boolean;
var
  Detection: TRebootDetectionResult;
begin
  Detection := DetectRebootRequirement(AFilePath);
  Result := (Detection.RequiresReboot = rrNotRequired) or 
            (Detection.RequiresReboot = rrRecommended);
end;

function TRebootDetector.CanSafelyDeleteFile(const AFilePath: string): Boolean;
var
  Detection: TRebootDetectionResult;
begin
  Detection := DetectRebootRequirement(AFilePath);
  Result := (Detection.RequiresReboot = rrNotRequired) and 
            not IsSystemCriticalFile(AFilePath) and
            not IsKernelFile(AFilePath);
end;

function TRebootDetector.GetOptimalOperationTime(const AFilePath: string): TDateTime;
var
  Detection: TRebootDetectionResult;
begin
  Detection := DetectRebootRequirement(AFilePath);
  
  case Detection.RequiresReboot of
    rrNotRequired:
      Result := Now; // 立即执行
    rrRecommended:
      Result := Now + (5 / (24 * 60)); // 5分钟后
    rrRequired:
      Result := Now + (1 / (24 * 60)); // 1分钟后
    rrCritical:
      Result := Now + (10 / (24 * 60 * 60)); // 10秒后
  else
    Result := Now;
  end;
end;

// 强制操作支持
function TRebootDetector.ForceCloseProcessesUsingFile(const AFilePath: string): Boolean;
var
  Processes: TArray<string>;
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ProcessHandle: THandle;
begin
  Result := True;
  
  Processes := GetProcessesUsingFile(AFilePath);
  
  if Length(Processes) = 0 then
    Exit;
  
  // 创建进程快照
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
  begin
    Result := False;
    Exit;
  end;
  
  try
    ProcessEntry.dwSize := SizeOf(TProcessEntry32);
    
    if Process32First(Snapshot, ProcessEntry) then
    begin
      repeat
        // 检查是否为目标进程
        for var ProcessName in Processes do
        begin
          if SameText(ProcessEntry.szExeFile, ProcessName) then
          begin
            // 检查是否可以终止
            if CanTerminateProcess(ProcessName) then
            begin
              ProcessHandle := OpenProcess(PROCESS_TERMINATE, False, ProcessEntry.th32ProcessID);
              if ProcessHandle <> 0 then
              begin
                try
                  if not TerminateProcess(ProcessHandle, 0) then
                    Result := False;
                finally
                  CloseHandle(ProcessHandle);
                end;
              end
              else
                Result := False;
            end
            else
              Result := False;
          end;
        end;
        
      until not Process32Next(Snapshot, ProcessEntry);
    end;
    
  finally
    CloseHandle(Snapshot);
  end;
end;

function TRebootDetector.ForceStopServicesUsingFile(const AFilePath: string): Boolean;
var
  Services: TArray<string>;
  SCManager, ServiceHandle: SC_HANDLE;
  ServiceStatus: TServiceStatus;
begin
  Result := True;
  
  Services := GetServicesUsingFile(AFilePath);
  
  if Length(Services) = 0 then
    Exit;
  
  SCManager := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SCManager = 0 then
  begin
    Result := False;
    Exit;
  end;
  
  try
    for var ServiceName in Services do
    begin
      if CanStopService(ServiceName) then
      begin
        ServiceHandle := OpenService(SCManager, PChar(ServiceName), SERVICE_STOP);
        if ServiceHandle <> 0 then
        begin
          try
            if not ControlService(ServiceHandle, SERVICE_CONTROL_STOP, ServiceStatus) then
              Result := False;
          finally
            CloseServiceHandle(ServiceHandle);
          end;
        end
        else
          Result := False;
      end
      else
        Result := False;
    end;
    
  finally
    CloseServiceHandle(SCManager);
  end;
end;

function TRebootDetector.ScheduleFileOperationAfterReboot(const AOldPath, ANewPath: string): Boolean;
var
  Reg: TRegistry;
  Operations: TStringList;
  OperationStr: string;
begin
  Result := False;
  
  Reg := TRegistry.Create(KEY_WRITE);
  Operations := TStringList.Create;
  
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKey('SYSTEM\CurrentControlSet\Control\Session Manager', False) then
    begin
      try
        // 读取现有的待处理操作
        if Reg.ValueExists('PendingFileRenameOperations') then
        begin
          Operations.Text := Reg.ReadString('PendingFileRenameOperations');
        end;
        
        // 添加新的操作
        if ANewPath <> '' then
          OperationStr := AOldPath + #0 + ANewPath + #0
        else
          OperationStr := AOldPath + #0#0; // 删除操作
        
        Operations.Add(OperationStr);
        
        // 写回注册表
        Reg.WriteString('PendingFileRenameOperations', Operations.Text);
        Result := True;
        
      finally
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
    Operations.Free;
  end;
end;

// 系统重启管理
function TRebootDetector.ScheduleSystemReboot(const ADelaySeconds: Integer; const AReason: string): Boolean;
var
  CommandLine: string;
begin
  CommandLine := Format('shutdown /r /t %d /c "%s"', [ADelaySeconds, AReason]);
  
  Result := WinExec(PAnsiChar(AnsiString(CommandLine)), SW_HIDE) > 31;
end;

function TRebootDetector.CancelScheduledReboot: Boolean;
var
  CommandLine: string;
begin
  CommandLine := 'shutdown /a';
  Result := WinExec(PAnsiChar(AnsiString(CommandLine)), SW_HIDE) > 31;
end;

function TRebootDetector.GetScheduledRebootInfo: string;
var
  Reg: TRegistry;
begin
  Result := '';
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update') then
    begin
      try
        if Reg.ValueExists('RebootRequired') then
          Result := '系统有待处理的重启需求';
      finally
        Reg.CloseKey;
      end;
    end;
    
    if Result = '' then
      Result := '系统当前没有计划的重启';
      
  finally
    Reg.Free;
  end;
end;//
 工具方法
class function TRebootDetector.RebootRequirementToString(ARequirement: TRebootRequirement): string;
begin
  case ARequirement of
    rrNotRequired: Result := '不需要重启';
    rrRecommended: Result := '建议重启';
    rrRequired: Result := '需要重启';
    rrCritical: Result := '必须重启';
  else
    Result := '未知';
  end;
end;

class function TRebootDetector.RebootReasonToString(AReason: TRebootReason): string;
begin
  case AReason of
    rrUnknown: Result := '未知原因';
    rrSystemFile: Result := '系统文件修改';
    rrDriverFile: Result := '驱动文件修改';
    rrServiceFile: Result := '服务文件修改';
    rrKernelFile: Result := '内核文件修改';
    rrRegistryChange: Result := '注册表修改';
    rrFileInUse: Result := '文件正在使用';
    rrPendingOperation: Result := '待处理操作';
    rrSecurityUpdate: Result := '安全更新';
    rrSystemUpdate: Result := '系统更新';
  else
    Result := '其他原因';
  end;
end;

class function TRebootDetector.RebootRequirementToColor(ARequirement: TRebootRequirement): Integer;
begin
  case ARequirement of
    rrNotRequired: Result := clGreen;
    rrRecommended: Result := clYellow;
    rrRequired: Result := clOrange;
    rrCritical: Result := clRed;
  else
    Result := clGray;
  end;
end;

end.