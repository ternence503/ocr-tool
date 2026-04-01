#!/bin/bash
# OCR 辨識工具 - Mac 安裝腳本

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

echo "=================================="
echo "  OCR 辨識工具 - 首次安裝"
echo "=================================="
echo ""

# 尋找相容的 Python（3.8–3.12，paddlepaddle 不支援 3.13+）
PYTHON_BIN=""
for ver in python3.12 python3.11 python3.10 python3.9 python3.8; do
    if command -v "$ver" &>/dev/null; then
        PYTHON_BIN=$(command -v "$ver")
        break
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "❌ 找不到相容的 Python（需要 3.8–3.12）"
    echo ""
    echo "請安裝 Python 3.12："
    echo "https://www.python.org/downloads/"
    echo ""
    read -r -p "按 Enter 關閉..."
    exit 1
fi

PYVER=$("$PYTHON_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✅ 使用 Python $PYVER（$PYTHON_BIN）"
echo ""

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
import sys
print('   下載中文模型...')
PaddleOCR(lang='ch')
print('   ✅ 中文模型下載完成')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ 模型下載失敗，請確認網路連線後重試"
    read -r -p "按 Enter 關閉..."
    exit 1
fi

echo ""
echo "=================================="
echo "  ✅ 安裝完成！"
echo "=================================="
echo ""
echo "之後請雙擊「OCR辨識工具（Mac）.command」啟動"
echo ""
read -r -p "按 Enter 關閉..."
