# 简化的清理功能测试

Write-Host "=== 清理功能测试 ===" -ForegroundColor Cyan

# 检查临时目录
Write-Host "`n1. 检查临时目录..." -ForegroundColor Green
$tempDir = $env:TEMP
if (Test-Path $tempDir) {
    $files = Get-ChildItem $tempDir -File -ErrorAction SilentlyContinue
    Write-Host "   临时目录: $tempDir" -ForegroundColor Yellow
    Write-Host "   文件数量: $($files.Count)" -ForegroundColor Yellow
} else {
    Write-Host "   临时目录不存在" -ForegroundColor Red
}

# 检查Windows临时目录
Write-Host "`n2. 检查Windows临时目录..." -ForegroundColor Green
$winTemp = "$env:WINDIR\Temp"
if (Test-Path $winTemp) {
    $files = Get-ChildItem $winTemp -File -ErrorAction SilentlyContinue
    Write-Host "   Windows临时目录: $winTemp" -ForegroundColor Yellow
    Write-Host "   文件数量: $($files.Count)" -ForegroundColor Yellow
} else {
    Write-Host "   Windows临时目录不存在" -ForegroundColor Red
}

# 检查更新缓存
Write-Host "`n3. 检查更新缓存..." -ForegroundColor Green
$updateCache = "$env:WINDIR\SoftwareDistribution\Download"
if (Test-Path $updateCache) {
    Write-Host "   更新缓存目录存在: $updateCache" -ForegroundColor Yellow
} else {
    Write-Host "   更新缓存目录不存在" -ForegroundColor Red
}

# 磁盘空间检查
Write-Host "`n4. 磁盘空间检查..." -ForegroundColor Green
$cDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
if ($cDrive) {
    $freeGB = [math]::Round($cDrive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($cDrive.Size / 1GB, 2)
    $usedPercent = [math]::Round((($cDrive.Size - $cDrive.FreeSpace) / $cDrive.Size) * 100, 1)
    Write-Host "   C盘: $freeGB GB 可用 / $totalGB GB 总计 (使用率: $usedPercent%)" -ForegroundColor Yellow
}

$dDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='D:'"
if ($dDrive) {
    $freeGB = [math]::Round($dDrive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($dDrive.Size / 1GB, 2)
    Write-Host "   D盘: $freeGB GB 可用 / $totalGB GB 总计" -ForegroundColor Yellow
} else {
    Write-Host "   D盘不存在" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan
Write-Host "请手动测试程序的清理功能" -ForegroundColor Yellow
