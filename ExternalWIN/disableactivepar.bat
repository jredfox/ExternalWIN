@echo off
setlocal enabledelayedexpansion
set PartitionCount=4

REM Loop through each partition and check if it is active
for /l %%i in (1, 1, %PartitionCount%) do (
    (
    echo select disk %disk%
    echo select partition %%i
    echo detail partition
    ) > "%TMP%\diskpart_script.txt"

    diskpart /s "%TMP%\diskpart_script.txt" > "%TMP%\partition_details.txt"
    REM Check if the partition is active ("Active: Yes" or "Active: True" ignoring case)
	set Found=F
    cscript "%~dp0FindSTR.vbs" "Active: Yes" "%TMP%\partition_details.txt" "false" >nul
	IF !ERRORLEVEL! EQU 0 (set Found=T)
	cscript "%~dp0FindSTR.vbs" "Active: True" "%TMP%\partition_details.txt" "false" >nul
	IF !ERRORLEVEL! EQU 0 (set Found=T)
    IF !Found! EQU T (
        echo Active partition found: %%i
        REM set par ID to 18
        (
        echo select disk %disk%
        echo select partition %%i
        echo set ID=18
        ) > "%TMP%\set_active_partition.txt"

        diskpart /s "%TMP%\set_active_partition.txt"
        del "%TMP%\set_active_partition.txt"
    )

    del "%TMP%\diskpart_script.txt"
    del "%TMP%\partition_details.txt"
	IF !Found! EQU T (exit /b)
)