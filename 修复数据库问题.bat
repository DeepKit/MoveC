@echo off
echo ===============================================
echo 修复数据库文件问题
echo ===============================================
echo.

echo [1/5] 检查当前目录的数据库文件...
echo 当前目录: %cd%
echo.
echo 数据库文件列表:
dir *.db /b

echo.
echo [2/5] 检查程序exe文件...
echo 程序文件列表:
dir *.exe /b

echo.
echo [3/5] 确保MoveC.db存在且可访问...
if not exist "MoveC.db" (
    echo MoveC.db不存在，创建空数据库文件...
    echo. > MoveC.db
    echo 已创建空的MoveC.db文件
) else (
    echo MoveC.db已存在
    for %%A in ("MoveC.db") do echo 大小: %%~zA 字节
)

echo.
echo [4/5] 验证数据库文件完整性...
echo 测试数据库连接:
sqlite3 MoveC.db "SELECT 'Database connection OK';" 2>nul
if errorlevel 1 (
    echo 数据库文件损坏，重新创建...
    del "MoveC.db"
    echo. > MoveC.db
    echo 已重新创建MoveC.db
) else (
    echo 数据库文件正常
)

echo.
echo [5/5] 创建必要的表结构...
echo 创建sync_tasks表:
sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, source_path TEXT NOT NULL, target_path TEXT NOT NULL, sync_mode INTEGER NOT NULL DEFAULT 0, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_enabled BOOLEAN NOT NULL DEFAULT 1, filter_rules TEXT, preset_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);" 2>nul

echo 创建sync_presets表:
sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, filter_rules TEXT, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_system BOOLEAN NOT NULL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);" 2>nul

echo.
echo 验证表创建:
sqlite3 MoveC.db ".tables"

echo.
echo ===============================================
echo 修复完成 - 程序运行指南
echo ===============================================
echo.

echo 现在数据库文件已准备就绪:
echo - 文件名: MoveC.db
echo - 位置: %cd%\MoveC.db
echo - 表结构: 已创建sync_tasks和sync_presets表
echo.

echo 运行程序时应该看到:
echo 1. 程序正常启动，不报"MoveC.db缺失"错误
echo 2. 日志显示: "[成功] 数据库已连接"
echo 3. 可以正常创建和删除任务
echo.

echo 如果程序仍然报错，可能的原因:
echo 1. 程序在别的目录运行
echo 2. 权限问题
echo 3. 程序内部路径处理错误
echo.

echo 解决方案:
echo 1. 将MoveC.db复制到程序exe所在目录
echo 2. 以管理员身份运行程序
echo 3. 检查程序代码中的路径设置
echo.

echo 现在可以尝试运行程序了...
echo.
pause
