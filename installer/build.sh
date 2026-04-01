#!/bin/bash
# OCR 辨識工具 - build macOS .pkg installer
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
COMPONENT_PKG="$BUILD_DIR/OCRTool-component.pkg"
OUTPUT_PKG="$REPO_DIR/ocr-tool-mac.pkg"

# ── 清理舊的 build ────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR/Library/Application Support/OCRTool"

# ── 複製 payload（Python 腳本，排除 macOS 元資料）────────────────
cp "$REPO_DIR/ocr.py" "$REPO_DIR/ocr_ui.py" \
   "$PAYLOAD_DIR/Library/Application Support/OCRTool/"
find "$PAYLOAD_DIR" -name "._*" -delete

# ── 建立 component package ─────────────────────────────────────
pkgbuild \
  --root "$PAYLOAD_DIR" \
  --scripts "$SCRIPT_DIR/scripts" \
  --identifier "com.ternence.ocr-tool" \
  --version "1.0.0" \
  --install-location "/" \
  "$COMPONENT_PKG"

# ── 建立最終 installer（含 welcome 畫面）──────────────────────
productbuild \
  --distribution "$SCRIPT_DIR/distribution.xml" \
  --resources "$SCRIPT_DIR/resources" \
  --package-path "$BUILD_DIR" \
  "$OUTPUT_PKG"

echo ""
echo "✅ 完成！輸出：$OUTPUT_PKG"
echo "   大小：$(du -sh "$OUTPUT_PKG" | cut -f1)"
