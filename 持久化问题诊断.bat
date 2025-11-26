@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo 持久化问题诊断工具
echo ===============================================
echo.

echo [1/6] 检查数据库文件状态...
if exist "MoveC.db" (
    echo ✅ 数据库文件存在
    for %%A in ("MoveC.db") do echo 📦 大小: %%~zA 字节
    for %%A in ("MoveC.db") do echo 🕐 修改时间: %%~tA
) else (
    echo ❌ 数据库文件不存在
    echo 💡 请先运行程序创建数据库
    pause
    exit /b
)

echo.
echo [2/6] 检查程序编译状态...
if exist "C盘超级瘦身.exe" (
    echo ✅ 可执行文件存在
) else (
    echo ❌ 可执行文件不存在，请先编译程序
    pause
    exit /b
)

echo.
echo [3/6] 启动程序进行诊断...
echo 📋 请按照以下步骤进行诊断：
echo.
echo 步骤1: 程序启动后查看日志
echo   应该看到: "[成功] 数据库已连接"
echo   应该看到: "[信息] 已从数据库加载 X 个同步任务"
echo.
echo 步骤2: 测试创建任务
echo   点击"文件" → "新建任务"
echo   填写任务信息并点击"确定"
echo   查看日志输出:
echo     ✅ 正常: "✅ 新建任务成功: xxx (ID: 1)"
echo     ❌ 异常: "❌ 异常: xxx" 或 "TaskID = 0"
echo.
echo 步骤3: 测试删除任务
echo   选择一个任务
echo   点击"文件" → "删除任务"
echo   查看日志输出:
echo     ✅ 正常: "✅ 已从数据库删除"
echo     ❌ 异常: "❌ 数据库删除失败"
echo.
echo 步骤4: 测试持久化
echo   关闭程序
echo   重新运行程序
echo   查看任务是否仍然存在
echo.
echo 💡 使用DebugView查看详细调试信息:
echo   1. 下载并运行 DebugView
echo   2. 以管理员身份运行
echo   3. 运行程序并操作
echo   4. 查看CreateSyncTask和DeleteSyncTask的输出
echo.

echo 现在启动程序...
"C盘超级瘦身.exe"

echo.
echo [4/6] 检查数据库内容变化...
echo 📊 检查数据库文件大小变化:
if exist "MoveC.db" (
    for %%A in ("MoveC.db") do echo 📦 当前大小: %%~zA 字节
)

echo.
echo [5/6] 问题诊断结果...
echo 📋 根据你的操作结果，选择对应的问题类型:
echo.
echo 类型1: 创建任务失败
echo   症状: TaskID = 0 或异常信息
echo   原因: 数据库写入失败
echo   解决: 检查数据库权限、表结构
echo.
echo 类型2: 删除任务失败
echo   症状: "数据库删除失败" 或任务重启后还在
echo   原因: SQL执行失败
echo   解决: 检查数据库连接、SQL语法
echo.
echo 类型3: 任务不持久化
echo   症状: 重启程序后任务消失
echo   原因: 只操作内存，未写入数据库
echo   解决: 检查Save方法调用
echo.
echo 类型4: 数据库连接失败
echo   症状: "数据库连接失败"
echo   原因: 文件权限、路径错误
echo   解决: 管理员运行、检查路径
echo.

echo [6/6] 推荐解决方案...
echo 🔧 根据问题类型选择解决方案:
echo.
echo 解决方案A: 重新初始化数据库
echo   1. 备份现有MoveC.db
echo   2. 删除MoveC.db
echo   3. 重新运行程序
echo   4. 重新创建任务
echo.
echo 解决方案B: 检查权限
echo   1. 以管理员身份运行程序
echo   2. 检查MoveC.db文件权限
echo   3. 关闭杀毒软件实时防护
echo.
echo 解决方案C: 使用DebugView调试
echo   1. 运行DebugView
echo   2. 查看详细的SQL执行信息
echo   3. 定位具体的错误点
echo.

echo ===============================================
echo 诊断完成
echo ===============================================
echo.
echo 📝 如果问题仍未解决，请提供以下信息:
echo 1. 程序日志截图
echo 2. DebugView输出截图
echo 3. 具体的错误信息
echo 4. 操作步骤描述
echo.
echo 📞 可以将上述信息发送给开发者进行进一步分析
echo.
pause
