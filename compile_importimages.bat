@echo off
chcp 65001 >nul
echo ========================================
echo 开始编译 ImportImages 项目
echo ========================================
echo.

echo 正在查找编译器...
where dcc32.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo 找到 dcc32.exe 编译器
    set COMPILER=dcc32.exe
    goto :compile
)

where dcc64.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo 找到 dcc64.exe 编译器
    set COMPILER=dcc64.exe
    goto :compile
)

echo 错误: 未找到 Delphi 编译器 (dcc32.exe 或 dcc64.exe)
echo 请确保 Delphi 已正确安装并添加到系统路径中
timeout /t 5 /nobreak >nul
exit /b 1

:compile
echo 使用编译器: %COMPILER%
echo 编译文件: ImportImages.dpr
echo.

%COMPILER% ImportImages.dpr

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo 编译成功！
    echo ========================================
    echo 生成文件: ImportImages.exe
    echo.
    echo 编译完成，程序将在 3 秒后自动退出...
    timeout /t 3 /nobreak >nul
) else (
    echo.
    echo ========================================
    echo 编译失败！
    echo ========================================
    echo 错误代码: %errorlevel%
    echo.
    echo 请检查错误信息并修复问题
    echo 程序将在 5 秒后自动退出...
    timeout /t 5 /nobreak >nul
    exit /b 1
)
