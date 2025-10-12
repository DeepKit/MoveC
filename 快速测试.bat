@echo off
chcp 65001 >nul

echo 编译 ImportImages...
dcc32 ImportImages.dpr >nul 2>&1

if %errorlevel% equ 0 (
    echo 编译成功，开始导入...
    echo.
    
    ImportImages.exe
    
    echo.
    echo ========================================
    echo 日志内容:
    echo ========================================
    type import_log.txt
) else (
    echo 编译失败
)

pause
