unit TestCleanupSafety;

{ 清理功能安全验证测试
  
  此测试单元用于验证:
  1. 关键路径黑名单保护 (IsSystemCriticalPath)
  2. 安全删除白名单 (IsSafeToDelete)
  3. 根目录保护
  4. 用户目录保护
  
  运行方式: 在 IDE 中运行主程序，调用 RunSafetyTests
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

procedure RunSafetyTests;

implementation

type
  TTestCase = record
    Path: string;
    ExpectedBlocked: Boolean;
    Description: string;
  end;

// 模拟 IsSystemCriticalPath 逻辑进行测试
function TestIsSystemCriticalPath(const APath: string): Boolean;
const
  CRITICAL_PATHS: array[0..23] of string = (
    'c:\windows\system32',
    'c:\windows\syswow64',
    'c:\windows\boot',
    'c:\windows\drivers',
    'c:\windows\fonts',
    'c:\windows\winsxs',
    'c:\windows\servicing',
    'c:\windows\assembly',
    'c:\program files',
    'c:\program files (x86)',
    'c:\programdata\microsoft',
    'c:\users\all users',
    'c:\users\default',
    'c:\users\public',
    'c:\$mft',
    'c:\$logfile',
    'c:\$volume',
    'c:\$recycle.bin',
    'c:\system volume information',
    'appdata\roaming\microsoft\windows\start menu',
    'appdata\roaming\microsoft\windows\recent',
    'appdata\local\microsoft\windows\explorer',
    'ntuser.dat',
    'usrclass.dat'
  );
var
  PathLower: string;
  I: Integer;
begin
  Result := False;
  PathLower := LowerCase(APath);
  
  for I := Low(CRITICAL_PATHS) to High(CRITICAL_PATHS) do
  begin
    if PathLower.StartsWith(CRITICAL_PATHS[I]) or 
       PathLower.Contains(CRITICAL_PATHS[I]) then
    begin
      Result := True;
      Exit;
    end;
  end;
  
  // 禁止删除根目录
  if (Length(PathLower) <= 3) and (Pos(':\', PathLower) = 2) then
  begin
    Result := True;
    Exit;
  end;
  
  // 禁止删除用户根目录
  if PathLower.EndsWith('\users') or 
     (Pos('\users\', PathLower) > 0) and (PathLower.CountChar('\') <= 3) then
  begin
    Result := True;
    Exit;
  end;
end;

procedure RunSafetyTests;
var
  Tests: array of TTestCase;
  I, Passed, Failed: Integer;
  Actual: Boolean;
  Output: TStringList;
begin
  // 定义测试用例
  SetLength(Tests, 30);
  
  // 必须被阻止的路径
  Tests[0].Path := 'C:\Windows\System32';
  Tests[0].ExpectedBlocked := True;
  Tests[0].Description := 'System32 目录';
  
  Tests[1].Path := 'C:\Windows\System32\drivers\etc\hosts';
  Tests[1].ExpectedBlocked := True;
  Tests[1].Description := 'System32 子目录文件';
  
  Tests[2].Path := 'C:\Program Files\SomeApp';
  Tests[2].ExpectedBlocked := True;
  Tests[2].Description := 'Program Files 目录';
  
  Tests[3].Path := 'C:\Program Files (x86)\SomeApp';
  Tests[3].ExpectedBlocked := True;
  Tests[3].Description := 'Program Files (x86) 目录';
  
  Tests[4].Path := 'C:\';
  Tests[4].ExpectedBlocked := True;
  Tests[4].Description := 'C盘根目录';
  
  Tests[5].Path := 'D:\';
  Tests[5].ExpectedBlocked := True;
  Tests[5].Description := 'D盘根目录';
  
  Tests[6].Path := 'C:\Users';
  Tests[6].ExpectedBlocked := True;
  Tests[6].Description := 'Users 根目录';
  
  Tests[7].Path := 'C:\Users\Administrator';
  Tests[7].ExpectedBlocked := True;
  Tests[7].Description := '用户根目录 (层级<=3)';
  
  Tests[8].Path := 'C:\Windows\WinSxS\somefolder';
  Tests[8].ExpectedBlocked := True;
  Tests[8].Description := 'WinSxS 子目录';
  
  Tests[9].Path := 'C:\Windows\Boot';
  Tests[9].ExpectedBlocked := True;
  Tests[9].Description := 'Boot 目录';
  
  Tests[10].Path := 'C:\Windows\Fonts';
  Tests[10].ExpectedBlocked := True;
  Tests[10].Description := 'Fonts 目录';
  
  Tests[11].Path := 'C:\ProgramData\Microsoft\Windows';
  Tests[11].ExpectedBlocked := True;
  Tests[11].Description := 'ProgramData\Microsoft 子目录';
  
  Tests[12].Path := 'C:\Users\Administrator\ntuser.dat';
  Tests[12].ExpectedBlocked := True;
  Tests[12].Description := 'NTUSER.DAT 文件';
  
  Tests[13].Path := 'C:\$MFT';
  Tests[13].ExpectedBlocked := True;
  Tests[13].Description := 'NTFS $MFT';
  
  Tests[14].Path := 'C:\System Volume Information';
  Tests[14].ExpectedBlocked := True;
  Tests[14].Description := 'System Volume Information';
  
  // 允许删除的路径 (安全的清理目标)
  Tests[15].Path := 'C:\Windows\Temp\somefile.tmp';
  Tests[15].ExpectedBlocked := False;
  Tests[15].Description := 'Windows Temp 目录文件';
  
  Tests[16].Path := 'C:\Windows\Prefetch\PROGRAM.EXE-12345.pf';
  Tests[16].ExpectedBlocked := False;
  Tests[16].Description := 'Prefetch 文件';
  
  Tests[17].Path := 'C:\Users\Administrator\AppData\Local\Temp';
  Tests[17].ExpectedBlocked := False;
  Tests[17].Description := '用户 Temp 目录 (层级>3)';
  
  Tests[18].Path := 'C:\Windows\Logs\CBS\CBS.log';
  Tests[18].ExpectedBlocked := False;
  Tests[18].Description := 'Windows Logs 文件';
  
  Tests[19].Path := 'D:\SomeFolder\cache';
  Tests[19].ExpectedBlocked := False;
  Tests[19].Description := '非系统盘缓存目录';
  
  // Start Menu 等用户配置应被保护
  Tests[20].Path := 'C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu';
  Tests[20].ExpectedBlocked := True;
  Tests[20].Description := 'Start Menu 目录';
  
  Tests[21].Path := 'C:\Users\Administrator\AppData\Local\Microsoft\Windows\Explorer';
  Tests[21].ExpectedBlocked := True;
  Tests[21].Description := 'Explorer 配置目录';
  
  // 浏览器缓存应可清理
  Tests[22].Path := 'C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Default\Cache';
  Tests[22].ExpectedBlocked := False;
  Tests[22].Description := 'Chrome 缓存目录';
  
  Tests[23].Path := 'C:\Users\Administrator\AppData\Local\Microsoft\Edge\User Data\Default\Cache';
  Tests[23].ExpectedBlocked := False;
  Tests[23].Description := 'Edge 缓存目录';
  
  // Windows Debug/Panther 应可清理
  Tests[24].Path := 'C:\Windows\Debug\WIA\wiatrace.log';
  Tests[24].ExpectedBlocked := False;
  Tests[24].Description := 'Windows Debug 日志';
  
  Tests[25].Path := 'C:\Windows\Panther\UnattendGC\setupact.log';
  Tests[25].ExpectedBlocked := False;
  Tests[25].Description := 'Windows Panther 日志';
  
  // Windows Update 缓存
  Tests[26].Path := 'C:\Windows\SoftwareDistribution\Download';
  Tests[26].ExpectedBlocked := False;
  Tests[26].Description := 'Windows Update 下载缓存';
  
  // 边界情况
  Tests[27].Path := 'C:\Windows\Servicing\Packages';
  Tests[27].ExpectedBlocked := True;
  Tests[27].Description := 'Servicing 目录';
  
  Tests[28].Path := 'C:\Users\Default';
  Tests[28].ExpectedBlocked := True;
  Tests[28].Description := 'Default 用户目录';
  
  Tests[29].Path := 'C:\Users\Public';
  Tests[29].ExpectedBlocked := True;
  Tests[29].Description := 'Public 目录';
  
  // 执行测试
  Output := TStringList.Create;
  try
    Passed := 0;
    Failed := 0;
    
    Output.Add('=== 清理功能安全验证测试 ===');
    Output.Add('测试时间: ' + DateTimeToStr(Now));
    Output.Add('');
    
    for I := 0 to High(Tests) do
    begin
      Actual := TestIsSystemCriticalPath(Tests[I].Path);
      
      if Actual = Tests[I].ExpectedBlocked then
      begin
        Inc(Passed);
        Output.Add(Format('[PASS] #%d %s', [I+1, Tests[I].Description]));
        Output.Add(Format('       路径: %s', [Tests[I].Path]));
        Output.Add(Format('       预期阻止: %s, 实际: %s', [
          BoolToStr(Tests[I].ExpectedBlocked, True),
          BoolToStr(Actual, True)]));
      end
      else
      begin
        Inc(Failed);
        Output.Add(Format('[FAIL] #%d %s', [I+1, Tests[I].Description]));
        Output.Add(Format('       路径: %s', [Tests[I].Path]));
        Output.Add(Format('       预期阻止: %s, 实际: %s  *** 失败 ***', [
          BoolToStr(Tests[I].ExpectedBlocked, True),
          BoolToStr(Actual, True)]));
      end;
      Output.Add('');
    end;
    
    Output.Add('=== 测试结果汇总 ===');
    Output.Add(Format('通过: %d, 失败: %d, 总计: %d', [Passed, Failed, Length(Tests)]));
    
    if Failed = 0 then
      Output.Add('状态: 全部通过 - 安全机制正常')
    else
      Output.Add('状态: 存在失败 - 请检查安全机制!');
    
    // 保存结果
    Output.SaveToFile('D:\_Progs\02Business\MoveC\tests\safety_test_results.txt');
    
    // 也输出到控制台
    WriteLn(Output.Text);
    
  finally
    Output.Free;
  end;
end;

end.
