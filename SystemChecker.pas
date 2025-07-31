unit SystemChecker;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Winapi.Windows, System.Win.Registry;

type
  // 系统检查器类
  TSystemChecker = class
  public
    // 系统信息检查
    class function GetWindowsVersion: string;
    class function GetSystemArchitecture: string;
    class function GetTotalMemory: Int64;
    class function GetAvailableMemory: Int64;
    class function GetCPUCount: Integer;
    class function GetCPUName: string;
    
    // 磁盘信息检查
    class function GetDiskFreeSpace(const ADrive: string): Int64;
    class function GetDiskTotalSpace(const ADrive: string): Int64;
    class function GetDiskUsagePercent(const ADrive: string): Double;
    
    // 权限检查
    class function IsRunningAsAdmin: Boolean;
    class function CanWriteToSystemFolder: Boolean;
    class function CanCreateSymbolicLinks: Boolean;
    
    // 系统兼容性检查
    class function IsWindows10OrLater: Boolean;
    class function SupportsSymbolicLinks: Boolean;
    class function HasNTFSSupport(const ADrive: string): Boolean;
    
    // 系统状态检查
    class function GetSystemUptime: Int64;
    class function IsSystemStable: Boolean;
    class function GetLastBootTime: TDateTime;
  end;

implementation

uses
  System.Win.ComObj;

class function TSystemChecker.GetWindowsVersion: string;
var
  VersionInfo: TOSVersionInfo;
begin
  Result := 'Unknown';
  
  try
    VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    if GetVersionEx(VersionInfo) then
    begin
      case VersionInfo.dwMajorVersion of
        10: 
        begin
          if VersionInfo.dwBuildNumber >= 22000 then
            Result := 'Windows 11'
          else
            Result := 'Windows 10';
        end;
        6:
        begin
          case VersionInfo.dwMinorVersion of
            3: Result := 'Windows 8.1';
            2: Result := 'Windows 8';
            1: Result := 'Windows 7';
            0: Result := 'Windows Vista';
          end;
        end;
        5:
        begin
          case VersionInfo.dwMinorVersion of
            2: Result := 'Windows Server 2003';
            1: Result := 'Windows XP';
            0: Result := 'Windows 2000';
          end;
        end;
      else
        Result := Format('Windows %d.%d', [VersionInfo.dwMajorVersion, VersionInfo.dwMinorVersion]);
      end;
    end;
  except
    Result := 'Unknown';
  end;
end;

class function TSystemChecker.GetSystemArchitecture: string;
var
  SystemInfo: TSystemInfo;
begin
  GetSystemInfo(SystemInfo);
  
  case SystemInfo.wProcessorArchitecture of
    PROCESSOR_ARCHITECTURE_AMD64: Result := 'x64';
    PROCESSOR_ARCHITECTURE_INTEL: Result := 'x86';
    PROCESSOR_ARCHITECTURE_ARM: Result := 'ARM';
  else
    Result := 'Unknown';
  end;
end;

class function TSystemChecker.GetTotalMemory: Int64;
var
  MemoryStatus: TMemoryStatusEx;
begin
  MemoryStatus.dwLength := SizeOf(TMemoryStatusEx);
  if GlobalMemoryStatusEx(MemoryStatus) then
    Result := MemoryStatus.ullTotalPhys
  else
    Result := 0;
end;

class function TSystemChecker.GetAvailableMemory: Int64;
var
  MemoryStatus: TMemoryStatusEx;
begin
  MemoryStatus.dwLength := SizeOf(TMemoryStatusEx);
  if GlobalMemoryStatusEx(MemoryStatus) then
    Result := MemoryStatus.ullAvailPhys
  else
    Result := 0;
end;

class function TSystemChecker.GetCPUCount: Integer;
var
  SystemInfo: TSystemInfo;
begin
  GetSystemInfo(SystemInfo);
  Result := SystemInfo.dwNumberOfProcessors;
end;

class function TSystemChecker.GetCPUName: string;
var
  Registry: TRegistry;
begin
  Result := 'Unknown CPU';
  
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    if Registry.OpenKey('HARDWARE\DESCRIPTION\System\CentralProcessor\0', False) then
    begin
      if Registry.ValueExists('ProcessorNameString') then
        Result := Trim(Registry.ReadString('ProcessorNameString'));
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

class function TSystemChecker.GetDiskFreeSpace(const ADrive: string): Int64;
var
  FreeBytes, TotalBytes: Int64;
