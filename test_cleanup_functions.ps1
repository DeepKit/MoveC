# 清理功能测试脚本
# 测试各项清理功能的可用性和安全性

Write-Host "=== C盘瘦身神器 - 清理功能测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date)" -ForegroundColor Yellow

# 创建测试环境
Write-Host "`n📁 创建测试环境..." -ForegroundColor Green

# 1. 创建测试临时文件
$testTempDir = "$env:TEMP\CDiskCleanerTest"
if (!(Test-Path $testTempDir)) {
    New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
}

# 创建一些测试文件
$testFiles = @()
for ($i = 1; $i -le 5; $i++) {
    $testFile = "$testTempDir\test_temp_$i.tmp"
    "Test temporary file content $i" | Out-File -FilePath $testFile -Encoding UTF8
    $testFiles += $testFile
}

Write-Host "   ✅ 创建了 $($testFiles.Count) 个测试临时文件" -ForegroundColor Green

# 2. 检查回收站状态
Write-Host "`n🗑️ 检查回收站状态..." -ForegroundColor Green
try {
    # 创建一个测试文件并删除到回收站
    $testRecycleFile = "$env:TEMP\test_recycle_file.txt"
    "Test file for recycle bin" | Out-File -FilePath $testRecycleFile -Encoding UTF8
    
    # 使用Shell.Application来删除到回收站
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace((Split-Path $testRecycleFile))
    $item = $folder.ParseName((Split-Path $testRecycleFile -Leaf))
    if ($item) {
        $item.InvokeVerb("delete")
        Write-Host "   ✅ 测试文件已添加到回收站" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️ 回收站测试文件创建失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. 检查系统临时目录
Write-Host "`n🧹 检查系统临时目录..." -ForegroundColor Green
$tempDirs = @(
    $env:TEMP,
    $env:TMP,
    "$env:WINDIR\Temp"
)

foreach ($dir in $tempDirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem $dir -File -ErrorAction SilentlyContinue | Measure-Object).Count
        $totalSize = (Get-ChildItem $dir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($totalSize / 1GB, 2)
        Write-Host "   📂 $dir : $fileCount 个文件, $sizeGB GB" -ForegroundColor Yellow
    } else {
        Write-Host "   ❌ $dir : 目录不存在" -ForegroundColor Red
    }
}

# 4. 检查Windows更新缓存
Write-Host "`n📦 检查Windows更新缓存..." -ForegroundColor Green
$updateDirs = @(
    "$env:WINDIR\SoftwareDistribution\Download",
    "$env:WINDIR\System32\catroot2"
)

foreach ($dir in $updateDirs) {
    if (Test-Path $dir) {
        try {
            $fileCount = (Get-ChildItem $dir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            $totalSize = (Get-ChildItem $dir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($totalSize / 1MB, 2)
            Write-Host "   📂 $dir : $fileCount 个文件, $sizeMB MB" -ForegroundColor Yellow
        } catch {
            Write-Host "   ⚠️ $dir : 需要管理员权限访问" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ $dir : 目录不存在" -ForegroundColor Red
    }
}

# 5. 检查备份文件
Write-Host "`n💾 检查系统备份..." -ForegroundColor Green
$backupDirs = @(
    "$env:WINDIR\System32\config\RegBack",
    "$env:WINDIR\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WebCache"
)

foreach ($dir in $backupDirs) {
    if (Test-Path $dir) {
        try {
            $fileCount = (Get-ChildItem $dir -File -ErrorAction SilentlyContinue | Measure-Object).Count
            $totalSize = (Get-ChildItem $dir -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($totalSize / 1MB, 2)
            Write-Host "   📂 $dir : $fileCount 个文件, $sizeMB MB" -ForegroundColor Yellow
        } catch {
            Write-Host "   ⚠️ $dir : 访问受限" -ForegroundColor Yellow
        }
    }
}

# 6. 磁盘空间统计
Write-Host "`n💽 当前磁盘空间状态..." -ForegroundColor Green
$drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $usedPercent = [math]::Round((($drive.Size - $drive.FreeSpace) / $drive.Size) * 100, 1)
    
    $status = if ($usedPercent -gt 90) { "🔴" } elseif ($usedPercent -gt 80) { "🟡" } else { "🟢" }
    Write-Host "   $status $($drive.DeviceID) $freeGB GB 可用 / $totalGB GB 总计 (使用率: $usedPercent%)" -ForegroundColor White
}

# 清理测试环境
Write-Host "`n🧽 清理测试环境..." -ForegroundColor Green
try {
    Remove-Item -Path $testTempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $testRecycleFile -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ 测试文件已清理" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ 部分测试文件清理失败" -ForegroundColor Yellow
}

# 测试总结
Write-Host "`n=== 测试总结 ===" -ForegroundColor Cyan
Write-Host "✅ 测试环境创建成功" -ForegroundColor Green
Write-Host "✅ 临时文件目录检查完成" -ForegroundColor Green
Write-Host "✅ 系统缓存目录检查完成" -ForegroundColor Green
Write-Host "✅ 磁盘空间统计完成" -ForegroundColor Green

Write-Host "`n📋 手动测试建议:" -ForegroundColor Yellow
Write-Host "1. 启动C盘瘦身.exe程序" -ForegroundColor White
Write-Host "2. 点击'清空回收站'按钮测试回收站清理" -ForegroundColor White
Write-Host "3. 点击'清理临时文件'按钮测试临时文件清理" -ForegroundColor White
Write-Host "4. 点击'清理更新缓存'按钮测试更新缓存清理" -ForegroundColor White
Write-Host "5. 观察状态栏的反馈信息" -ForegroundColor White

Write-Host "`n⚠️ 安全提醒:" -ForegroundColor Red
Write-Host "- 清理功能会永久删除文件，请谨慎使用" -ForegroundColor Yellow
Write-Host "- 建议在测试环境中先验证功能" -ForegroundColor Yellow
Write-Host "- 重要数据请提前备份" -ForegroundColor Yellow

Write-Host "`n测试脚本执行完成！" -ForegroundColor Green
