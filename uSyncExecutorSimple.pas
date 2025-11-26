unit uSyncExecutorSimple;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.SyncObjs, uFileSyncComparerSimple, uSyncDatabase;

type
  // 同步进度信息
  TSyncProgressInfo = record
    CurrentOperation: string;
    CurrentFile: string;
    TotalFiles: Integer;
    ProcessedFiles: Integer;
    CopiedFiles: Integer;
    UpdatedFiles: Integer;
    DeletedFiles: Integer;
    SkippedFiles: Integer;
    ErrorFiles: Integer;
    PercentComplete: Double;
    BytesTransferred: Int64;
    TotalBytes: Int64;
    EstimatedTimeRemaining: Double; // 以秒为单位
    Speed: Int64; // bytes per second
  end;
  
  // 同步操作结果
  TSyncOperationResult = record
    Success: Boolean;
    Operation: string;
    FilePath: string;
    ErrorMessage: string;
    ErrorCode: Integer;
    Duration: Double; // 以秒为单位
    BytesTransferred: Int64;
  end;
  
  // 同步执行事件
  TSyncProgressEvent = procedure(const AProgress: TSyncProgressInfo) of object;
  TSyncOperationEvent = procedure(const AResult: TSyncOperationResult) of object;
  TSyncCompletedEvent = procedure(const ASuccess: Boolean; const ASummary: string) of object;

type
  TSyncExecutor = class
  private
    FFileSyncComparer: TFileSyncComparer;
    FProgressLock: TCriticalSection;
    FCurrentProgress: TSyncProgressInfo;
    FStartTime: TDateTime;
    FIsRunning: Boolean;
    FIsPaused: Boolean;
    
    // 事件
    FOnProgress: TSyncProgressEvent;
    FOnOperation: TSyncOperationEvent;
    FOnCompleted: TSyncCompletedEvent;
    
    // 内部方法
    function ExecuteSyncOperation(const ARecommendation: TSyncRecommendation): TSyncOperationResult;
    function CopyFileWithProgress(const ASource, ATarget: string): TSyncOperationResult;
    function UpdateFileWithProgress(const ASource, ATarget: string): TSyncOperationResult;
    function DeleteFileWithProgress(const AFilePath: string): TSyncOperationResult;
    function CreateDirectoryRecursive(const APath: string): Boolean;
    procedure UpdateProgress(const AOperation: string; const ACurrentFile: string);
    procedure CalculateEstimatedTime;
    function FormatSummary(const AProgress: TSyncProgressInfo): string;
    function FormatBytes(const ABytes: Int64): string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要执行功能
    function ExecuteSync(const ASourcePath, ATargetPath: string; 
      const ARecommendations: TArray<TSyncRecommendation>): TSyncProgressInfo;
    
    // 控制功能
    procedure CancelSync;
    procedure PauseSync;
    procedure ResumeSync;
    
    // 属性
    property IsRunning: Boolean read FIsRunning;
    property IsPaused: Boolean read FIsPaused;
    property CurrentProgress: TSyncProgressInfo read FCurrentProgress;
    
    // 事件
    property OnProgress: TSyncProgressEvent read FOnProgress write FOnProgress;
    property OnOperation: TSyncOperationEvent read FOnOperation write FOnOperation;
    property OnCompleted: TSyncCompletedEvent read FOnCompleted write FOnCompleted;
  end;

implementation

constructor TSyncExecutor.Create;
begin
  inherited Create;
  FFileSyncComparer := TFileSyncComparer.Create;
  FProgressLock := TCriticalSection.Create;
  FIsRunning := False;
  FIsPaused := False;
  
  // 初始化进度信息
  FCurrentProgress.CurrentOperation := '';
  FCurrentProgress.CurrentFile := '';
  FCurrentProgress.TotalFiles := 0;
  FCurrentProgress.ProcessedFiles := 0;
  FCurrentProgress.CopiedFiles := 0;
  FCurrentProgress.UpdatedFiles := 0;
  FCurrentProgress.DeletedFiles := 0;
  FCurrentProgress.SkippedFiles := 0;
  FCurrentProgress.ErrorFiles := 0;
  FCurrentProgress.PercentComplete := 0.0;
  FCurrentProgress.BytesTransferred := 0;
  FCurrentProgress.TotalBytes := 0;
  FCurrentProgress.EstimatedTimeRemaining := 0.0;
  FCurrentProgress.Speed := 0;
end;

destructor TSyncExecutor.Destroy;
begin
  FProgressLock.Free;
  FFileSyncComparer.Free;
  inherited Destroy;
end;

function TSyncExecutor.ExecuteSync(const ASourcePath, ATargetPath: string; 
  const ARecommendations: TArray<TSyncRecommendation>): TSyncProgressInfo;
var
  I: Integer;
  OperationResult: TSyncOperationResult;
  TotalBytes: Int64;
