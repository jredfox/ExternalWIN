@Echo Off
setlocal enableDelayedExpansion
IF "!disk!" EQU "" (
set disk=%~1
set disk=!disk:"=!
)
REM ### Find the Active Partition Here ###
set par=-1
FOR /F "tokens=1* delims= " %%a in ('wmic partition where "DiskIndex=!disk!" get BootPartition^,DeviceID') DO (
IF /I "%%a" EQU "TRUE" (
FOR /F "tokens=3 delims=#" %%i in ("%%b") DO (
    set par=%%i
    set /A par=!par! + 1
    GOTO ENDLOOP
)
)
)
REM ### Disable the Active Partition Here if it is found ###
:ENDLOOP
del /F /Q /A "%TMP%\disablepar.txt" >nul 2>&1
IF "%par%" EQU "-1" (exit /b)
echo Disabling Active Partition^: %par%
    (
        echo select disk %disk%
        echo select partition %par%
        echo set ID=18
    ) > "%TMP%\disablepar.txt"
diskpart /s "%TMP%\disablepar.txt"
del /F /Q /A "%TMP%\disablepar.txt" >nul 2>&1