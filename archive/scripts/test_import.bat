@echo off
chcp 65001 >nul
echo ========================================
echo 测试 ImportImages 工具
echo ========================================
echo.

echo 检查 ImportImages.exe 是否存在...
if exist ImportImages.exe (
    echo ✓ ImportImages.exe 已找到
) else (
    echo ✗ ImportImages.exe 不存在，需要先编译
    pause
    exit /b 1
)

echo.
echo 检查数据库文件...
if exist MoveC.db (
    echo ✓ MoveC.db 已找到
) else (
    echo ✗ MoveC.db 不存在
)

echo.
echo 检查 assets 目录...
if exist assets\ (
    echo ✓ assets 目录存在
    dir /b assets\*.png assets\*.jpg 2>nul
) else (
    echo ✗ assets 目录不存在
)

echo.
echo ========================================
echo 准备运行 ImportImages.exe
echo ========================================
echo.
echo 按任意键开始导入图像...
pause >nul

ImportImages.exe

echo.
echo ========================================
echo 导入完成
echo ========================================
pause
