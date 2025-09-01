@echo off
echo === 防篡改机制打包工具 ===
echo.

:: 创建打包目录
if not exist "AntiTamperPackage" mkdir "AntiTamperPackage"

:: 复制核心文件
echo 复制核心文件...
copy "uAntiTamperPackage.pas" "AntiTamperPackage\"
copy "uImageSecurity.pas" "AntiTamperPackage\"
copy "AntiTamper_README.md" "AntiTamperPackage\"

:: 创建示例文件
echo 创建示例文件...
echo unit ExampleUsage; > "AntiTamperPackage\ExampleUsage.pas"
echo. >> "AntiTamperPackage\ExampleUsage.pas"
echo interface >> "AntiTamperPackage\ExampleUsage.pas"
echo. >> "AntiTamperPackage\ExampleUsage.pas"
echo uses >> "AntiTamperPackage\ExampleUsage.pas"
echo   uAntiTamperPackage; >> "AntiTamperPackage\ExampleUsage.pas"
echo. >> "AntiTamperPackage\ExampleUsage.pas"
echo // 参考 AntiTamper_README.md 中的使用示例 >> "AntiTamperPackage\ExampleUsage.pas"
echo. >> "AntiTamperPackage\ExampleUsage.pas"
echo end. >> "AntiTamperPackage\ExampleUsage.pas"

echo.
echo 打包完成！文件位于 AntiTamperPackage 目录中
echo.
echo 包含文件：
echo - uAntiTamperPackage.pas    (主要防篡改包)
echo - uImageSecurity.pas        (图像安全工具)
echo - AntiTamper_README.md      (使用说明)
echo - ExampleUsage.pas          (使用示例)
echo.
pause
