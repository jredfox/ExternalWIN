@Echo off
set /p img=Enter Image(VHD, VHDX, ISO, ESD):
powershell -ExecutionPolicy Bypass -File "%dp0~IMG2WIM.ps1"