@Echo Off
setlocal enableDelayedExpansion
IF "%ISMBR%" EQU "" (
echo Internal Utility Script Cannot be used by itself exiting^.^.^.
pause
exit /b 1
)
IF %ISMBR% NEQ T (
diskpart /s "%~dp0Clean.txt"
timeout /NOBREAK 2
echo Deleting Auto Generted MSR If It exists
diskpart /s "%~dp0Clean-1.txt" > nul
) ELSE (
diskpart /s "%~dp0Clean-MBR.txt"
)