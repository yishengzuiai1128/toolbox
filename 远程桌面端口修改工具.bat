@echo off
color f0
echo.
echo 支持系统：Windows 2003 / 2008 / 2008R2 / 2012 / 2012R2 / 7 / 8 / 10
echo 日期：%date%   时间：%time%
echo ARK工具 - 添加防火墙规则并修改远程桌面端口
echo.

set /p port=请输入远程桌面端口（1025-65535）: 
if "%port%"=="" goto end
set /a portnum=%port%

REM 检查端口范围
if %portnum% LSS 1025 (
    echo [错误] 端口号太小，必须大于1024。
    goto end
)
if %portnum% GTR 65535 (
    echo [错误] 端口号太大，不能超过65535。
    goto end
)

REM 添加防火墙规则
netsh advfirewall firewall add rule name="Remote Desktop Port %portnum%" dir=in action=allow protocol=TCP localport=%portnum%

REM 修改注册表中的远程桌面端口
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v "PortNumber" /t REG_DWORD /d %portnum% /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber" /t REG_DWORD /d %portnum% /f

echo.
echo [成功] 已修改远程桌面端口为 %portnum%
echo 即将重启系统以应用更改...
pause
shutdown /r /t 0
exit

:end
echo.
echo 操作已取消或失败。
pause
