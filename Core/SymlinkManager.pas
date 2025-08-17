unit SymlinkManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections,
  Winapi.Windows, DataTypes, ConfigManager;

type
  // 符号链接类型
  TSymlinkType = (stUnknown, stFile, stDirectory, stJunction, stHardLink, stMountPoint);
  
  // 符号链接状态
  TSymlinkStatus = (ssValid, ssBroken, ssInvalid, ssAccessDenied, ssNotFound, ssCircular);
  
  // 符号链接信息
  TSymlinkInfo = record
    LinkPath: string;
    TargetPath: string;
    LinkType: TSymlinkType;
    Status: TSymlinkStatus;
    CreationTime: TDateTime;
    LastAccessTime: TDateTime;
    Attributes: DWORD;
    Size: Int64;
    IsRelative: Boolean;
    Depth: Integer; // 链接深度，用于检测循环
    ErrorMessage: string;
    CanRepair: Boolean;
    RepairSuggestion: string;
  end;
  
  // 符号链接操作选项
  TSymlinkOptions = record
    CreateAsRelative: Boolean;
    OverwriteExisting: Boolean;
    CreateBackup: Boolean;
    ValidateTarget: Boolean;
    FollowChain: Boolean;
    MaxDepth: Integer;
    PreserveAttributes: Boolean;
    LogOperations: Boolean;
  end;
  
  // 符号链接统计
  TSymlinkStatistics = record
    TotalLinks: Integer;
    ValidLinks: Integer;
    BrokenLinks: Integer;
    CircularLinks: Integer;
    FileLinks: Integer;
    DirectoryLinks: Integer;
    Junctions: Integer;
    HardLinks: Integer;
    RelativeLinks: Integer;
    AbsoluteLinks: Integer;
  end;
  
  // 符号链接管理器
  TSymlinkManager = class
  private
    FConfigManager: TConfigManager;
    FOptions: TSymlinkOptions;
    FLinkCache: TDictionary<string, TSymlinkInfo>;
    FValidationCache: TDictionary<string, Boolean>;
    
    // 内部检测方法
    function DetectSymlinkType(const ALinkPath: string): TSymlinkType;
    function GetSymlinkTarget(const ALinkPath: string): string;
    function ValidateSymlinkTarget(const ATargetPath: string): Boolean;
    function CheckCircularReference(const ALinkPath: string; AVisited: TStringList): Boolean;
    function CalculateLinkDepth(const ALinkPath: string): Integer;
    
    // 内部操作方法
    function CreateFileSymlink(const ASource, ATarget: string): Boolean;
    function CreateDirectorySymlink(const ASource, ATarget: string): Boolean;
    function CreateDirectoryJunction(const ASource, ATarget: string): Boolean;
    function CreateHardLink(const ASource, ATarget: string): Boolean;
    function RemoveSymlinkInternal(const ALinkPath: string): Boolean;
    
    // 辅助方法
    function IsReparsePoint(const APath: string): Boolean;
    function GetReparsePointData(const APath: string): TBytes;
    function ParseReparsePointData(const AData: TBytes): string;
    function MakeRelativePath(const AFrom, ATo: string): string;
    function MakeAbsolutePath(const ABasePath, ARelativePath: string): string;
    function GetSymlinkTypeString(AType: TSymlinkType): string;
    function GetSymlinkStatusString(AStatus: TSymlinkStatus): string;
    
    // 缓存管理
    procedure UpdateCache(const ALinkPath: string; const AInfo: TSymlinkInfo);
    function GetFromCache(const ALinkPath: string): TSymlinkInfo;
    procedure ClearCache;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // 主要操作方法
    function CreateSymlink(const ASource, ATarget: string; AType: TSymlinkType = stUnknown): Boolean;
    function RemoveSymlink(const ALinkPath: string): Boolean;
    function ValidateSymlink(const ALinkPath: string): Boolean;
    function RepairSymlink(const ALinkPath: string): Boolean;
    
    // 信息获取方法
    function GetSymlinkInfo(const ALinkPath: string): TSymlinkInfo;
    function IsSymlink(const APath: string): Boolean;
    function GetTargetPath(const ALinkPath: string): string;
    function GetLinkType(const ALinkPath: string): TSymlinkType;
    function GetLinkStatus(const ALinkPath: string): TSymlinkStatus;
    
    // 批量操作方法
    function BatchValidate(const APaths: TArray<string>): TArray<TSymlinkInfo>;
    function BatchRepair(const APaths: TArray<string>): Integer;
    function FindBrokenLinks(const ASearchPath: string; ARecursive: Boolean = True): TArray<string>;
    function FindCircularLinks(const ASearchPath: string; ARecursive: Boolean = True): TArray<string>;
    
    // 高级功能
    function ConvertToRelative(const ALinkPath: string): Boolean;
    function ConvertToAbsolute(const ALinkPath: string): Boolean;
    function UpdateLinkTarget(const ALinkPath, ANewTarget: string): Boolean;
    function CloneSymlink(const ASourceLink, ATargetLink: string): Boolean;
    
    // 配置和选项
    procedure SetOptions(const AOptions: TSymlinkOptions);
    function GetOptions: TSymlinkOptions;
    procedure SetDefaultOptions;
    
    // 统计和报告
    function GetStatistics(const ASearchPath: string; ARecursive: Boolean = True): TSymlinkStatistics;
    function GenerateReport(const ASearchPath: string; ARecursive: Boolean = True): string;
    function GenerateHealthReport(const ASearchPath: string): string;
  end;