begin
  if FIsRunning then
    raise Exception.Create('同步操作已在运行中');
    
  FIsRunning := True;
  FIsPaused := False;
  FStartTime := Now;
  
  try
    // 初始化进度
    FCurrentProgress.TotalFiles := Length(ARecommendations);
    FCurrentProgress.ProcessedFiles := 0;
    FCurrentProgress.CopiedFiles := 0;
    FCurrentProgress.UpdatedFiles := 0;
    FCurrentProgress.DeletedFiles := 0;
    FCurrentProgress.SkippedFiles := 0;
    FCurrentProgress.ErrorFiles := 0;
    FCurrentProgress.BytesTransferred := 0;
    FCurrentProgress.TotalBytes := 0;
    
    // 计算总字节数
    TotalBytes := 0;
    for I := 0 to High(ARecommendations) do
    begin
      if TFile.Exists(ARecommendations[I].Diff.SourceFullPath) then
        TotalBytes := TotalBytes + TFile.GetSize(ARecommendations[I].Diff.SourceFullPath);
    end;
    FCurrentProgress.TotalBytes := TotalBytes;
    
    UpdateProgress('开始同步', '');
    
    // 执行同步操作
    for I := 0 to High(ARecommendations) do
    begin
      if FIsPaused then
      begin
        while FIsPaused do
          Sleep(100);
      end;
      
      OperationResult := ExecuteSyncOperation(ARecommendations[I]);
      
      if OperationResult.Success then
      begin
        case ARecommendations[I].RecommendedAction of
          saCopyToTarget: Inc(FCurrentProgress.CopiedFiles);
          saUpdateTarget: Inc(FCurrentProgress.UpdatedFiles);
          saDeleteFromTarget: Inc(FCurrentProgress.DeletedFiles);
          saSkip: Inc(FCurrentProgress.SkippedFiles);
        else
          Inc(FCurrentProgress.SkippedFiles);
        end;
        
        FCurrentProgress.BytesTransferred := FCurrentProgress.BytesTransferred + OperationResult.BytesTransferred;
      end
      else
      begin
        Inc(FCurrentProgress.ErrorFiles);
      end;
      
      Inc(FCurrentProgress.ProcessedFiles);
      FCurrentProgress.PercentComplete := (FCurrentProgress.ProcessedFiles * 100.0) / FCurrentProgress.TotalFiles;
      
      CalculateEstimatedTime;
      
      // 触发进度事件
      if Assigned(FOnProgress) then
        FOnProgress(FCurrentProgress);
        
      // 触发操作事件
      if Assigned(FOnOperation) then
        FOnOperation(OperationResult);
    end;
    
    UpdateProgress('同步完成', '');
    
    // 触发完成事件
    if Assigned(FOnCompleted) then
      FOnCompleted(FCurrentProgress.ErrorFiles = 0, FormatSummary(FCurrentProgress));
      
    Result := FCurrentProgress;
    
  finally
    FIsRunning := False;
  end;
end;

function TSyncExecutor.ExecuteSyncOperation(const ARecommendation: TSyncRecommendation): TSyncOperationResult;
begin
  Result.Success := True;
  Result.Operation := '';
  Result.FilePath := '';
  Result.ErrorMessage := '';
  Result.ErrorCode := 0;
  Result.Duration := 0;
  Result.BytesTransferred := 0;
  
  try
    case ARecommendation.RecommendedAction of
      saCopyToTarget:
        begin
          Result.Operation := '复制文件';
          Result.FilePath := ARecommendation.Diff.SourceFullPath;
          Result := CopyFileWithProgress(ARecommendation.Diff.SourceFullPath, ARecommendation.Diff.TargetFullPath);
        end;
        
      saUpdateTarget:
        begin
          Result.Operation := '更新文件';
          Result.FilePath := ARecommendation.Diff.SourceFullPath;
          Result := UpdateFileWithProgress(ARecommendation.Diff.SourceFullPath, ARecommendation.Diff.TargetFullPath);
        end;
        
      saDeleteFromTarget:
        begin
          Result.Operation := '删除文件';
          Result.FilePath := ARecommendation.Diff.TargetFullPath;
          Result := DeleteFileWithProgress(ARecommendation.Diff.TargetFullPath);
        end;
        
      saSkip:
        begin
          Result.Operation := '跳过文件';
          Result.FilePath := ARecommendation.Diff.SourceFullPath;
          Result.Success := True;
        end;
        
      saAskUser:
        begin
          Result.Operation := '用户确认';
          Result.FilePath := ARecommendation.Diff.SourceFullPath;
          Result.Success := True; // 暂时跳过，需要用户确认
        end;
    else
      Result.Operation := '未知操作';
      Result.Success := False;
      Result.ErrorMessage := '未知的同步操作类型';
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Result.ErrorCode := -1;
    end;
  end;
end;

function TSyncExecutor.CopyFileWithProgress(const ASource, ATarget: string): TSyncOperationResult;
var
  StartTime: TDateTime;
