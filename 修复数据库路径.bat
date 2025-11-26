@echo off
echo ===============================================
echo 修复数据库路径问题
echo ===============================================
echo.

echo [1/4] 检查项目根目录数据库...
if exist "MoveC.db" (
    echo OK: 项目根目录 MoveC.db 存在
    for %%A in ("MoveC.db") do echo 大小: %%~zA 字节
) else (
    echo ERROR: 项目根目录 MoveC.db 不存在
    echo 创建空数据库文件...
    echo. > MoveC.db
    echo 已创建 MoveC.db
)

echo.
echo [2/4] 检查Debug目录...
if exist "Win64\Debug\" (
    echo OK: Debug目录存在
) else (
    echo ERROR: Debug目录不存在
    echo 创建Debug目录...
    mkdir "Win64\Debug"
)

echo.
echo [3/4] 复制数据库到Debug目录...
copy "MoveC.db" "Win64\Debug\MoveC.db" >nul
if exist "Win64\Debug\MoveC.db" (
    echo OK: 已复制 MoveC.db 到 Debug目录
    for %%A in ("Win64\Debug\MoveC.db") do echo 大小: %%~zA 字节
) else (
    echo ERROR: 复制失败
)

echo.
echo [4/4] 验证数据库表结构...
echo 检查sync_tasks表:
sqlite3 "Win64\Debug\MoveC.db" ".tables" 2>nul
echo.

echo 创建sync_tasks表(如果不存在):
sqlite3 "Win64\Debug\MoveC.db" "CREATE TABLE IF NOT EXISTS sync_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, source_path TEXT NOT NULL, target_path TEXT NOT NULL, sync_mode INTEGER NOT NULL DEFAULT 0, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_enabled BOOLEAN NOT NULL DEFAULT 1, filter_rules TEXT, preset_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);" 2>nul

echo 创建sync_presets表(如果不存在):
sqlite3 "Win64\Debug\MoveC.db" "CREATE TABLE IF NOT EXISTS sync_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, filter_rules TEXT, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_system BOOLEAN NOT NULL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);" 2>nul

echo.
echo 验证表创建:
sqlite3 "Win64\Debug\MoveC.db" ".tables"

echo.
echo ===============================================
echo 修复完成
echo ===============================================
echo.

echo 问题原因:
echo 程序在 Debug 目录运行，但 MoveC.db 在项目根目录
echo.
echo 解决方案:
echo 1. 已将 MoveC.db 复制到 Win64\Debug\ 目录
echo 2. 已创建必要的数据库表结构
echo 3. 程序现在应该能正常启动
echo.

echo 现在可以运行程序了:
echo - 程序路径: Win64\Debug\C盘超级瘦身.exe
echo - 数据库路径: Win64\Debug\MoveC.db
echo - 应该不再报 "MoveC.db 缺失" 错误
echo.

pause
