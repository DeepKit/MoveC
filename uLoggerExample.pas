unit uLoggerExample;

{
  统一日志接口使用示例
  
  演示如何在应用程序的不同模块中使用统一日志接口
  包括基本日志记录、格式化日志、异常处理等
}

interface

uses
  System.SysUtils, System.Classes, uLogger;

type
  // 示例类 - 演示在类中使用日志
  TExampleService = class
  private
    FServiceName: string;
    
  public
    constructor Create(const AServiceName: string);
    destructor Destroy; override;
    
    // 基本操作示例
    procedure DoWork;
    procedure ProcessData(const AData: string);
    function CalculateResult(const AInput: Integer): Integer;
    
    // 异常处理示例
    procedure SafeOperation;
    procedure RiskyOperation;
  end;

// 全局函数示例
procedure PerformSystemOperation;
procedure LogUserAction(const AAction: string);
procedure HandleApplicationError(const AError: Exception);

implementation

{ TExampleService }

constructor TExampleService.Create(const AServiceName: string);
begin
  inherited Create;
  FServiceName := AServiceName;
  LogInfo('ExampleService', Format('服务 %s 已创建', [AServiceName]));
end;

destructor TExampleService.Destroy;
begin
  LogInfo('ExampleService', Format('服务 %s 已销毁', [FServiceName]));
  inherited Destroy;
end;

procedure TExampleService.DoWork;
begin
  LogInfo('ExampleService', Format('开始执行 %s 的工作', [FServiceName]));
  
  try
    // 模拟一些工作
    Sleep(100);
    
    LogDebug('ExampleService', '工作步骤 1 完成');
    Sleep(50);
    
    LogDebug('ExampleService', '工作步骤 2 完成');
    Sleep(50);
    
    LogInfo('ExampleService', Format('%s 工作执行成功', [FServiceName]));
    
  except
    on E: Exception do
    begin
      LogError('ExampleService', Format('%s 工作执行失败: %s', [FServiceName, E.Message]));
      raise;
    end;
  end;
end;

procedure TExampleService.ProcessData(const AData: string);
var
  ProcessedData: string;
begin
  LogInfoFormat('ExampleService', '开始处理数据: %s', [AData]);
  
  try
    // 模拟数据处理
    ProcessedData := UpperCase(AData);
    
    LogDebugFormat('ExampleService', '数据处理结果: %s', [ProcessedData]);
    
    // 记录处理统计
    LogInfoFormat('ExampleService', '数据处理完成 - 输入长度: %d, 输出长度: %d', 
      [Length(AData), Length(ProcessedData)]);
    
  except
    on E: Exception do
    begin
      LogErrorFormat('ExampleService', '数据处理失败: %s', [E.Message]);
      raise;
    end;
  end;
end;

function TExampleService.CalculateResult(const AInput: Integer): Integer;
begin
  LogDebugFormat('ExampleService', '计算结果 - 输入: %d', [AInput]);
  
  try
    Result := AInput * 2 + 10;
    
    LogDebugFormat('ExampleService', '计算结果 - 输出: %d', [Result]);
    
    // 如果结果很大，记录警告
    if Result > 1000 then
    begin
      LogWarningFormat('ExampleService', '计算结果较大: %d，可能需要优化', [Result]);
    end;
    
  except
    on E: Exception do
    begin
      LogErrorFormat('ExampleService', '计算失败 - 输入: %d, 错误: %s', [AInput, E.Message]);
      raise;
    end;
  end;
end;

procedure TExampleService.SafeOperation;
begin
  LogInfo('ExampleService', '执行安全操作');
  
  try
    // 模拟安全操作
    LogDebug('ExampleService', '安全操作步骤 1');
    LogDebug('ExampleService', '安全操作步骤 2');
    
    LogInfo('ExampleService', '安全操作完成');
    
  except
    on E: Exception do
    begin
      LogError('ExampleService', '安全操作失败: ' + E.Message);
      // 安全操作不应该抛出异常
    end;
  end;
end;

procedure TExampleService.RiskyOperation;
begin
  LogInfo('ExampleService', '执行风险操作');
  
  try
    // 模拟可能失败的操作
    if Random(10) < 3 then // 30% 失败率
    begin
      raise Exception.Create('模拟的随机失败');
    end;
    
    LogInfo('ExampleService', '风险操作成功');
    
  except
    on E: Exception do
    begin
      LogError('ExampleService', '风险操作失败: ' + E.Message);
      raise; // 重新抛出异常，让调用者处理
    end;
  end;
end;

// 全局函数示例

procedure PerformSystemOperation;
begin
  LogInfo('System', '开始执行系统操作');
  
  try
    // 模拟系统操作
    LogDebug('System', '检查系统状态');
    LogDebug('System', '执行系统任务');
    LogDebug('System', '验证操作结果');
    
    LogInfo('System', '系统操作完成');
    
  except
    on E: Exception do
    begin
      LogCritical('System', '系统操作失败: ' + E.Message);
      raise;
    end;
  end;
end;

procedure LogUserAction(const AAction: string);
begin
  // 记录用户操作 - 通常使用 Info 级别
  LogInfoFormat('UserAction', '用户执行: %s', [AAction]);
end;

procedure HandleApplicationError(const AError: Exception);
begin
  // 处理应用程序错误 - 使用 Error 级别
  LogErrorFormat('Application', '应用程序错误: %s', [AError.Message]);
  
  // 如果是严重错误，使用 Critical 级别
  if AError is EAccessViolation then
  begin
    LogCritical('Application', '发生访问违例，应用程序可能不稳定');
  end;
  
  // 记录错误堆栈（如果可用）
  LogDebugFormat('Application', '错误堆栈: %s', [AError.StackTrace]);
end;

// 初始化函数 - 在应用程序启动时调用
procedure InitializeLoggerExample;
begin
  LogInfo('LoggerExample', '日志示例模块已初始化');
  
  // 演示不同级别的日志
  LogDebug('LoggerExample', '这是调试信息 - 只在调试模式下可见');
  LogInfo('LoggerExample', '这是一般信息 - 总是可见');
  LogWarning('LoggerExample', '这是警告信息 - 表示潜在问题');
  LogError('LoggerExample', '这是错误信息 - 表示发生了错误');
  LogCritical('LoggerExample', '这是严重错误 - 表示系统级问题');
  
  // 演示格式化日志
  LogInfoFormat('LoggerExample', '当前时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
  LogInfoFormat('LoggerExample', '应用程序版本: %s, 构建模式: %s', 
    ['1.0.0', {$IFDEF DEBUG}'Debug'{$ELSE}'Release'{$ENDIF}]);
end;

// 清理函数 - 在应用程序关闭时调用
procedure CleanupLoggerExample;
begin
  LogInfo('LoggerExample', '日志示例模块正在清理');
  
  // 确保所有日志都被写入
  TUnifiedLogger.Instance.Flush;
end;

end.
