@echo off
chcp 65001 >nul
echo ========================================
echo 重新编译 ImportImages
echo ========================================
echo.

echo 正在编译...
dcc32 ImportImages.dpr

if %errorlevel% equ 0 (
    echo.
    echo ✓ 编译成功！
    echo.
    echo ========================================
    echo 开始导入图像
    echo ========================================
    echo.
    
    ImportImages.exe
    
    echo.
    echo ========================================
    echo 完成
    echo ========================================
) else (
    echo.
    echo ✗ 编译失败
    echo 错误代码: %errorlevel%
)

pause
