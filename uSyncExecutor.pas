unit uSyncExecutor;

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
    FCancellationToken: TCancellationTokenSource;
    FProgressLock: TCriticalSection;
    FCurrentProgress: TSyncProgressInfo;
    FStopwatch: TStopwatch;
    FLastProgressUpdate: TDateTime;
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
    
    // 异步执行
    procedure ExecuteSyncAsync(const ASourcePath, ATargetPath: string; 
      const ARecommendations: TArray<TSyncRecommendation>);
    
    // 批量操作
    function ExecuteBatchOperations(const AOperations: TArray<TSyncRecommendation>): TSyncProgressInfo;
    
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

{ TSyncExecutor }

constructor TSyncExecutor.Create;
begin
  inherited Create;
  FFileSyncComparer := TFileSyncComparer.Create;
  FCancellationToken := T CancellationTokenSource.Create;
  FProgressLock := TCriticalSection.Create;
  FIsRunning := False;
  FIsPaused := False;
  FStopwatch := TStopwatch.Create;
  
  // 初始化进度信息
  FillChar(FCurrentProgress, SizeOf(FCurrentProgress), 0);
  FLastProgressUpdate := Now;
end;

destructor TSyncExecutor.Destroy;
begin
  CancelSync;
  FreeAndNil(FStopwatch);
  FreeAndNil(FProgressLock);
  FreeAndNil(FCancellationToken);
  FreeAndNil(FFileSyncComparer);
  inherited Destroy;
end;

procedure TSyncExecutor.UpdateProgress(const AOperation: string; const ACurrentFile: string);
begin
  FProgressLock.Enter;
  try
    FCurrentProgress.CurrentOperation := AOperation;
    FCurrentProgress.CurrentFile := ACurrentFile;
    
    // 计算百分比
    if FCurrentProgress.TotalFiles > 0 then
      FCurrentProgress.PercentComplete := FCurrentProgress.ProcessedFiles * 100.0 / FCurrentProgress.TotalFiles
    else
      FCurrentProgress.PercentComplete := 0.0;
    
    // 计算传输速度和预计剩余时间
    if FStopwatch.IsRunning then
    begin
      var ElapsedSeconds := FStopwatch.Elapsed.TotalSeconds;
      if ElapsedSeconds > 0 then
      begin
        FCurrentProgress.Speed := Trunc(FCurrentProgress.BytesTransferred / ElapsedSeconds);
        CalculateEstimatedTime;
      end;
    end;
    
    // 限制进度更新频率（最多每100ms更新一次）
    if (Now - FLastProgressUpdate).TotalMilliseconds > 100 then
    begin
      if Assigned(FOnProgress) then
        FOnProgress(FCurrentProgress);
      FLastProgressUpdate := Now;
    end;
  finally
    FProgressLock.Leave;
  end;
end;

procedure TSyncExecutor.CalculateEstimatedTime;
begin
  if FCurrentProgress.Speed > 0 then
  begin
    var RemainingBytes := FCurrentProgress.TotalBytes - FCurrentProgress.BytesTransferred;
    var RemainingSeconds := RemainingBytes / FCurrentProgress.Speed;
    FCurrentProgress.EstimatedTimeRemaining := TTimeSpan.FromSeconds(RemainingSeconds);
  end
  else
  begin
    FCurrentProgress.EstimatedTimeRemaining := TTimeSpan.Zero;
  end;
end;

function TSyncExecutor.CreateDirectoryRecursive(const APath: string): Boolean;
begin
  try
    if not TDirectory.Exists(APath) then
      TDirectory.CreateDirectory(APath);
    Result := True;
  except
    Result := False;
  end;
end;

function TSyncExecutor.CopyFileWithProgress(const ASource, ATarget: string): TSyncOperationResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  BytesRead, BytesWritten: Int64;
  TotalBytes, CopiedBytes: Int64;
  CopyStopwatch: TStopwatch;
