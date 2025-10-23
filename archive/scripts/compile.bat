@echo off
cd /d "D:\SynologyDrive\Progs\_Delphi\MoveC"
echo Compiling...
"D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\DCC32.EXE" "C盘瘦身.dpr" > compile_output.txt 2>&1
echo Compilation finished. Output:
type compile_output.txt