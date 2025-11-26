@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo 持久化功能测试（无mock数据版本）
echo ===============================================
echo.

echo [1/4] 删除旧的数据库文件...
if exist "MoveC.db" (
    del "MoveC.db"
    echo ✅ 旧数据库已删除
) else (
    echo ℹ️  数据库文件不存在
)

echo.
echo [2/4] 启动程序进行测试...
echo 请按以下步骤操作：
echo.
echo 1. 程序启动后，查看日志窗口
echo    应该显示: "[成功] 数据库已连接"
echo    应该显示: "[信息] 已从数据库加载 0 个同步任务"
echo.
echo 2. 点击"文件" → "新建任务"
echo    任务名称: 测试持久化
echo    源路径: D:\Test\Source
echo    目标路径: D:\Test\Target
echo    点击"确定"
echo.
echo 3. 查看日志窗口
echo    应该显示: "[hh:mm:ss] 新建任务: 测试持久化 (ID: 1)"
echo    ⚠️  如果显示 ID: 0，说明保存失败！
echo.
echo 4. 关闭程序（托盘右键 → 退出）
echo.
echo 5. 重新运行程序
echo    应该看到: "[信息] 已从数据库加载 1 个同步任务"
echo    任务列表中应该有"测试持久化"任务
echo.

echo 现在启动程序...
"C盘超级瘦身.exe"

echo.
echo [3/4] 检查数据库文件...
if exist "MoveC.db" (
    echo ✅ 数据库文件已创建
    for %%A in ("MoveC.db") do echo 📦 大小: %%~zA 字节
) else (
    echo ❌ 数据库文件未创建
)

echo.
echo [4/4] 测试完成
echo ===============================================
echo 测试结果检查：
echo.
echo ✅ 成功标志：
echo    - 新建任务后显示 ID: 1 (不是 ID: 0)
echo    - 重启程序后显示"已加载 1 个同步任务"
echo    - 任务列表中任务仍然存在
echo.
echo ❌ 失败标志：
echo    - 新建任务后显示 ID: 0
echo    - 重启程序后显示"已加载 0 个同步任务"
echo    - 任务列表为空
echo.
echo ===============================================
echo.
pause
