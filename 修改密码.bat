@echo off
title 设置 Administrator 密码
color 0a

:: 管理员权限检查
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [×] 请以管理员身份运行此脚本！
    pause
    exit /b
)

:: 安全输入密码
for /f "delims=" %%p in ('powershell -command "$p = Read-Host -AsSecureString '请输入您的新密码'; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))"') do set input=%%p

echo.
echo 正在设置密码...

:: 执行密码修改
net user administrator "%input%"
if %errorlevel% equ 0 (
    echo [√] 密码设置成功！
) else (
    echo [×] 密码设置失败，请检查账户状态或权限。
)

pause
