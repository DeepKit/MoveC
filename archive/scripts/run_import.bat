@echo off
dcc32 ImportImages.dpr
if %errorlevel% equ 0 (
    ImportImages.exe
    type import_log.txt
) else (
    echo Compile failed
)
pause
