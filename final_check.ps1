# 最终验证所有事件处理程序

Write-Host "=== 最终验证事件处理程序 ===" -ForegroundColor Cyan

$dfmFile = "uMain.dfm"
$pasFile = "uMain.pas"

$dfmContent = Get-Content $dfmFile -Raw
$pasContent = Get-Content $pasFile -Raw

# 提取所有事件处理程序
$events = [regex]::Matches($dfmContent, 'On\w+\s*=\s*(\w+)')

Write-Host "检查 $($events.Count) 个事件处理程序..." -ForegroundColor Yellow

$allGood = $true

foreach ($event in $events) {
    $methodName = $event.Groups[1].Value
    $eventLine = $event.Groups[0].Value
    
    # 检查方法是否在.pas文件中存在
    $methodPattern = "procedure\s+TfrmMain\.$methodName\s*\("
    
    if ($pasContent -match $methodPattern) {
        Write-Host "✅ $eventLine" -ForegroundColor Green
    } else {
        Write-Host "❌ $eventLine (方法不存在)" -ForegroundColor Red
        $allGood = $false
    }
}

if ($allGood) {
    Write-Host "`n🎉 所有事件处理程序验证通过！" -ForegroundColor Green
    Write-Host "程序应该可以正常运行，不会出现事件相关的错误。" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 仍有事件处理程序问题需要修复。" -ForegroundColor Red
}

# 额外检查：查找可能的签名问题
Write-Host "`n=== 检查方法签名 ===" -ForegroundColor Cyan

$timerEvents = [regex]::Matches($dfmContent, 'OnTimer\s*=\s*(\w+)')
foreach ($timerEvent in $timerEvents) {
    $methodName = $timerEvent.Groups[1].Value
    Write-Host "Timer事件: $methodName" -ForegroundColor Yellow
    
    # Timer事件应该有 (Sender: TObject) 签名
    if ($pasContent -match "procedure\s+TfrmMain\.$methodName\s*\(\s*Sender:\s*TObject\s*\)") {
        Write-Host "  ✅ 签名正确" -ForegroundColor Green
    } else {
        Write-Host "  ❌ 签名可能有问题" -ForegroundColor Red
    }
}

Write-Host "`n验证完成！" -ForegroundColor Cyan
