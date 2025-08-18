# 全面检查.dfm文件中的所有事件处理程序

$dfmFile = "uMain.dfm"
$pasFile = "uMain.pas"

Write-Host "=== 全面检查事件处理程序 ===" -ForegroundColor Cyan

# 读取文件内容
$dfmContent = Get-Content $dfmFile -Raw
$pasContent = Get-Content $pasFile -Raw

# 提取所有事件处理程序（更全面的模式）
$eventPatterns = @(
    'OnClick\s*=\s*(\w+)',
    'OnTimer\s*=\s*(\w+)',
    'OnChange\s*=\s*(\w+)',
    'OnDblClick\s*=\s*(\w+)',
    'OnKeyDown\s*=\s*(\w+)',
    'OnContextPopup\s*=\s*(\w+)',
    'OnPopup\s*=\s*(\w+)',
    'OnShow\s*=\s*(\w+)',
    'OnCreate\s*=\s*(\w+)',
    'OnDestroy\s*=\s*(\w+)',
    'OnClose\s*=\s*(\w+)',
    'OnCloseQuery\s*=\s*(\w+)',
    'OnActivate\s*=\s*(\w+)',
    'OnDeactivate\s*=\s*(\w+)',
    'OnResize\s*=\s*(\w+)',
    'OnPaint\s*=\s*(\w+)',
    'OnMouseDown\s*=\s*(\w+)',
    'OnMouseUp\s*=\s*(\w+)',
    'OnMouseMove\s*=\s*(\w+)',
    'OnEnter\s*=\s*(\w+)',
    'OnExit\s*=\s*(\w+)',
    'OnKeyPress\s*=\s*(\w+)',
    'OnKeyUp\s*=\s*(\w+)'
)

$allEvents = @()
$missingMethods = @()

foreach ($pattern in $eventPatterns) {
    $matches = [regex]::Matches($dfmContent, $pattern)
    foreach ($match in $matches) {
        $eventType = $match.Groups[0].Value.Split('=')[0].Trim()
        $methodName = $match.Groups[1].Value
        $allEvents += [PSCustomObject]@{
            EventType = $eventType
            MethodName = $methodName
        }
    }
}

Write-Host "找到 $($allEvents.Count) 个事件处理程序:" -ForegroundColor Yellow

foreach ($event in $allEvents | Sort-Object MethodName) {
    $methodName = $event.MethodName
    $eventType = $event.EventType
    
    # 检查方法是否在.pas文件中存在
    $methodPattern = "procedure\s+TfrmMain\.$methodName\s*\("
    
    if ($pasContent -match $methodPattern) {
        Write-Host "✅ $eventType = $methodName" -ForegroundColor Green
    } else {
        Write-Host "❌ $eventType = $methodName (缺失)" -ForegroundColor Red
        $missingMethods += $methodName
    }
}

if ($missingMethods.Count -eq 0) {
    Write-Host "`n🎉 所有事件处理程序都有对应的实现！" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 发现 $($missingMethods.Count) 个缺失的方法:" -ForegroundColor Yellow
    $uniqueMissing = $missingMethods | Sort-Object | Get-Unique
    foreach ($method in $uniqueMissing) {
        Write-Host "  - $method" -ForegroundColor Red
    }
}
