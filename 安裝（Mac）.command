#!/bin/bash
# OCR 辨識工具 - Mac 安裝腳本

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.ocr-tool"
VENV_DIR="$INSTALL_DIR/.venv"

echo "=================================="
echo "  OCR 辨識工具 - 首次安裝"
echo "=================================="
echo ""

# 尋找相容的 Python（需要 3.8–3.12，PaddlePaddle 尚未支援 3.13+）
PYTHON_BIN=""
for candidate in python3.12 python3.11 python3.10 python3.9 python3.8 python3; do
    bin_path=$(command -v "$candidate" 2>/dev/null)
    if [ -z "$bin_path" ]; then
        for prefix in /opt/homebrew/bin /usr/local/bin; do
            [ -x "$prefix/$candidate" ] && bin_path="$prefix/$candidate" && break
        done
    fi
    if [ -n "$bin_path" ]; then
        ver=$("$bin_path" -c 'import sys; print(sys.version_info.major * 10 + sys.version_info.minor)' 2>/dev/null)
        if [ -n "$ver" ] && [ "$ver" -ge 38 ] && [ "$ver" -le 312 ]; then
            PYTHON_BIN="$bin_path"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "❌ 找不到相容的 Python（需要 3.8–3.12）"
    echo ""
    echo "請先安裝 Python 3.12："
    echo "https://www.python.org/downloads/"
    echo ""
    read -r -p "按 Enter 關閉..."
    exit 1
fi

PYVER=$("$PYTHON_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✅ 使用 Python $PYVER（$PYTHON_BIN）"
echo ""

# 建立安裝目錄，複製腳本進去（之後 zip 可以刪除）
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/ocr.py" "$SCRIPT_DIR/ocr_ui.py" "$INSTALL_DIR/"

# 建立虛擬環境
if [ ! -d "$VENV_DIR" ]; then
    echo "▶ 建立虛擬環境..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
    echo "✅ 虛擬環境建立完成"
else
    echo "✅ 虛擬環境已存在"
fi
echo ""

# 安裝依賴
echo "▶ 安裝必要套件（約需 3–5 分鐘，視網速而定）..."
echo "   正在安裝 PaddleOCR..."
"$VENV_DIR/bin/pip" install --upgrade pip -q 2>/dev/null
"$VENV_DIR/bin/pip" install paddlepaddle paddleocr Pillow pymupdf -q 2>/dev/null

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 安裝失敗，請確認網路連線後重試"
    read -r -p "按 Enter 關閉..."
    exit 1
fi
echo "✅ 套件安裝完成"
echo ""

# 下載模型
echo "▶ 下載辨識模型（約需 1–3 分鐘）..."
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True "$VENV_DIR/bin/python3" -c "
from paddleocr import PaddleOCR
langs = [('ch', '中文'), ('japan', '日文'), ('en', '英文')]
for code, label in langs:
    print(f'   下載{label}模型...')
    PaddleOCR(
        lang=code,
        text_detection_model_name='PP-OCRv5_mobile_det',
        text_recognition_model_name='PP-OCRv5_mobile_rec',
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
    )
    print(f'   ✅ {label}模型下載完成')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ 模型下載失敗，請確認網路連線後重試"
    read -r -p "按 Enter 關閉..."
    exit 1
fi

# 建立 /Applications App
echo "▶ 建立應用程式..."
APP_PATH="/Applications/OCR辨識工具.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

# 生成 .icns 圖示
"$VENV_DIR/bin/python3" -c "
from PIL import Image, ImageDraw, ImageFont
import os, subprocess, shutil, tempfile

def load_font(size):
    for path in [
        '/Library/Fonts/Arial Unicode.ttf',
        '/System/Library/Fonts/Geneva.ttf',
        '/System/Library/Fonts/Monaco.ttf',
    ]:
        if os.path.exists(path):
            try: return ImageFont.truetype(path, size)
            except: pass
    return None

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
    if font:
        text = 'OCR'
        bbox = draw.textbbox((0,0), text, font=font)
        tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
        tx = (size - tw) // 2 - bbox[0]
        ty = (size - th) // 2 - bbox[1]
        if size >= 32:
            draw.text((tx+1, ty+1), text, font=font, fill=(0,0,0,80))
        draw.text((tx, ty), text, font=font, fill=(255,255,255,255))
    return img

iconset = tempfile.mkdtemp(suffix='.iconset')
for s, name in [(16,'16x16'),(32,'16x16@2x'),(32,'32x32'),(64,'32x32@2x'),(128,'128x128'),(256,'128x128@2x'),(256,'256x256'),(512,'256x256@2x'),(512,'512x512'),(1024,'512x512@2x')]:
    make_frame(s).save(f'{iconset}/icon_{name}.png')
subprocess.run(['iconutil', '-c', 'icns', iconset, '-o', '$APP_PATH/Contents/Resources/AppIcon.icns'], check=True)
shutil.rmtree(iconset)
" 2>/dev/null

# 建立執行檔（指向固定安裝目錄 ~/.ocr-tool，zip 可刪除）
printf '#!/bin/bash\nPADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True "%s/bin/python3" "%s/ocr_ui.py"\n' \
    "$VENV_DIR" "$INSTALL_DIR" > "$APP_PATH/Contents/MacOS/OCR辨識工具"
chmod +x "$APP_PATH/Contents/MacOS/OCR辨識工具"

# Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>OCR辨識工具</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>OCR辨識工具</string>
    <key>CFBundleVersion</key>
    <string>1.0.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST

echo ""
echo "=================================="
echo "  ✅ 安裝完成！"
echo "=================================="
echo ""
echo "已安裝至「應用程式」，從 Launchpad 或 Spotlight 搜尋「OCR」即可啟動。"
echo "安裝完成後，本資料夾可以刪除或移動，不影響使用。"
echo ""
read -r -p "按 Enter 關閉..."
