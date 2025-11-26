@echo off
echo ===============================================
echo Database Status Check
echo ===============================================
echo.

echo [1/5] Checking database file...
if exist "MoveC.db" (
    echo OK: MoveC.db exists
    for %%A in ("MoveC.db") do echo Size: %%~zA bytes
    for %%A in ("MoveC.db") do echo Modified: %%~tA
) else (
    echo ERROR: MoveC.db not found
    echo Program will create it automatically
    pause
    exit /b
)

echo.
echo [2/5] Checking database tables...
echo Tables in database:
sqlite3 MoveC.db ".tables"

echo.
echo [3/5] Checking sync_tasks table...
sqlite3 MoveC.db "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_tasks';"

echo.
echo [4/5] sync_tasks table structure:
sqlite3 MoveC.db ".schema sync_tasks"

echo.
echo [5/5] Testing database operations...
echo Inserting test task...
sqlite3 MoveC.db "INSERT INTO sync_tasks (name, source_path, target_path) VALUES ('test_task', 'C:\\test\\source', 'C:\\test\\target');"

echo.
echo Viewing inserted task:
sqlite3 MoveC.db "SELECT id, name FROM sync_tasks WHERE name='test_task';"

echo.
echo Deleting test task...
sqlite3 MoveC.db "DELETE FROM sync_tasks WHERE name='test_task';"

echo.
echo Verifying deletion (should show 0):
sqlite3 MoveC.db "SELECT COUNT(*) FROM sync_tasks WHERE name='test_task';"

echo.
echo Current tasks in database:
sqlite3 MoveC.db "SELECT id, name, source_path FROM sync_tasks;"

echo.
echo ===============================================
echo Check Complete
echo ===============================================
echo.
echo If all operations above succeeded, database is working.
echo If you see errors, database has problems.
echo.
pause
