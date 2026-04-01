#!/bin/bash
# OCR 辨識工具 - Mac 啟動腳本

INSTALL_DIR="$HOME/.ocr-tool"
VENV_DIR="$INSTALL_DIR/.venv"

# 檢查是否已安裝
if [ ! -f "$VENV_DIR/bin/python3" ]; then
    echo "❌ 尚未安裝，請先雙擊「安裝（Mac）.command」"
    echo ""
    read -r -p "按 Enter 關閉..."
    exit 1
fi

# 啟動 UI（略過 PaddleOCR 網路連線檢查，加快啟動速度）
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True "$VENV_DIR/bin/python3" "$INSTALL_DIR/ocr_ui.py" 2>/dev/null
