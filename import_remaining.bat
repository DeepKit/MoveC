@echo off
echo Importing remaining 4 images...
echo.

echo [1/4] Importing alipay...
ImportImages.exe alipay assets\AliPay.png "支付宝收款码"
if errorlevel 1 echo ERROR importing alipay
echo.

echo [2/4] Importing btc...
ImportImages.exe btc assets\btc.png "BTC地址"
if errorlevel 1 echo ERROR importing btc
echo.

echo [3/4] Importing usdt...
ImportImages.exe usdt assets\usdt.png "USDT地址"
if errorlevel 1 echo ERROR importing usdt
echo.

echo [4/4] Importing aboutme...
ImportImages.exe aboutme assets\itsMe.jpg "关于我"
if errorlevel 1 echo ERROR importing aboutme
echo.

echo All done! Check import_log.txt for details
pause
