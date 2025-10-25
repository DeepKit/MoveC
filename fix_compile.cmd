@echo off
echo 正在修复编译错误...

rem 设置编码为UTF-8
chcp 65001

rem 编译项目
echo 开始编译项目...
dcc32.exe "C盘瘦身.dpr"

if %errorlevel% equ 0 (
    echo 编译成功！
) else (
    echo 编译失败，错误代码: %errorlevel%
)

pause