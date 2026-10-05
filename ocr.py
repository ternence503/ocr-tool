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
from glob import escape as glob_escape

def open_file(path):
    """用系統預設程式開檔；不經 shell，檔名含引號或特殊字元也安全。"""
    if sys.platform == 'darwin':
        subprocess.run(['open', str(path)], check=False)
    elif sys.platform.startswith('win'):
        os.startfile(str(path))
    else:
        subprocess.run(['xdg-open', str(path)], check=False)

_SOURCE_EXTS = {'.jpg', '.jpeg', '.png', '.pdf'}

def ocr_output_path(src_path):
    """輸出檔路徑：<原檔名>_ocr.txt。同資料夾若有同名但副檔名不同的來源檔（a.jpg 與 a.png），
    改用 <原檔名>_<副檔名>_ocr.txt，避免兩份辨識結果互相覆蓋。"""
    src = Path(src_path)
    clash = any(p != src and p.suffix.lower() in _SOURCE_EXTS and p.stem == src.stem
                for p in src.parent.glob(glob_escape(src.stem) + '.*'))
    name = f"{src.stem}_{src.suffix.lstrip('.').lower()}_ocr.txt" if clash else f"{src.stem}_ocr.txt"
    return src.parent / name

def resize_if_needed(image_path, max_size=2000):
    from PIL import Image
    from PIL import ImageOps
    with Image.open(image_path) as img:
        # 手機直拍的照片常靠 EXIF 方向標記，不校正會被當成橫的辨識
        rotated = img.getexif().get(0x0112, 1) not in (0, 1)
        img = ImageOps.exif_transpose(img)
        w, h = img.size
        too_big = max(w, h) > max_size
        if not rotated and not too_big:
            return image_path
        if too_big:
            ratio = max_size / max(w, h)
            new_w, new_h = int(w * ratio), int(h * ratio)
            img = img.resize((new_w, new_h), Image.LANCZOS)
            print(f"圖片已縮小：{w}×{h} → {new_w}×{new_h}")
        if rotated:
            print("已依 EXIF 方向標記校正圖片方向")
        # 存到系統暫存區，不要寫在原圖旁邊（可能沒權限，也會留下垃圾檔）
        tmp_fd, resized_path = tempfile.mkstemp(suffix='_ocr_resized.jpg')
        os.close(tmp_fd)
        img.convert('RGB').save(resized_path, quality=95)
    return resized_path

_ocr_cache = {}

def get_ocr(lang):
    """同一語言只載入一次模型；多頁 PDF 不再每頁重載。"""
    if lang not in _ocr_cache:
        from paddleocr import PaddleOCR
        _ocr_cache[lang] = PaddleOCR(lang=lang)
    return _ocr_cache[lang]

def ocr_image(image_path, lang='ch'):
    print(f"語言：{lang}，辨識中...")
    ocr = get_ocr(lang)
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
    try:
        doc = fitz.open(pdf_path)
    except Exception as e:
        raise RuntimeError(f"無法開啟 PDF（檔案可能損毀）：{e}") from e
    if doc.needs_pass:
        doc.close()
        raise RuntimeError("這份 PDF 有密碼保護，請先解除密碼再辨識")
    with tempfile.TemporaryDirectory(prefix='ocr_pdf_') as tmp_dir, doc:
        print(f"PDF 共 {len(doc)} 頁")
        for i, page in enumerate(doc):
            print(f"辨識第 {i+1} 頁...")
            # 依頁面大小決定解析度：長邊渲染不超過 2000px，大圖紙不會先產生巨大圖片
            long_pt = max(page.rect.width, page.rect.height) or 1
            pix = page.get_pixmap(dpi=max(36, min(150, int(2000 * 72 / long_pt))))
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
    output_path = str(ocr_output_path(input_path))

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
