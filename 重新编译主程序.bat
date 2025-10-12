@echo off
chcp 65001 >nul
echo ========================================
echo 强制重新编译主程序
echo ========================================
echo.

echo 步骤1: 删除旧的exe文件...
if exist "C盘瘦身.exe" (
    del "C盘瘦身.exe"
    echo   已删除 C盘瘦身.exe
) else (
    echo   C盘瘦身.exe 不存在
)
echo.

echo 步骤2: 清理所有编译缓存...
del /Q *.dcu 2>nul
del /S /Q Win32\Debug\*.dcu 2>nul
del /S /Q Win64\Debug\*.dcu 2>nul
echo   已清理所有 .dcu 文件
echo.

echo 步骤3: 删除旧日志...
if exist "aboutme_debug.log" (
    del "aboutme_debug.log"
    echo   已删除 aboutme_debug.log
)
echo.

echo 步骤4: 查找编译器...
where dcc32.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo   找到 dcc32.exe
    set COMPILER=dcc32.exe
    goto :compile
)

where dcc64.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo   找到 dcc64.exe
    set COMPILER=dcc64.exe
    goto :compile
)

echo   错误: 未找到 Delphi 编译器
echo   请在 Delphi IDE 中手动编译
pause
exit /b 1

:compile
echo.
echo 步骤5: 重新编译主程序...
echo   使用编译器: %COMPILER%
echo   编译文件: C盘瘦身.dpr
echo.

%COMPILER% -B "C盘瘦身.dpr"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ✓ 编译成功
    echo ========================================
    echo.
    
    if exist "C盘瘦身.exe" (
        echo 新的exe文件已生成
        dir "C盘瘦身.exe" | findstr "C盘瘦身.exe"
        echo.
        echo 现在可以运行程序测试图像显示
    ) else (
        echo 警告: exe文件未生成
    )
) else (
    echo.
    echo ========================================
    echo ✗ 编译失败
    echo ========================================
    echo.
    echo 请检查编译错误信息
)

echo.
pause
