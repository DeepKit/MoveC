# Delphi 项目编译脚本
$ErrorActionPreference = "Stop"

Write-Host "正在编译 C盘超级瘦身项目..." -ForegroundColor Cyan

& "D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\DCC64.EXE" `
    -U"AntiTamperPackage" `
    "C盘超级瘦身.dpr" 2>&1 | Tee-Object -FilePath "compile_output.txt"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n编译成功！" -ForegroundColor Green
} else {
    Write-Host "`n编译失败，请查看 compile_output.txt" -ForegroundColor Red
    exit $LASTEXITCODE
}
