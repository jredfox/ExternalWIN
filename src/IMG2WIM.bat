@Echo off
set /p img=Enter Image(VHD, VHDX, ISO, ESD):
powershell -ExecutionPolicy Bypass -File "%~dp0IMG2WIM.ps1" -Image %img%
pause