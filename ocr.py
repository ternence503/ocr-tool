#!/usr/bin/env python3
"""
OCR 辨識工具
支援：JPG、PNG、PDF
自動縮圖（超過 2000px 自動縮小）
語言：ch（繁簡中文）、japan（日文）、en（英文）
用法：python3 ocr.py <圖片路徑> [語言]
"""

import sys
import os
import subprocess
import tempfile
from pathlib import Path

def open_file(path):
    """用系統預設程式開檔；不經 shell，檔名含引號或特殊字元也安全。"""
    if sys.platform == 'darwin':
        subprocess.run(['open', str(path)], check=False)
    elif sys.platform.startswith('win'):
        os.startfile(str(path))
    else:
        subprocess.run(['xdg-open', str(path)], check=False)

def resize_if_needed(image_path, max_size=2000):
    from PIL import Image
    img = Image.open(image_path)
    w, h = img.size
    if max(w, h) <= max_size:
        return image_path
    ratio = max_size / max(w, h)
    new_w, new_h = int(w * ratio), int(h * ratio)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    # 存到系統暫存區，不要寫在原圖旁邊（可能沒權限，也會留下垃圾檔）
    tmp_fd, resized_path = tempfile.mkstemp(suffix='_ocr_resized.jpg')
    os.close(tmp_fd)
    resized.convert('RGB').save(resized_path, quality=95)
    print(f"圖片已縮小：{w}×{h} → {new_w}×{new_h}")
    return resized_path

def ocr_image(image_path, lang='ch'):
    from paddleocr import PaddleOCR
    print(f"語言：{lang}，辨識中...")
    ocr = PaddleOCR(lang=lang)
    result = ocr.predict(image_path)
    texts = []
    for res in result:
        for line in res['rec_texts']:
            if line.strip():
                texts.append(line)
    return texts

def ocr_pdf(pdf_path, lang='ch'):
    import fitz  # PyMuPDF
    from PIL import Image
    import io
    all_texts = []
    # 頁面圖放在專用暫存資料夾，無論成功或出錯離開時整個刪除
    with tempfile.TemporaryDirectory(prefix='ocr_pdf_') as tmp_dir, fitz.open(pdf_path) as doc:
        print(f"PDF 共 {len(doc)} 頁")
        for i, page in enumerate(doc):
            print(f"辨識第 {i+1} 頁...")
            pix = page.get_pixmap(dpi=150)
            tmp_path = os.path.join(tmp_dir, f'page_{i}.jpg')
            with open(tmp_path, 'wb') as f:
                f.write(pix.tobytes("jpeg"))
            ocr_path = resize_if_needed(tmp_path)
            try:
                texts = ocr_image(ocr_path, lang)
            finally:
                if ocr_path != tmp_path and os.path.exists(ocr_path):
                    os.remove(ocr_path)
            all_texts.append(f"\n=== 第 {i+1} 頁 ===\n")
            all_texts.extend(texts)
    return all_texts

def main():
    if len(sys.argv) < 2:
        print("用法：python3 ocr.py <檔案路徑> [語言]")
        print("語言選項：ch（預設，繁簡中文）、japan（日文）、en（英文）")
        sys.exit(1)

    input_path = sys.argv[1]
    lang = sys.argv[2] if len(sys.argv) > 2 else 'ch'

    if not os.path.exists(input_path):
        print(f"找不到檔案：{input_path}")
        sys.exit(1)

    ext = Path(input_path).suffix.lower()
    base_name = Path(input_path).stem
    output_path = os.path.join(os.path.dirname(input_path), f"{base_name}_ocr.txt")

    print(f"檔案：{input_path}")

    if ext == '.pdf':
        texts = ocr_pdf(input_path, lang)
    else:
        image_path = resize_if_needed(input_path)
        try:
            texts = ocr_image(image_path, lang)
        finally:
            # 清理暫存縮圖（出錯也要清）
            if image_path != input_path and os.path.exists(image_path):
                os.remove(image_path)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(texts))

    print(f"\n完成！結果存至：{output_path}")
    print(f"共辨識 {len([t for t in texts if t.strip()])} 行文字")

    # 自動用 TextEdit 開啟
    open_file(output_path)

if __name__ == '__main__':
    main()
