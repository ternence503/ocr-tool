@echo off
chcp 65001 >nul
echo ==================================
echo   OCR 辨識工具 - Windows 安裝
echo ==================================
echo.

:: 檢查 Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 找不到 Python
    echo.
    echo 請安裝 Python 3.12：
    echo https://www.python.org/downloads/release/python-3129/
    echo.
    echo 安裝時請勾選「Add Python to PATH」
    echo.
    pause
    exit /b 1
)

:: 檢查 Python 版本（paddlepaddle 不支援 3.13+）
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set PY_MAJOR=%%a
    set PY_MINOR=%%b
)
if %PY_MINOR% GTR 12 (
    echo ❌ Python %PYVER% 不相容（paddlepaddle 需要 3.8–3.12）
    echo.
    echo 請安裝 Python 3.12：
    echo https://www.python.org/downloads/release/python-3129/
    echo.
    pause
    exit /b 1
)

echo ✅ Python %PYVER% 已安裝
echo.

:: 建立虛擬環境
set VENV_DIR=%~dp0.venv
if not exist "%VENV_DIR%" (
    echo ▶ 建立虛擬環境...
    python -m venv "%VENV_DIR%"
    echo ✅ 虛擬環境建立完成
) else (
    echo ✅ 虛擬環境已存在
)
echo.

:: 安裝依賴
echo ▶ 安裝必要套件（約需 3–5 分鐘）...
"%VENV_DIR%\Scripts\pip" install --upgrade pip -q
"%VENV_DIR%\Scripts\pip" install paddlepaddle paddleocr Pillow pymupdf -q

if %errorlevel% neq 0 (
    echo.
    echo ❌ 安裝失敗，請確認網路連線後重試
    pause
    exit /b 1
)
echo ✅ 套件安裝完成
echo.

:: 下載模型
echo ▶ 下載辨識模型（約需 1–3 分鐘）...
"%VENV_DIR%\Scripts\python" -c "from paddleocr import PaddleOCR; PaddleOCR(lang='ch')" 2>nul

if %errorlevel% neq 0 (
    echo ❌ 模型下載失敗，請確認網路連線後重試
    pause
    exit /b 1
)

echo.
echo ==================================
echo   ✅ 安裝完成！
echo ==================================
echo.
echo 之後請雙擊「OCR辨識工具（Windows）.bat」啟動
echo.
pause
