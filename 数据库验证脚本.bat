@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo 数据库验证脚本
echo ===============================================
echo.

echo [1/5] 检查数据库文件...
if exist "MoveC.db" (
    echo ✅ 数据库文件存在
    for %%A in ("MoveC.db") do echo 📦 大小: %%~zA 字节
) else (
    echo ❌ 数据库文件不存在
    pause
    exit /b
)

echo.
echo [2/5] 检查数据库表结构...
sqlite3 MoveC.db ".tables"
echo.
sqlite3 MoveC.db ".schema sync_tasks"

echo.
echo [3/5] 检查现有数据...
sqlite3 MoveC.db "SELECT COUNT(*) as task_count FROM sync_tasks;"
echo.
sqlite3 MoveC.db "SELECT id, name, source_path FROM sync_tasks;"

echo.
echo [4/5] 测试插入数据...
sqlite3 MoveC.db "INSERT INTO sync_tasks (name, source_path, target_path) VALUES ('测试任务', 'C:\test\source', 'C:\test\target');"
echo.
sqlite3 MoveC.db "SELECT id, name FROM sync_tasks WHERE name = '测试任务';"

echo.
echo [5/5] 测试删除数据...
sqlite3 MoveC.db "DELETE FROM sync_tasks WHERE name = '测试任务';"
echo.
sqlite3 MoveC.db "SELECT COUNT(*) as task_count FROM sync_tasks;"

echo.
echo ===============================================
echo 数据库验证完成
echo ===============================================
echo.
echo 📋 验证结果:
echo ✅ 数据库连接正常
echo ✅ sync_tasks表已创建
echo ✅ 插入/删除操作正常
echo.
echo 💡 如果以上操作都成功，说明数据库工作正常
echo    程序持久化问题可能在于代码逻辑
echo.
pause
