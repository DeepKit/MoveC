unit FileOperationEngine;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections,
  Winapi.Windows, Winapi.ShellAPI, DataTypes, ConfigManager;

type
  // 文件操作类型
  TFileOperationType = (fotCopy, fotMove, fotDelete, fotCreateLink, fotVerify);
  
  // 操作状态
  TOperationStatus = (osIdle, osRunning, osPaused, osCompleted, osFailed, osCancelled);
  
  // 进度回调事件
  TProgressCallback = procedure(const AOperation: string; AProgress: Integer; const ACurrentFile: string) of object;
  TStatusCallback = procedure(AStatus: TOperationStatus; const AMessage: string) of object;
  TErrorCallback = procedure(const AError: string; var AAction: Integer) of object; // 0=Abort, 1=Retry, 2=Skip
  
  // 文件操作项
  TFileOperation = record
    OperationType: TFileOperationType;
    SourcePath: string;
    TargetPath: string;
    Attributes: DWORD;
    Size: Int64;
    CreationTime: TFileTime;
    LastWriteTime: TFileTime;
    LastAccessTime: TFileTime;
    Checksum: string;
    Priority: Integer;
    Completed: Boolean;
    ErrorMessage: string;
  end;
  
  // 操作选项
  TOperationOptions = record
    PreserveAttributes: Boolean;
    PreserveTimestamps: Boolean;
    VerifyAfterCopy: Boolean;
    OverwriteExisting: Boolean;
    CreateBackup: Boolean;
    UseBufferedIO: Boolean;
    BufferSize: Integer;
    MaxRetries: Integer;
    RetryDelay: Integer;
    SkipLockedFiles: Boolean;
    FollowSymlinks: Boolean;
  end;
  
  // 操作统计
  TOperationStatistics = record
    TotalOperations: Integer;
    CompletedOperations: Integer;
    FailedOperations: Integer;
    SkippedOperations: Integer;
    TotalBytes: Int64;
    ProcessedBytes: Int64;
    StartTime: TDateTime;
    EndTime: TDateTime;
    ElapsedTime: Integer; // 秒
    AverageSpeed: Int64; // 字节/秒
    EstimatedTimeRemaining: Integer; // 秒
  end;
  
  // 文件操作引擎
  TFileOperationEngine = class
  private
    FConfigManager: TConfigManager;
    FOperations: TList<TFileOperation>;
    FOptions: TOperationOptions;
    FStatistics: TOperationStatistics;
    FStatus: TOperationStatus;
    FCancelled: Boolean;
    FPaused: Boolean;
    FCurrentOperation: Integer;
    FBuffer: TBytes;
    
    // 回调事件
    FOnProgress: TProgressCallback;
    FOnStatus: TStatusCallback;
    FOnError: TErrorCallback;
    
    // 内部操作方法
    function ExecuteCopyOperation(const AOperation: TFileOperation): Boolean;
    function ExecuteMoveOperation(const AOperation: TFileOperation): Boolean;
    function ExecuteDeleteOperation(const AOperation: TFileOperation): Boolean;
    function ExecuteCreateLinkOperation(const AOperation: TFileOperation): Boolean;
    function ExecuteVerifyOperation(const AOperation: TFileOperation): Boolean;
    
    // 文件操作辅助方法
    function CopyFileWithProgress(const ASource, ATarget: string; ASize: Int64): Boolean;
    function MoveFileWithProgress(const ASource, ATarget: string): Boolean;
    function DeleteFileWithProgress(const AFilePath: string): Boolean;
    function CreateSymbolicLink(const ASource, ATarget: string): Boolean;
    function CreateDirectoryJunction(const ASource, ATarget: string): Boolean;
    function VerifyFileIntegrity(const AFilePath: string; const AExpectedChecksum: string): Boolean;
    
    // 文件属性和时间戳处理
    function PreserveFileAttributes(const ASource, ATarget: string): Boolean;
    function PreserveFileTimestamps(const ASource, ATarget: string): Boolean;
    function GetFileInformation(const AFilePath: string): TFileOperation;
    function CalculateFileChecksum(const AFilePath: string): string;
    
    // 错误处理和重试
    function HandleError(const AError: string; ARetryCount: Integer): Integer;
    function RetryOperation(const AOperation: TFileOperation; AMaxRetries: Integer): Boolean;
    
    // 进度和状态更新
    procedure UpdateProgress(const AOperation: string; AProgress: Integer; const ACurrentFile: string);
    procedure UpdateStatus(AStatus: TOperationStatus; const AMessage: string);
    procedure UpdateStatistics;
    
    // 辅助方法
    function FormatBytes(ABytes: Int64): string;
    function FormatDuration(ASeconds: Integer): string;
    function GetOperationTypeString(AType: TFileOperationType): string;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // 操作管理
    procedure AddOperation(AType: TFileOperationType; const ASource, ATarget: string);
    procedure ClearOperations;
    function GetOperationCount: Integer;
    function GetOperation(AIndex: Integer): TFileOperation;
    
    // 执行控制
    function Execute: Boolean;
    procedure Pause;
    procedure Resume;
    procedure Cancel;
    function GetStatus: TOperationStatus;
    
    // 配置
    procedure SetOptions(const AOptions: TOperationOptions);
    function GetOptions: TOperationOptions;
    procedure SetDefaultOptions;
    
    // 统计和报告
    function GetStatistics: TOperationStatistics;
    function GenerateReport: string;
    function GetProgressPercentage: Integer;
    function GetEstimatedTimeRemaining: Integer;
    
    // 事件
    property OnProgress: TProgressCallback read FOnProgress write FOnProgress;
    property OnStatus: TStatusCallback read FOnStatus write FOnStatus;
    property OnError: TErrorCallback read FOnError write FOnError;
  end;

