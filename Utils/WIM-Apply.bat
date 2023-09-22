@ECHO OFF
set /p wim=Enter WIM Path:
dism /get-imageinfo /imagefile:"%wim%"
set /p index=Enter Index:
set /p applydir=Enter Drive Letter(Apply Dir):
dism /Apply-Image /ImageFile:"%wim%" /index:"%index%" /ApplyDir:"%applydir%"