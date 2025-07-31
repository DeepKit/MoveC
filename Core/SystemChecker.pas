unit SystemChecker;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Win.Registry,
  DataTypes;

type
  // 系统检查结果
  TSystemCheckResult = record
    CheckName: string;
    Passed: Boolean;
    Message: string;
    Severity: Integer; // 0=信息, 1=警告, 2=错误
  end;

  // 系统检查器
  TSystemChecker = class
  private
    FCheckResults: TArray<TSystemCheckResult>;
    
    procedure AddCheckResult(const ACheckName: string; APassed: Boolean; 
                           const AMessage: string; ASeverity: Integer = 0);
    function CheckWindowsVersion: Boolean;
    function CheckAdminRights: Boolean;
    function CheckDiskSpace: Boolean;
    function CheckMemory: Boolean;
    function CheckDotNetFramework: Boolean;
    function CheckFileSystemSupport: Boolean;
    function CheckAntivirusCompatibility: Boolean;
    function GetWindowsVersionString: string;
    function GetAvailableDiskSpace(const ADrive: string): Int64;
    function GetTotalMemory: Int64;
    function IsRunningAsAdmin: Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 执行系统检查
    function PerformSystemCheck: Boolean;
    function PerformQuickCheck: Boolean;
    
    // 获取检查结果
    function GetCheckResults: TArray<TSystemCheckResult>;
    function GetErrorCount: Integer;
    function GetWarningCount: Integer;
    function HasCriticalErrors: Boolean;
    
    // 生成检查报告
    function GenerateReport: string;
    function GenerateHTMLReport: string;
    
    // 修复建议
    function GetFixSuggestions: TStringList;
  end;

implementation

uses
  System.IOUtils, Vcl.Forms;

type
  TOKEN_ELEVATION = record
    TokenIsElevated: DWORD;
  end;

const
  TokenElevation = 20;

constructor TSystemChecker.Create;
begin
  inherited;
  SetLength(FCheckResults, 0);
end;

destructor TSystemChecker.Destroy;
begin
  inherited;
end;

// 添加检查结果
procedure TSystemChecker.AddCheckResult(const ACheckName: string; APassed: Boolean; 
                                       const AMessage: string; ASeverity: Integer = 0);
var
  CheckResult: TSystemCheckResult;
begin
  CheckResult.CheckName := ACheckName;
  CheckResult.Passed := APassed;
  CheckResult.Message := AMessage;
  CheckResult.Severity := ASeverity;
  
  SetLength(FCheckResults, Length(FCheckResults) + 1);
  FCheckResults[High(FCheckResults)] := CheckResult;
end;

// 执行完整系统检查
function TSystemChecker.PerformSystemCheck: Boolean;
var
  AllPassed: Boolean;
begin
  SetLength(FCheckResults, 0);
  AllPassed := True;
  
  try
    // Windows版本检查
    if not CheckWindowsVersion then
      AllPassed := False;
    
    // 管理员权限检查
    if not CheckAdminRights then
      AllPassed := False;
    
    // 磁盘空间检查
    if not CheckDiskSpace then
      AllPassed := False;
    
    // 内存检查
    if not CheckMemory then
      AllPassed := False;
    
    // .NET Framework检查
    if not CheckDotNetFramework then
      AllPassed := False;
    
    // 文件系统支持检查
    if not CheckFileSystemSupport then
      AllPassed := False;
    
    // 杀毒软件兼容性检查
    if not CheckAntivirusCompatibility then
      AllPassed := False;
    
    Result := AllPassed;
    
  except
    on E: Exception do
    begin
      AddCheckResult('系统检查异常', False, '系统检查过程中发生异常: ' + E.Message, 2);
      Result := False;
    end;
  end;
end;

// 执行快速检查
function TSystemChecker.PerformQuickCheck: Boolean;
var
  AllPassed: Boolean;
