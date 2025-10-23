@echo off
echo Importing all images...
ImportImages.exe wechat assets\wechat.png "微信收款码"
ImportImages.exe alipay assets\AliPay.png "支付宝收款码"
ImportImages.exe btc assets\btc.png "BTC地址"
ImportImages.exe usdt assets\usdt.png "USDT地址"
ImportImages.exe aboutme assets\itsMe.jpg "关于我"
echo Import completed!
pause
