@echo off
echo ===============================================
echo Database Initialization
echo ===============================================
echo.

echo [1/3] Creating sync_tasks table...
sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, source_path TEXT NOT NULL, target_path TEXT NOT NULL, sync_mode INTEGER NOT NULL DEFAULT 0, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_enabled BOOLEAN NOT NULL DEFAULT 1, filter_rules TEXT, preset_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
echo sync_tasks table created

echo.
echo [2/3] Creating sync_presets table...
sqlite3 MoveC.db "CREATE TABLE IF NOT EXISTS sync_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, filter_rules TEXT, conflict_strategy INTEGER NOT NULL DEFAULT 0, is_system BOOLEAN NOT NULL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
echo sync_presets table created

echo.
echo [3/3] Verifying tables...
echo Tables in database:
sqlite3 MoveC.db ".tables"

echo.
echo sync_tasks structure:
sqlite3 MoveC.db ".schema sync_tasks"

echo.
echo ===============================================
echo Initialization Complete
echo ===============================================
echo.
echo Database is now ready for the program.
echo You can run the program to test persistence.
echo.
pause