implementation

uses
  System.Hash, System.DateUtils, System.Math, Vcl.Forms;

constructor TFileOperationEngine.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FOperations := TList<TFileOperation>.Create;
  FStatus := osIdle;
  FCancelled := False;
  FPaused := False;
  FCurrentOperation := 0;
  
  SetDefaultOptions;
  SetLength(FBuffer, FOptions.BufferSize);
  
  // 初始化统计
  FillChar(FStatistics, SizeOf(FStatistics), 0);
end;

destructor TFileOperationEngine.Destroy;
begin
  FOperations.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

// 设置默认选项
procedure TFileOperationEngine.SetDefaultOptions;
begin
  FOptions.PreserveAttributes := True;
  FOptions.PreserveTimestamps := True;
  FOptions.VerifyAfterCopy := True;
  FOptions.OverwriteExisting := False;
  FOptions.CreateBackup := True;
  FOptions.UseBufferedIO := True;
  FOptions.BufferSize := 64 * 1024; // 64KB
  FOptions.MaxRetries := 3;
  FOptions.RetryDelay := 1000; // 1秒
  FOptions.SkipLockedFiles := True;
  FOptions.FollowSymlinks := False;
end;

// 添加操作
procedure TFileOperationEngine.AddOperation(AType: TFileOperationType; const ASource, ATarget: string);
var
  Operation: TFileOperation;
begin
  FillChar(Operation, SizeOf(Operation), 0);
  Operation.OperationType := AType;
  Operation.SourcePath := ASource;
  Operation.TargetPath := ATarget;
  Operation.Priority := 0;
  Operation.Completed := False;
  
  // 获取文件信息
  if FileExists(ASource) then
  begin
    var FileInfo := GetFileInformation(ASource);
    Operation.Size := FileInfo.Size;
    Operation.Attributes := FileInfo.Attributes;
    Operation.CreationTime := FileInfo.CreationTime;
    Operation.LastWriteTime := FileInfo.LastWriteTime;
    Operation.LastAccessTime := FileInfo.LastAccessTime;
    
    if FOptions.VerifyAfterCopy then
      Operation.Checksum := CalculateFileChecksum(ASource);
  end;
  
  FOperations.Add(Operation);
  
  // 更新统计
  Inc(FStatistics.TotalOperations);
  FStatistics.TotalBytes := FStatistics.TotalBytes + Operation.Size;
end;//
 清空操作列表
procedure TFileOperationEngine.ClearOperations;
begin
  FOperations.Clear;
  FillChar(FStatistics, SizeOf(FStatistics), 0);
  FCurrentOperation := 0;
end;

// 获取操作数量
function TFileOperationEngine.GetOperationCount: Integer;
begin
  Result := FOperations.Count;
end;

