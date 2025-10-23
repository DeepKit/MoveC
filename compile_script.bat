@echo off
cd /d "D:\SynologyDrive\Progs\_Delphi\MoveC"
echo 正在编译64位版本...
"D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" "C盘瘦身.dpr" > compilation_log.txt 2>&1
if %errorlevel% equ 0 (
  echo 编译成功！ > compilation_status.txt
) else (
  echo 编译失败，错误代码：%errorlevel% > compilation_status.txt
)