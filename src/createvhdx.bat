@Echo off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set type=fixed
set vdisk=%~1
set vhdsize=%~2
set fs=%~3
set label=%~4
set letvdisk=%~5
diskpart /s "%~dp0newvhdx.txt"
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b