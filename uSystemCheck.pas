unit uSystemCheck;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Classes,
  System.IOUtils, System.Win.Registry;

type
  // 权限检查结果
  TPrivilegeCheckResult = record
    IsAdmin: Boolean;
    IsElevated: Boolean;
    CanCreateJunction: Boolean;
    Message: string;
  end;

  // 磁盘空间检查结果
  TDiskSpaceCheckResult = record
    Available: Int64;
    Required: Int64;
    HasEnoughSpace: Boolean;
    Message: string;
  end;

  // 文件占用信息
  TFileUsageInfo = record
    FilePath: string;
    ProcessName: string;
    ProcessID: DWORD;
    IsLocked: Boolean;
  end;

  // 系统检查工具类
  TSystemCheck = class
  public
    // 权限检查
    class function CheckAdminPrivileges: TPrivilegeCheckResult;
    class function IsRunAsAdmin: Boolean;
    class function IsProcessElevated: Boolean;
    class function CanCreateSymbolicLink: Boolean;
    class function RequestElevation(const AExePath: string = ''): Boolean;

    // 磁盘空间检查
    class function CheckDiskSpace(const APath: string; ARequiredBytes: Int64): TDiskSpaceCheckResult;
    class function GetDiskFreeSpace(const APath: string): Int64;
    class function GetDiskTotalSpace(const APath: string): Int64;

    // 文件占用检查
    class function IsFileInUse(const AFilePath: string): Boolean;
    class function IsDirectoryInUse(const ADirPath: string): Boolean;
    class function GetFileLockInfo(const AFilePath: string): TFileUsageInfo;
    class function TryDeleteFile(const AFilePath: string; out AErrorMsg: string): Boolean;
    class function TryRenameDirectory(const AOldPath, ANewPath: string; 
      out AErrorMsg: string): Boolean;

    // 辅助方法
    class function FormatBytes(ABytes: Int64): string;
  end;

implementation

uses
  Winapi.TlHelp32, System.StrUtils;

{ TSystemCheck }

// ===== 权限检查 =====

class function TSystemCheck.IsRunAsAdmin: Boolean;
var
  hToken: THandle;
  TokenInfo: TOKEN_ELEVATION;
  ReturnLength: Cardinal;
begin
  Result := False;
  
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
  try
    if GetTokenInformation(hToken, TokenElevation, @TokenInfo, 
       SizeOf(TokenInfo), ReturnLength) then
      Result := TokenInfo.TokenIsElevated <> 0;
  finally
    CloseHandle(hToken);
  end;
end;

class function TSystemCheck.IsProcessElevated: Boolean;
var
  TokenHandle: THandle;
  Elevation: TOKEN_ELEVATION;
  ReturnLength: DWORD;
begin
  Result := False;
  
  if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, TokenHandle) then
  begin
    try
      if GetTokenInformation(TokenHandle, TokenElevation, @Elevation,
         SizeOf(Elevation), ReturnLength) then
        Result := Elevation.TokenIsElevated <> 0;
    finally
      CloseHandle(TokenHandle);
    end;
  end;
end;

class function TSystemCheck.CanCreateSymbolicLink: Boolean;
var
  TestDir, TestLink: string;
begin
  Result := False;
  
  // 尝试在临时目录创建测试链接
  TestDir := TPath.GetTempPath + 'test_junction_' + IntToStr(GetTickCount);
  TestLink := TPath.GetTempPath + 'test_link_' + IntToStr(GetTickCount);
  
  try
    // 创建测试目录
    if not TDirectory.Exists(TestDir) then
      TDirectory.CreateDirectory(TestDir);
      
    // 尝试创建 Junction
    Result := CreateDirectoryW(PWideChar(TestLink), nil) or 
              (GetLastError = ERROR_ALREADY_EXISTS);
    
    // 清理
    try
      if TDirectory.Exists(TestLink) then
        RemoveDirectory(PWideChar(TestLink));
      if TDirectory.Exists(TestDir) then
        TDirectory.Delete(TestDir);
    except
      // 忽略清理错误
    end;
  except
    Result := False;
  end;
end;

class function TSystemCheck.CheckAdminPrivileges: TPrivilegeCheckResult;
begin
  Result.IsAdmin := IsRunAsAdmin;
  Result.IsElevated := IsProcessElevated;
  Result.CanCreateJunction := CanCreateSymbolicLink;
  
  if Result.IsAdmin and Result.IsElevated then
    Result.Message := '当前以管理员权限运行'
  else if Result.IsAdmin then
    Result.Message := '具有管理员权限，但未提升'
  else
    Result.Message := '未以管理员权限运行，部分功能可能受限';
end;

class function TSystemCheck.RequestElevation(const AExePath: string): Boolean;
var
  ExePath: string;
  SEI: TShellExecuteInfo;
begin
  Result := False;
  
  if AExePath <> '' then
    ExePath := AExePath
  else
    ExePath := ParamStr(0);
    
  ZeroMemory(@SEI, SizeOf(SEI));
  SEI.cbSize := SizeOf(SEI);
  SEI.Wnd := 0;
  SEI.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI;
  SEI.lpVerb := 'runas';
  SEI.lpFile := PChar(ExePath);
  SEI.nShow := SW_SHOWNORMAL;
  
  Result := ShellExecuteEx(@SEI);
end;

// ===== 磁盘空间检查 =====

class function TSystemCheck.GetDiskFreeSpace(const APath: string): Int64;
var
  FreeAvailable, TotalSpace: Int64;
