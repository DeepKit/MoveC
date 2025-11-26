@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo 数据库初始化脚本
echo ===============================================
echo.

echo [1/4] 备份现有数据库...
if exist "MoveC.db" (
    copy "MoveC.db" "MoveC_backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.db"
    echo ✅ 数据库已备份
) else (
    echo ⚠️ 数据库文件不存在，将创建新数据库
)

echo.
echo [2/4] 创建同步任务表...
sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, source_path TEXT NOT NULL, target_path TEXT NOT NULL, sync_mode INTEGER NOT NULL DEFAULT 0, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_enabled BOOLEAN NOT NULL DEFAULT 1, filter_rules TEXT, preset_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
echo ✅ sync_tasks表创建完成

echo.
echo [3/4] 创建其他表...
sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, filter_rules TEXT, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_system BOOLEAN NOT NULL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
echo ✅ sync_presets表创建完成

sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_history (id INTEGER PRIMARY KEY AUTOINCREMENT, task_id INTEGER NOT NULL, sync_type TEXT NOT NULL, start_time DATETIME NOT NULL, end_time DATETIME, files_scanned INTEGER DEFAULT 0, files_copied INTEGER DEFAULT 0, files_updated INTEGER DEFAULT 0, files_deleted INTEGER DEFAULT 0, files_skipped INTEGER DEFAULT 0, bytes_transferred INTEGER DEFAULT 0, error_message TEXT, status TEXT NOT NULL DEFAULT 'running', created_at DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (task_id) REFERENCES sync_tasks(id) ON DELETE CASCADE);"
echo ✅ sync_history表创建完成

sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS file_states (id INTEGER PRIMARY KEY AUTOINCREMENT, task_id INTEGER NOT NULL, file_path TEXT NOT NULL, file_hash TEXT, file_size INTEGER DEFAULT 0, modified_time DATETIME, last_sync_time DATETIME, sync_status TEXT NOT NULL DEFAULT 'pending', exists_in_source BOOLEAN NOT NULL DEFAULT 0, exists_in_target BOOLEAN NOT NULL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (task_id) REFERENCES sync_tasks(id) ON DELETE CASCADE);"
echo ✅ file_states表创建完成

echo.
echo [4/4] 创建索引...
sqlite3 MoveC.db "CREATE INDEX IF NOT EXISTS idx_sync_tasks_name ON sync_tasks(name);"
sqlite3 MoveC.db "CREATE INDEX IF NOT EXISTS idx_sync_tasks_enabled ON sync_tasks(is_enabled);"
sqlite3 MoveC.db "CREATE INDEX IF NOT EXISTS idx_sync_history_task_id ON sync_history(task_id);"
sqlite3 MoveC.db "CREATE INDEX IF NOT EXISTS idx_file_states_task_id ON file_states(task_id);"
sqlite3 MoveC.db "CREATE INDEX IF NOT EXISTS idx_file_states_path ON file_states(task_id, file_path);"
echo ✅ 索引创建完成

echo.
echo ===============================================
echo 验证数据库结构...
echo ===============================================
echo.
echo 📋 数据库表列表:
sqlite3 MoveC.db ".tables"

echo.
echo 📋 sync_tasks表结构:
sqlite3 MoveC.db ".schema sync_tasks"

echo.
echo 📋 当前任务数量:
sqlite3 MoveC.db "SELECT COUNT(*) as task_count FROM sync_tasks;"

echo.
echo ===============================================
echo 数据库初始化完成！
echo ===============================================
echo.
echo 🎯 现在可以运行程序测试持久化功能:
echo 1. 启动程序
echo 2. 创建新任务
echo 3. 验证TaskID > 0
echo 4. 重启程序验证任务仍然存在
echo.
echo 💡 如果程序启动时看到 "sync_tasks table exists" 
echo    在DebugView中，说明表创建成功
echo.
pause