// 获取指定操作
function TFileOperationEngine.GetOperation(AIndex: Integer): TFileOperation;
begin
  if (AIndex >= 0) and (AIndex < FOperations.Count) then
    Result := FOperations[AIndex]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

// 执行所有操作
function TFileOperationEngine.Execute: Boolean;
var
  I: Integer;
  Operation: TFileOperation;
  Success: Boolean;
begin
  Result := True;
  
  if FOperations.Count = 0 then
    Exit;
  
  try
    FStatus := osRunning;
    FCancelled := False;
    FPaused := False;
    FStatistics.StartTime := Now;
    FStatistics.CompletedOperations := 0;
    FStatistics.FailedOperations := 0;
    FStatistics.SkippedOperations := 0;
    FStatistics.ProcessedBytes := 0;
    
    UpdateStatus(osRunning, '开始执行文件操作');
    
    for I := 0 to FOperations.Count - 1 do
    begin
      if FCancelled then
      begin
        UpdateStatus(osCancelled, '操作已取消');
        Result := False;
        Break;
      end;
      
      // 处理暂停
      while FPaused and not FCancelled do
      begin
        UpdateStatus(osPaused, '操作已暂停');
        Sleep(100);
      end;
      
      FCurrentOperation := I;
      Operation := FOperations[I];
      Success := False;
      
      try
        // 根据操作类型执行相应操作
        case Operation.OperationType of
          fotCopy: Success := ExecuteCopyOperation(Operation);
          fotMove: Success := ExecuteMoveOperation(Operation);
          fotDelete: Success := ExecuteDeleteOperation(Operation);
          fotCreateLink: Success := ExecuteCreateLinkOperation(Operation);
          fotVerify: Success := ExecuteVerifyOperation(Operation);
        end;
        
        if Success then
        begin
          Operation.Completed := True;
          Inc(FStatistics.CompletedOperations);
          FStatistics.ProcessedBytes := FStatistics.ProcessedBytes + Operation.Size;
        end
        else
        begin
          Inc(FStatistics.FailedOperations);
          Result := False;
        end;
        
        // 更新操作状态
        FOperations[I] := Operation;
        
        // 更新进度
        UpdateProgress(GetOperationTypeString(Operation.OperationType), 
          (I + 1) * 100 div FOperations.Count, Operation.SourcePath);
        
        UpdateStatistics;
        
      except
        on E: Exception do
        begin
          Operation.ErrorMessage := E.Message;
          FOperations[I] := Operation;
          Inc(FStatistics.FailedOperations);
          
          if Assigned(FOnError) then
          begin
            var Action := 0;
            FOnError(E.Message, Action);
            
            case Action of
              0: // Abort
              begin
                Result := False;
                Break;
              end;
              1: // Retry
              begin
                Dec(I); // 重试当前操作
                Continue;
              end;
              2: // Skip
              begin
                Inc(FStatistics.SkippedOperations);
                Continue;
              end;
            end;
          end
          else
          begin
            Result := False;
            Break;
          end;
        end;
      end;
    end;
    
    FStatistics.EndTime := Now;
    FStatistics.ElapsedTime := SecondsBetween(FStatistics.EndTime, FStatistics.StartTime);
    
    if FCancelled then
      FStatus := osCancelled
    else if Result then
      FStatus := osCompleted
    else
      FStatus := osFailed;
    
    UpdateStatus(FStatus, Format('操作完成。成功: %d, 失败: %d, 跳过: %d', 
      [FStatistics.CompletedOperations, FStatistics.FailedOperations, FStatistics.SkippedOperations]));
    
    // 记录操作日志
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('FILE_OPERATION', 'Batch execution', '', '', 
        Result.ToString, Format('Operations: %d, Success: %d, Failed: %d', 
        [FOperations.Count, FStatistics.CompletedOperations, FStatistics.FailedOperations]));
    end;
    
  except
    on E: Exception do
    begin
      FStatus := osFailed;
      UpdateStatus(osFailed, '执行异常: ' + E.Message);
      Result := False;
      
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('FILE_OPERATION', 'Execution error', '', '', 'ERROR', E.Message);
    end;
  end;
end;

// 暂停操作
procedure TFileOperationEngine.Pause;
begin
  FPaused := True;
  UpdateStatus(osPaused, '操作已暂停');
