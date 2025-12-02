unit uMigrationService;

{
  单元名称: uMigrationService
  功能描述: 目录迁移服务，封装核心迁移业务逻辑
  作者: MoveC Team
  创建日期: 2025-12-01
  
  设计目标:
  - 将迁移逻辑从 TfrmMain 中解耦
  - 提供清晰的进度回调接口
  - 支持单元测试
  - 统一错误处理
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  Winapi.Windows, uMigrationTransaction, uSystemCheck, uLogManager;

type
  /// <summary>迁移状态枚举</summary>
  TMigrationState = (
    msIdle,           // 空闲
    msPreparing,      // 准备中
    msCopying,        // 复制中
    msVerifying,      // 校验中
    msBackingUp,      // 备份中
    msCreatingLink,   // 创建链接
    msCompleted,      // 完成
    msFailed,         // 失败
    msCancelled       // 已取消
  );

  /// <summary>迁移进度信息</summary>
  TMigrationProgress = record
    State: TMigrationState;
    CurrentFile: string;
    ProcessedFiles: Integer;
    TotalFiles: Integer;
    ProcessedBytes: Int64;
    TotalBytes: Int64;
    Percent: Double;
    EstimatedTimeRemaining: TDateTime;
    Message: string;
  end;

  /// <summary>迁移结果</summary>
  TMigrationResult = record
    Success: Boolean;
    State: TMigrationState;
    ErrorMessage: string;
    VerifiedCount: Integer;
    FailedCount: Integer;
    BackupDir: string;
    BackupSize: Int64;
    TotalFiles: Integer;
    TotalBytes: Int64;
    ElapsedTime: TDateTime;
  end;

  /// <summary>迁移进度回调接口</summary>
  IMigrationProgress = interface
    ['{E8F2A1B3-4C5D-6E7F-8A9B-0C1D2E3F4A5B}']
    procedure OnProgress(const Progress: TMigrationProgress);
    procedure OnStateChanged(OldState, NewState: TMigrationState);
    procedure OnError(const ErrorMessage: string);
    procedure OnComplete(const Result: TMigrationResult);
    function IsCancelRequested: Boolean;
  end;

  /// <summary>迁移配置</summary>
  TMigrationConfig = record
    SourcePath: string;
    TargetPath: string;
    VerifyFiles: Boolean;       // 是否校验文件
    CreateBackup: Boolean;      // 是否创建备份
    UseJunction: Boolean;       // 使用 Junction 还是 SymLink
    SkipInUseFiles: Boolean;    // 跳过占用的文件
    MaxRetries: Integer;        // 最大重试次数
  end;

  /// <summary>自定义迁移异常</summary>
  EMigrationException = class(Exception)
  private
    FErrorCode: Integer;
    FState: TMigrationState;
  public
    constructor Create(const AMessage: string; AErrorCode: Integer = 0; 
      AState: TMigrationState = msFailed);
    property ErrorCode: Integer read FErrorCode;
    property State: TMigrationState read FState;
  end;

  /// <summary>迁移服务类</summary>
  TMigrationService = class
  private
    FConfig: TMigrationConfig;
    FProgressCallback: IMigrationProgress;
    FTransaction: TMigrationTransaction;
    FState: TMigrationState;
    FStartTime: TDateTime;
    FCancelRequested: Boolean;
    
    // 进度统计
    FProcessedFiles: Integer;
    FTotalFiles: Integer;
    FProcessedBytes: Int64;
    FTotalBytes: Int64;
    
    procedure SetState(NewState: TMigrationState);
    procedure ReportProgress(const AMessage: string = '');
    procedure ReportError(const AMessage: string);
    function CheckCancelled: Boolean;
    
    // 核心操作
    procedure ValidatePaths;
    procedure CheckSystemRequirements;
    procedure ComputeDirectoryStats(const APath: string; 
      out AFileCount: Integer; out ATotalSize: Int64);
    function CopyDirectoryWithVerify(const ASrc, ADst: string): Boolean;
    function CopyFileWithVerify(const ASrcFile, ADstFile: string): Boolean;
    function BackupOriginalDirectory: Boolean;
    function CreateDirectoryLink(const ASource, ATarget: string): Boolean;
    function VerifyJunction(const AJunctionPath, ATargetPath: string): Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>执行迁移操作</summary>
    function Execute(const AConfig: TMigrationConfig; 
      AProgressCallback: IMigrationProgress = nil): TMigrationResult;
    
    /// <summary>请求取消操作</summary>
    procedure Cancel;
    
    /// <summary>获取当前状态</summary>
    property State: TMigrationState read FState;
    
    /// <summary>获取事务对象（用于断点续迁）</summary>
    property Transaction: TMigrationTransaction read FTransaction;
    
    /// <summary>状态转字符串</summary>
    class function StateToString(AState: TMigrationState): string;
  end;

implementation

uses
  System.Math, System.DateUtils, syncLocal.uFileHasher;

const
  // 配置常量
  PROGRESS_UPDATE_INTERVAL = 500;  // 进度更新间隔（毫秒）
  DEFAULT_MAX_RETRIES = 3;
  FILE_COPY_BUFFER_SIZE = 65536;   // 64KB

{ EMigrationException }

constructor EMigrationException.Create(const AMessage: string; 
  AErrorCode: Integer; AState: TMigrationState);
begin
  inherited Create(AMessage);
  FErrorCode := AErrorCode;
  FState := AState;
end;

{ TMigrationService }

constructor TMigrationService.Create;
begin
  inherited Create;
  FState := msIdle;
  FCancelRequested := False;
  FTransaction := nil;
end;

destructor TMigrationService.Destroy;
begin
  FreeAndNil(FTransaction);
  inherited;
end;

class function TMigrationService.StateToString(AState: TMigrationState): string;
begin
  case AState of
    msIdle: Result := '空闲';
    msPreparing: Result := '准备中';
    msCopying: Result := '复制中';
    msVerifying: Result := '校验中';
    msBackingUp: Result := '备份中';
    msCreatingLink: Result := '创建链接';
    msCompleted: Result := '已完成';
    msFailed: Result := '失败';
    msCancelled: Result := '已取消';
  else
    Result := '未知';
  end;
end;

procedure TMigrationService.SetState(NewState: TMigrationState);
var
  OldState: TMigrationState;
begin
  if FState <> NewState then
  begin
    OldState := FState;
    FState := NewState;
    LogInfo('MigrationService', Format('状态变更: %s -> %s', 
      [StateToString(OldState), StateToString(NewState)]));
    
    if Assigned(FProgressCallback) then
      FProgressCallback.OnStateChanged(OldState, NewState);
  end;
end;

procedure TMigrationService.ReportProgress(const AMessage: string);
var
  Progress: TMigrationProgress;
  ElapsedSeconds: Double;
  RemainingSeconds: Double;
begin
  Progress.State := FState;
  Progress.CurrentFile := AMessage;
  Progress.ProcessedFiles := FProcessedFiles;
  Progress.TotalFiles := FTotalFiles;
  Progress.ProcessedBytes := FProcessedBytes;
  Progress.TotalBytes := FTotalBytes;
  Progress.Message := AMessage;
  
  if FTotalBytes > 0 then
    Progress.Percent := (FProcessedBytes * 100.0) / FTotalBytes
  else if FTotalFiles > 0 then
    Progress.Percent := (FProcessedFiles * 100.0) / FTotalFiles
  else
    Progress.Percent := 0;
  
  // 估算剩余时间
  if (FProcessedBytes > 0) and (FTotalBytes > FProcessedBytes) then
  begin
    ElapsedSeconds := SecondSpan(Now, FStartTime);
    if ElapsedSeconds > 0 then
    begin
      RemainingSeconds := (ElapsedSeconds / FProcessedBytes) * (FTotalBytes - FProcessedBytes);
      Progress.EstimatedTimeRemaining := RemainingSeconds / SecsPerDay;
    end
    else
      Progress.EstimatedTimeRemaining := 0;
  end
  else
    Progress.EstimatedTimeRemaining := 0;
  
  if Assigned(FProgressCallback) then
    FProgressCallback.OnProgress(Progress);
end;

procedure TMigrationService.ReportError(const AMessage: string);
begin
  LogError('MigrationService', AMessage);
  if Assigned(FProgressCallback) then
    FProgressCallback.OnError(AMessage);
end;

function TMigrationService.CheckCancelled: Boolean;
begin
  if FCancelRequested then
  begin
    Result := True;
    Exit;
  end;
  
  if Assigned(FProgressCallback) then
    Result := FProgressCallback.IsCancelRequested
  else
    Result := False;
  
  if Result then
    FCancelRequested := True;
end;

procedure TMigrationService.Cancel;
begin
  FCancelRequested := True;
  LogInfo('MigrationService', '收到取消请求');
end;

procedure TMigrationService.ValidatePaths;
begin
  // 验证源路径
  if FConfig.SourcePath = '' then
    raise EMigrationException.Create('源路径不能为空', 1, msFailed);
  
  if not TDirectory.Exists(FConfig.SourcePath) then
    raise EMigrationException.Create('源路径不存在: ' + FConfig.SourcePath, 2, msFailed);
  
  // 验证目标路径
  if FConfig.TargetPath = '' then
    raise EMigrationException.Create('目标路径不能为空', 3, msFailed);
  
  if not TDirectory.Exists(FConfig.TargetPath) then
  begin
    try
      TDirectory.CreateDirectory(FConfig.TargetPath);
    except
      on E: Exception do
        raise EMigrationException.Create('无法创建目标路径: ' + E.Message, 4, msFailed);
    end;
  end;
  
  // 检查源和目标不能相同或嵌套
  if SameText(FConfig.SourcePath, FConfig.TargetPath) then
    raise EMigrationException.Create('源路径和目标路径不能相同', 5, msFailed);
  
  if FConfig.TargetPath.ToLower.StartsWith(FConfig.SourcePath.ToLower + PathDelim) then
    raise EMigrationException.Create('目标路径不能是源路径的子目录', 6, msFailed);
end;

procedure TMigrationService.CheckSystemRequirements;
var
  PrivCheck: TPrivilegeCheckResult;
  SpaceCheck: TDiskSpaceCheckResult;
begin
  // 检查管理员权限
  PrivCheck := TSystemCheck.CheckAdminPrivileges;
  if not PrivCheck.IsAdmin then
    LogWarning('MigrationService', '未以管理员权限运行，部分操作可能失败');
  
  // 检查磁盘空间
  SpaceCheck := TSystemCheck.CheckDiskSpace(FConfig.TargetPath, FTotalBytes);
  if not SpaceCheck.HasEnoughSpace then
    raise EMigrationException.Create(SpaceCheck.Message, 10, msFailed);
  
  // 检查源目录是否被占用
  if TSystemCheck.IsDirectoryInUse(FConfig.SourcePath) then
  begin
    if not FConfig.SkipInUseFiles then
      raise EMigrationException.Create('源目录中有文件被占用', 11, msFailed)
    else
      LogWarning('MigrationService', '源目录中有文件被占用，将跳过这些文件');
  end;
end;

procedure TMigrationService.ComputeDirectoryStats(const APath: string;
  out AFileCount: Integer; out ATotalSize: Int64);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
begin
  AFileCount := 0;
  ATotalSize := 0;
  
  try
    Files := TDirectory.GetFiles(APath);
    for I := 0 to High(Files) do
    begin
      try
        Inc(AFileCount);
        ATotalSize := ATotalSize + TFile.GetSize(Files[I]);
      except
        // 忽略无法访问的文件
      end;
    end;
    
    // 递归子目录
    Dirs := TDirectory.GetDirectories(APath);
    for I := 0 to High(Dirs) do
    begin
      var SubCount: Integer;
      var SubSize: Int64;
      ComputeDirectoryStats(Dirs[I], SubCount, SubSize);
      Inc(AFileCount, SubCount);
      ATotalSize := ATotalSize + SubSize;
    end;
  except
    // 忽略访问权限错误
  end;
end;

function TMigrationService.CopyFileWithVerify(const ASrcFile, ADstFile: string): Boolean;
var
  SrcHash, DstHash: string;
  FileSize: Int64;
  RetryCount: Integer;
begin
  Result := False;
  RetryCount := 0;
  
  while RetryCount < FConfig.MaxRetries do
  begin
    try
      // 复制文件
      TFile.Copy(ASrcFile, ADstFile, True);
      FileSize := TFile.GetSize(ASrcFile);
      
      // 校验文件
      if FConfig.VerifyFiles then
      begin
        SrcHash := TFileHasher.ComputeSHA256(ASrcFile, hoSampleHash);
        DstHash := TFileHasher.ComputeSHA256(ADstFile, hoSampleHash);
        
        if not SameText(SrcHash, DstHash) then
        begin
          Inc(RetryCount);
          LogWarning('MigrationService', Format('文件校验失败，重试 %d/%d: %s', 
            [RetryCount, FConfig.MaxRetries, ASrcFile]));
          Continue;
        end;
      end;
      
      // 记录到事务
      if Assigned(FTransaction) then
      begin
        FTransaction.AddFileRecord(ASrcFile, ADstFile, FileSize, SrcHash);
        FTransaction.UpdateFileRecord(ASrcFile, SrcHash, True);
      end;
      
      // 更新统计
      Inc(FProcessedFiles);
      FProcessedBytes := FProcessedBytes + FileSize;
      
      Result := True;
      Exit;
      
    except
      on E: Exception do
      begin
        Inc(RetryCount);
        if RetryCount < FConfig.MaxRetries then
          LogWarning('MigrationService', Format('复制失败，重试 %d/%d: %s - %s', 
            [RetryCount, FConfig.MaxRetries, ASrcFile, E.Message]))
        else
        begin
          LogError('MigrationService', Format('复制最终失败: %s - %s', [ASrcFile, E.Message]));
          if Assigned(FTransaction) then
            FTransaction.MarkFileError(ASrcFile, E.Message);
        end;
      end;
    end;
  end;
end;

function TMigrationService.CopyDirectoryWithVerify(const ASrc, ADst: string): Boolean;
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
  SrcFile, DstFile, SubDir, DstSubDir: string;
  LastProgressUpdate: TDateTime;
begin
  Result := True;
  LastProgressUpdate := Now;
  
  // 确保目标目录存在
  if not TDirectory.Exists(ADst) then
    TDirectory.CreateDirectory(ADst);
  
  // 复制文件
  try
    Files := TDirectory.GetFiles(ASrc);
  except
    on E: Exception do
    begin
      ReportError('无法访问目录: ' + ASrc + ' - ' + E.Message);
      Exit(False);
    end;
  end;
  
  for I := 0 to High(Files) do
  begin
    if CheckCancelled then
    begin
      SetState(msCancelled);
      Exit(False);
    end;
    
    SrcFile := Files[I];
    DstFile := TPath.Combine(ADst, ExtractFileName(SrcFile));
    
    // 更新进度（每500ms）
    if MilliSecondsBetween(Now, LastProgressUpdate) >= PROGRESS_UPDATE_INTERVAL then
    begin
      ReportProgress(SrcFile);
      LastProgressUpdate := Now;
    end;
    
    if not CopyFileWithVerify(SrcFile, DstFile) then
      Result := False;  // 继续复制其他文件
  end;
  
  // 递归复制子目录
  try
    Dirs := TDirectory.GetDirectories(ASrc);
  except
    Exit(Result);  // 无法获取子目录，返回当前状态
  end;
  
  for I := 0 to High(Dirs) do
  begin
    if CheckCancelled then
    begin
      SetState(msCancelled);
      Exit(False);
    end;
    
    SubDir := ExtractFileName(Dirs[I]);
    DstSubDir := TPath.Combine(ADst, SubDir);
    
    if not CopyDirectoryWithVerify(Dirs[I], DstSubDir) then
      Result := False;
  end;
end;

function TMigrationService.BackupOriginalDirectory: Boolean;
var
  ErrorMsg: string;
begin
  Result := False;
  
  if not Assigned(FTransaction) then
    Exit;
  
  if TSystemCheck.TryRenameDirectory(FConfig.SourcePath, 
    FTransaction.BackupDir, ErrorMsg) then
  begin
    LogInfo('MigrationService', '已备份原目录到: ' + FTransaction.BackupDir);
    Result := True;
  end
  else
  begin
    ReportError('备份原目录失败: ' + ErrorMsg);
    Result := False;
  end;
end;

function TMigrationService.CreateDirectoryLink(const ASource, ATarget: string): Boolean;
var
  Command: string;
begin
  Result := False;
  
  // 优先使用 Junction
  if FConfig.UseJunction then
    Command := Format('cmd /c mklink /J "%s" "%s"', [ASource, ATarget])
  else
    Command := Format('cmd /c mklink /D "%s" "%s"', [ASource, ATarget]);
  
  LogInfo('MigrationService', '创建链接: ' + Command);
  
  if WinExec(PAnsiChar(AnsiString(Command)), SW_HIDE) > 31 then
  begin
    Sleep(1000);  // 等待命令执行
    Result := TDirectory.Exists(ASource);
  end;
  
  if not Result and FConfig.UseJunction then
  begin
    // Junction 失败，尝试符号链接
    Command := Format('cmd /c mklink /D "%s" "%s"', [ASource, ATarget]);
    LogInfo('MigrationService', '尝试符号链接: ' + Command);
    
    if WinExec(PAnsiChar(AnsiString(Command)), SW_HIDE) > 31 then
    begin
      Sleep(1000);
      Result := TDirectory.Exists(ASource);
    end;
  end;
  
  if Result then
    LogInfo('MigrationService', '链接创建成功')
  else
    LogError('MigrationService', '链接创建失败');
end;

function TMigrationService.VerifyJunction(const AJunctionPath, ATargetPath: string): Boolean;
var
  TestFile, TargetTestFile: string;
  TestContent: string;
begin
  Result := False;
  
  // 检查链接目录是否存在
  if not TDirectory.Exists(AJunctionPath) then
  begin
    LogError('MigrationService', '链接目录不存在: ' + AJunctionPath);
    Exit;
  end;
  
  // 创建测试文件验证读写
  TestFile := TPath.Combine(AJunctionPath, '_verify_test.tmp');
  TestContent := 'Junction verification - ' + DateTimeToStr(Now);
  
  try
    TFile.WriteAllText(TestFile, TestContent);
    
    // 验证文件在目标目录中
    TargetTestFile := TPath.Combine(ATargetPath, '_verify_test.tmp');
    if TFile.Exists(TargetTestFile) then
    begin
      if TFile.ReadAllText(TargetTestFile) = TestContent then
      begin
        Result := True;
        LogInfo('MigrationService', 'Junction 验证成功');
      end;
    end;
    
    // 清理测试文件
    if TFile.Exists(TestFile) then
      TFile.Delete(TestFile);
  except
    on E: Exception do
      LogError('MigrationService', 'Junction 验证失败: ' + E.Message);
  end;
end;

function TMigrationService.Execute(const AConfig: TMigrationConfig;
  AProgressCallback: IMigrationProgress): TMigrationResult;
var
  DstDir: string;
  BackupFileCount: Integer;
begin
  // 初始化
  FConfig := AConfig;
  FProgressCallback := AProgressCallback;
  FCancelRequested := False;
  FStartTime := Now;
  FProcessedFiles := 0;
  FProcessedBytes := 0;
  
  // 设置默认值
  if FConfig.MaxRetries <= 0 then
    FConfig.MaxRetries := DEFAULT_MAX_RETRIES;
  
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.Success := False;
  
  LogInfo('MigrationService', '开始迁移操作');
  LogInfo('MigrationService', '源路径: ' + FConfig.SourcePath);
  LogInfo('MigrationService', '目标路径: ' + FConfig.TargetPath);
  
  try
    // 阶段1: 准备
    SetState(msPreparing);
    ReportProgress('验证路径...');
    ValidatePaths;
    
    // 计算目标目录
    DstDir := TPath.Combine(FConfig.TargetPath, 
      ExtractFileName(ExcludeTrailingPathDelimiter(FConfig.SourcePath)));
    
    // 统计文件
    ReportProgress('统计文件...');
    ComputeDirectoryStats(FConfig.SourcePath, FTotalFiles, FTotalBytes);
    Result.TotalFiles := FTotalFiles;
    Result.TotalBytes := FTotalBytes;
    
    LogInfo('MigrationService', Format('共 %d 个文件，总大小 %s', 
      [FTotalFiles, TSystemCheck.FormatBytes(FTotalBytes)]));
    
    // 系统检查
    ReportProgress('系统检查...');
    CheckSystemRequirements;
    
    if CheckCancelled then
    begin
      SetState(msCancelled);
      Result.State := msCancelled;
      Exit;
    end;
    
    // 创建事务
    FreeAndNil(FTransaction);
    FTransaction := TMigrationTransaction.Create;
    FTransaction.StartTransaction(FConfig.SourcePath, DstDir);
    FTransaction.UpdateProgress(0, FTotalFiles, 0, FTotalBytes);
    
    // 阶段2: 复制
    SetState(msCopying);
    ReportProgress('复制文件...');
    
    if not CopyDirectoryWithVerify(FConfig.SourcePath, DstDir) then
    begin
      if FState = msCancelled then
      begin
        FTransaction.FailTransaction('用户取消');
        Result.State := msCancelled;
        // 清理已复制的文件
        if TDirectory.Exists(DstDir) then
          TDirectory.Delete(DstDir, True);
        Exit;
      end;
      
      // 复制失败但未取消
      FTransaction.FailTransaction('文件复制失败');
      raise EMigrationException.Create('文件复制失败', 20, msFailed);
    end;
    
    // 阶段3: 备份原目录
    if FConfig.CreateBackup then
    begin
      SetState(msBackingUp);
      ReportProgress('备份原目录...');
      
      if not BackupOriginalDirectory then
      begin
        FTransaction.FailTransaction('备份失败');
        raise EMigrationException.Create('备份原目录失败', 30, msFailed);
      end;
    end;
    
    // 阶段4: 创建链接
    SetState(msCreatingLink);
    ReportProgress('创建目录链接...');
    
    if not CreateDirectoryLink(FConfig.SourcePath, DstDir) then
    begin
      FTransaction.FailTransaction('创建链接失败');
      
      // 回滚：恢复原目录
      if FConfig.CreateBackup and TDirectory.Exists(FTransaction.BackupDir) then
      begin
        if not RenameFile(FTransaction.BackupDir, FConfig.SourcePath) then
          LogError('MigrationService', '回滚失败，请手动恢复: ' + FTransaction.BackupDir);
      end;
      
      raise EMigrationException.Create('创建链接失败', 40, msFailed);
    end;
    
    // 阶段5: 验证链接
    SetState(msVerifying);
    ReportProgress('验证链接...');
    
    if not VerifyJunction(FConfig.SourcePath, DstDir) then
      LogWarning('MigrationService', '链接验证未通过，但迁移已完成');
    
    // 完成事务
    FTransaction.CompleteTransaction;
    SetState(msCompleted);
    
    // 填充结果
    Result.Success := True;
    Result.State := msCompleted;
    Result.VerifiedCount := Length(FTransaction.GetProcessedFiles);
    Result.FailedCount := Length(FTransaction.GetFailedFiles);
    Result.BackupDir := FTransaction.BackupDir;
    Result.ElapsedTime := Now - FStartTime;
    
    // 计算备份目录大小
    if TDirectory.Exists(FTransaction.BackupDir) then
      ComputeDirectoryStats(FTransaction.BackupDir, BackupFileCount, Result.BackupSize);
    
    LogInfo('MigrationService', Format('迁移完成！验证 %d 个文件，失败 %d 个', 
      [Result.VerifiedCount, Result.FailedCount]));
    
    if Assigned(FProgressCallback) then
      FProgressCallback.OnComplete(Result);
    
  except
    on E: EMigrationException do
    begin
      SetState(E.State);
      Result.State := E.State;
      Result.ErrorMessage := E.Message;
      ReportError(E.Message);
      
      if Assigned(FProgressCallback) then
        FProgressCallback.OnComplete(Result);
    end;
    on E: Exception do
    begin
      SetState(msFailed);
      Result.State := msFailed;
      Result.ErrorMessage := E.Message;
      ReportError('未预期的错误: ' + E.Message);
      
      if Assigned(FTransaction) then
        FTransaction.FailTransaction(E.Message);
      
      if Assigned(FProgressCallback) then
        FProgressCallback.OnComplete(Result);
    end;
  end;
end;

end.