implementation

uses
  System.DateUtils, System.Math, Vcl.Forms;

constructor TSymlinkManager.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FLinkCache := TDictionary<string, TSymlinkInfo>.Create;
  FValidationCache := TDictionary<string, Boolean>.Create;
  
  SetDefaultOptions;
end;

destructor TSymlinkManager.Destroy;
begin
  FLinkCache.Free;
  FValidationCache.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

// 设置默认选项
procedure TSymlinkManager.SetDefaultOptions;
begin
  FOptions.CreateAsRelative := False;
  FOptions.OverwriteExisting := False;
  FOptions.CreateBackup := True;
  FOptions.ValidateTarget := True;
  FOptions.FollowChain := True;
  FOptions.MaxDepth := 10;
  FOptions.PreserveAttributes := True;
  FOptions.LogOperations := True;
end;

// 检测符号链接类型
function TSymlinkManager.DetectSymlinkType(const ALinkPath: string): TSymlinkType;
var
  Attrs: DWORD;
  Handle: THandle;
  ReparseData: TBytes;
  ReparseTag: DWORD;
begin
  Result := stUnknown;
  
  try
    if not PathExists(ALinkPath) then
      Exit;
    
    Attrs := GetFileAttributes(PChar(ALinkPath));
    if Attrs = INVALID_FILE_ATTRIBUTES then
      Exit;
    
    // 检查是否为重解析点
    if (Attrs and FILE_ATTRIBUTE_REPARSE_POINT) = 0 then
    begin
      // 可能是硬链接，需要进一步检查
      Handle := CreateFile(PChar(ALinkPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
      
      if Handle <> INVALID_HANDLE_VALUE then
      begin
        try
          var FileInfo: BY_HANDLE_FILE_INFORMATION;
          if GetFileInformationByHandle(Handle, FileInfo) then
          begin
            if FileInfo.nNumberOfLinks > 1 then
              Result := stHardLink;
          end;
        finally
          CloseHandle(Handle);
        end;
      end;
      
      Exit;
    end;
    
    // 获取重解析点数据
    ReparseData := GetReparsePointData(ALinkPath);
    if Length(ReparseData) < 8 then
      Exit;
    
    // 读取重解析标签
    ReparseTag := PDWORD(@ReparseData[0])^;
    
    case ReparseTag of
      IO_REPARSE_TAG_SYMLINK:
      begin
        if (Attrs and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
          Result := stDirectory
        else
          Result := stFile;
      end;
      
      IO_REPARSE_TAG_MOUNT_POINT:
      begin
        if (Attrs and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
          Result := stJunction
        else
          Result := stMountPoint;
      end;
      
    else
      Result := stUnknown;
    end;
    
  except
    Result := stUnknown;
  end;
end;

// 获取符号链接目标
function TSymlinkManager.GetSymlinkTarget(const ALinkPath: string): string;
var
  ReparseData: TBytes;
begin
  Result := '';
  
  try
    if not IsReparsePoint(ALinkPath) then
      Exit;
    
    ReparseData := GetReparsePointData(ALinkPath);
    if Length(ReparseData) > 0 then
      Result := ParseReparsePointData(ReparseData);
    
  except
    Result := '';
  end;
end;// 验证符号链接目标

function TSymlinkManager.ValidateSymlinkTarget(const ATargetPath: string): Boolean;
begin
  Result := False;
  
  try
    // 检查缓存
    if FValidationCache.TryGetValue(ATargetPath, Result) then
      Exit;
    
    // 验证目标是否存在
    Result := PathExists(ATargetPath);
    
    // 更新缓存
    FValidationCache.AddOrSetValue(ATargetPath, Result);
    
  except
    Result := False;
  end;
end;

// 检查循环引用
function TSymlinkManager.CheckCircularReference(const ALinkPath: string; AVisited: TStringList): Boolean;
var
  TargetPath: string;
begin
  Result := False;
  
  try
    if AVisited.IndexOf(ALinkPath) >= 0 then
    begin
      Result := True;
      Exit;
    end;
    
    if not IsSymlink(ALinkPath) then
      Exit;
    
    AVisited.Add(ALinkPath);
    
    TargetPath := GetSymlinkTarget(ALinkPath);
    if (Length(TargetPath) > 0) and IsSymlink(TargetPath) then
      Result := CheckCircularReference(TargetPath, AVisited);
    
  except
    Result := False;
  end;
end;

// 计算链接深度
function TSymlinkManager.CalculateLinkDepth(const ALinkPath: string): Integer;
var
  CurrentPath: string;
  Visited: TStringList;
begin
  Result := 0;
  CurrentPath := ALinkPath;
  Visited := TStringList.Create;
  
  try
    while IsSymlink(CurrentPath) and (Result < FOptions.MaxDepth) do
    begin
      if Visited.IndexOf(CurrentPath) >= 0 then
        Break; // 循环引用
      
      Visited.Add(CurrentPath);
      CurrentPath := GetSymlinkTarget(CurrentPath);
      Inc(Result);
      
      if Length(CurrentPath) = 0 then
        Break;
    end;
    
  finally
    Visited.Free;
  end;
end;

// 创建文件符号链接
function TSymlinkManager.CreateFileSymlink(const ASource, ATarget: string): Boolean;
begin
  Result := False;
  
  try
    Result := CreateSymbolicLinkW(PWideChar(ATarget), PWideChar(ASource), 0);
    
    if Result and FOptions.LogOperations and Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('SYMLINK', 'File symlink created', ASource, ATarget, 'SUCCESS', '');
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'File symlink creation failed', ASource, ATarget, 'ERROR', E.Message);
    end;
  end;
end;

// 创建目录符号链接
function TSymlinkManager.CreateDirectorySymlink(const ASource, ATarget: string): Boolean;
begin
  Result := False;
  
  try
    Result := CreateSymbolicLinkW(PWideChar(ATarget), PWideChar(ASource), SYMBOLIC_LINK_FLAG_DIRECTORY);
    
    if Result and FOptions.LogOperations and Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('SYMLINK', 'Directory symlink created', ASource, ATarget, 'SUCCESS', '');
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'Directory symlink creation failed', ASource, ATarget, 'ERROR', E.Message);
    end;
  end;
end;

// 创建目录联接
function TSymlinkManager.CreateDirectoryJunction(const ASource, ATarget: string): Boolean;
begin
  Result := False;
  
  try
    // 使用mklink命令创建目录联接
    var CmdLine := Format('mklink /J "%s" "%s"', [ATarget, ASource]);
    
    var StartupInfo: TStartupInfo;
    var ProcessInfo: TProcessInformation;
    
    FillChar(StartupInfo, SizeOf(StartupInfo), 0);
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;
    
    if CreateProcess(nil, PChar('cmd.exe /C ' + CmdLine), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
    begin
      try
        WaitForSingleObject(ProcessInfo.hProcess, 5000); // 等待5秒
        
        var ExitCode: DWORD;
        if GetExitCodeProcess(ProcessInfo.hProcess, ExitCode) then
          Result := (ExitCode = 0);
        
      finally
        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end;
    end;
    
    if Result and FOptions.LogOperations and Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('SYMLINK', 'Directory junction created', ASource, ATarget, 'SUCCESS', '');
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'Directory junction creation failed', ASource, ATarget, 'ERROR', E.Message);
    end;
  end;
end;

// 创建硬链接
function TSymlinkManager.CreateHardLink(const ASource, ATarget: string): Boolean;
begin
  Result := False;
  
  try
    Result := CreateHardLinkW(PWideChar(ATarget), PWideChar(ASource), nil);
    
    if Result and FOptions.LogOperations and Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('SYMLINK', 'Hard link created', ASource, ATarget, 'SUCCESS', '');
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'Hard link creation failed', ASource, ATarget, 'ERROR', E.Message);
    end;
  end;
end;

// 内部删除符号链接
function TSymlinkManager.RemoveSymlinkInternal(const ALinkPath: string): Boolean;
var
  LinkType: TSymlinkType;
begin
  Result := False;
  
  try
    LinkType := DetectSymlinkType(ALinkPath);
    
    case LinkType of
      stFile, stHardLink:
        Result := DeleteFile(ALinkPath);
      
      stDirectory, stJunction:
        Result := RemoveDirectory(PChar(ALinkPath));
      
    else
      // 尝试作为文件删除
      Result := DeleteFile(ALinkPath);
      if not Result then
        Result := RemoveDirectory(PChar(ALinkPath));
    end;
    
    if Result and FOptions.LogOperations and Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('SYMLINK', 'Symlink removed', ALinkPath, '', 'SUCCESS', '');
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'Symlink removal failed', ALinkPath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 检查是否为重解析点
function TSymlinkManager.IsReparsePoint(const APath: string): Boolean;
var
  Attrs: DWORD;
begin
  Result := False;
  
  try
    Attrs := GetFileAttributes(PChar(APath));
    Result := (Attrs <> INVALID_FILE_ATTRIBUTES) and ((Attrs and FILE_ATTRIBUTE_REPARSE_POINT) <> 0);
  except
    Result := False;
  end;
end;

// 获取重解析点数据
function TSymlinkManager.GetReparsePointData(const APath: string): TBytes;
var
  Handle: THandle;
  Buffer: array[0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE-1] of Byte;
  BytesReturned: DWORD;
begin
  SetLength(Result, 0);
  
  try
    Handle := CreateFile(PChar(APath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE,
      nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
    
    if Handle <> INVALID_HANDLE_VALUE then
    begin
      try
        if DeviceIoControl(Handle, FSCTL_GET_REPARSE_POINT, nil, 0, @Buffer[0], 
          SizeOf(Buffer), BytesReturned, nil) then
        begin
          SetLength(Result, BytesReturned);
          Move(Buffer[0], Result[0], BytesReturned);
        end;
      finally
        CloseHandle(Handle);
      end;
    end;
    
  except
    SetLength(Result, 0);
  end;
end;

// 解析重解析点数据
function TSymlinkManager.ParseReparsePointData(const AData: TBytes): string;
var
  ReparseTag: DWORD;
  DataLength: WORD;
  PathOffset: WORD;
  PathLength: WORD;
  PathBuffer: PWideChar;
begin
  Result := '';
  
  try
    if Length(AData) < 8 then
      Exit;
    
    ReparseTag := PDWORD(@AData[0])^;
    DataLength := PWORD(@AData[4])^;
    
    case ReparseTag of
      IO_REPARSE_TAG_SYMLINK:
      begin
        if Length(AData) < 20 then
          Exit;
        
        PathOffset := PWORD(@AData[8])^;
        PathLength := PWORD(@AData[10])^;
        
        if (20 + PathOffset + PathLength) <= Length(AData) then
        begin
          PathBuffer := PWideChar(@AData[20 + PathOffset]);
          SetString(Result, PathBuffer, PathLength div 2);
        end;
      end;
      
      IO_REPARSE_TAG_MOUNT_POINT:
      begin
        if Length(AData) < 16 then
          Exit;
        
        PathOffset := PWORD(@AData[8])^;
        PathLength := PWORD(@AData[10])^;
        
        if (16 + PathOffset + PathLength) <= Length(AData) then
        begin
          PathBuffer := PWideChar(@AData[16 + PathOffset]);
          SetString(Result, PathBuffer, PathLength div 2);
        end;
      end;
    end;
    
    // 清理路径格式
    if StartsText('\\?\', Result) then
      Result := Copy(Result, 5, MaxInt);
    
  except
    Result := '';
  end;
end;

// 创建相对路径
function TSymlinkManager.MakeRelativePath(const AFrom, ATo: string): string;
var
  FromParts, ToParts: TArray<string>;
  CommonCount, I: Integer;
  RelativeParts: TStringList;
begin
  Result := ATo;
  
  try
    FromParts := AFrom.Split(['\']);
    ToParts := ATo.Split(['\']);
    
    // 找到公共前缀
    CommonCount := 0;
    while (CommonCount < Length(FromParts)) and (CommonCount < Length(ToParts)) and
          SameText(FromParts[CommonCount], ToParts[CommonCount]) do
      Inc(CommonCount);
    
    if CommonCount = 0 then
      Exit; // 没有公共路径
    
    RelativeParts := TStringList.Create;
    try
      // 添加向上的路径
      for I := CommonCount to Length(FromParts) - 2 do
        RelativeParts.Add('..');
      
      // 添加向下的路径
      for I := CommonCount to Length(ToParts) - 1 do
        RelativeParts.Add(ToParts[I]);
      
      if RelativeParts.Count > 0 then
        Result := StringReplace(RelativeParts.Text.Trim, sLineBreak, '\', [rfReplaceAll]);
      
    finally
      RelativeParts.Free;
    end;
    
  except
    Result := ATo;
  end;
end;

// 创建绝对路径
function TSymlinkManager.MakeAbsolutePath(const ABasePath, ARelativePath: string): string;
begin
  Result := ARelativePath;
  
  try
    if not TPath.IsPathRooted(ARelativePath) then
    begin
      Result := TPath.Combine(ExtractFilePath(ABasePath), ARelativePath);
      Result := TPath.GetFullPath(Result);
    end;
  except
    Result := ARelativePath;
  end;
end;//
 获取符号链接类型字符串
function TSymlinkManager.GetSymlinkTypeString(AType: TSymlinkType): string;
begin
  case AType of
    stFile: Result := '文件符号链接';
    stDirectory: Result := '目录符号链接';
    stJunction: Result := '目录联接';
    stHardLink: Result := '硬链接';
    stMountPoint: Result := '挂载点';
  else
    Result := '未知类型';
  end;
end;

// 获取符号链接状态字符串
function TSymlinkManager.GetSymlinkStatusString(AStatus: TSymlinkStatus): string;
begin
  case AStatus of
    ssValid: Result := '有效';
    ssBroken: Result := '损坏';
    ssInvalid: Result := '无效';
    ssAccessDenied: Result := '访问被拒绝';
    ssNotFound: Result := '未找到';
    ssCircular: Result := '循环引用';
  else
    Result := '未知状态';
  end;
end;

// 更新缓存
procedure TSymlinkManager.UpdateCache(const ALinkPath: string; const AInfo: TSymlinkInfo);
begin
  FLinkCache.AddOrSetValue(ALinkPath, AInfo);
end;

// 从缓存获取
function TSymlinkManager.GetFromCache(const ALinkPath: string): TSymlinkInfo;
begin
  if not FLinkCache.TryGetValue(ALinkPath, Result) then
    FillChar(Result, SizeOf(Result), 0);
end;

// 清空缓存
procedure TSymlinkManager.ClearCache;
begin
  FLinkCache.Clear;
  FValidationCache.Clear;
end;

// 创建符号链接
function TSymlinkManager.CreateSymlink(const ASource, ATarget: string; AType: TSymlinkType): Boolean;
var
  TargetPath: string;
  BackupPath: string;
begin
  Result := False;
  
  try
    // 验证源路径
    if FOptions.ValidateTarget and not PathExists(ASource) then
      Exit;
    
    // 处理相对路径
    if FOptions.CreateAsRelative then
      TargetPath := MakeRelativePath(ATarget, ASource)
    else
      TargetPath := ASource;
    
    // 检查目标是否存在
    if PathExists(ATarget) then
    begin
      if not FOptions.OverwriteExisting then
        Exit;
      
      if FOptions.CreateBackup then
      begin
        BackupPath := ATarget + '.backup';
        if not MoveFile(PChar(ATarget), PChar(BackupPath)) then
          Exit;
      end
      else
      begin
        if not RemoveSymlinkInternal(ATarget) then
          Exit;
      end;
    end;
    
    // 确保目标目录存在
    var TargetDir := ExtractFilePath(ATarget);
    if not DirectoryExists(TargetDir) then
      ForceDirectories(TargetDir);
    
    // 根据类型创建链接
    if AType = stUnknown then
    begin
      if DirectoryExists(ASource) then
        AType := stDirectory
      else if FileExists(ASource) then
        AType := stFile
      else
        Exit;
    end;
    
    case AType of
      stFile: Result := CreateFileSymlink(TargetPath, ATarget);
      stDirectory: Result := CreateDirectorySymlink(TargetPath, ATarget);
      stJunction: Result := CreateDirectoryJunction(TargetPath, ATarget);
      stHardLink: Result := CreateHardLink(TargetPath, ATarget);
    else
      Result := False;
    end;
    
    // 如果失败且有备份，恢复备份
    if not Result and FOptions.CreateBackup and FileExists(BackupPath) then
      MoveFile(PChar(BackupPath), PChar(ATarget));
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'Create symlink error', ASource, ATarget, 'ERROR', E.Message);
    end;
  end;
end;

// 删除符号链接
function TSymlinkManager.RemoveSymlink(const ALinkPath: string): Boolean;
var
  BackupPath: string;
begin
  Result := False;
  
  try
    if not IsSymlink(ALinkPath) then
      Exit;
    
    if FOptions.CreateBackup then
    begin
      BackupPath := ALinkPath + '.removed';
      Result := MoveFile(PChar(ALinkPath), PChar(BackupPath));
    end
    else
    begin
      Result := RemoveSymlinkInternal(ALinkPath);
    end;
    
    // 清理缓存
    FLinkCache.Remove(ALinkPath);
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SYMLINK', 'Remove symlink error', ALinkPath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 验证符号链接
function TSymlinkManager.ValidateSymlink(const ALinkPath: string): Boolean;
var
  TargetPath: string;
  Visited: TStringList;
begin
  Result := False;
  
  try
    if not IsSymlink(ALinkPath) then
      Exit;
    
    TargetPath := GetSymlinkTarget(ALinkPath);
    if Length(TargetPath) = 0 then
      Exit;
    
    // 检查循环引用
    Visited := TStringList.Create;
    try
      if CheckCircularReference(ALinkPath, Visited) then
        Exit;
    finally
      Visited.Free;
    end;
    
    // 验证目标存在
    Result := ValidateSymlinkTarget(TargetPath);
    
  except
    Result := False;
  end;
end;

// 修复符号链接
function TSymlinkManager.RepairSymlink(const ALinkPath: string): Boolean;
var
  Info: TSymlinkInfo;
  NewTarget: string;
  SearchPaths: TArray<string>;
  I: Integer;
begin
  Result := False;
  
  try
    Info := GetSymlinkInfo(ALinkPath);
    if Info.Status = ssValid then
    begin
      Result := True;
      Exit;
    end;
    
    if not Info.CanRepair then
      Exit;
    
    // 尝试查找可能的目标
    var OriginalTarget := ExtractFileName(Info.TargetPath);
    
    SetLength(SearchPaths, 4);
    SearchPaths[0] := ExtractFilePath(ALinkPath);
    SearchPaths[1] := GetCurrentDir;
    SearchPaths[2] := 'C:\Program Files';
    SearchPaths[3] := 'C:\Program Files (x86)';
    
    for I := 0 to Length(SearchPaths) - 1 do
    begin
      NewTarget := TPath.Combine(SearchPaths[I], OriginalTarget);
      if PathExists(NewTarget) then
      begin
        Result := UpdateLinkTarget(ALinkPath, NewTarget);
        if Result then
          Break;
      end;
    end;
    
  except
    Result := False;
  end;
end;

// 获取符号链接信息
function TSymlinkManager.GetSymlinkInfo(const ALinkPath: string): TSymlinkInfo;
var
  Visited: TStringList;
begin
  // 先检查缓存
  Result := GetFromCache(ALinkPath);
  if Length(Result.LinkPath) > 0 then
    Exit;
  
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.LinkPath := ALinkPath;
  Result.LinkType := stUnknown;
  Result.Status := ssInvalid;
  
  try
    if not PathExists(ALinkPath) then
    begin
      Result.Status := ssNotFound;
      Result.ErrorMessage := '链接路径不存在';
      Exit;
    end;
    
    // 检测链接类型
    Result.LinkType := DetectSymlinkType(ALinkPath);
    if Result.LinkType = stUnknown then
    begin
      Result.ErrorMessage := '不是有效的符号链接';
      Exit;
    end;
    
    // 获取目标路径
    Result.TargetPath := GetSymlinkTarget(ALinkPath);
    if Length(Result.TargetPath) = 0 then
    begin
      Result.Status := ssInvalid;
      Result.ErrorMessage := '无法获取目标路径';
      Exit;
    end;
    
    // 检查是否为相对路径
    Result.IsRelative := not TPath.IsPathRooted(Result.TargetPath);
    if Result.IsRelative then
      Result.TargetPath := MakeAbsolutePath(ALinkPath, Result.TargetPath);
    
    // 检查循环引用
    Visited := TStringList.Create;
    try
      if CheckCircularReference(ALinkPath, Visited) then
      begin
        Result.Status := ssCircular;
        Result.ErrorMessage := '检测到循环引用';
        Result.CanRepair := False;
        Exit;
      end;
    finally
      Visited.Free;
    end;
    
    // 计算链接深度
    Result.Depth := CalculateLinkDepth(ALinkPath);
    
    // 验证目标
    if ValidateSymlinkTarget(Result.TargetPath) then
    begin
      Result.Status := ssValid;
    end
    else
    begin
      Result.Status := ssBroken;
      Result.ErrorMessage := '目标路径不存在';
      Result.CanRepair := True;
      Result.RepairSuggestion := '尝试查找并更新目标路径';
    end;
    
    // 获取文件属性
    var Attrs := GetFileAttributes(PChar(ALinkPath));
    if Attrs <> INVALID_FILE_ATTRIBUTES then
      Result.Attributes := Attrs;
    
    // 获取时间信息
    var FileTime: TDateTime;
    if FileAge(ALinkPath, FileTime) then
    begin
      Result.CreationTime := FileTime;
      Result.LastAccessTime := FileTime;
    end;
    
    // 获取大小（对于文件）
    if (Result.LinkType = stFile) and FileExists(ALinkPath) then
    begin
      try
        Result.Size := TFile.GetSize(ALinkPath);
      except
        Result.Size := 0;
      end;
    end;
    
    // 更新缓存
    UpdateCache(ALinkPath, Result);
    
  except
    on E: Exception do
    begin
      Result.Status := ssInvalid;
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

// 检查是否为符号链接
function TSymlinkManager.IsSymlink(const APath: string): Boolean;
begin
  Result := DetectSymlinkType(APath) <> stUnknown;
end;

// 获取目标路径
function TSymlinkManager.GetTargetPath(const ALinkPath: string): string;
begin
  Result := GetSymlinkTarget(ALinkPath);
end;

// 获取链接类型
function TSymlinkManager.GetLinkType(const ALinkPath: string): TSymlinkType;
begin
  Result := DetectSymlinkType(ALinkPath);
end;

// 获取链接状态
function TSymlinkManager.GetLinkStatus(const ALinkPath: string): TSymlinkStatus;
var
  Info: TSymlinkInfo;
begin
  Info := GetSymlinkInfo(ALinkPath);
  Result := Info.Status;
end;//
 批量验证
function TSymlinkManager.BatchValidate(const APaths: TArray<string>): TArray<TSymlinkInfo>;
var
  I: Integer;
begin
  SetLength(Result, Length(APaths));
  
  for I := 0 to Length(APaths) - 1 do
  begin
    Result[I] := GetSymlinkInfo(APaths[I]);
  end;
end;

// 批量修复
function TSymlinkManager.BatchRepair(const APaths: TArray<string>): Integer;
var
  I: Integer;
begin
  Result := 0;
  
  for I := 0 to Length(APaths) - 1 do
  begin
    if RepairSymlink(APaths[I]) then
      Inc(Result);
  end;
end;

// 查找损坏的链接
function TSymlinkManager.FindBrokenLinks(const ASearchPath: string; ARecursive: Boolean): TArray<string>;
var
  BrokenLinks: TList<string>;
  SearchOption: TSearchOption;
  Files: TArray<string>;
  I: Integer;
  Info: TSymlinkInfo;
begin
  BrokenLinks := TList<string>.Create;
  
  try
    if ARecursive then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;
    
    try
      Files := TDirectory.GetFiles(ASearchPath, '*', SearchOption);
      
      for I := 0 to Length(Files) - 1 do
      begin
        if IsSymlink(Files[I]) then
        begin
          Info := GetSymlinkInfo(Files[I]);
          if Info.Status = ssBroken then
            BrokenLinks.Add(Files[I]);
        end;
      end;
      
      // 也检查目录
      var Dirs := TDirectory.GetDirectories(ASearchPath, '*', SearchOption);
      for I := 0 to Length(Dirs) - 1 do
      begin
        if IsSymlink(Dirs[I]) then
        begin
          Info := GetSymlinkInfo(Dirs[I]);
          if Info.Status = ssBroken then
            BrokenLinks.Add(Dirs[I]);
        end;
      end;
      
    except
      // 忽略访问错误
    end;
    
    SetLength(Result, BrokenLinks.Count);
    for I := 0 to BrokenLinks.Count - 1 do
      Result[I] := BrokenLinks[I];
    
  finally
    BrokenLinks.Free;
  end;
end;

// 查找循环链接
function TSymlinkManager.FindCircularLinks(const ASearchPath: string; ARecursive: Boolean): TArray<string>;
var
  CircularLinks: TList<string>;
  SearchOption: TSearchOption;
  Files: TArray<string>;
  I: Integer;
  Info: TSymlinkInfo;
begin
  CircularLinks := TList<string>.Create;
  
  try
    if ARecursive then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;
    
    try
      Files := TDirectory.GetFiles(ASearchPath, '*', SearchOption);
      
      for I := 0 to Length(Files) - 1 do
      begin
        if IsSymlink(Files[I]) then
        begin
          Info := GetSymlinkInfo(Files[I]);
          if Info.Status = ssCircular then
            CircularLinks.Add(Files[I]);
        end;
      end;
      
      // 也检查目录
      var Dirs := TDirectory.GetDirectories(ASearchPath, '*', SearchOption);
      for I := 0 to Length(Dirs) - 1 do
      begin
        if IsSymlink(Dirs[I]) then
        begin
          Info := GetSymlinkInfo(Dirs[I]);
          if Info.Status = ssCircular then
            CircularLinks.Add(Dirs[I]);
        end;
      end;
      
    except
      // 忽略访问错误
    end;
    
    SetLength(Result, CircularLinks.Count);
    for I := 0 to CircularLinks.Count - 1 do
      Result[I] := CircularLinks[I];
    
  finally
    CircularLinks.Free;
  end;
end;

// 转换为相对路径
function TSymlinkManager.ConvertToRelative(const ALinkPath: string): Boolean;
var
  Info: TSymlinkInfo;
  RelativePath: string;
begin
  Result := False;
  
  try
    Info := GetSymlinkInfo(ALinkPath);
    if (Info.Status <> ssValid) or Info.IsRelative then
      Exit;
    
    RelativePath := MakeRelativePath(ALinkPath, Info.TargetPath);
    if Length(RelativePath) = 0 then
      Exit;
    
    Result := UpdateLinkTarget(ALinkPath, RelativePath);
    
  except
    Result := False;
  end;
end;

// 转换为绝对路径
function TSymlinkManager.ConvertToAbsolute(const ALinkPath: string): Boolean;
var
  Info: TSymlinkInfo;
  AbsolutePath: string;
begin
  Result := False;
  
  try
    Info := GetSymlinkInfo(ALinkPath);
    if (Info.Status <> ssValid) or not Info.IsRelative then
      Exit;
    
    AbsolutePath := MakeAbsolutePath(ALinkPath, Info.TargetPath);
    if Length(AbsolutePath) = 0 then
      Exit;
    
    Result := UpdateLinkTarget(ALinkPath, AbsolutePath);
    
  except
    Result := False;
  end;
end;

// 更新链接目标
function TSymlinkManager.UpdateLinkTarget(const ALinkPath, ANewTarget: string): Boolean;
var
  Info: TSymlinkInfo;
begin
  Result := False;
  
  try
    Info := GetSymlinkInfo(ALinkPath);
    if Info.LinkType = stUnknown then
      Exit;
    
    // 删除旧链接
    if not RemoveSymlinkInternal(ALinkPath) then
      Exit;
    
    // 创建新链接
    Result := CreateSymlink(ANewTarget, ALinkPath, Info.LinkType);
    
    // 清理缓存
    FLinkCache.Remove(ALinkPath);
    
  except
    Result := False;
  end;
end;

// 克隆符号链接
function TSymlinkManager.CloneSymlink(const ASourceLink, ATargetLink: string): Boolean;
var
  Info: TSymlinkInfo;
begin
  Result := False;
  
  try
    Info := GetSymlinkInfo(ASourceLink);
    if Info.Status <> ssValid then
      Exit;
    
    Result := CreateSymlink(Info.TargetPath, ATargetLink, Info.LinkType);
    
  except
    Result := False;
  end;
end;

// 设置选项
procedure TSymlinkManager.SetOptions(const AOptions: TSymlinkOptions);
begin
  FOptions := AOptions;
end;

// 获取选项
function TSymlinkManager.GetOptions: TSymlinkOptions;
begin
  Result := FOptions;
end;

// 获取统计信息
function TSymlinkManager.GetStatistics(const ASearchPath: string; ARecursive: Boolean): TSymlinkStatistics;
var
  SearchOption: TSearchOption;
  Files: TArray<string>;
  I: Integer;
  Info: TSymlinkInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  try
    if ARecursive then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;
    
    try
      Files := TDirectory.GetFiles(ASearchPath, '*', SearchOption);
      
      for I := 0 to Length(Files) - 1 do
      begin
        if IsSymlink(Files[I]) then
        begin
          Inc(Result.TotalLinks);
          Info := GetSymlinkInfo(Files[I]);
          
          case Info.Status of
            ssValid: Inc(Result.ValidLinks);
            ssBroken: Inc(Result.BrokenLinks);
            ssCircular: Inc(Result.CircularLinks);
          end;
          
          case Info.LinkType of
            stFile: Inc(Result.FileLinks);
            stDirectory: Inc(Result.DirectoryLinks);
            stJunction: Inc(Result.Junctions);
            stHardLink: Inc(Result.HardLinks);
          end;
          
          if Info.IsRelative then
            Inc(Result.RelativeLinks)
          else
            Inc(Result.AbsoluteLinks);
        end;
      end;
      
      // 也检查目录
      var Dirs := TDirectory.GetDirectories(ASearchPath, '*', SearchOption);
      for I := 0 to Length(Dirs) - 1 do
      begin
        if IsSymlink(Dirs[I]) then
        begin
          Inc(Result.TotalLinks);
          Info := GetSymlinkInfo(Dirs[I]);
          
          case Info.Status of
            ssValid: Inc(Result.ValidLinks);
            ssBroken: Inc(Result.BrokenLinks);
            ssCircular: Inc(Result.CircularLinks);
          end;
          
          case Info.LinkType of
            stDirectory: Inc(Result.DirectoryLinks);
            stJunction: Inc(Result.Junctions);
          end;
          
          if Info.IsRelative then
            Inc(Result.RelativeLinks)
          else
            Inc(Result.AbsoluteLinks);
        end;
      end;
      
    except
      // 忽略访问错误
    end;
    
  except
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

// 生成报告
function TSymlinkManager.GenerateReport(const ASearchPath: string; ARecursive: Boolean): string;
var
  Report: TStringList;
  Stats: TSymlinkStatistics;
begin
  Report := TStringList.Create;
  
  try
    Stats := GetStatistics(ASearchPath, ARecursive);
    
    Report.Add('符号链接管理报告');
    Report.Add('═══════════════════════');
    Report.Add(Format('生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add(Format('搜索路径: %s', [ASearchPath]));
    Report.Add(Format('递归搜索: %s', [BoolToStr(ARecursive, True)]));
    Report.Add('');
    
    Report.Add('统计信息:');
    Report.Add(Format('  总链接数: %d', [Stats.TotalLinks]));
    Report.Add(Format('  有效链接: %d (%.1f%%)', [Stats.ValidLinks, Stats.ValidLinks * 100.0 / Max(1, Stats.TotalLinks)]));
    Report.Add(Format('  损坏链接: %d (%.1f%%)', [Stats.BrokenLinks, Stats.BrokenLinks * 100.0 / Max(1, Stats.TotalLinks)]));
    Report.Add(Format('  循环链接: %d (%.1f%%)', [Stats.CircularLinks, Stats.CircularLinks * 100.0 / Max(1, Stats.TotalLinks)]));
    Report.Add('');
    
    Report.Add('类型分布:');
    Report.Add(Format('  文件链接: %d', [Stats.FileLinks]));
    Report.Add(Format('  目录链接: %d', [Stats.DirectoryLinks]));
    Report.Add(Format('  目录联接: %d', [Stats.Junctions]));
    Report.Add(Format('  硬链接: %d', [Stats.HardLinks]));
    Report.Add('');
    
    Report.Add('路径类型:');
    Report.Add(Format('  相对路径: %d', [Stats.RelativeLinks]));
    Report.Add(Format('  绝对路径: %d', [Stats.AbsoluteLinks]));
    
    Result := Report.Text;
    
  finally
    Report.Free;
  end;
end;

// 生成健康报告
function TSymlinkManager.GenerateHealthReport(const ASearchPath: string): string;
var
  Report: TStringList;
  BrokenLinks, CircularLinks: TArray<string>;
  I: Integer;
begin
  Report := TStringList.Create;
  
  try
    Report.Add('符号链接健康检查报告');
    Report.Add('═══════════════════════');
    Report.Add(Format('检查时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add(Format('检查路径: %s', [ASearchPath]));
    Report.Add('');
    
    // 查找损坏的链接
    BrokenLinks := FindBrokenLinks(ASearchPath, True);
    Report.Add(Format('损坏的链接 (%d 个):', [Length(BrokenLinks)]));
    if Length(BrokenLinks) = 0 then
      Report.Add('  无')
    else
    begin
      for I := 0 to Length(BrokenLinks) - 1 do
        Report.Add('  - ' + BrokenLinks[I]);
    end;
    Report.Add('');
    
    // 查找循环链接
    CircularLinks := FindCircularLinks(ASearchPath, True);
    Report.Add(Format('循环引用链接 (%d 个):', [Length(CircularLinks)]));
    if Length(CircularLinks) = 0 then
      Report.Add('  无')
    else
    begin
      for I := 0 to Length(CircularLinks) - 1 do
        Report.Add('  - ' + CircularLinks[I]);
    end;
    Report.Add('');
    
    // 健康评估
    var TotalProblems := Length(BrokenLinks) + Length(CircularLinks);
    Report.Add('健康评估:');
    if TotalProblems = 0 then
      Report.Add('  ✓ 所有符号链接状态良好')
    else if TotalProblems <= 5 then
      Report.Add('  ⚠ 发现少量问题，建议修复')
    else
      Report.Add('  ❌ 发现较多问题，需要立即处理');
    
    Report.Add('');
    Report.Add('建议操作:');
    if Length(BrokenLinks) > 0 then
      Report.Add('  • 修复或删除损坏的符号链接');
    if Length(CircularLinks) > 0 then
      Report.Add('  • 解决循环引用问题');
    if TotalProblems = 0 then
      Report.Add('  • 继续保持良好的链接管理');
    
    Result := Report.Text;
    
  finally
    Report.Free;
  end;
end;

end.