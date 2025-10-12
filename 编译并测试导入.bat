@echo off
chcp 65001 >nul
echo ========================================
echo 编译并测试 ImportImages
echo ========================================
echo.

echo 正在编译...
dcc32 ImportImages.dpr

if %errorlevel% equ 0 (
    echo.
    echo ✓ 编译成功！
    echo.
    echo 开始导入图像...
    echo.
    
    ImportImages.exe
    
    echo.
    echo ========================================
    echo 查看日志文件
    echo ========================================
    echo.
    
    if exist import_log.txt (
        type import_log.txt
        echo.
        echo ========================================
        echo 日志文件已显示完毕
        echo ========================================
    ) else (
        echo 日志文件不存在
    )
) else (
    echo.
    echo ✗ 编译失败
    echo 错误代码: %errorlevel%
)

echo.
pause
