@Echo off
set /p vdisk=Input VHDX File:
set vdisk=%vdisk:"=%
call %~dp0%WinInstallVHDX.bat