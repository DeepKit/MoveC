# 简化的功能测试脚本

Write-Host "=== C盘瘦身神器功能测试 ===" -ForegroundColor Cyan

# 测试1: 程序启动测试
Write-Host "`n1. 程序启动测试..." -ForegroundColor Green
if (Test-Path ".\C盘瘦身.exe") {
    Write-Host "   ✅ 可执行文件存在" -ForegroundColor Green
} else {
    Write-Host "   ❌ 可执行文件不存在" -ForegroundColor Red
}

# 测试2: 关键文件检查
Write-Host "`n2. 关键文件检查..." -ForegroundColor Green
$files = @("uMain.dfm", "uMain.pas", "uSmartDuplicateCleanup.dfm", "Core\ConfigManager.pas")
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file" -ForegroundColor Red
    }
}

# 测试3: 网站文件检查
Write-Host "`n3. 网站文件检查..." -ForegroundColor Green
$webFiles = @("html\index.html", "html\styles.css", "html\script.js")
foreach ($file in $webFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file" -ForegroundColor Red
    }
}

# 测试4: 编译测试
Write-Host "`n4. 编译测试..." -ForegroundColor Green
try {
    $result = & dcc32 -U"Core" "C盘瘦身.dpr" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ 编译成功" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 编译失败" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ 编译异常" -ForegroundColor Red
}

# 测试5: 磁盘空间检查
Write-Host "`n5. 磁盘空间检查..." -ForegroundColor Green
$cDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
if ($cDrive) {
    $freeGB = [math]::Round($cDrive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($cDrive.Size / 1GB, 2)
    Write-Host "   C盘: $freeGB GB 可用 / $totalGB GB 总计" -ForegroundColor Yellow
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan
Write-Host "请手动测试程序界面功能" -ForegroundColor Yellow
