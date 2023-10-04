@Echo Off
setlocal enabledelayedexpansion
IF "%ISMBR%" EQU "T" (
exit /b
)

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
    findstr /i /c:"e3c9e316-0b5c-4db8-817d-f92df00215ae" "%TMP%\partition_details.txt" > nul
    IF !ERRORLEVEL! EQU 0 (
       echo Found MSR Partition %%i
       set found=T
    )

    del "%TMP%\diskpart_script.txt"
    del "%TMP%\partition_details.txt"
    IF "!found!" EQU "T" GOTO END
)

:END
IF "!found!" NEQ "T" (
echo Creating MSR Partition as it wasn't found
diskpart /s "%~dp0ParMSR.txt"
)