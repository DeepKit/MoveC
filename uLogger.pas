unit uLogger;

{
  统一日志接口 - Unified Logging Interface
  
  提供简单易用的全局日志接口，支持：
  - Debug/Release 模式自动切换
  - 配置化日志路径和级别
  - 多种输出目标（文件、调试器、控制台）
  - 线程安全的日志记录
  - 自动日志轮转
  - 性能优化的缓存机制
  
  使用方法：
  - LogInfo('Module', 'Message');
  - LogError('Module', 'Error message');
  - LogDebug('Module', 'Debug info');
  
  作者: AI助手
  版本: 1.0
  日期: 2024
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, 
  System.DateUtils, System.SyncObjs, System.Generics.Collections,
  uLogManager;

type
  // 简化的日志级别（与 uLogManager 兼容）
  TLoggerLevel = (llDebug, llInfo, llWarning, llError, llCritical);
  
  // 日志配置
  TLoggerConfig = record
    LogDirectory: string;
    LogFileName: string;
    LogLevel: TLoggerLevel;
    LogToFile: Boolean;
    LogToDebug: Boolean;
    LogToConsole: Boolean;
    MaxFileSize: Int64;
    MaxFiles: Integer;
    EnableCache: Boolean;
    CacheSize: Integer;
    AutoFlushInterval: Integer; // 秒
  end;

  // 统一日志接口类
  TUnifiedLogger = class
  private
    class var FInstance: TUnifiedLogger;
    class var FLock: TCriticalSection;
    class function GetInstance: TUnifiedLogger; static;
    
    FLogManager: TLogManager;
    FConfig: TLoggerConfig;
    FIsDebugMode: Boolean;
    FLastFlush: TDateTime;
    FAutoFlushTimer: TTimer;
    FLogCache: TList<TLogEntry>;
    
    procedure InitializeConfig;
    procedure LoadConfigFromRegistry;
    procedure SaveConfigToRegistry;
    procedure ApplyConfig;
    procedure SetupAutoFlush;
    procedure OnAutoFlushTimer(Sender: TObject);
    procedure InternalLog(Level: TLoggerLevel; const Module, Message: string);
    function ConvertLogLevel(Level: TLoggerLevel): TLogLevel;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 全局访问接口
    class property Instance: TUnifiedLogger read GetInstance;
    
    // 配置管理
    procedure LoadConfig;
    procedure SaveConfig;
    procedure SetConfig(const AConfig: TLoggerConfig);
    function GetConfig: TLoggerConfig;
    
    // 基本日志记录方法
    procedure LogDebug(const Module, Message: string);
    procedure LogInfo(const Module, Message: string);
    procedure LogWarning(const Module, Message: string);
    procedure LogError(const Module, Message: string);
    procedure LogCritical(const Module, Message: string);
    
    // 格式化日志记录
    procedure LogDebugFormat(const Module, AFormat: string; const Args: array of const);
    procedure LogInfoFormat(const Module, AFormat: string; const Args: array of const);
    procedure LogWarningFormat(const Module, AFormat: string; const Args: array of const);
    procedure LogErrorFormat(const Module, AFormat: string; const Args: array of const);
    procedure LogCriticalFormat(const Module, AFormat: string; const Args: array of const);
    
    // 高级功能
    procedure Flush;
    procedure Clear;
    procedure SetDebugMode(ADebugMode: Boolean);
    function IsDebugMode: Boolean;
    procedure SetLogLevel(ALevel: TLoggerLevel);
    function GetLogLevel: TLoggerLevel;
    
    // 统计信息
    function GetLogCount: Integer;
    function GetLogFiles: TArray<string>;
    function GetRecentLogs(Count: Integer = 100): TArray<TLogEntry>;
  end;

// 全局便捷函数
procedure LogInfo(const Module, Message: string);
procedure LogError(const Module, Message: string);
procedure LogDebug(const Module, Message: string);
procedure LogWarning(const Module, Message: string);
procedure LogCritical(const Module, Message: string);

procedure LogInfoFormat(const Module, AFormat: string; const Args: array of const);
procedure LogErrorFormat(const Module, AFormat: string; const Args: array of const);
procedure LogDebugFormat(const Module, AFormat: string; const Args: array of const);
procedure LogWarningFormat(const Module, AFormat: string; const Args: array of const);
procedure LogCriticalFormat(const Module, AFormat: string; const Args: array of const);

// 配置函数
procedure SetLoggerConfig(const AConfig: TLoggerConfig);
function GetLoggerConfig: TLoggerConfig;
procedure SetDebugMode(ADebugMode: Boolean);
function IsDebugMode: Boolean;

implementation

{ TUnifiedLogger }

class function TUnifiedLogger.GetInstance: TUnifiedLogger;
begin
  if not Assigned(FInstance) then
  begin
    FLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TUnifiedLogger.Create;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

constructor TUnifiedLogger.Create;
begin
  inherited Create;
  FLogManager := TLogManager.Create;
  FLogCache := TList<TLogEntry>.Create;
  FAutoFlushTimer := TTimer.Create(nil);
  FAutoFlushTimer.Enabled := False;
  FAutoFlushTimer.OnTimer := OnAutoFlushTimer;
  
  // 检测编译模式
  {$IFDEF DEBUG}
  FIsDebugMode := True;
  {$ELSE}
  FIsDebugMode := False;
  {$ENDIF}
  
  InitializeConfig;
  LoadConfig;
  ApplyConfig;
  SetupAutoFlush;
end;

destructor TUnifiedLogger.Destroy;
begin
  Flush; // 刷新所有缓存的日志
  FreeAndNil(FAutoFlushTimer);
  FreeAndNil(FLogCache);
  FreeAndNil(FLogManager);
  inherited Destroy;
end;

procedure TUnifiedLogger.InitializeConfig;
begin
  // 默认配置
  FConfig.LogDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Logs');
  FConfig.LogFileName := 'MoveC.log';
  FConfig.LogLevel := llInfo;
  FConfig.LogToFile := True;
  FConfig.LogToDebug := FIsDebugMode;
  FConfig.LogToConsole := False;
  FConfig.MaxFileSize := 10 * 1024 * 1024; // 10MB
  FConfig.MaxFiles := 5;
  FConfig.EnableCache := True;
  FConfig.CacheSize := 1000;
  FConfig.AutoFlushInterval := 30; // 30秒
end;

procedure TUnifiedLogger.LoadConfigFromRegistry;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\MoveC\Logger', False) then
    begin
      if Registry.ValueExists('LogDirectory') then
        FConfig.LogDirectory := Registry.ReadString('LogDirectory');
      if Registry.ValueExists('LogFileName') then
        FConfig.LogFileName := Registry.ReadString('LogFileName');
      if Registry.ValueExists('LogLevel') then
        FConfig.LogLevel := TLoggerLevel(Registry.ReadInteger('LogLevel'));
      if Registry.ValueExists('LogToFile') then
        FConfig.LogToFile := Registry.ReadBool('LogToFile');
      if Registry.ValueExists('LogToDebug') then
        FConfig.LogToDebug := Registry.ReadBool('LogToDebug');
      if Registry.ValueExists('LogToConsole') then
        FConfig.LogToConsole := Registry.ReadBool('LogToConsole');
      if Registry.ValueExists('MaxFileSize') then
        FConfig.MaxFileSize := Registry.ReadInt64('MaxFileSize');
      if Registry.ValueExists('MaxFiles') then
        FConfig.MaxFiles := Registry.ReadInteger('MaxFiles');
      if Registry.ValueExists('EnableCache') then
        FConfig.EnableCache := Registry.ReadBool('EnableCache');
      if Registry.ValueExists('CacheSize') then
        FConfig.CacheSize := Registry.ReadInteger('CacheSize');
      if Registry.ValueExists('AutoFlushInterval') then
        FConfig.AutoFlushInterval := Registry.ReadInteger('AutoFlushInterval');
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TUnifiedLogger.SaveConfigToRegistry;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\MoveC\Logger', True) then
    begin
      Registry.WriteString('LogDirectory', FConfig.LogDirectory);
      Registry.WriteString('LogFileName', FConfig.LogFileName);
      Registry.WriteInteger('LogLevel', Integer(FConfig.LogLevel));
      Registry.WriteBool('LogToFile', FConfig.LogToFile);
      Registry.WriteBool('LogToDebug', FConfig.LogToDebug);
      Registry.WriteBool('LogToConsole', FConfig.LogToConsole);
      Registry.WriteInt64('MaxFileSize', FConfig.MaxFileSize);
      Registry.WriteInteger('MaxFiles', FConfig.MaxFiles);
      Registry.WriteBool('EnableCache', FConfig.EnableCache);
      Registry.WriteInteger('CacheSize', FConfig.CacheSize);
      Registry.WriteInteger('AutoFlushInterval', FConfig.AutoFlushInterval);
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TUnifiedLogger.LoadConfig;
begin
  LoadConfigFromRegistry;
  ApplyConfig;
end;

procedure TUnifiedLogger.SaveConfig;
begin
  SaveConfigToRegistry;
end;

procedure TUnifiedLogger.ApplyConfig;
begin
  // 确保日志目录存在
  if not TDirectory.Exists(FConfig.LogDirectory) then
    TDirectory.CreateDirectory(FConfig.LogDirectory);
  
  // 应用配置到日志管理器
  FLogManager.LogLevel := ConvertLogLevel(FConfig.LogLevel);
  FLogManager.LogToFile := FConfig.LogToFile;
  FLogManager.MaxFileSize := FConfig.MaxFileSize;
  FLogManager.MaxFiles := FConfig.MaxFiles;
end;

procedure TUnifiedLogger.SetupAutoFlush;
begin
  if FConfig.AutoFlushInterval > 0 then
  begin
    FAutoFlushTimer.Interval := FConfig.AutoFlushInterval * 1000;
    FAutoFlushTimer.Enabled := True;
  end
  else
  begin
    FAutoFlushTimer.Enabled := False;
  end;
end;

procedure TUnifiedLogger.OnAutoFlushTimer(Sender: TObject);
begin
  Flush;
end;

procedure TUnifiedLogger.InternalLog(Level: TLoggerLevel; const Module, Message: string);
var
  Entry: TLogEntry;
begin
  // 检查日志级别
  if Level < FConfig.LogLevel then Exit;
  
  // 在 Release 模式下跳过 Debug 日志
  if (Level = llDebug) and not FIsDebugMode then Exit;
  
  // 创建日志条目
  Entry.Timestamp := Now;
  Entry.Level := ConvertLogLevel(Level);
  Entry.Module := Module;
  Entry.Message := Message;
  Entry.ThreadID := GetCurrentThreadId;
  Entry.ProcessID := GetCurrentProcessId;
  
  // 输出到调试器
  if FConfig.LogToDebug then
  begin
    OutputDebugString(PChar(Format('[%s] [%s] %s: %s', 
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.Timestamp),
       CopyRight(Uppercase(LogLevelToString(Level)), 1, 4),
       Module, Message])));
  end;
  
  // 输出到控制台（如果有的话）
  if FConfig.LogToConsole and IsConsole then
  begin
    Writeln(Format('[%s] [%s] %s: %s', 
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.Timestamp),
       CopyRight(Uppercase(LogLevelToString(Level)), 1, 4),
       Module, Message]));
  end;
  
  // 缓存或直接写入文件
  if FConfig.EnableCache then
  begin
    FLogCache.Add(Entry);
    if FLogCache.Count >= FConfig.CacheSize then
      Flush;
  end
  else
  begin
    FLogManager.Log(Entry.Level, Module, Message);
  end;
