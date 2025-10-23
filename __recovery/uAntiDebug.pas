unit uAntiDebug;

{
  反调试保护模块
  
  功能：
  1. 检测调试器存在
  2. 检测远程调试器
  3. 检测时间异常（反单步调试）
  4. 检测硬件断点
  5. 保护进程（可选）
  
  使用方法：
  1. 在程序启动时调用 TAntiDebug.CheckAll
  2. 如果返回True，表示检测到调试器，应终止程序
  
  编译指令：
  - 在Release配置中定义RELEASE符号以启用反调试保护
}

{$IFDEF RELEASE}
  {$DEFINE ENABLE_ANTI_DEBUG}  // 生产环境启用反调试
{$ENDIF}

interface

uses
  Winapi.Windows, System.SysUtils;

type
  TAntiDebug = class
  private
    class function GetTickCountDiff(StartTick: DWORD): DWORD;
  public
    // 检测调试器
    class function IsDebuggerPresent: Boolean;
    class function CheckRemoteDebugger: Boolean;
    class function DetectTimingAnomaly: Boolean;
    class function DetectHardwareBreakpoints: Boolean;
    
    // 综合检测
    class function CheckAll: Boolean;
    
    // 保护进程（需要管理员权限）
    class procedure ProtectProcess;
  end;

implementation

// 检测本地调试器
class function TAntiDebug.IsDebuggerPresent: Boolean;
begin
  {$IFDEF ENABLE_ANTI_DEBUG}
  Result := Winapi.Windows.IsDebuggerPresent;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

// 检测远程调试器
class function TAntiDebug.CheckRemoteDebugger: Boolean;
var
  IsPresent: BOOL;
  ProcessHandle: THandle;
begin
  Result := False;
  {$IFDEF ENABLE_ANTI_DEBUG}
  ProcessHandle := GetCurrentProcess;
  IsPresent := False;
  
  if CheckRemoteDebuggerPresent(ProcessHandle, IsPresent) then
    Result := IsPresent;
  {$ENDIF}
end;

// 计算时间差
class function TAntiDebug.GetTickCountDiff(StartTick: DWORD): DWORD;
var
  CurrentTick: DWORD;
begin
  CurrentTick := GetTickCount;
  if CurrentTick >= StartTick then
    Result := CurrentTick - StartTick
  else
    // 处理溢出情况
    Result := (High(DWORD) - StartTick) + CurrentTick + 1;
end;

// 检测时间异常（反单步调试）
class function TAntiDebug.DetectTimingAnomaly: Boolean;
var
  StartTick: DWORD;
  TimeDiff: DWORD;
const
  THRESHOLD_MS = 100; // 100毫秒阈值
begin
  Result := False;
  {$IFDEF ENABLE_ANTI_DEBUG}
  StartTick := GetTickCount;
  
  // 执行一些简单操作
  Sleep(10);
  
  TimeDiff := GetTickCountDiff(StartTick);
  
  // 如果时间差异过大，可能存在调试器
  if TimeDiff > THRESHOLD_MS then
    Result := True;
  {$ENDIF}
end;

// 检测硬件断点
class function TAntiDebug.DetectHardwareBreakpoints: Boolean;
var
  Context: TContext;
  ThreadHandle: THandle;
begin
  Result := False;
  {$IFDEF ENABLE_ANTI_DEBUG}
  ThreadHandle := GetCurrentThread;
  
  FillChar(Context, SizeOf(Context), 0);
  Context.ContextFlags := CONTEXT_DEBUG_REGISTERS;
  
  if GetThreadContext(ThreadHandle, Context) then
  begin
    // 检查调试寄存器DR0-DR3
    if (Context.Dr0 <> 0) or (Context.Dr1 <> 0) or 
       (Context.Dr2 <> 0) or (Context.Dr3 <> 0) then
      Result := True;
  end;
  {$ENDIF}
end;

// 综合检测所有反调试方法
class function TAntiDebug.CheckAll: Boolean;
begin
  Result := False;
  
  {$IFDEF ENABLE_ANTI_DEBUG}
  // 检测本地调试器
  if IsDebuggerPresent then
  begin
    Result := True;
    Exit;
  end;
  
  // 检测远程调试器
  if CheckRemoteDebugger then
  begin
    Result := True;
    Exit;
  end;
  
  // 检测时间异常
  if DetectTimingAnomaly then
  begin
    Result := True;
    Exit;
  end;
  
  // 检测硬件断点
  if DetectHardwareBreakpoints then
  begin
    Result := True;
    Exit;
  end;
  {$ENDIF}
end;

// 保护进程（使调试器崩溃）
class procedure TAntiDebug.ProtectProcess;
type
  TNtSetInformationProcess = function(
    ProcessHandle: THandle;
    ProcessInformationClass: DWORD;
    ProcessInformation: Pointer;
    ProcessInformationLength: ULONG
  ): DWORD; stdcall;
var
  NtSetInformationProcess: TNtSetInformationProcess;
  ProcessInformation: DWORD;
  NtDllHandle: THandle;
begin
  {$IFDEF ENABLE_ANTI_DEBUG}
  try
    NtDllHandle := GetModuleHandle('ntdll.dll');
    if NtDllHandle <> 0 then
    begin
      @NtSetInformationProcess := GetProcAddress(NtDllHandle, 'NtSetInformationProcess');
      if Assigned(NtSetInformationProcess) then
      begin
        ProcessInformation := 1;
        // ProcessBreakOnTermination = 29
        NtSetInformationProcess(GetCurrentProcess, 29, @ProcessInformation, SizeOf(ProcessInformation));
      end;
    end;
  except
    // 忽略错误（可能没有管理员权限）
  end;
  {$ENDIF}
end;

end.
