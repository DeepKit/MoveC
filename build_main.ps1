$ErrorActionPreference = 'SilentlyContinue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

Write-Host 'Cleaning test projects in root...'
$tests = Get-ChildItem -LiteralPath $here -File -Filter 'Test*.dpr'
foreach ($t in $tests) { Write-Host ' -' $t.FullName; Remove-Item -LiteralPath $t.FullName -Force }
$extra = Join-Path $here '简化测试程序.dpr'
if (Test-Path -LiteralPath $extra) { Write-Host ' -' $extra; Remove-Item -LiteralPath $extra -Force }
Get-ChildItem -Path (Join-Path $here '.backup_encoding*') -Recurse -File -Include 'D__SynologyDrive_Progs__Delphi_MoveC_*Test*.dpr','*测试*.dpr' | ForEach-Object { Write-Host ' -' $_.FullName; Remove-Item -LiteralPath $_.FullName -Force }

$Dcc = 'D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe'
$proj = Join-Path $here 'C盘超级瘦身.dpr'
$out = Join-Path $here 'build\\Win64'
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

# Get short (8.3) path to avoid Unicode path issues with dcc
Add-Type -Namespace Win32 -Name Kernel32 -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet=System.Runtime.InteropServices.CharSet.Auto)]
public static extern int GetShortPathName(string lfn, System.Text.StringBuilder sfn, int len);
"@
function Get-ShortPath([string]$p){ $sb = New-Object System.Text.StringBuilder 1024; [void][Win32.Kernel32]::GetShortPathName($p, $sb, $sb.Capacity); return $sb.ToString() }
$projShort = Get-ShortPath $proj; if ([string]::IsNullOrWhiteSpace($projShort)) { $projShort = $proj }
$dproj = Join-Path $here 'C盘超级瘦身.dproj'
$dprojShort = Get-ShortPath $dproj; if ([string]::IsNullOrWhiteSpace($dprojShort)) { $dprojShort = $dproj }

Write-Host 'Compiling main project...'
& $Dcc -B ("-E$out") $projShort
$code = $LASTEXITCODE
if ($code -ne 0) {
  Write-Host "dcc64 failed (exit $code). Trying MSBuild via rsvars.bat..."
$mscmd = '"D:\\Program Files (x86)\\Embarcadero\\Studio\\23.0\\bin\\rsvars.bat" && msbuild ' + '"' + $dprojShort + '"' + ' /t:Build /p:Config=Release /p:Platform=Win64'
  cmd.exe /c $mscmd
  $mscode = $LASTEXITCODE
  if ($mscode -ne 0) { Write-Host "MSBuild failed (exit $mscode)."; exit $mscode } else { Write-Host 'MSBuild succeeded.' }
} else {
  Write-Host 'Compile succeeded.'
}