begin
  Result.Success := False;
  Result.Operation := '复制文件';
  Result.FilePath := ATarget;
  Result.ErrorMessage := '';
  Result.ErrorCode := 0;
  Result.BytesTransferred := 0;
  CopyStopwatch := TStopwatch.StartNew;
  
  try
    // 确保目标目录存在
    var TargetDir := ExtractFileDir(ATarget);
    if not CreateDirectoryRecursive(TargetDir) then
    begin
      Result.ErrorMessage := '无法创建目标目录: ' + TargetDir;
      Result.ErrorCode := GetLastError;
      Exit;
    end;
    
    // 打开文件流
    SourceStream := TFileStream.Create(ASource, fmOpenRead or fmShareDenyWrite);
    try
      TargetStream := TFileStream.Create(ATarget, fmCreate or fmShareDenyWrite);
      try
        TotalBytes := SourceStream.Size;
        SetLength(Buffer, 64 * 1024); // 64KB buffer
        CopiedBytes := 0;
        
        // 复制文件内容
        while CopiedBytes < TotalBytes do
        begin
          if FCancellationToken.IsCancellationRequested then
          begin
            Result.ErrorMessage := '操作被取消';
            Exit;
          end;
          
          BytesRead := SourceStream.Read(Buffer[0], Length(Buffer));
          if BytesRead = 0 then Break;
          
          BytesWritten := TargetStream.Write(Buffer[0], BytesRead);
          Inc(CopiedBytes, BytesWritten);
          Result.BytesTransferred := CopiedBytes;
          
          // 更新进度
          UpdateProgress('复制文件', ASource);
        end;
        
        // 保持文件时间戳
        var SourceInfo := TFileInfo.Create(ASource);
        try
          TFile.SetLastWriteTime(ATarget, SourceInfo.LastWriteTime);
          TFile.SetCreationTime(ATarget, SourceInfo.CreationTime);
        finally
          SourceInfo.Free;
        end;
        
        Result.Success := True;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Result.ErrorCode := GetLastError;
    end;
  end;
  
  Result.Duration := CopyStopwatch.Elapsed;
end;

function TSyncExecutor.UpdateFileWithProgress(const ASource, ATarget: string): TSyncOperationResult;
begin
  // 更新文件本质上就是复制（覆盖）
  Result := CopyFileWithProgress(ASource, ATarget);
  Result.Operation := '更新文件';
end;

function TSyncExecutor.DeleteFileWithProgress(const AFilePath: string): TSyncOperationResult;
var
  DeleteStopwatch: TStopwatch;
begin
  Result.Success := False;
  Result.Operation := '删除文件';
  Result.FilePath := AFilePath;
  Result.ErrorMessage := '';
  Result.ErrorCode := 0;
  Result.BytesTransferred := 0;
  DeleteStopwatch := TStopwatch.StartNew;
  
  try
    if TFile.Exists(AFilePath) then
    begin
      TFile.Delete(AFilePath);
      Result.Success := True;
    end
    else
    begin
      Result.Success := True; // 文件不存在也算成功
      Result.ErrorMessage := '文件不存在';
    end;
    
    UpdateProgress('删除文件', AFilePath);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Result.ErrorCode := GetLastError;
    end;
  end;
  
  Result.Duration := DeleteStopwatch.Elapsed;
end;

function TSyncExecutor.ExecuteSyncOperation(const ARecommendation: TSyncRecommendation): TSyncOperationResult;
begin
  Result.Success := False;
  
  case ARecommendation.RecommendedAction of
    saCopyToTarget, saUpdateTarget:
      begin
        if ARecommendation.Diff.SourceFullPath <> '' then
          Result := CopyFileWithProgress(ARecommendation.Diff.SourceFullPath, ARecommendation.Diff.TargetFullPath);
      end;
      
    saCopyToSource, saUpdateSource:
      begin
        if ARecommendation.Diff.TargetFullPath <> '' then
          Result := CopyFileWithProgress(ARecommendation.Diff.TargetFullPath, ARecommendation.Diff.SourceFullPath);
      end;
      
    saDeleteFromTarget:
      begin
        Result := DeleteFileWithProgress(ARecommendation.Diff.TargetFullPath);
      end;
      
    saDeleteFromSource:
      begin
        Result := DeleteFileWithProgress(ARecommendation.Diff.SourceFullPath);
      end;
      
    saSkip:
      begin
        Result.Success := True;
        Result.Operation := '跳过文件';
        Result.FilePath := ARecommendation.Diff.RelativePath;
        Result.ErrorMessage := '无需同步';
      end;
      
    saAskUser:
      begin
        Result.Success := False;
        Result.Operation := '需要用户确认';
        Result.FilePath := ARecommendation.Diff.RelativePath;
        Result.ErrorMessage := '需要用户手动处理冲突: ' + ARecommendation.Explanation;
      end;
  end;
  
  // 触发操作事件
  if Assigned(FOnOperation) then
    FOnOperation(Result);
end;

function TSyncExecutor.ExecuteSync(const ASourcePath, ATargetPath: string; 
  const ARecommendations: TArray<TSyncRecommendation>): TSyncProgressInfo;
var
  I: Integer;
  OperationResult: TSyncOperationResult;