end;

function TUnifiedLogger.ConvertLogLevel(Level: TLoggerLevel): TLogLevel;
begin
  case Level of
    llDebug: Result := llDebug;
    llInfo: Result := llInfo;
    llWarning: Result := llWarning;
    llError: Result := llError;
    llCritical: Result := llCritical;
  else
    Result := llInfo;
  end;
end;

procedure TUnifiedLogger.LogDebug(const Module, Message: string);
begin
  InternalLog(llDebug, Module, Message);
end;

procedure TUnifiedLogger.LogInfo(const Module, Message: string);
begin
  InternalLog(llInfo, Module, Message);
end;

procedure TUnifiedLogger.LogWarning(const Module, Message: string);
begin
  InternalLog(llWarning, Module, Message);
end;

procedure TUnifiedLogger.LogError(const Module, Message: string);
begin
  InternalLog(llError, Module, Message);
end;

procedure TUnifiedLogger.LogCritical(const Module, Message: string);
begin
  InternalLog(llCritical, Module, Message);
end;

procedure TUnifiedLogger.LogDebugFormat(const Module, AFormat: string; const Args: array of const);
begin
  InternalLog(llDebug, Module, Format(AFormat, Args));
end;

procedure TUnifiedLogger.LogInfoFormat(const Module, AFormat: string; const Args: array of const);
begin
  InternalLog(llInfo, Module, Format(AFormat, Args));
