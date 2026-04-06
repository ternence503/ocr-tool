@echo off
chcp 65001 >/dev/null
echo ==================================
echo   OCR 辨識工具 - 安裝中
echo ==================================
echo.

:: ── 偵測 Python ──────────────────────────────────────────────
set PYTHON_EXE=
set PYTHON_OK=0

:: 先找 PATH 中的 python（版本需 3.8-3.12）
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set PY_MAJOR=%%a
    set PY_MINOR=%%b
)
if defined PY_MINOR (
    if %PY_MINOR% LEQ 12 (
        set PYTHON_EXE=python
        set PYTHON_OK=1
    )
)

:: 再找常見安裝位置
if "%PYTHON_OK%"=="0" (
    for %%p in (
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
        "C:\Python312\python.exe"
        "C:\Python311\python.exe"
    ) do (
        if exist %%~p (
            set PYTHON_EXE=%%~p
            set PYTHON_OK=1
            goto :check_done
        )
    )
)
:check_done

:: 沒有 Python -> 自動下載安裝
if "%PYTHON_OK%"=="0" (
    echo 未偵測到 Python，正在自動下載 Python 3.12...
    echo 下載中，約 25MB，請稍候...
    echo.
    powershell -NoProfile -Command ^
      "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe' -OutFile '%TEMP%\python312_setup.exe'" 2>/dev/null
    if not exist "%TEMP%\python312_setup.exe" (
        echo.
        echo 下載失敗，請確認網路連線後重試。
        pause
        exit /b 1
    )
    echo 正在安裝 Python 3.12，請稍候...
    "%TEMP%\python312_setup.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1
    del "%TEMP%\python312_setup.exe" >/dev/null 2>&1
    set PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe
    if not exist "%PYTHON_EXE%" (
        echo.
        echo Python 安裝失敗，請至 https://www.python.org/downloads/release/python-3129/ 手動安裝後重試。
        pause
        exit /b 1
    )
    echo Python 3.12 安裝完成！
    echo.
)

echo Python 已就緒
echo.

:: ── 建立虛擬環境 ──────────────────────────────────────────────
set VENV_DIR=%~dp0.venv
if not exist "%VENV_DIR%" (
    echo 正在建立執行環境...
    "%PYTHON_EXE%" -m venv "%VENV_DIR%"
    if %errorlevel% neq 0 (
        echo 建立執行環境失敗，請重試。
        pause
        exit /b 1
    )
    echo 執行環境建立完成
) else (
    echo 執行環境已存在，略過
)
echo.

:: ── 安裝套件 ──────────────────────────────────────────────────
echo 正在安裝必要套件（約需 3-5 分鐘）...
"%VENV_DIR%\Scripts\pip" install --upgrade pip -q
"%VENV_DIR%\Scripts\pip" install paddlepaddle paddleocr Pillow pymupdf -q
if %errorlevel% neq 0 (
    echo.
    echo 套件安裝失敗，請確認網路連線後重試。
    pause
    exit /b 1
)
echo 套件安裝完成
echo.

:: ── 下載辨識模型 ──────────────────────────────────────────────
echo 正在下載辨識模型（約需 1-3 分鐘）...
"%VENV_DIR%\Scripts\python" -c "from paddleocr import PaddleOCR; langs=[('ch','中文'),('japan','日文'),('en','英文')]; [PaddleOCR(lang=code, text_detection_model_name='PP-OCRv5_mobile_det', text_recognition_model_name='PP-OCRv5_mobile_rec', use_doc_orientation_classify=False, use_doc_unwarping=False) for code,_label in langs]" 2>/dev/null
if %errorlevel% neq 0 (
    echo.
    echo 模型下載失敗，請確認網路連線後重試。
    pause
    exit /b 1
)
echo 辨識模型下載完成
echo.

:: ── 建立圖示 ──────────────────────────────────────────────────
echo 正在建立圖示...
"%VENV_DIR%\Scripts\python" -c "
from PIL import Image, ImageDraw, ImageFont
import os

def load_font(size):
    for path in [
        r'C:\Windows\Fonts\arialbd.ttf',
        r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\calibrib.ttf',
        r'C:\Windows\Fonts\segoeui.ttf',
    ]:
        if os.path.exists(path):
            try: return ImageFont.truetype(path, size)
            except: pass
    return ImageFont.load_default()

def make_frame(size):
    img = Image.new('RGBA', (size, size), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    pad = max(1, size // 12)
    r = max(2, size // 4)
    draw.rounded_rectangle([pad, pad, size-pad-1, size-pad-1], radius=r, fill=(30, 115, 220, 255))
    if size >= 48:
        for y in range(pad + r + 2, size - pad - r - 2, max(3, size // 20)):
            draw.line([(pad+r, y), (size-pad-r, y)], fill=(255,255,255,35), width=1)
    font = load_font(max(6, int(size * 0.38)))
    text = 'OCR'
    bbox = draw.textbbox((0,0), text, font=font)
    tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
    tx = (size - tw) // 2 - bbox[0]
    ty = (size - th) // 2 - bbox[1]
    if size >= 32:
        draw.text((tx+1, ty+1), text, font=font, fill=(0,0,0,80))
    draw.text((tx, ty), text, font=font, fill=(255,255,255,255))
    return img

frames = [make_frame(s) for s in [16,32,48,256]]
frames[0].save(r'%~dp0icon.ico', format='ICO', sizes=[(16,16),(32,32),(48,48),(256,256)], append_images=frames[1:])
print('done')
" 2>/dev/null

:: ── 建立桌面捷徑 ──────────────────────────────────────────────
echo 正在建立桌面捷徑...
powershell -NoProfile -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\OCR辨識工具.lnk');$s.TargetPath='%~dp0ocr_launcher.bat';$s.WorkingDirectory='%~dp0';$s.IconLocation='%~dp0icon.ico';$s.WindowStyle=7;$s.Save()"

echo.
echo ==================================
echo   安裝完成！
echo ==================================
echo.
echo 桌面已建立「OCR辨識工具」捷徑，點兩下即可啟動。
echo.
pause