begin
  Result.Success := True;
  Result.Operation := '复制文件';
  Result.FilePath := ASource;
  Result.ErrorMessage := '';
  Result.ErrorCode := 0;
  StartTime := Now;
  
  try
    UpdateProgress('复制文件', ExtractFileName(ASource));
    
    // 确保目标目录存在
    if not CreateDirectoryRecursive(ExtractFileDir(ATarget)) then
    begin
      Result.Success := False;
      Result.ErrorMessage := '无法创建目标目录';
      Exit;
    end;
    
    // 复制文件
    if TFile.Exists(ASource) then
    begin
      TFile.Copy(ASource, ATarget, True);
      Result.BytesTransferred := TFile.GetSize(ATarget);
    end
    else
    begin
      Result.Success := False;
      Result.ErrorMessage := '源文件不存在';
    end;
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Result.ErrorCode := -1;
    end;
  end;
  
  Result.Duration := (Now - StartTime) * 24 * 60 * 60; // 转换为秒
end;

function TSyncExecutor.UpdateFileWithProgress(const ASource, ATarget: string): TSyncOperationResult;
begin
  // 更新文件和复制文件使用相同的逻辑
  Result := CopyFileWithProgress(ASource, ATarget);
  Result.Operation := '更新文件';
end;

function TSyncExecutor.DeleteFileWithProgress(const AFilePath: string): TSyncOperationResult;
var
  StartTime: TDateTime;
begin
  Result.Success := True;
  Result.Operation := '删除文件';
  Result.FilePath := AFilePath;
  Result.ErrorMessage := '';
  Result.ErrorCode := 0;
  StartTime := Now;
  
  try
    UpdateProgress('删除文件', ExtractFileName(AFilePath));
    
    if TFile.Exists(AFilePath) then
    begin
      TFile.Delete(AFilePath);
      Result.BytesTransferred := 0;
    end
    else
    begin
      Result.Success := False;
      Result.ErrorMessage := '文件不存在';
    end;
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Result.ErrorCode := -1;
    end;
  end;
  
  Result.Duration := (Now - StartTime) * 24 * 60 * 60; // 转换为秒
end;

function TSyncExecutor.CreateDirectoryRecursive(const APath: string): Boolean;
begin
  Result := True;
  try
    if not TDirectory.Exists(APath) then
      TDirectory.CreateDirectory(APath);
  except
    Result := False;
  end;
end;

procedure TSyncExecutor.UpdateProgress(const AOperation: string; const ACurrentFile: string);
begin
  FProgressLock.Enter;
  try
    FCurrentProgress.CurrentOperation := AOperation;
    FCurrentProgress.CurrentFile := ACurrentFile;
  finally
    FProgressLock.Leave;
  end;
end;

procedure TSyncExecutor.CalculateEstimatedTime;
var
  ElapsedTime: Double;
  FilesPerSecond: Double;
begin
  if FCurrentProgress.ProcessedFiles <= 0 then Exit;
  
  ElapsedTime := (Now - FStartTime) * 24 * 60 * 60; // 转换为秒
  
  if ElapsedTime > 0 then
  begin
    FilesPerSecond := FCurrentProgress.ProcessedFiles / ElapsedTime;
    FCurrentProgress.Speed := Round(FCurrentProgress.BytesTransferred / ElapsedTime);
    
    if FilesPerSecond > 0 then
      FCurrentProgress.EstimatedTimeRemaining := (FCurrentProgress.TotalFiles - FCurrentProgress.ProcessedFiles) / FilesPerSecond
    else
      FCurrentProgress.EstimatedTimeRemaining := 0;
  end;
end;

function TSyncExecutor.FormatSummary(const AProgress: TSyncProgressInfo): string;
begin
  Result := Format('同步完成 - 总计: %d, 复制: %d, 更新: %d, 删除: %d, 跳过: %d, 错误: %d, 传输: %s',
    [AProgress.TotalFiles, AProgress.CopiedFiles, AProgress.UpdatedFiles, 
     AProgress.DeletedFiles, AProgress.SkippedFiles, AProgress.ErrorFiles,
     FormatBytes(AProgress.BytesTransferred)]);
end;

function TSyncExecutor.FormatBytes(const ABytes: Int64): string;
const
  KB = 1024;
  MB = 1024 * KB;
  GB = 1024 * MB;
begin
  if ABytes < KB then
    Result := Format('%d B', [ABytes])
  else if ABytes < MB then
    Result := Format('%.1f KB', [ABytes / KB])
  else if ABytes < GB then
    Result := Format('%.1f MB', [ABytes / MB])
  else
    Result := Format('%.2f GB', [ABytes / GB]);
end;

procedure TSyncExecutor.CancelSync;
begin
  // 简化实现 - 设置标志位
  FIsRunning := False;
end;

procedure TSyncExecutor.PauseSync;
begin
  FIsPaused := True;
end;

procedure TSyncExecutor.ResumeSync;
begin
  FIsPaused := False;
end;

end.
