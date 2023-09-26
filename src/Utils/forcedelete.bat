REM this is to force delete the extracted WIM files when mounting goes wrong. Do not Delete SYSTEM32 with this
set dir=%~1
takeown /F "%dir%" /R /D Y
icacls "%dir%" /T /C /grant administrators:F System:F everyone:F
del /F "%dir%" /s /q /a
rmdir /s /q "%dir%"