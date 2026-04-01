@echo off
chcp 65001 >nul
set VENV_DIR=%~dp0.venv

if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo ❌ 尚未安裝，請先雙擊「安裝（Windows）.bat」
    pause
    exit /b 1
)

"%VENV_DIR%\Scripts\python" "%~dp0ocr_ui.py"
