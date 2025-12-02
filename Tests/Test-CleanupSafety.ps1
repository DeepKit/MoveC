# 清理功能安全验证测试
# 验证 IsSystemCriticalPath 逻辑

$Script:CriticalPaths = @(
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
)

function Test-IsSystemCriticalPath {
    param([string]$Path)
    
    $pathLower = $Path.ToLower()
    
    # 检查黑名单
    foreach ($critical in $Script:CriticalPaths) {
        if ($pathLower.StartsWith($critical) -or $pathLower.Contains($critical)) {
            return $true
        }
    }
    
    # 根目录保护
    if ($pathLower -match '^[a-z]:\\?$') {
        return $true
    }
    
    # 用户根目录保护 (层级<=3)
    if ($pathLower.EndsWith('\users') -or 
        ($pathLower -match '\\users\\' -and ($pathLower.Split('\').Count -le 4))) {
        return $true
    }
    
    return $false
}

# 定义测试用例
$TestCases = @(
    # 必须被阻止的路径
    @{ Path = 'C:\Windows\System32'; ExpectedBlocked = $true; Description = 'System32 目录' }
    @{ Path = 'C:\Windows\System32\drivers\etc\hosts'; ExpectedBlocked = $true; Description = 'System32 子目录文件' }
    @{ Path = 'C:\Program Files\SomeApp'; ExpectedBlocked = $true; Description = 'Program Files 目录' }
    @{ Path = 'C:\Program Files (x86)\SomeApp'; ExpectedBlocked = $true; Description = 'Program Files (x86) 目录' }
    @{ Path = 'C:\'; ExpectedBlocked = $true; Description = 'C盘根目录' }
    @{ Path = 'D:\'; ExpectedBlocked = $true; Description = 'D盘根目录' }
    @{ Path = 'C:\Users'; ExpectedBlocked = $true; Description = 'Users 根目录' }
    @{ Path = 'C:\Users\Administrator'; ExpectedBlocked = $true; Description = '用户根目录 (层级<=3)' }
    @{ Path = 'C:\Windows\WinSxS\somefolder'; ExpectedBlocked = $true; Description = 'WinSxS 子目录' }
    @{ Path = 'C:\Windows\Boot'; ExpectedBlocked = $true; Description = 'Boot 目录' }
    @{ Path = 'C:\Windows\Fonts'; ExpectedBlocked = $true; Description = 'Fonts 目录' }
    @{ Path = 'C:\ProgramData\Microsoft\Windows'; ExpectedBlocked = $true; Description = 'ProgramData\Microsoft 子目录' }
    @{ Path = 'C:\Users\Administrator\ntuser.dat'; ExpectedBlocked = $true; Description = 'NTUSER.DAT 文件' }
    @{ Path = 'C:\$MFT'; ExpectedBlocked = $true; Description = 'NTFS $MFT' }
    @{ Path = 'C:\System Volume Information'; ExpectedBlocked = $true; Description = 'System Volume Information' }
    
    # 允许删除的路径 (安全的清理目标)
    @{ Path = 'C:\Windows\Temp\somefile.tmp'; ExpectedBlocked = $false; Description = 'Windows Temp 目录文件' }
    @{ Path = 'C:\Windows\Prefetch\PROGRAM.EXE-12345.pf'; ExpectedBlocked = $false; Description = 'Prefetch 文件' }
    @{ Path = 'C:\Users\Administrator\AppData\Local\Temp'; ExpectedBlocked = $false; Description = '用户 Temp 目录 (层级>3)' }
    @{ Path = 'C:\Windows\Logs\CBS\CBS.log'; ExpectedBlocked = $false; Description = 'Windows Logs 文件' }
    @{ Path = 'D:\SomeFolder\cache'; ExpectedBlocked = $false; Description = '非系统盘缓存目录' }
    
    # Start Menu 等用户配置应被保护
    @{ Path = 'C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu'; ExpectedBlocked = $true; Description = 'Start Menu 目录' }
    @{ Path = 'C:\Users\Administrator\AppData\Local\Microsoft\Windows\Explorer'; ExpectedBlocked = $true; Description = 'Explorer 配置目录' }
    
    # 浏览器缓存应可清理
    @{ Path = 'C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Default\Cache'; ExpectedBlocked = $false; Description = 'Chrome 缓存目录' }
    @{ Path = 'C:\Users\Administrator\AppData\Local\Microsoft\Edge\User Data\Default\Cache'; ExpectedBlocked = $false; Description = 'Edge 缓存目录' }
    
    # Windows Debug/Panther 应可清理
    @{ Path = 'C:\Windows\Debug\WIA\wiatrace.log'; ExpectedBlocked = $false; Description = 'Windows Debug 日志' }
    @{ Path = 'C:\Windows\Panther\UnattendGC\setupact.log'; ExpectedBlocked = $false; Description = 'Windows Panther 日志' }
    
    # Windows Update 缓存
    @{ Path = 'C:\Windows\SoftwareDistribution\Download'; ExpectedBlocked = $false; Description = 'Windows Update 下载缓存' }
    
    # 边界情况
    @{ Path = 'C:\Windows\Servicing\Packages'; ExpectedBlocked = $true; Description = 'Servicing 目录' }
    @{ Path = 'C:\Users\Default'; ExpectedBlocked = $true; Description = 'Default 用户目录' }
    @{ Path = 'C:\Users\Public'; ExpectedBlocked = $true; Description = 'Public 目录' }
)

Write-Host "=== 清理功能安全验证测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$Passed = 0
$Failed = 0
$Index = 0

foreach ($test in $TestCases) {
    $Index++
    $actual = Test-IsSystemCriticalPath -Path $test.Path
    
    if ($actual -eq $test.ExpectedBlocked) {
        $Passed++
        Write-Host "[PASS] #$Index $($test.Description)" -ForegroundColor Green
    } else {
        $Failed++
        Write-Host "[FAIL] #$Index $($test.Description)" -ForegroundColor Red
        Write-Host "       路径: $($test.Path)" -ForegroundColor Yellow
        Write-Host "       预期阻止: $($test.ExpectedBlocked), 实际: $actual" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== 测试结果汇总 ===" -ForegroundColor Cyan
Write-Host "通过: $Passed, 失败: $Failed, 总计: $($TestCases.Count)" -ForegroundColor White

if ($Failed -eq 0) {
    Write-Host "状态: 全部通过 - 安全机制正常" -ForegroundColor Green
} else {
    Write-Host "状态: 存在失败 - 请检查安全机制!" -ForegroundColor Red
}