end;

// 恢复操作
procedure TFileOperationEngine.Resume;
begin
  FPaused := False;
  UpdateStatus(osRunning, '操作已恢复');
end;

// 取消操作
procedure TFileOperationEngine.Cancel;
begin
  FCancelled := True;
  FPaused := False;
  UpdateStatus(osCancelled, '正在取消操作...');
end;

// 获取状态
function TFileOperationEngine.GetStatus: TOperationStatus;
begin
  Result := FStatus;
end;

// 执行复制操作
function TFileOperationEngine.ExecuteCopyOperation(const AOperation: TFileOperation): Boolean;
var
  TargetDir: string;
begin
  Result := False;
  
  try
    // 确保目标目录存在
    TargetDir := ExtractFilePath(AOperation.TargetPath);
    if not DirectoryExists(TargetDir) then
      ForceDirectories(TargetDir);
    
    // 检查目标文件是否存在
    if FileExists(AOperation.TargetPath) and not FOptions.OverwriteExisting then
    begin
      if FOptions.CreateBackup then
      begin
        var BackupPath := AOperation.TargetPath + '.bak';
        if not MoveFile(PChar(AOperation.TargetPath), PChar(BackupPath)) then
          Exit;
      end
      else
        Exit;
    end;
    
    // 执行复制
    Result := CopyFileWithProgress(AOperation.SourcePath, AOperation.TargetPath, AOperation.Size);
    
    if Result then
    begin
      // 保持文件属性
      if FOptions.PreserveAttributes then
        PreserveFileAttributes(AOperation.SourcePath, AOperation.TargetPath);
      
      // 保持时间戳
      if FOptions.PreserveTimestamps then
        PreserveFileTimestamps(AOperation.SourcePath, AOperation.TargetPath);
      
      // 验证文件完整性
      if FOptions.VerifyAfterCopy and (Length(AOperation.Checksum) > 0) then
        Result := VerifyFileIntegrity(AOperation.TargetPath, AOperation.Checksum);
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('FILE_OPERATION', 'Copy error', AOperation.SourcePath, AOperation.TargetPath, 'ERROR', E.Message);
    end;
  end;
end;

// 执行移动操作
function TFileOperationEngine.ExecuteMoveOperation(const AOperation: TFileOperation): Boolean;
begin
  Result := False;
  
  try
    // 先复制文件
    if ExecuteCopyOperation(AOperation) then
    begin
      // 复制成功后删除源文件
      Result := DeleteFile(AOperation.SourcePath);
      
      if not Result then
      begin
        // 删除失败，清理目标文件
        DeleteFile(AOperation.TargetPath);
      end;
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('FILE_OPERATION', 'Move error', AOperation.SourcePath, AOperation.TargetPath, 'ERROR', E.Message);
    end;
  end;
end;

