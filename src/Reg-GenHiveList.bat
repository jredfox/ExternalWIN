@Echo Off
setlocal enableDelayedExpansion
set hivelist=%~dp0hivelist.txt
del /f /q /a "%hivelist%" >nul 2>&1
reg query HKLM\SYSTEM\CurrentControlSet\Control\hivelist >"%hivelist%"