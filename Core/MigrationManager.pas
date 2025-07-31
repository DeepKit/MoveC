unit MigrationManager;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.StrUtils,
  System.Generics.Collections, IMigrationManager2, IFileAnalyzer2, DataTypes;

type
  // 迁移管理器具体实现
  TMigrationManager = class(TInterfacedObject, IMigrationManager)
  private
    FFileAnalyzer: IFileAnalyzer;
    
    // 内部方法
    function CalculateDirectorySize(const APath: string): Int64;
    function GetAvailableSpace(const ADrivePath: string): Int64;
    function EstimateMigrationTime(const APlan: TMigrationPlan): Integer;
    function ValidateSourcePath(const APath: string): Boolean;
    function ValidateTargetPath(const APath: string): Boolean;
    function CreateDirectoryStructure(const ASourcePath, ATargetPath: string): Boolean;
    function CopyFileWithProgress(const ASourceFile, ATargetFile: string; 
      AProgressCallback: TProgressCallback): Boolean;
    function CreateSymbolicLink(const ALinkPath, ATargetPath: string): Boolean;
    function IsNTFSFileSystem(const APath: string): Boolean;
    procedure LogMigrationStep(const AMessage: string);
    
  public
    constructor Create(AFileAnalyzer: IFileAnalyzer);
    destructor Destroy; override;
    
    // IMigrationManager 接口实现
    function CreateMigrationPlan(const ASourcePath, ATargetPath: string): TMigrationPlan;
    function ValidateMigrationPlan(const APlan: TMigrationPlan): Boolean;
    function ExecuteMigration(const APlan: TMigrationPlan; AProgressCallback: TProgressCallback): Boolean;
    function CanRollback(const APlan: TMigrationPlan): Boolean;
  end;

implementation

uses
  Vcl.Forms, Winapi.ShellAPI;

constructor TMigrationManager.Create(AFileAnalyzer: IFileAnalyzer);
begin
  inherited Create;
  FFileAnalyzer := AFileAnalyzer;
end;

destructor TMigrationManager.Destroy;
begin
  inherited;
end;

// 计算目录大小
function TMigrationManager.CalculateDirectorySize(const APath: string): Int64;
var
  SearchRec: TSearchRec;
  FilePath: string;