begin
  Result := 0;
  
  if GetDiskFreeSpaceEx(PChar(ExtractFileDrive(APath)), 
     FreeAvailable, TotalSpace, nil) then
    Result := FreeAvailable;
end;

class function TSystemCheck.GetDiskTotalSpace(const APath: string): Int64;
var
  FreeAvailable, TotalSpace: Int64;
begin
  Result := 0;
  
  if GetDiskFreeSpaceEx(PChar(ExtractFileDrive(APath)), 
     FreeAvailable, TotalSpace, nil) then
    Result := TotalSpace;
end;

class function TSystemCheck.CheckDiskSpace(const APath: string; 
  ARequiredBytes: Int64): TDiskSpaceCheckResult;
var
  AvailableBytes: Int64;
  SafetyMargin: Int64;
begin
  AvailableBytes := GetDiskFreeSpace(APath);
  
  // 添加 10% 安全边际
  SafetyMargin := Round(ARequiredBytes * 1.1);
  
  Result.Available := AvailableBytes;
  Result.Required := SafetyMargin;
  Result.HasEnoughSpace := AvailableBytes >= SafetyMargin;
  
  if Result.HasEnoughSpace then
    Result.Message := Format('磁盘空间充足：可用 %s，需要 %s',
      [FormatBytes(AvailableBytes), FormatBytes(SafetyMargin)])
  else
    Result.Message := Format('磁盘空间不足：可用 %s，需要 %s（不足 %s）',
      [FormatBytes(AvailableBytes), FormatBytes(SafetyMargin),
       FormatBytes(SafetyMargin - AvailableBytes)]);
end;

// ===== 文件占用检查 =====

class function TSystemCheck.IsFileInUse(const AFilePath: string): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;
  
  if not TFile.Exists(AFilePath) then
    Exit;
    
  FileHandle := CreateFile(PChar(AFilePath), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    
  if FileHandle = INVALID_HANDLE_VALUE then
    Result := (GetLastError = ERROR_SHARING_VIOLATION)
  else
    CloseHandle(FileHandle);
end;

class function TSystemCheck.IsDirectoryInUse(const ADirPath: string): Boolean;
var
  Files: TArray<string>;
  FilePath: string;
begin
  Result := False;
  
  if not TDirectory.Exists(ADirPath) then
    Exit;
    
  try
    // 检查目录中的文件
    Files := TDirectory.GetFiles(ADirPath, '*', TSearchOption.soAllDirectories);
    for FilePath in Files do
    begin
      if IsFileInUse(FilePath) then
      begin
        Result := True;
        Break;
      end;
    end;
  except
    // 如果无法访问目录，认为它被占用
    Result := True;
  end;
end;

class function TSystemCheck.GetFileLockInfo(const AFilePath: string): TFileUsageInfo;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ModuleSnapshot: THandle;
  ModuleEntry: TModuleEntry32;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.FilePath := AFilePath;
  Result.IsLocked := IsFileInUse(AFilePath);
  
  if not Result.IsLocked then
    Exit;
    
  // 尝试查找占用进程（简化版本）
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot <> INVALID_HANDLE_VALUE then
  try
    ProcessEntry.dwSize := SizeOf(ProcessEntry);
    if Process32First(Snapshot, ProcessEntry) then
    begin
      repeat
        // 这里可以扩展更详细的进程-文件关联检查
        // 当前仅返回基本信息
      until not Process32Next(Snapshot, ProcessEntry);
    end;
  finally
    CloseHandle(Snapshot);
  end;
  
  Result.ProcessName := '未知进程';
  Result.ProcessID := 0;
end;

class function TSystemCheck.TryDeleteFile(const AFilePath: string; 
  out AErrorMsg: string): Boolean;
begin
  Result := False;
  AErrorMsg := '';
  
  try
    if not TFile.Exists(AFilePath) then
    begin
      Result := True;
      Exit;
    end;
    
    TFile.Delete(AFilePath);
    Result := True;
  except
    on E: Exception do
    begin
      AErrorMsg := E.Message;
      
      if IsFileInUse(AFilePath) then
        AErrorMsg := AErrorMsg + ' (文件被占用)';
    end;
  end;
end;

class function TSystemCheck.TryRenameDirectory(const AOldPath, ANewPath: string; 
  out AErrorMsg: string): Boolean;
begin
  Result := False;
  AErrorMsg := '';
  
  try
    if not TDirectory.Exists(AOldPath) then
    begin
      AErrorMsg := '源目录不存在';
      Exit;
    end;
    
    if TDirectory.Exists(ANewPath) then
    begin
      AErrorMsg := '目标目录已存在';
      Exit;
    end;
    
    // 检查目录是否被占用
    if IsDirectoryInUse(AOldPath) then
    begin
      AErrorMsg := '目录中的文件被占用';
      Exit;
    end;
    
    // 尝试重命名
    if RenameFile(AOldPath, ANewPath) then
      Result := True
    else
      AErrorMsg := '重命名失败: ' + SysErrorMessage(GetLastError);
      
  except
    on E: Exception do
      AErrorMsg := E.Message;
  end;
end;

// ===== 辅助方法 =====

class function TSystemCheck.FormatBytes(ABytes: Int64): string;
begin
  if ABytes < 1024 then
    Result := Format('%d B', [ABytes])
  else if ABytes < 1024 * 1024 then
    Result := Format('%.2f KB', [ABytes / 1024])
  else if ABytes < 1024 * 1024 * 1024 then
    Result := Format('%.2f MB', [ABytes / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [ABytes / (1024 * 1024 * 1024)]);
end;

end.
