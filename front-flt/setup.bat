@echo off
REM Doble clic para preparar el proyecto (flutter create + pub get + tests).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
pause
