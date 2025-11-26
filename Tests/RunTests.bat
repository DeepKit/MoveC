@echo off
chcp 65001 > nul
echo ========================================
echo   编译并运行单元测试
echo ========================================
echo.

set DCC="D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe"
set PROJECT=SyncTests.dpr

if not exist %DCC% (
    echo [错误] 找不到 Delphi 编译器: %DCC%
    pause
    exit /b 1
)

echo [1/3] 编译测试项目...
%DCC% %PROJECT%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [失败] 编译失败
    pause
    exit /b 1
)

echo.
echo [2/3] 运行测试...
echo ========================================
echo.

SyncTests.exe --console

set TEST_RESULT=%ERRORLEVEL%

echo.
echo ========================================
echo [3/3] 测试完成
echo ========================================

if %TEST_RESULT% EQU 0 (
    echo.
    echo ✓ 所有测试通过！
    echo.
) else (
    echo.
    echo ✗ 测试失败，返回代码: %TEST_RESULT%
    echo.
)

pause
exit /b %TEST_RESULT%