end;

procedure TUnifiedLogger.LogWarningFormat(const Module, AFormat: string; const Args: array of const);
begin
  InternalLog(llWarning, Module, Format(AFormat, Args));
end;

procedure TUnifiedLogger.LogErrorFormat(const Module, AFormat: string; const Args: array of const);
begin
  InternalLog(llError, Module, Format(AFormat, Args));
end;

procedure TUnifiedLogger.LogCriticalFormat(const Module, AFormat: string; const Args: array of const);
begin
  InternalLog(llCritical, Module, Format(AFormat, Args));
end;

procedure TUnifiedLogger.Flush;
var
  Entry: TLogEntry;
begin
  if FConfig.EnableCache and (FLogCache.Count > 0) then
  begin
    for Entry in FLogCache do
    begin
      FLogManager.Log(Entry.Level, Entry.Module, Entry.Message);
    end;
    FLogCache.Clear;
    FLogManager.FlushLogs;
    FLastFlush := Now;
  end;
end;

procedure TUnifiedLogger.Clear;
begin
  FLogCache.Clear;
  FLogManager.ClearLogs;
end;

procedure TUnifiedLogger.SetDebugMode(ADebugMode: Boolean);
begin
  FIsDebugMode := ADebugMode;
  FConfig.LogToDebug := ADebugMode;
  ApplyConfig;
