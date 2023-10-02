@ECHO OFF
reg import "%~dp0HKLM.reg"
reg import "%~dp0HKCU.reg"
reg import "%~dp0HKCR.reg"
reg import "%~dp0HKU.reg"
reg import "%~dp0HKCC.reg"
pause