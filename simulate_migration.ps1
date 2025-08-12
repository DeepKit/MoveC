$ErrorActionPreference = 'Stop'

$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$name = "AugmentMigrationTest_$ts"
$src = "C:\Users\$name"
$dstRoot = "D:\Users"
$dst = Join-Path $dstRoot $name
$backup = "$src.backup_$ts"

# Ensure D:\Users exists
if (-not (Test-Path $dstRoot)) { New-Item -ItemType Directory -Force -Path $dstRoot | Out-Null }

# Clean any previous leftovers
if (Test-Path $src) { Remove-Item -Recurse -Force $src }
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
if (Test-Path $backup) { Remove-Item -Recurse -Force $backup }

# Create a small test tree under C:\Users
New-Item -ItemType Directory -Force -Path (Join-Path $src 'sub') | Out-Null
Set-Content -Path (Join-Path $src 'file1.txt') -Value 'hello'
Set-Content -Path (Join-Path $src 'sub\file2.txt') -Value ("data $ts")

# Simulate the app's migration flow
Copy-Item -Recurse -Force -Path $src -Destination $dst
Rename-Item -Path $src -NewName $backup
cmd /c ("mklink /J `"$src`" `"$dst`"") | Out-Null

# Validate
$srcItem = Get-Item $src -ErrorAction Stop
$srcIsReparse = ($srcItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0

$dstFiles = Get-ChildItem -Force -Recurse $dst -File
$viaSrcFiles = Get-ChildItem -Force -Recurse $src -File

$dstCount = $dstFiles.Count
$viaSrcCount = $viaSrcFiles.Count
$dstSize = ($dstFiles | Measure-Object -Property Length -Sum).Sum
$viaSrcSize = ($viaSrcFiles | Measure-Object -Property Length -Sum).Sum

Write-Output ("SRC=" + $src)
Write-Output ("DST=" + $dst)
Write-Output ("BACKUP=" + $backup)
Write-Output ("REPARSE=" + $srcIsReparse)
Write-Output ("COUNT_DST=" + $dstCount + " COUNT_SRC=" + $viaSrcCount)
Write-Output ("SIZE_DST=" + $dstSize + " SIZE_SRC=" + $viaSrcSize)

if ($srcIsReparse -and ($dstCount -eq $viaSrcCount) -and ($dstSize -eq $viaSrcSize)) {
  Write-Output 'MIGRATION_SIM_OK'
  exit 0
} else {
  Write-Output 'MIGRATION_SIM_MISMATCH'
  exit 1
}