end;

function TUnifiedLogger.IsDebugMode: Boolean;
begin
  Result := FIsDebugMode;
end;

procedure TUnifiedLogger.SetLogLevel(ALevel: TLoggerLevel);
begin
  FConfig.LogLevel := ALevel;
  ApplyConfig;
end;

function TUnifiedLogger.GetLogLevel: TLoggerLevel;
begin
  Result := FConfig.LogLevel;
end;

function TUnifiedLogger.GetLogCount: Integer;
begin
  Result := FLogCache.Count;
end;

function TUnifiedLogger.GetLogFiles: TArray<string>;
begin
  Result := FLogManager.GetLogFiles;
end;

function TUnifiedLogger.GetRecentLogs(Count: Integer): TArray<TLogEntry>;
begin
  Result := FLogManager.GetRecentLogs(Count);
end;

procedure TUnifiedLogger.SetConfig(const AConfig: TLoggerConfig);
begin
  FConfig := AConfig;
  ApplyConfig;
  SetupAutoFlush;
end;

function TUnifiedLogger.GetConfig: TLoggerConfig;
begin
  Result := FConfig;
end;

// 全局便捷函数实现

procedure LogInfo(const Module, Message: string);
begin
  TUnifiedLogger.Instance.LogInfo(Module, Message);
end;

procedure LogError(const Module, Message: string);
begin
  TUnifiedLogger.Instance.LogError(Module, Message);
end;

procedure LogDebug(const Module, Message: string);
begin
  TUnifiedLogger.Instance.LogDebug(Module, Message);
end;

procedure LogWarning(const Module, Message: string);
begin
  TUnifiedLogger.Instance.LogWarning(Module, Message);
end;

procedure LogCritical(const Module, Message: string);
begin
  TUnifiedLogger.Instance.LogCritical(Module, Message);
end;

procedure LogInfoFormat(const Module, AFormat: string; const Args: array of const);
begin
  TUnifiedLogger.Instance.LogInfoFormat(Module, AFormat, Args);
end;

procedure LogErrorFormat(const Module, AFormat: string; const Args: array of const);
begin
  TUnifiedLogger.Instance.LogErrorFormat(Module, AFormat, Args);
end;

procedure LogDebugFormat(const Module, AFormat: string; const Args: array of const);
begin
  TUnifiedLogger.Instance.LogDebugFormat(Module, AFormat, Args);
end;

procedure LogWarningFormat(const Module, AFormat: string; const Args: array of const);
begin
  TUnifiedLogger.Instance.LogWarningFormat(Module, AFormat, Args);
end;

procedure LogCriticalFormat(const Module, AFormat: string; const Args: array of const);
begin
  TUnifiedLogger.Instance.LogCriticalFormat(Module, AFormat, Args);
end;

procedure SetLoggerConfig(const AConfig: TLoggerConfig);
begin
  TUnifiedLogger.Instance.SetConfig(AConfig);
end;

function GetLoggerConfig: TLoggerConfig;
begin
  Result := TUnifiedLogger.Instance.GetConfig;
end;

procedure SetDebugMode(ADebugMode: Boolean);
begin
  TUnifiedLogger.Instance.SetDebugMode(ADebugMode);
end;

function IsDebugMode: Boolean;
begin
  Result := TUnifiedLogger.Instance.IsDebugMode;
end;

// 辅助函数
function LogLevelToString(Level: TLogLevel): string;
begin
  case Level of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarning: Result := 'WARN';
    llError: Result := 'ERROR';
    llCritical: Result := 'CRIT';
  else
    Result := 'UNKNOWN';
  end;
end;

initialization

TUnifiedLogger.FLock := TCriticalSection.Create;

finalization

FreeAndNil(TUnifiedLogger.FLock);
if Assigned(TUnifiedLogger.FInstance) then
  FreeAndNil(TUnifiedLogger.FInstance);

end.
