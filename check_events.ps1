# 检查.dfm文件中的事件处理程序是否在.pas文件中都有对应实现

$dfmFile = "uMain.dfm"
$pasFile = "uMain.pas"

# 读取文件内容
$dfmContent = Get-Content $dfmFile -Raw
$pasContent = Get-Content $pasFile -Raw

# 提取.dfm中的所有事件处理程序
$events = [regex]::Matches($dfmContent, 'On\w+\s*=\s*(\w+)')

Write-Host "检查.dfm文件中的事件处理程序..." -ForegroundColor Green
Write-Host "总共找到 $($events.Count) 个事件处理程序" -ForegroundColor Yellow

$missingMethods = @()

foreach ($event in $events) {
    $methodName = $event.Groups[1].Value
    
    # 检查方法是否在.pas文件中存在
    $methodPattern = "procedure\s+TfrmMain\.$methodName\s*\("
    
    if ($pasContent -notmatch $methodPattern) {
        $missingMethods += $methodName
        Write-Host "❌ 缺失方法: $methodName" -ForegroundColor Red
    } else {
        Write-Host "✅ 找到方法: $methodName" -ForegroundColor Green
    }
}

if ($missingMethods.Count -eq 0) {
    Write-Host "`n🎉 所有事件处理程序都有对应的实现！" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 发现 $($missingMethods.Count) 个缺失的方法:" -ForegroundColor Yellow
    foreach ($method in $missingMethods) {
        Write-Host "  - $method" -ForegroundColor Red
    }
}
