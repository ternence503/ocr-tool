#!/bin/bash
# OCR 辨識工具 - Mac 啟動腳本

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# 檢查是否已安裝
if [ ! -f "$VENV_DIR/bin/python3" ]; then
    echo "❌ 尚未安裝，請先雙擊「安裝（Mac）.command」"
    echo ""
    read -r -p "按 Enter 關閉..."
    exit 1
fi

# 啟動 UI
"$VENV_DIR/bin/python3" "$SCRIPT_DIR/ocr_ui.py"
