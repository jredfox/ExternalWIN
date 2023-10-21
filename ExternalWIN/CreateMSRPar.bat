@Echo Off
setlocal enabledelayedexpansion
IF "%ISMBR%" EQU "T" (
exit /b
)
del /F /Q /A "%TMP%\diskpart_script.txt"
del /F /Q /A "%TMP%\partition_details.txt"

REM GPT Disks supports 128 partitions and the for loop starts at 1 and goes to 128
set PartitionCount=128

for /l %%i in (1, 1, %PartitionCount%) do (
    (
    echo select disk %disk%
    echo select partition %%i
    echo detail partition
    ) > "%TMP%\diskpart_script.txt"

    diskpart /s "%TMP%\diskpart_script.txt" > "%TMP%\partition_details.txt"
    IF !ERRORLEVEL! NEQ 0 (
	GOTO END
    )
    cscript "%~dp0FindSTR.vbs" "e3c9e316-0b5c-4db8-817d-f92df00215ae" "%TMP%\partition_details.txt" "false" >nul
    IF !ERRORLEVEL! EQU 0 (
       echo Found MSR Partition %%i
       set found=T
    )

    del /F /Q /A "%TMP%\diskpart_script.txt"
    del /F /Q /A "%TMP%\partition_details.txt"
    IF "!found!" EQU "T" GOTO END
)

:END
IF "!found!" NEQ "T" (
echo Creating MSR Partition as it wasn't found
diskpart /s "%~dp0ParMSR.txt"
REM We Have to Sleep Before Cleaning up the Par so FEND can close the popups first
cscript "%~dp0Sleep.vbs" "1800" >nul 2>&1
call "%~dp0CleanupPar.bat"
)
exit /b