begin
  if GetDiskFreeSpaceEx(PChar(ADrive), FreeBytes, TotalBytes, nil) then
    Result := FreeBytes
  else
    Result := 0;
end;

class function TSystemChecker.GetDiskTotalSpace(const ADrive: string): Int64;
var
  FreeBytes, TotalBytes: Int64;
begin
  if GetDiskFreeSpaceEx(PChar(ADrive), FreeBytes, TotalBytes, nil) then
    Result := TotalBytes
  else
    Result := 0;
end;

class function TSystemChecker.GetDiskUsagePercent(const ADrive: string): Double;
var
  FreeBytes, TotalBytes: Int64;
begin
  if GetDiskFreeSpaceEx(PChar(ADrive), FreeBytes, TotalBytes, nil) and (TotalBytes > 0) then
    Result := ((TotalBytes - FreeBytes) / TotalBytes) * 100
  else
    Result := 0;
end;

class function TSystemChecker.IsRunningAsAdmin: Boolean;
var
  Token: THandle;
  TokenInfo: TOKEN_ELEVATION;
  ReturnLength: DWORD;
begin
  Result := False;
  
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token) then
  try
    if GetTokenInformation(Token, TokenElevation, @TokenInfo, SizeOf(TokenInfo), ReturnLength) then
      Result := TokenInfo.TokenIsElevated <> 0;
  finally
    CloseHandle(Token);
  end;
end;

class function TSystemChecker.CanWriteToSystemFolder: Boolean;
var
  TestFile: string;
  FileHandle: THandle;
begin
  Result := False;
  
  try
    TestFile := GetEnvironmentVariable('WINDIR') + '\temp_test_' + IntToStr(GetTickCount) + '.tmp';
    
    FileHandle := CreateFile(PChar(TestFile), GENERIC_WRITE, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_TEMPORARY, 0);
    if FileHandle <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(FileHandle);
      DeleteFile(PChar(TestFile));
      Result := True;
    end;
  except
    Result := False;
  end;
end;

class function TSystemChecker.CanCreateSymbolicLinks: Boolean;
var
  TestLink, TestTarget: string;
begin
  Result := False;
  
  try
    TestTarget := System.IOUtils.TPath.GetTempPath + 'test_target_' + IntToStr(GetTickCount) + '.tmp';
    TestLink := System.IOUtils.TPath.GetTempPath + 'test_link_' + IntToStr(GetTickCount) + '.lnk';
    
    // 创建测试目标文件
    if FileCreate(TestTarget) <> -1 then
    begin
      // 尝试创建符号链接
      if CreateSymbolicLink(PChar(TestLink), PChar(TestTarget), 0) then
      begin
        Result := True;
        DeleteFile(PChar(TestLink));
      end;
      DeleteFile(PChar(TestTarget));
    end;
  except
    Result := False;
  end;
end;

class function TSystemChecker.IsWindows10OrLater: Boolean;
var
  VersionInfo: TOSVersionInfo;
begin
  Result := False;
  
  try
    VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    if GetVersionEx(VersionInfo) then
      Result := VersionInfo.dwMajorVersion >= 10;
  except
    Result := False;
  end;
end;

class function TSystemChecker.SupportsSymbolicLinks: Boolean;
begin
  // Windows Vista及以后版本支持符号链接
  Result := IsWindows10OrLater or CanCreateSymbolicLinks;
end;

class function TSystemChecker.HasNTFSSupport(const ADrive: string): Boolean;
var
  FileSystemName: array[0..MAX_PATH] of Char;
  MaxComponentLength, FileSystemFlags: DWORD;
begin
  Result := GetVolumeInformation(PChar(ADrive), nil, 0, nil, MaxComponentLength, FileSystemFlags, FileSystemName, MAX_PATH);
  if Result then
    Result := SameText(string(FileSystemName), 'NTFS');
end;

class function TSystemChecker.GetSystemUptime: Int64;
begin
  Result := GetTickCount64;
end;

class function TSystemChecker.IsSystemStable: Boolean;
begin
  // 简单的稳定性检查：系统运行时间超过5分钟
  Result := GetSystemUptime > 5 * 60 * 1000;
end;

class function TSystemChecker.GetLastBootTime: TDateTime;
var
  Uptime: Int64;
begin
  Uptime := GetSystemUptime;
  Result := Now - (Uptime / (24 * 60 * 60 * 1000));
end;

end.