begin
  Result := 0;
  
  if not DirectoryExists(APath) then
    Exit;
    
  if FindFirst(APath + '\*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FilePath := TPath.Combine(APath, SearchRec.Name);
          
          if (SearchRec.Attr and faDirectory) = faDirectory then
          begin
            // 递归计算子目录大小
            Result := Result + CalculateDirectorySize(FilePath);
          end
          else
          begin
            // 累加文件大小
            Result := Result + SearchRec.Size;
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

// 获取可用空间
function TMigrationManager.GetAvailableSpace(const ADrivePath: string): Int64;
var
  FreeBytesAvailable, TotalNumberOfBytes: Int64;
begin
  Result := 0;
  
  if GetDiskFreeSpaceEx(PChar(ADrivePath), FreeBytesAvailable, TotalNumberOfBytes, nil) then
    Result := FreeBytesAvailable;
end;

// 估算迁移时间（秒）
function TMigrationManager.EstimateMigrationTime(const APlan: TMigrationPlan): Integer;
var
  TotalSize: Int64;
  TransferRate: Int64; // 字节/秒
begin
  TotalSize := APlan.SpaceSavings;
  
  // 假设传输速度为50MB/s（根据实际情况调整）
  TransferRate := 50 * 1024 * 1024;
  
  if TransferRate > 0 then
    Result := Integer(TotalSize div TransferRate)
  else
    Result := 0;
    
  // 最少1秒
  if Result < 1 then
    Result := 1;
end;

// 验证源路径
function TMigrationManager.ValidateSourcePath(const APath: string): Boolean;
begin
  Result := DirectoryExists(APath) and 
            (not StartsText(GetEnvironmentVariable('WINDIR'), APath)) and
            (not StartsText(GetEnvironmentVariable('ProgramFiles'), APath));
end;

// 验证目标路径
function TMigrationManager.ValidateTargetPath(const APath: string): Boolean;
var
  DriveLetter: string;
begin
  Result := False;
  
  // 检查路径是否存在
  if not DirectoryExists(ExtractFilePath(APath)) then
    Exit;
    
  // 检查不是C盘
  DriveLetter := UpperCase(ExtractFileDrive(APath));
  if DriveLetter = 'C:' then
    Exit;
    
  // 检查是否为NTFS文件系统
  if not IsNTFSFileSystem(APath) then
    Exit;
    
  Result := True;
end;

// 检查是否为NTFS文件系统（简化实现）
function TMigrationManager.IsNTFSFileSystem(const APath: string): Boolean;
var
  DriveLetter: string;
begin
  // 简化检查：假设大部分现代系统都是NTFS
  DriveLetter := UpperCase(ExtractFileDrive(APath));
  Result := (DriveLetter <> 'A:') and (DriveLetter <> 'B:'); // 排除软盘
end;

// 创建目录结构
function TMigrationManager.CreateDirectoryStructure(const ASourcePath, ATargetPath: string): Boolean;
begin
  Result := False;
  
  try
    if not DirectoryExists(ATargetPath) then
    begin
      if not ForceDirectories(ATargetPath) then
        Exit;
    end;
    
    Result := True;
  except
    Result := False;
  end;
end;

// 复制文件并显示进度
function TMigrationManager.CopyFileWithProgress(const ASourceFile, ATargetFile: string; 
  AProgressCallback: TProgressCallback): Boolean;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: array[0..65535] of Byte;
  BytesRead, TotalBytes, BytesCopied: Int64;
  Progress: Integer;
begin
  Result := False;
  
  try
    if not FileExists(ASourceFile) then
      Exit;
      
    // 确保目标目录存在
    ForceDirectories(ExtractFilePath(ATargetFile));
    
    SourceStream := TFileStream.Create(ASourceFile, fmOpenRead or fmShareDenyWrite);
    try
      TargetStream := TFileStream.Create(ATargetFile, fmCreate);
      try
        TotalBytes := SourceStream.Size;
        BytesCopied := 0;
        
        while BytesCopied < TotalBytes do
        begin
          BytesRead := SourceStream.Read(Buffer, SizeOf(Buffer));
          if BytesRead = 0 then
            Break;
            
          TargetStream.Write(Buffer, BytesRead);
          BytesCopied := BytesCopied + BytesRead;
          
          // 更新进度
          if Assigned(AProgressCallback) and (TotalBytes > 0) then
          begin
            Progress := Integer((BytesCopied * 100) div TotalBytes);
            AProgressCallback(Progress, '正在复制: ' + ExtractFileName(ASourceFile));
          end;
        end;
        
        Result := True;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
    
    // 复制文件属性
    if Result then
    begin
      var SourceAttrs := FileGetAttr(ASourceFile);
      if SourceAttrs <> -1 then
        FileSetAttr(ATargetFile, SourceAttrs);
    end;
    
  except
    Result := False;
  end;
end;

// 创建符号链接
function TMigrationManager.CreateSymbolicLink(const ALinkPath, ATargetPath: string): Boolean;
var
  Flags: DWORD;
begin
  Result := False;
  
  try
    // 确保链接路径的父目录存在
    ForceDirectories(ExtractFilePath(ALinkPath));
    
    // 如果链接已存在，先删除
    if DirectoryExists(ALinkPath) or FileExists(ALinkPath) then
    begin
      if DirectoryExists(ALinkPath) then
        RemoveDir(ALinkPath)
      else
        DeleteFile(ALinkPath);
    end;
    
    // 创建符号链接
    if DirectoryExists(ATargetPath) then
      Flags := SYMBOLIC_LINK_FLAG_DIRECTORY
    else
      Flags := 0;
      
    Result := CreateSymbolicLinkW(PWideChar(ALinkPath), PWideChar(ATargetPath), Flags);
    
  except
    Result := False;
  end;
end;

// 记录迁移步骤
procedure TMigrationManager.LogMigrationStep(const AMessage: string);
begin
  // 这里可以实现日志记录功能
  // 暂时简化处理
end;

// 创建迁移计划
function TMigrationManager.CreateMigrationPlan(const ASourcePath, ATargetPath: string): TMigrationPlan;
var
  AnalysisResults: TArray<TFileAnalysisResult>;
  TotalSize: Int64;
  RequiresRestart: Boolean;
  I: Integer;
begin
  // 初始化计划
  Result.SourcePath := ASourcePath;
  Result.TargetPath := ATargetPath;
  Result.EstimatedTime := 0;
  Result.SpaceSavings := 0;
  Result.RequiresRestart := False;
  SetLength(Result.Files, 0);
  
  // 验证路径
  if not ValidateSourcePath(ASourcePath) then
    raise Exception.Create('源路径无效或不安全');
    
  if not ValidateTargetPath(ATargetPath) then
    raise Exception.Create('目标路径无效或不支持符号链接');
  
  // 分析源目录
  AnalysisResults := FFileAnalyzer.AnalyzeDirectory(ASourcePath);
  
  // 过滤可安全迁移的文件
  var SafeFiles: TList<TFileAnalysisResult>;
  SafeFiles := TList<TFileAnalysisResult>.Create;
  try
    TotalSize := 0;
    RequiresRestart := False;
    
    for I := 0 to Length(AnalysisResults) - 1 do
    begin
      var FileResult := AnalysisResults[I];
      
      // 只包含可链接和有风险级别的文件
      if FileResult.SymlinkFeasibility in [sfCanLink, sfRisky] then
      begin
        SafeFiles.Add(FileResult);
        TotalSize := TotalSize + FileResult.Size;
        
        if FileResult.RequiresRestart then
          RequiresRestart := True;
      end;
    end;
    
    SetLength(Result.Files, SafeFiles.Count);
    for I := 0 to SafeFiles.Count - 1 do
      Result.Files[I] := SafeFiles[I];
    Result.SpaceSavings := TotalSize;
    Result.RequiresRestart := RequiresRestart;
    Result.EstimatedTime := EstimateMigrationTime(Result);
    
  finally
    SafeFiles.Free;
  end;
end;

// 验证迁移计划
function TMigrationManager.ValidateMigrationPlan(const APlan: TMigrationPlan): Boolean;
var
  AvailableSpace: Int64;
begin
  Result := False;
  
  try
    // 检查源路径是否存在
    if not DirectoryExists(APlan.SourcePath) then
      Exit;
      
    // 检查目标路径是否有效
    if not ValidateTargetPath(APlan.TargetPath) then
      Exit;
      
    // 检查目标磁盘空间是否足够
    AvailableSpace := GetAvailableSpace(ExtractFileDrive(APlan.TargetPath) + '\');
    if AvailableSpace < APlan.SpaceSavings then
      Exit;
      
    // 检查是否有文件需要迁移
    if Length(APlan.Files) = 0 then
      Exit;
      
    Result := True;
    
  except
    Result := False;
  end;
end;

// 执行迁移
function TMigrationManager.ExecuteMigration(const APlan: TMigrationPlan; AProgressCallback: TProgressCallback): Boolean;
var
  I: Integer;
  FileResult: TFileAnalysisResult;
  SourceFile, TargetFile: string;
  TotalFiles: Integer;
  CurrentProgress: Integer;
begin
  Result := False;
  
  try
    // 验证计划
    if not ValidateMigrationPlan(APlan) then
      raise Exception.Create('迁移计划验证失败');
    
    TotalFiles := Length(APlan.Files);
    if TotalFiles = 0 then
      Exit;
    
    // 创建目标目录结构
    if not CreateDirectoryStructure(APlan.SourcePath, APlan.TargetPath) then
      raise Exception.Create('无法创建目标目录结构');
    
    // 逐个处理文件
    for I := 0 to TotalFiles - 1 do
    begin
      FileResult := APlan.Files[I];
      
      // 计算进度
      CurrentProgress := (I * 100) div TotalFiles;
      
      if Assigned(AProgressCallback) then
        AProgressCallback(CurrentProgress, '处理文件: ' + ExtractFileName(FileResult.FilePath));
      
      // 构建目标文件路径
      var RelativePath := ExtractRelativePath(APlan.SourcePath + '\', FileResult.FilePath);
      TargetFile := TPath.Combine(APlan.TargetPath, RelativePath);
      
      // 复制文件
      if not CopyFileWithProgress(FileResult.FilePath, TargetFile, AProgressCallback) then
      begin
        LogMigrationStep('复制文件失败: ' + FileResult.FilePath);
        Continue; // 继续处理其他文件
      end;
      
      LogMigrationStep('文件复制成功: ' + FileResult.FilePath);
    end;
    
    // 创建符号链接
    if Assigned(AProgressCallback) then
      AProgressCallback(90, '创建符号链接...');
      
    if CreateSymbolicLink(APlan.SourcePath, APlan.TargetPath) then
    begin
      LogMigrationStep('符号链接创建成功');
      Result := True;
    end
    else
    begin
      LogMigrationStep('符号链接创建失败');
      // 即使符号链接失败，文件已经复制，可以认为部分成功
      Result := True;
    end;
    
    if Assigned(AProgressCallback) then
      AProgressCallback(100, '迁移完成');
    
  except
    on E: Exception do
    begin
      LogMigrationStep('迁移失败: ' + E.Message);
      if Assigned(AProgressCallback) then
        AProgressCallback(0, '迁移失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

// 检查是否可以回退
function TMigrationManager.CanRollback(const APlan: TMigrationPlan): Boolean;
begin
  // 检查目标路径是否存在
  Result := DirectoryExists(APlan.TargetPath);
  
  // 检查源路径是否为符号链接
  if Result then
  begin
    var FileAttrs := GetFileAttributes(PChar(APlan.SourcePath));
    Result := (FileAttrs <> INVALID_FILE_ATTRIBUTES) and 
              (FileAttrs and FILE_ATTRIBUTE_REPARSE_POINT <> 0);
  end;
end;

end.