// 执行删除操作
function TFileOperationEngine.ExecuteDeleteOperation(const AOperation: TFileOperation): Boolean;
begin
  Result := False;
  
  try
    if FOptions.CreateBackup then
    begin
      var BackupPath := AOperation.SourcePath + '.deleted';
      Result := MoveFile(PChar(AOperation.SourcePath), PChar(BackupPath));
    end
    else
    begin
      Result := DeleteFileWithProgress(AOperation.SourcePath);
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('FILE_OPERATION', 'Delete error', AOperation.SourcePath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 执行创建链接操作
function TFileOperationEngine.ExecuteCreateLinkOperation(const AOperation: TFileOperation): Boolean;
begin
  Result := False;
  
  try
    // 首先尝试创建符号链接
    Result := CreateSymbolicLink(AOperation.SourcePath, AOperation.TargetPath);
    
    if not Result then
    begin
      // 符号链接失败，尝试创建目录联接
      if DirectoryExists(AOperation.SourcePath) then
        Result := CreateDirectoryJunction(AOperation.SourcePath, AOperation.TargetPath);
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('FILE_OPERATION', 'Link creation error', AOperation.SourcePath, AOperation.TargetPath, 'ERROR', E.Message);
    end;
  end;
end;

// 执行验证操作
function TFileOperationEngine.ExecuteVerifyOperation(const AOperation: TFileOperation): Boolean;
begin
  Result := False;
  
  try
    if FileExists(AOperation.SourcePath) then
    begin
      if Length(AOperation.Checksum) > 0 then
        Result := VerifyFileIntegrity(AOperation.SourcePath, AOperation.Checksum)
      else
        Result := True; // 文件存在即认为验证通过
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('FILE_OPERATION', 'Verify error', AOperation.SourcePath, '', 'ERROR', E.Message);
    end;
  end;
end;// 带进
度的文件复制
function TFileOperationEngine.CopyFileWithProgress(const ASource, ATarget: string; ASize: Int64): Boolean;
var
  SourceFile, TargetFile: TFileStream;
  BytesRead, TotalRead: Int64;
  LastProgress: Integer;
begin
  Result := False;
  TotalRead := 0;
  LastProgress := -1;
  
  try
    SourceFile := TFileStream.Create(ASource, fmOpenRead or fmShareDenyWrite);
    try
      TargetFile := TFileStream.Create(ATarget, fmCreate);
      try
        while (TotalRead < ASize) and not FCancelled do
        begin
          // 处理暂停
          while FPaused and not FCancelled do
            Sleep(100);
          
          if FCancelled then
            Break;
          
          BytesRead := SourceFile.Read(FBuffer[0], Length(FBuffer));
          if BytesRead = 0 then
            Break;
          
          TargetFile.Write(FBuffer[0], BytesRead);
          TotalRead := TotalRead + BytesRead;
          
          // 更新进度
          var Progress := (TotalRead * 100) div ASize;
          if Progress <> LastProgress then
          begin
            UpdateProgress('复制文件', Progress, ASource);
            LastProgress := Progress;
          end;
        end;
        
        Result := (TotalRead = ASize) and not FCancelled;
        
      finally
        TargetFile.Free;
      end;
    finally
      SourceFile.Free;
    end;
    
    // 如果取消或失败，删除部分复制的文件
    if not Result and FileExists(ATarget) then
      DeleteFile(ATarget);
    
  except
    on E: Exception do
    begin
      Result := False;
      if FileExists(ATarget) then
        DeleteFile(ATarget);
    end;
  end;
end;

// 带进度的文件移动
function TFileOperationEngine.MoveFileWithProgress(const ASource, ATarget: string): Boolean;
begin
  Result := False;
  
  try
    // 尝试直接移动（同一磁盘）
    if MoveFile(PChar(ASource), PChar(ATarget)) then
    begin
      Result := True;
      UpdateProgress('移动文件', 100, ASource);
    end
    else
    begin
      // 跨磁盘移动，需要复制后删除
      var FileSize := TFile.GetSize(ASource);
      if CopyFileWithProgress(ASource, ATarget, FileSize) then
      begin
        Result := DeleteFile(ASource);
        if not Result then
          DeleteFile(ATarget); // 清理
      end;
    end;
    
  except
    Result := False;
  end;
end;

// 带进度的文件删除
function TFileOperationEngine.DeleteFileWithProgress(const AFilePath: string): Boolean;
begin
  Result := False;
  
  try
    UpdateProgress('删除文件', 50, AFilePath);
    
    // 先移除只读属性
    var Attrs := GetFileAttributes(PChar(AFilePath));
    if (Attrs <> INVALID_FILE_ATTRIBUTES) and ((Attrs and FILE_ATTRIBUTE_READONLY) <> 0) then
    begin
      SetFileAttributes(PChar(AFilePath), Attrs and not FILE_ATTRIBUTE_READONLY);
    end;
    
    Result := DeleteFile(AFilePath);
    
    if Result then
      UpdateProgress('删除文件', 100, AFilePath);
    
  except
    Result := False;
  end;
end;

// 创建符号链接
function TFileOperationEngine.CreateSymbolicLink(const ASource, ATarget: string): Boolean;
var
  Flags: DWORD;
begin
  Result := False;
  
  try
    if DirectoryExists(ASource) then
      Flags := SYMBOLIC_LINK_FLAG_DIRECTORY
    else
      Flags := 0;
    
    Result := CreateSymbolicLinkW(PWideChar(ATarget), PWideChar(ASource), Flags);
    
  except
    Result := False;
  end;
end;

// 创建目录联接
function TFileOperationEngine.CreateDirectoryJunction(const ASource, ATarget: string): Boolean;
begin
  Result := False;
  
  try
    // 简化实现：使用mklink命令
    var CmdLine := Format('mklink /J "%s" "%s"', [ATarget, ASource]);
    var ExitCode := 0;
    
    if ShellExecute(0, 'open', 'cmd.exe', PChar('/C ' + CmdLine), nil, SW_HIDE) > 32 then
    begin
      Sleep(1000); // 等待命令执行
      Result := DirectoryExists(ATarget);
    end;
    
  except
    Result := False;
  end;
end;

// 验证文件完整性
function TFileOperationEngine.VerifyFileIntegrity(const AFilePath: string; const AExpectedChecksum: string): Boolean;
var
  ActualChecksum: string;
begin
  Result := False;
  
  try
    ActualChecksum := CalculateFileChecksum(AFilePath);
    Result := SameText(ActualChecksum, AExpectedChecksum);
    
  except
    Result := False;
  end;
end;

// 保持文件属性
function TFileOperationEngine.PreserveFileAttributes(const ASource, ATarget: string): Boolean;
var
  Attrs: DWORD;
begin
  Result := False;
  
  try
    Attrs := GetFileAttributes(PChar(ASource));
    if Attrs <> INVALID_FILE_ATTRIBUTES then
    begin
      Result := SetFileAttributes(PChar(ATarget), Attrs);
    end;
    
  except
    Result := False;
  end;
end;

// 保持文件时间戳
function TFileOperationEngine.PreserveFileTimestamps(const ASource, ATarget: string): Boolean;
var
  SourceHandle, TargetHandle: THandle;
  CreationTime, LastAccessTime, LastWriteTime: TFileTime;
begin
  Result := False;
  
  try
    SourceHandle := CreateFile(PChar(ASource), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
    if SourceHandle <> INVALID_HANDLE_VALUE then
    begin
      try
        if GetFileTime(SourceHandle, @CreationTime, @LastAccessTime, @LastWriteTime) then
        begin
          TargetHandle := CreateFile(PChar(ATarget), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
          if TargetHandle <> INVALID_HANDLE_VALUE then
          begin
            try
              Result := SetFileTime(TargetHandle, @CreationTime, @LastAccessTime, @LastWriteTime);
            finally
              CloseHandle(TargetHandle);
            end;
          end;
        end;
      finally
        CloseHandle(SourceHandle);
      end;
    end;
    
  except
    Result := False;
  end;
end;

// 获取文件信息
function TFileOperationEngine.GetFileInformation(const AFilePath: string): TFileOperation;
var
  FileHandle: THandle;
  FileInfo: TWin32FileAttributeData;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.SourcePath := AFilePath;
  
  try
    if GetFileAttributesEx(PChar(AFilePath), GetFileExInfoStandard, @FileInfo) then
    begin
      Result.Attributes := FileInfo.dwFileAttributes;
      Result.Size := (Int64(FileInfo.nFileSizeHigh) shl 32) or FileInfo.nFileSizeLow;
      Result.CreationTime := FileInfo.ftCreationTime;
      Result.LastWriteTime := FileInfo.ftLastWriteTime;
      Result.LastAccessTime := FileInfo.ftLastAccessTime;
    end;
    
  except
    // 使用默认值
  end;
end;

// 计算文件校验和
function TFileOperationEngine.CalculateFileChecksum(const AFilePath: string): string;
var
  FileStream: TFileStream;
  Hash: THashMD5;
begin
  Result := '';
  
  try
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      Hash := THashMD5.Create;
      Hash.Update(FileStream);
      Result := Hash.HashAsString;
    finally
      FileStream.Free;
    end;
    
  except
    Result := '';
  end;
end;

// 错误处理
function TFileOperationEngine.HandleError(const AError: string; ARetryCount: Integer): Integer;
begin
  Result := 0; // 默认中止
  
  if Assigned(FOnError) then
  begin
    FOnError(AError, Result);
  end
  else
  begin
    // 自动重试逻辑
    if ARetryCount < FOptions.MaxRetries then
    begin
      Sleep(FOptions.RetryDelay);
      Result := 1; // 重试
    end;
  end;
end;

// 重试操作
function TFileOperationEngine.RetryOperation(const AOperation: TFileOperation; AMaxRetries: Integer): Boolean;
var
  RetryCount: Integer;
begin
  Result := False;
  RetryCount := 0;
  
  while (RetryCount < AMaxRetries) and not Result and not FCancelled do
  begin
    try
      case AOperation.OperationType of
        fotCopy: Result := ExecuteCopyOperation(AOperation);
        fotMove: Result := ExecuteMoveOperation(AOperation);
        fotDelete: Result := ExecuteDeleteOperation(AOperation);
        fotCreateLink: Result := ExecuteCreateLinkOperation(AOperation);
        fotVerify: Result := ExecuteVerifyOperation(AOperation);
      end;
      
      if not Result then
      begin
        Inc(RetryCount);
        if RetryCount < AMaxRetries then
          Sleep(FOptions.RetryDelay);
      end;
      
    except
      on E: Exception do
      begin
        Inc(RetryCount);
        if RetryCount >= AMaxRetries then
          raise;
        Sleep(FOptions.RetryDelay);
      end;
    end;
  end;
end;

// 更新进度
procedure TFileOperationEngine.UpdateProgress(const AOperation: string; AProgress: Integer; const ACurrentFile: string);
begin
  if Assigned(FOnProgress) then
    FOnProgress(AOperation, AProgress, ACurrentFile);
end;

// 更新状态
procedure TFileOperationEngine.UpdateStatus(AStatus: TOperationStatus; const AMessage: string);
begin
  FStatus := AStatus;
  if Assigned(FOnStatus) then
    FOnStatus(AStatus, AMessage);
end;

// 更新统计
procedure TFileOperationEngine.UpdateStatistics;
begin
  if FStatistics.StartTime > 0 then
  begin
    FStatistics.ElapsedTime := SecondsBetween(Now, FStatistics.StartTime);
    
    if FStatistics.ElapsedTime > 0 then
    begin
      FStatistics.AverageSpeed := FStatistics.ProcessedBytes div FStatistics.ElapsedTime;
      
      var RemainingBytes := FStatistics.TotalBytes - FStatistics.ProcessedBytes;
      if FStatistics.AverageSpeed > 0 then
        FStatistics.EstimatedTimeRemaining := RemainingBytes div FStatistics.AverageSpeed
      else
        FStatistics.EstimatedTimeRemaining := 0;
    end;
  end;
end;// 配
置方法
procedure TFileOperationEngine.SetOptions(const AOptions: TOperationOptions);
begin
  FOptions := AOptions;
  
  // 重新分配缓冲区
  if FOptions.BufferSize <> Length(FBuffer) then
    SetLength(FBuffer, FOptions.BufferSize);
end;

function TFileOperationEngine.GetOptions: TOperationOptions;
begin
  Result := FOptions;
end;

// 获取统计信息
function TFileOperationEngine.GetStatistics: TOperationStatistics;
begin
  UpdateStatistics;
  Result := FStatistics;
end;

// 获取进度百分比
function TFileOperationEngine.GetProgressPercentage: Integer;
begin
  if FStatistics.TotalBytes > 0 then
    Result := (FStatistics.ProcessedBytes * 100) div FStatistics.TotalBytes
  else if FStatistics.TotalOperations > 0 then
    Result := (FStatistics.CompletedOperations * 100) div FStatistics.TotalOperations
  else
    Result := 0;
end;

// 获取预估剩余时间
function TFileOperationEngine.GetEstimatedTimeRemaining: Integer;
begin
  UpdateStatistics;
  Result := FStatistics.EstimatedTimeRemaining;
end;

// 生成报告
function TFileOperationEngine.GenerateReport: string;
var
  Report: TStringList;
  I: Integer;
  Operation: TFileOperation;
begin
  Report := TStringList.Create;
  
  try
    Report.Add('文件操作执行报告');
    Report.Add('═══════════════════════');
    Report.Add(Format('生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add('');
    
    // 统计信息
    Report.Add('执行统计:');
    Report.Add(Format('  总操作数: %d', [FStatistics.TotalOperations]));
    Report.Add(Format('  成功操作: %d', [FStatistics.CompletedOperations]));
    Report.Add(Format('  失败操作: %d', [FStatistics.FailedOperations]));
    Report.Add(Format('  跳过操作: %d', [FStatistics.SkippedOperations]));
    Report.Add(Format('  总数据量: %s', [FormatBytes(FStatistics.TotalBytes)]));
    Report.Add(Format('  已处理: %s', [FormatBytes(FStatistics.ProcessedBytes)]));
    
    if FStatistics.StartTime > 0 then
    begin
      Report.Add(Format('  开始时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', FStatistics.StartTime)]));
      if FStatistics.EndTime > 0 then
        Report.Add(Format('  结束时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', FStatistics.EndTime)]));
      Report.Add(Format('  执行时间: %s', [FormatDuration(FStatistics.ElapsedTime)]));
      
      if FStatistics.AverageSpeed > 0 then
        Report.Add(Format('  平均速度: %s/秒', [FormatBytes(FStatistics.AverageSpeed)]));
    end;
    
    Report.Add('');
    
    // 操作详情
    if FOperations.Count > 0 then
    begin
      Report.Add('操作详情:');
      Report.Add('─────────────────────────');
      
      for I := 0 to FOperations.Count - 1 do
      begin
        Operation := FOperations[I];
        Report.Add('');
        Report.Add(Format('操作 %d:', [I + 1]));
        Report.Add(Format('  类型: %s', [GetOperationTypeString(Operation.OperationType)]));
        Report.Add(Format('  源路径: %s', [Operation.SourcePath]));
        if Length(Operation.TargetPath) > 0 then
          Report.Add(Format('  目标路径: %s', [Operation.TargetPath]));
        Report.Add(Format('  大小: %s', [FormatBytes(Operation.Size)]));
        Report.Add(Format('  状态: %s', [BoolToStr(Operation.Completed, '完成', '未完成')]));
        
        if Length(Operation.ErrorMessage) > 0 then
          Report.Add(Format('  错误: %s', [Operation.ErrorMessage]));
      end;
    end;
    
    // 配置信息
    Report.Add('');
    Report.Add('配置选项:');
    Report.Add(Format('  保持属性: %s', [BoolToStr(FOptions.PreserveAttributes, True)]));
    Report.Add(Format('  保持时间戳: %s', [BoolToStr(FOptions.PreserveTimestamps, True)]));
    Report.Add(Format('  复制后验证: %s', [BoolToStr(FOptions.VerifyAfterCopy, True)]));
    Report.Add(Format('  覆盖现有文件: %s', [BoolToStr(FOptions.OverwriteExisting, True)]));
    Report.Add(Format('  创建备份: %s', [BoolToStr(FOptions.CreateBackup, True)]));
    Report.Add(Format('  缓冲区大小: %s', [FormatBytes(FOptions.BufferSize)]));
    Report.Add(Format('  最大重试次数: %d', [FOptions.MaxRetries]));
    Report.Add(Format('  重试延迟: %d 毫秒', [FOptions.RetryDelay]));
    
    Result := Report.Text;
    
  finally
    Report.Free;
  end;
end;

// 辅助方法
function TFileOperationEngine.FormatBytes(ABytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
  TB = GB * Int64(1024);
begin
  if ABytes >= TB then
    Result := Format('%.2f TB', [ABytes / TB])
  else if ABytes >= GB then
    Result := Format('%.2f GB', [ABytes / GB])
  else if ABytes >= MB then
    Result := Format('%.2f MB', [ABytes / MB])
  else if ABytes >= KB then
    Result := Format('%.2f KB', [ABytes / KB])
  else
    Result := Format('%d B', [ABytes]);
end;

function TFileOperationEngine.FormatDuration(ASeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours := ASeconds div 3600;
  Minutes := (ASeconds mod 3600) div 60;
  Seconds := ASeconds mod 60;
  
  if Hours > 0 then
    Result := Format('%d小时%d分钟%d秒', [Hours, Minutes, Seconds])
  else if Minutes > 0 then
    Result := Format('%d分钟%d秒', [Minutes, Seconds])
  else
    Result := Format('%d秒', [Seconds]);
end;

function TFileOperationEngine.GetOperationTypeString(AType: TFileOperationType): string;
begin
  case AType of
    fotCopy: Result := '复制';
    fotMove: Result := '移动';
    fotDelete: Result := '删除';
    fotCreateLink: Result := '创建链接';
    fotVerify: Result := '验证';
  else
    Result := '未知';
  end;
end;

end.