begin
  SetLength(FCheckResults, 0);
  AllPassed := True;
  
  try
    // 只检查关键项目
    if not CheckWindowsVersion then
      AllPassed := False;
    
    if not CheckDiskSpace then
      AllPassed := False;
    
    if not CheckFileSystemSupport then
      AllPassed := False;
    
    Result := AllPassed;
    
  except
    on E: Exception do
    begin
      AddCheckResult('快速检查异常', False, '快速检查过程中发生异常: ' + E.Message, 2);
      Result := False;
    end;
  end;
end;

// 检查Windows版本
function TSystemChecker.CheckWindowsVersion: Boolean;
var
  VersionInfo: TOSVersionInfo;
  VersionString: string;
begin
  Result := True;
  
  try
    VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    if GetVersionEx(VersionInfo) then
    begin
      VersionString := GetWindowsVersionString;
      
      // 检查是否为支持的Windows版本
      if (VersionInfo.dwMajorVersion >= 6) then // Windows Vista及以上
      begin
        AddCheckResult('Windows版本', True, 
          Format('当前系统: %s (版本 %d.%d)', [VersionString, VersionInfo.dwMajorVersion, VersionInfo.dwMinorVersion]), 0);
      end
      else
      begin
        AddCheckResult('Windows版本', False, 
          Format('不支持的Windows版本: %s。建议使用Windows 7或更高版本', [VersionString]), 2);
        Result := False;
      end;
    end
    else
    begin
      AddCheckResult('Windows版本', False, '无法获取Windows版本信息', 1);
      Result := False;
    end;
    
  except
    on E: Exception do
    begin
      AddCheckResult('Windows版本', False, 'Windows版本检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 检查管理员权限
function TSystemChecker.CheckAdminRights: Boolean;
begin
  Result := True;
  
  try
    if IsRunningAsAdmin then
    begin
      AddCheckResult('管理员权限', True, '程序以管理员权限运行', 0);
    end
    else
    begin
      AddCheckResult('管理员权限', False, '程序未以管理员权限运行。某些功能可能受限', 1);
      Result := False;
    end;
    
  except
    on E: Exception do
    begin
      AddCheckResult('管理员权限', False, '权限检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 检查磁盘空间
function TSystemChecker.CheckDiskSpace: Boolean;
var
  SystemDrive: string;
  AvailableSpace: Int64;
  RequiredSpace: Int64;
begin
  Result := True;
  RequiredSpace := 100 * 1024 * 1024; // 100MB最小要求
  
  try
    SystemDrive := ExtractFileDrive(Application.ExeName);
    AvailableSpace := GetAvailableDiskSpace(SystemDrive);
    
    if AvailableSpace >= RequiredSpace then
    begin
      AddCheckResult('磁盘空间', True, 
        Format('可用空间: %.2f GB', [AvailableSpace / (1024 * 1024 * 1024)]), 0);
    end
    else
    begin
      AddCheckResult('磁盘空间', False, 
        Format('磁盘空间不足。可用: %.2f MB，需要: %.2f MB', 
        [AvailableSpace / (1024 * 1024), RequiredSpace / (1024 * 1024)]), 2);
      Result := False;
    end;
    
  except
    on E: Exception do
    begin
      AddCheckResult('磁盘空间', False, '磁盘空间检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 检查内存
function TSystemChecker.CheckMemory: Boolean;
var
  MemoryStatus: TMemoryStatusEx;
  TotalMemory, AvailableMemory: Int64;
  RequiredMemory: Int64;
begin
  Result := True;
  RequiredMemory := 512 * 1024 * 1024; // 512MB最小要求
  
  try
    MemoryStatus.dwLength := SizeOf(TMemoryStatusEx);
    if GlobalMemoryStatusEx(MemoryStatus) then
    begin
      TotalMemory := MemoryStatus.ullTotalPhys;
      AvailableMemory := MemoryStatus.ullAvailPhys;
      
      if AvailableMemory >= RequiredMemory then
      begin
        AddCheckResult('系统内存', True, 
          Format('总内存: %.2f GB，可用: %.2f GB', 
          [TotalMemory / (1024 * 1024 * 1024), AvailableMemory / (1024 * 1024 * 1024)]), 0);
      end
      else
      begin
        AddCheckResult('系统内存', False, 
          Format('可用内存不足。可用: %.2f MB，建议: %.2f MB', 
          [AvailableMemory / (1024 * 1024), RequiredMemory / (1024 * 1024)]), 1);
        Result := False;
      end;
    end
    else
    begin
      AddCheckResult('系统内存', False, '无法获取内存信息', 1);
      Result := False;
    end;
    
  except
    on E: Exception do
    begin
      AddCheckResult('系统内存', False, '内存检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 检查.NET Framework
function TSystemChecker.CheckDotNetFramework: Boolean;
var
  Registry: TRegistry;
  DotNetVersion: string;
begin
  Result := True;
  
  try
    Registry := TRegistry.Create(KEY_READ);
    try
      Registry.RootKey := HKEY_LOCAL_MACHINE;
      
      // 检查.NET Framework 4.0或更高版本
      if Registry.OpenKey('SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full', False) then
      begin
        if Registry.ValueExists('Release') then
        begin
          DotNetVersion := '4.0+';
          AddCheckResult('.NET Framework', True, 
            Format('已安装 .NET Framework %s', [DotNetVersion]), 0);
        end
        else
        begin
          AddCheckResult('.NET Framework', False, 
            '未检测到 .NET Framework 4.0 或更高版本', 1);
          Result := False;
        end;
        Registry.CloseKey;
      end
      else
      begin
        AddCheckResult('.NET Framework', False, 
          '未检测到 .NET Framework', 1);
        Result := False;
      end;
      
    finally
      Registry.Free;
    end;
    
  except
    on E: Exception do
    begin
      AddCheckResult('.NET Framework', False, '.NET Framework检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 检查文件系统支持
function TSystemChecker.CheckFileSystemSupport: Boolean;
var
  SystemDrive: string;
  FileSystem: string;
  VolumeNameBuffer: array[0..MAX_PATH] of Char;
  FileSystemNameBuffer: array[0..MAX_PATH] of Char;
  SerialNumber, MaxComponentLength, FileSystemFlags: DWORD;
begin
  Result := True;
  
  try
    SystemDrive := ExtractFileDrive(Application.ExeName) + '\';
    
    if GetVolumeInformation(PChar(SystemDrive), VolumeNameBuffer, MAX_PATH,
                           @SerialNumber, MaxComponentLength, FileSystemFlags,
                           FileSystemNameBuffer, MAX_PATH) then
    begin
      FileSystem := string(FileSystemNameBuffer);
      
      if (FileSystem = 'NTFS') or (FileSystem = 'ReFS') then
      begin
        AddCheckResult('文件系统', True, 
          Format('文件系统: %s (支持符号链接)', [FileSystem]), 0);
      end
      else
      begin
        AddCheckResult('文件系统', False, 
          Format('文件系统: %s (不完全支持符号链接功能)', [FileSystem]), 1);
        Result := False;
      end;
    end
    else
    begin
      AddCheckResult('文件系统', False, '无法获取文件系统信息', 1);
      Result := False;
    end;
    
  except
    on E: Exception do
    begin
      AddCheckResult('文件系统', False, '文件系统检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 检查杀毒软件兼容性
function TSystemChecker.CheckAntivirusCompatibility: Boolean;
begin
  Result := True;
  
  try
    // 这里可以添加特定杀毒软件的检查逻辑
    // 目前只是一个通用提醒
    AddCheckResult('杀毒软件兼容性', True, 
      '请确保杀毒软件不会阻止文件操作。如遇问题，请将程序添加到白名单', 0);
    
  except
    on E: Exception do
    begin
      AddCheckResult('杀毒软件兼容性', False, '杀毒软件兼容性检查失败: ' + E.Message, 1);
      Result := False;
    end;
  end;
end;

// 获取Windows版本字符串
function TSystemChecker.GetWindowsVersionString: string;
var
  VersionInfo: TOSVersionInfo;
begin
  Result := 'Unknown';
  
  VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(VersionInfo) then
  begin
    case VersionInfo.dwMajorVersion of
      5: case VersionInfo.dwMinorVersion of
           0: Result := 'Windows 2000';
           1: Result := 'Windows XP';
           2: Result := 'Windows Server 2003';
         end;
      6: case VersionInfo.dwMinorVersion of
           0: Result := 'Windows Vista/Server 2008';
           1: Result := 'Windows 7/Server 2008 R2';
           2: Result := 'Windows 8/Server 2012';
           3: Result := 'Windows 8.1/Server 2012 R2';
         end;
      10: Result := 'Windows 10/11/Server 2016+';
    end;
  end;
end;

// 获取可用磁盘空间
function TSystemChecker.GetAvailableDiskSpace(const ADrive: string): Int64;
var
  FreeBytesAvailable, TotalNumberOfBytes: Int64;
begin
  Result := 0;
  
  if GetDiskFreeSpaceEx(PChar(ADrive), FreeBytesAvailable, TotalNumberOfBytes, nil) then
    Result := FreeBytesAvailable;
end;

// 获取总内存
function TSystemChecker.GetTotalMemory: Int64;
var
  MemoryStatus: TMemoryStatusEx;
begin
  Result := 0;
  
  MemoryStatus.dwLength := SizeOf(TMemoryStatusEx);
  if GlobalMemoryStatusEx(MemoryStatus) then
    Result := MemoryStatus.ullTotalPhys;
end;

// 检查是否以管理员权限运行
function TSystemChecker.IsRunningAsAdmin: Boolean;
var
  hToken: THandle;
  TokenElevationInfo: TOKEN_ELEVATION;
  dwSize: DWORD;
begin
  Result := False;

  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
  try
    if GetTokenInformation(hToken, TTokenInformationClass(TokenElevation), @TokenElevationInfo, SizeOf(TOKEN_ELEVATION), dwSize) then
      Result := TokenElevationInfo.TokenIsElevated <> 0;
  finally
    CloseHandle(hToken);
  end;
end;

// 获取检查结果
function TSystemChecker.GetCheckResults: TArray<TSystemCheckResult>;
begin
  Result := FCheckResults;
end;

// 获取错误数量
function TSystemChecker.GetErrorCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Length(FCheckResults) - 1 do
  begin
    if (not FCheckResults[I].Passed) and (FCheckResults[I].Severity = 2) then
      Inc(Result);
  end;
end;

// 获取警告数量
function TSystemChecker.GetWarningCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Length(FCheckResults) - 1 do
  begin
    if (not FCheckResults[I].Passed) and (FCheckResults[I].Severity = 1) then
      Inc(Result);
  end;
end;

// 是否有严重错误
function TSystemChecker.HasCriticalErrors: Boolean;
begin
  Result := GetErrorCount > 0;
end;

// 生成检查报告
function TSystemChecker.GenerateReport: string;
var
  I: Integer;
  Report: TStringList;
  CheckResult: TSystemCheckResult;
  StatusText: string;
begin
  Report := TStringList.Create;
  try
    Report.Add('=== 系统兼容性检查报告 ===');
    Report.Add('检查时间: ' + DateTimeToStr(Now));
    Report.Add('');
    
    for I := 0 to Length(FCheckResults) - 1 do
    begin
      CheckResult := FCheckResults[I];
      
      if CheckResult.Passed then
        StatusText := '[通过]'
      else
        case CheckResult.Severity of
          1: StatusText := '[警告]';
          2: StatusText := '[错误]';
          else StatusText := '[失败]';
        end;
      
      Report.Add(Format('%s %s: %s', [StatusText, CheckResult.CheckName, CheckResult.Message]));
    end;
    
    Report.Add('');
    Report.Add(Format('总计: %d项检查，%d个错误，%d个警告', 
      [Length(FCheckResults), GetErrorCount, GetWarningCount]));
    
    Result := Report.Text;
    
  finally
    Report.Free;
  end;
end;

// 生成HTML报告
function TSystemChecker.GenerateHTMLReport: string;
var
  I: Integer;
  Report: TStringList;
  CheckResult: TSystemCheckResult;
  StatusClass, StatusText: string;
begin
  Report := TStringList.Create;
  try
    Report.Add('<html><head><title>系统兼容性检查报告</title>');
    Report.Add('<style>');
    Report.Add('body { font-family: Arial, sans-serif; margin: 20px; }');
    Report.Add('.pass { color: green; }');
    Report.Add('.warning { color: orange; }');
    Report.Add('.error { color: red; }');
    Report.Add('table { border-collapse: collapse; width: 100%; }');
    Report.Add('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    Report.Add('th { background-color: #f2f2f2; }');
    Report.Add('</style></head><body>');
    
    Report.Add('<h1>系统兼容性检查报告</h1>');
    Report.Add('<p>检查时间: ' + DateTimeToStr(Now) + '</p>');
    
    Report.Add('<table>');
    Report.Add('<tr><th>检查项目</th><th>状态</th><th>详细信息</th></tr>');
    
    for I := 0 to Length(FCheckResults) - 1 do
    begin
      CheckResult := FCheckResults[I];
      
      if CheckResult.Passed then
      begin
        StatusClass := 'pass';
        StatusText := '通过';
      end
      else
        case CheckResult.Severity of
          1: begin
               StatusClass := 'warning';
               StatusText := '警告';
             end;
          2: begin
               StatusClass := 'error';
               StatusText := '错误';
             end;
          else begin
                 StatusClass := 'error';
                 StatusText := '失败';
               end;
        end;
      
      Report.Add(Format('<tr><td>%s</td><td class="%s">%s</td><td>%s</td></tr>', 
        [CheckResult.CheckName, StatusClass, StatusText, CheckResult.Message]));
    end;
    
    Report.Add('</table>');
    
    Report.Add(Format('<p><strong>总计:</strong> %d项检查，%d个错误，%d个警告</p>', 
      [Length(FCheckResults), GetErrorCount, GetWarningCount]));
    
    Report.Add('</body></html>');
    
    Result := Report.Text;
    
  finally
    Report.Free;
  end;
end;

// 获取修复建议
function TSystemChecker.GetFixSuggestions: TStringList;
var
  I: Integer;
  CheckResult: TSystemCheckResult;
begin
  Result := TStringList.Create;
  
  for I := 0 to Length(FCheckResults) - 1 do
  begin
    CheckResult := FCheckResults[I];
    
    if not CheckResult.Passed then
    begin
      if CheckResult.CheckName = 'Windows版本' then
        Result.Add('• 升级到Windows 7或更高版本以获得最佳兼容性')
      else if CheckResult.CheckName = '管理员权限' then
        Result.Add('• 右键点击程序图标，选择"以管理员身份运行"')
      else if CheckResult.CheckName = '磁盘空间' then
        Result.Add('• 清理磁盘空间或选择其他驱动器进行操作')
      else if CheckResult.CheckName = '系统内存' then
        Result.Add('• 关闭不必要的程序以释放内存')
      else if CheckResult.CheckName = '.NET Framework' then
        Result.Add('• 从Microsoft官网下载并安装.NET Framework 4.0或更高版本')
      else if CheckResult.CheckName = '文件系统' then
        Result.Add('• 考虑将目标位置设置为NTFS格式的驱动器');
    end;
  end;
  
  if Result.Count = 0 then
    Result.Add('系统检查通过，无需修复操作。');
end;

end.
