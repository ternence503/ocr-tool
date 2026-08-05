@echo off
chcp 65001 >nul
echo ┌─────────────────────────────────────────────┐
echo │       OCR 辨識工具 — 安裝進度              │
echo └─────────────────────────────────────────────┘
echo.
echo   請勿關閉此視窗，安裝完成後會自動關閉。
echo   請保持網路連線，整個過程約需 5–15 分鐘。
echo.
echo ─────────────────────────────────────────────

:: ── [1/5] 檢查 Python ────────────────────────────────────────
echo   🔍 [1/5] 檢查 Python 版本...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   ❌ 找不到 Python
    echo.
    echo   請安裝 Python 3.12，安裝時請勾選「Add Python to PATH」：
    echo   https://www.python.org/downloads/release/python-3129/
    echo.
    pause
    exit /b 1
)

for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set PY_MAJOR=%%a
    set PY_MINOR=%%b
)
if %PY_MINOR% GTR 12 (
    echo.
    echo   ❌ Python %PYVER% 不相容
    echo   PaddleOCR 需要 Python 3.8–3.12，不支援 3.13 以上。
    echo.
    echo   請安裝 Python 3.12：
    echo   https://www.python.org/downloads/release/python-3129/
    echo.
    pause
    exit /b 1
)
echo   ✅ [1/5] Python %PYVER% 已確認
echo.

:: ── [2/5] 建立虛擬環境 ───────────────────────────────────────
echo   📁 [2/5] 準備安裝目錄...
set VENV_DIR=%~dp0.venv
if not exist "%VENV_DIR%" (
    python -m venv "%VENV_DIR%"
)

if not exist "%VENV_DIR%\Scripts\pip.exe" (
    echo.
    echo   ❌ 虛擬環境建立失敗，請重新執行安裝程式
    echo.
    pause
    exit /b 1
)
echo   ✅ [2/5] 安裝目錄準備完成
echo.

:: ── [3/5] 安裝套件 ───────────────────────────────────────────
echo   📦 [3/5] 下載並安裝必要套件（約需 3–5 分鐘）...
"%VENV_DIR%\Scripts\pip" install --upgrade pip -q
"%VENV_DIR%\Scripts\pip" install paddlepaddle paddleocr Pillow pymupdf -q

if %errorlevel% neq 0 (
    echo.
    echo   ❌ 套件安裝失敗
    echo   請確認網路連線後重新執行安裝程式。
    echo   若持續失敗，請截圖此畫面並回報問題。
    echo.
    pause
    exit /b 1
)
echo   ✅ [3/5] 套件安裝完成
echo.

:: ── [4/5] 下載辨識模型 ───────────────────────────────────────
echo   🤖 [4/5] 下載中文辨識模型（約需 1–3 分鐘）...
set PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
"%VENV_DIR%\Scripts\python" -c "from paddleocr import PaddleOCR; PaddleOCR(lang='ch', text_detection_model_name='PP-OCRv5_mobile_det', text_recognition_model_name='PP-OCRv5_mobile_rec', use_doc_orientation_classify=False, use_doc_unwarping=False)" 2>nul

if %errorlevel% neq 0 (
    echo.
    echo   ❌ 模型下載失敗
    echo   請確認網路連線後重新執行安裝程式。
    echo.
    pause
    exit /b 1
)
echo   ✅ [4/5] 辨識模型下載完成
echo.

:: ── [5/5] 建立捷徑 ───────────────────────────────────────────
echo   🖥  [5/5] 建立桌面捷徑...

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
" 2>nul

powershell -NoProfile -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\OCR辨識工具.lnk');$s.TargetPath='%~dp0OCR辨識工具（Windows）.bat';$s.WorkingDirectory='%~dp0';$s.IconLocation='%~dp0icon.ico';$s.WindowStyle=7;$s.Save()"

echo   ✅ [5/5] 桌面捷徑建立完成
echo.
echo ─────────────────────────────────────────────
echo.
echo   ✅ 安裝完成！
echo.
echo   桌面已建立「OCR辨識工具」捷徑，點兩下即可啟動。
echo   安裝完成後，本資料夾可以移動，不影響使用。
echo.
echo ─────────────────────────────────────────────
echo.
pause
