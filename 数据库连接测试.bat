@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo 数据库连接和持久化测试
echo ===============================================
echo.

echo 📋 程序数据库配置确认:
echo    文件名: MoveC.db (不是data.db)
echo    位置: %cd%\MoveC.db
echo    大小: 
if exist "MoveC.db" (
    for %%A in ("MoveC.db") do echo    %%~zA 字节
) else (
    echo    文件不存在
)

echo.
echo [1/4] 检查数据库表结构...
echo 📋 当前数据库表:
sqlite3 MoveC.db ".tables" 2>nul
echo.

echo 📋 sync_tasks表结构:
sqlite3 MoveC.db ".schema sync_tasks" 2>nul
if errorlevel 1 (
    echo ❌ sync_tasks表不存在 - 这是主要问题！
    echo.
    echo 🔧 立即修复:
    sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, source_path TEXT NOT NULL, target_path TEXT NOT NULL, sync_mode INTEGER NOT NULL DEFAULT 0, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_enabled BOOLEAN NOT NULL DEFAULT 1, filter_rules TEXT, preset_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
    echo ✅ sync_tasks表已创建
) else (
    echo ✅ sync_tasks表存在
)

echo.
echo [2/4] 检查预设表...
sqlite3 MoveC.db ".schema sync_presets" 2>nul
if errorlevel 1 (
    echo ❌ sync_presets表不存在
    echo 🔧 创建预设表:
    sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, filter_rules TEXT, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_system BOOLEAN NOT NULL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
    echo ✅ sync_presets表已创建
) else (
    echo ✅ sync_presets表存在
)

echo.
echo [3/4] 测试数据库操作...
echo 🧪 插入测试任务:
sqlite3 MoveC.db "INSERT INTO sync_tasks (name, source_path, target_path) VALUES ('持久化测试任务', 'D:\test\source', 'D:\test\target');" 2>nul
if errorlevel 1 (
    echo ❌ 插入失败
) else (
    echo ✅ 插入成功
    echo 📋 查看插入的任务:
    sqlite3 MoveC.db "SELECT id, name, created_at FROM sync_tasks WHERE name='持久化测试任务';"
)

echo.
echo 🧪 删除测试任务:
sqlite3 MoveC.db "DELETE FROM sync_tasks WHERE name='持久化测试任务';" 2>nul
if errorlevel 1 (
    echo ❌ 删除失败
) else (
    echo ✅ 删除成功
    echo 📋 验证删除: 应该显示0条记录
    sqlite3 MoveC.db "SELECT COUNT(*) FROM sync_tasks WHERE name='持久化测试任务';"
)

echo.
echo [4/4] 最终状态检查...
echo 📋 当前任务数量:
sqlite3 MoveC.db "SELECT COUNT(*) as total_tasks FROM sync_tasks;" 2>nul
if errorlevel 1 (
    echo ❌ 查询失败
) else (
    echo ✅ 查询成功
)

echo.
echo 📋 所有任务列表:
sqlite3 MoveC.db "SELECT id, name, source_path FROM sync_tasks ORDER BY id;" 2>nul

echo.
echo ===============================================
echo 测试完成 - 程序运行指南
echo ===============================================
echo.

echo 🎯 如果以上测试都成功，说明数据库正常:
echo.
echo 📝 程序运行时应该看到:
echo    ✅ "[成功] 数据库已连接: d:\_Progs\02Business\MoveC\MoveC.db"
echo    ✅ "[信息] 已从数据库加载 X 个同步任务"
echo    ✅ "CreateTables: sync_tasks table created successfully"
echo    ✅ "CreateDefaultPresets: Created basic sync preset"
echo.
echo 📝 创建任务时应该看到:
echo    ✅ "✅ 新建任务成功: xxx (ID: 1)"
echo    📝 DebugView中应该看到:
echo    ✅ "CreateSyncTask: Generated ID: 1"
echo.
echo 📝 删除任务时应该看到:
echo    ✅ "✅ 已从数据库删除"
echo    📝 DebugView中应该看到:
echo    ✅ "DeleteSyncTask: Task deleted successfully"
echo.

echo ⚠️  如果仍然不持久化，可能的原因:
echo 1. 程序连接到错误的数据库文件
echo 2. 程序没有写入权限
echo 3. 数据库操作被异常中断
echo 4. Mock数据干扰了真实数据
echo.

echo 💡 建议的调试步骤:
echo 1. 运行此脚本确认数据库正常
echo 2. 启动程序并查看所有日志
echo 3. 使用DebugView查看详细调试信息
echo 4. 确认TaskID > 0
echo 5. 重启程序验证任务是否还在
echo.

pause
