@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo 数据库状态检查脚本
echo ===============================================
echo.

echo [1/5] 检查数据库文件...
if exist "MoveC.db" (
    echo ✅ MoveC.db 存在
    for %%A in ("MoveC.db") do echo 📦 大小: %%~zA 字节
    for %%A in ("MoveC.db") do echo 🕐 修改时间: %%~tA
) else (
    echo ❌ MoveC.db 不存在
    echo 💡 程序运行时会自动创建
    pause
    exit /b
)

echo.
echo [2/5] 检查数据库表...
echo 📋 数据库中的所有表:
sqlite3 MoveC.db ".tables"

echo.
echo 📋 检查sync_tasks表是否存在:
sqlite3 MoveC.db "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_tasks';"

echo.
echo [3/5] 检查sync_tasks表结构...
if exist "MoveC.db" (
    sqlite3 MoveC.db ".schema sync_tasks" 2>nul
    if errorlevel 1 (
        echo ❌ sync_tasks表不存在
    ) else (
        echo ✅ sync_tasks表结构正常
    )
)

echo.
echo [4/5] 检查现有任务数据...
sqlite3 MoveC.db "SELECT COUNT(*) as task_count FROM sync_tasks;" 2>nul
if errorlevel 1 (
    echo ❌ 无法查询sync_tasks表
) else (
    echo ✅ 查询成功，显示任务列表:
    sqlite3 MoveC.db "SELECT id, name, source_path, target_path FROM sync_tasks;" 2>nul
)

echo.
echo [5/5] 测试删除操作...
echo 🧪 插入测试任务...
sqlite3 MoveC.db "INSERT INTO sync_tasks (name, source_path, target_path) VALUES ('测试删除任务', 'C:\test\source', 'C:\test\target');" 2>nul
if errorlevel 1 (
    echo ❌ 插入测试任务失败
) else (
    echo ✅ 插入测试任务成功
    
    echo 🧪 查看插入的任务...
    sqlite3 MoveC.db "SELECT id, name FROM sync_tasks WHERE name='测试删除任务';"
    
    echo 🧪 删除测试任务...
    sqlite3 MoveC.db "DELETE FROM sync_tasks WHERE name='测试删除任务';" 2>nul
    if errorlevel 1 (
        echo ❌ 删除测试任务失败
    ) else (
        echo ✅ 删除测试任务成功
        
        echo 🧪 验证删除结果...
        sqlite3 MoveC.db "SELECT COUNT(*) FROM sync_tasks WHERE name='测试删除任务';"
    )
)

echo.
echo ===============================================
echo 检查完成 - 问题诊断
echo ===============================================
echo.

echo 📋 根据检查结果判断问题:
echo.
echo 情况1: sync_tasks表不存在
echo   症状: ❌ 表不存在或查询失败
echo   原因: 程序启动时表创建失败
echo   解决: 检查程序日志，确认CreateTables执行
echo.
echo 情况2: 表存在但操作失败
echo   症状: ✅ 表存在但❌ 插入/删除失败
echo   原因: 数据库权限或SQL语法问题
echo   解决: 检查数据库文件权限
echo.
echo 情况3: 一切正常
echo   症状: ✅ 所有操作都成功
echo   原因: 数据库工作正常，问题在程序逻辑
echo   解决: 检查程序中的数据库操作代码
echo.

echo 💡 程序使用的数据库路径确认:
echo    文件名: MoveC.db
echo    位置: 程序exe所在目录
echo    不是: data.db
echo.

pause
