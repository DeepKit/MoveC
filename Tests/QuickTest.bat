@echo off
chcp 65001 > nul
echo ========================================
echo   快速测试 - 仅检查编译
echo ========================================
echo.

set DCC="D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe"

echo [1/2] 检查编译器...
if not exist %DCC% (
    echo [错误] 找不到 Delphi 编译器
    echo 请修改 DCC 变量指向正确的路径
    pause
    exit /b 1
)

echo [2/2] 编译测试项目...
echo.

%DCC% -Q -B SyncTests.dpr

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✓ 编译成功！
    echo ========================================
    echo.
    echo 现在可以运行: SyncTests.exe --console
    echo 或者运行: RunTests.bat
    echo.
) else (
    echo.
    echo ========================================
    echo ✗ 编译失败
    echo ========================================
    echo.
    echo 请检查错误信息并修复
    echo.
)

pause
