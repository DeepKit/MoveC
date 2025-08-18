# 将Pascal文件转换为UTF-8 BOM格式
$files = @(
    "uMain.pas",
    "uSplash.pas", 
    "uStyles.pas",
    "uStrings.pas",
    "uConfigManager.pas",
    "uSmartDuplicateCleanup.pas",
    "uDirectoryMigration.pas"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Converting $file to UTF-8 BOM..."
        
        # 读取文件内容
        $content = Get-Content $file -Raw -Encoding Default
        
        # 创建临时文件名
        $tempFile = "$file.temp"
        
        # 写入UTF-8 BOM格式
        $utf8 = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($tempFile, $content, $utf8)
        
        # 替换原文件
        Move-Item $tempFile $file -Force
        
        Write-Host "Converted $file successfully"
    } else {
        Write-Host "File $file not found"
    }
}

Write-Host "All files converted to UTF-8 BOM format"
