@echo off
title ���� Administrator ����
color 0a

:: ����ԱȨ�޼��
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [��] ���Թ���Ա������д˽ű���
    pause
    exit /b
)

:: ��ȫ��������
for /f "delims=" %%p in ('powershell -command "$p = Read-Host -AsSecureString '����������������'; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))"') do set input=%%p

echo.
echo ������������...

:: ִ�������޸�
net user administrator "%input%"
if %errorlevel% equ 0 (
    echo [��] �������óɹ���
) else (
    echo [��] ��������ʧ�ܣ������˻�״̬��Ȩ�ޡ�
)

pause
