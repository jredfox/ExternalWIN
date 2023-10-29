@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
title ExternalWin Version 1.0.9 VHDX
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
set /p vdisk="Input VHDX File:"
set vdisk=%vdisk:"=%
call "%~dp0WinInstallVHDX.bat"
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b