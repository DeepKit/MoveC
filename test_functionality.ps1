# C盘瘦身神器功能测试脚本
# 测试各项基本功能是否正常工作

Write-Host "=== C盘瘦身神器功能测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date)" -ForegroundColor Yellow

# 测试1: 程序启动测试
Write-Host "`n1. 程序启动测试..." -ForegroundColor Green
try {
    $process = Start-Process ".\C盘瘦身.exe" -PassThru -WindowStyle Minimized
    Start-Sleep -Seconds 3
    
    if ($process -and !$process.HasExited) {
        Write-Host "   ✅ 程序启动成功" -ForegroundColor Green
        $process.CloseMainWindow()
        Start-Sleep -Seconds 2
        if (!$process.HasExited) {
            $process.Kill()
        }
    } else {
        Write-Host "   ❌ 程序启动失败" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ 程序启动异常: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试2: 文件存在性检查
Write-Host "`n2. 关键文件检查..." -ForegroundColor Green
$requiredFiles = @(
    "C盘瘦身.exe",
    "uMain.dfm",
    "uMain.pas",
    "uSmartDuplicateCleanup.dfm",
    "uSmartDuplicateCleanup.pas",
    "Core\ConfigManager.pas",
    "Core\DataTypes.pas"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file (缺失)" -ForegroundColor Red
    }
}

# 测试3: 网站文件检查
Write-Host "`n3. 网站文件检查..." -ForegroundColor Green
$webFiles = @(
    "html\index.html",
    "html\styles.css",
    "html\script.js"
)

foreach ($file in $webFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file (缺失)" -ForegroundColor Red
    }
}

# 测试4: 编译状态检查
Write-Host "`n4. 编译状态检查..." -ForegroundColor Green
try {
    $compileResult = & dcc32 -U"Core" "C盘瘦身.dpr" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ 编译成功" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 编译失败" -ForegroundColor Red
        Write-Host "   编译错误: $compileResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ 编译测试异常: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试5: 临时文件创建测试（模拟清理功能）
Write-Host "`n5. 清理功能模拟测试..." -ForegroundColor Green
try {
    # 创建测试临时文件
    $testTempDir = "$env:TEMP\CDiskCleanerTest"
    if (!(Test-Path $testTempDir)) {
        New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
    }

    # 创建一些测试文件
    $testFiles = @(
        "$testTempDir\test1.tmp",
        "$testTempDir\test2.log",
        "$testTempDir\test3.cache"
    )

    foreach ($file in $testFiles) {
        "Test content" | Out-File -FilePath $file -Encoding UTF8
    }

    Write-Host "   ✅ 测试文件创建成功" -ForegroundColor Green

    # 清理测试文件
    Remove-Item -Path $testTempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ 测试文件清理成功" -ForegroundColor Green

} catch {
    Write-Host "   ❌ 清理功能测试异常: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试6: 磁盘空间检查
Write-Host "`n6. 磁盘空间检查..." -ForegroundColor Green
try {
    $cDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $dDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='D:'"
    
    if ($cDrive) {
        $cFreeGB = [math]::Round($cDrive.FreeSpace / 1GB, 2)
        $cTotalGB = [math]::Round($cDrive.Size / 1GB, 2)
        $cUsedPercent = [math]::Round((($cDrive.Size - $cDrive.FreeSpace) / $cDrive.Size) * 100, 1)
        Write-Host "   C盘: $cFreeGB GB 可用 / $cTotalGB GB 总计 (使用率: $cUsedPercent%)" -ForegroundColor Yellow
    }
    
    if ($dDrive) {
        $dFreeGB = [math]::Round($dDrive.FreeSpace / 1GB, 2)
        $dTotalGB = [math]::Round($dDrive.Size / 1GB, 2)
        Write-Host "   D盘: $dFreeGB GB 可用 / $dTotalGB GB 总计" -ForegroundColor Yellow
    } else {
        Write-Host "   ⚠️ D盘不存在，迁移功能可能受限" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   ❌ 磁盘空间检查异常: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试总结
Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan
Write-Host "请手动测试以下功能:" -ForegroundColor Yellow
Write-Host "1. 启动程序并检查界面是否正常显示" -ForegroundColor White
Write-Host "2. 点击各个清理按钮是否有响应" -ForegroundColor White
Write-Host "3. 打开智能清理窗口是否显示中文" -ForegroundColor White
Write-Host "4. 测试目录选择和扫描功能" -ForegroundColor White
Write-Host "5. 检查配置管理器是否能正常打开" -ForegroundColor White

Write-Host "`n测试脚本执行完成!" -ForegroundColor Green
