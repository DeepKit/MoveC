@echo off
cd /d d:\SynologyDrive\Progs\_Delphi\MoveC
del import_log.txt
ImportImages.exe
type import_log.txt
pause