begin
  // 初始化进度
  FProgressLock.Enter;
  try
    FillChar(FCurrentProgress, SizeOf(FCurrentProgress), 0);
    FCurrentProgress.TotalFiles := Length(ARecommendations);
    FCurrentProgress.TotalBytes := ARecommendations.Sum(function(const Rec: TSyncRecommendation): Int64
      begin
        Result := Rec.Diff.SourceSize + Rec.Diff.TargetSize;
      end);
  finally
    FProgressLock.Leave;
  end;
  
  FIsRunning := True;
  FStopwatch.Restart;
  
  try
    UpdateProgress('开始同步', '');
    
    // 执行所有同步操作
    for I := 0 to High(ARecommendations) do
    begin
      if FCancellationToken.IsCancellationRequested then
      begin
        Break;
      end;
      
      OperationResult := ExecuteSyncOperation(ARecommendations[I]);
      
      // 更新统计
      FProgressLock.Enter;
      try
        Inc(FCurrentProgress.ProcessedFiles);
        Inc(FCurrentProgress.BytesTransferred, OperationResult.BytesTransferred);
        
        if OperationResult.Success then
        begin
          case ARecommendations[I].RecommendedAction of
            saCopyToTarget, saCopyToSource:
              Inc(FCurrentProgress.CopiedFiles);
            saUpdateTarget, saUpdateSource:
              Inc(FCurrentProgress.UpdatedFiles);
            saDeleteFromTarget, saDeleteFromSource:
              Inc(FCurrentProgress.DeletedFiles);
            saSkip:
              Inc(FCurrentProgress.SkippedFiles);
          end;
        end
        else
        begin
          Inc(FCurrentProgress.ErrorFiles);
        end;
      finally
        FProgressLock.Leave;
      end;
    end;
    
    FIsRunning := False;
    FStopwatch.Stop;
    
    // 完成回调
    if Assigned(FOnCompleted) then
      FOnCompleted(not FCancellationToken.IsCancellationRequested, FormatSummary(FCurrentProgress));
    
    Result := FCurrentProgress;
  except
    on E: Exception do
    begin
      FIsRunning := False;
      FStopwatch.Stop;
      
      if Assigned(FOnCompleted) then
        FOnCompleted(False, '同步过程中发生错误: ' + E.Message);
      
      Result := FCurrentProgress;
    end;
  end;
end;

procedure TSyncExecutor.ExecuteSyncAsync(const ASourcePath, ATargetPath: string; 
  const ARecommendations: TArray<TSyncRecommendation>);
begin
  TTask.Run(procedure
  begin
    ExecuteSync(ASourcePath, ATargetPath, ARecommendations);
  end);
end;

function TSyncExecutor.ExecuteBatchOperations(const AOperations: TArray<TSyncRecommendation>): TSyncProgressInfo;
begin
  // 批量操作与普通同步相同，只是路径可能不同
  Result := ExecuteSync('', '', AOperations);
end;

procedure TSyncExecutor.CancelSync;
begin
  if FIsRunning then
  begin
    FCancellationToken.Cancel;
    FIsRunning := False;
    FStopwatch.Stop;
  end;
end;

procedure TSyncExecutor.PauseSync;
begin
  // TODO: 实现暂停功能
  FIsPaused := True;
end;

procedure TSyncExecutor.ResumeSync;
begin
  // TODO: 实现恢复功能
  FIsPaused := False;
end;

function TSyncExecutor.FormatSummary(const AProgress: TSyncProgressInfo): string;
begin
  Result := Format(
    '同步完成 - 总计: %d, 复制: %d, 更新: %d, 删除: %d, 跳过: %d, 错误: %d, 传输: %s',
    [
      AProgress.TotalFiles,
      AProgress.CopiedFiles,
      AProgress.UpdatedFiles,
      AProgress.DeletedFiles,
      AProgress.SkippedFiles,
      AProgress.ErrorFiles,
      FormatBytes(AProgress.BytesTransferred)
    ]
  );
end;

function TSyncExecutor.FormatBytes(const ABytes: Int64): string;
const
  KB = 1024;
  MB = 1024 * KB;
  GB = 1024 * MB;
  TB = 1024 * GB;
begin
  if ABytes < KB then
    Result := Format('%d B', [ABytes])
  else if ABytes < MB then
    Result := Format('%.1f KB', [ABytes / KB])
  else if ABytes < GB then
    Result := Format('%.1f MB', [ABytes / MB])
  else if ABytes < TB then
    Result := Format('%.1f GB', [ABytes / GB])
  else
    Result := Format('%.1f TB', [ABytes / TB]);
end;

end.
