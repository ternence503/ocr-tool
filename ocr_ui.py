#!/usr/bin/env python3
"""
OCR 辨識工具 完整版
Powered by PaddleOCR (Apache 2.0) - https://github.com/PaddlePaddle/PaddleOCR
"""

import tkinter as tk
from tkinter import ttk, filedialog, scrolledtext, messagebox
import threading
import os
import sys
import json
from pathlib import Path

APP_NAME = "OCR 辨識工具"
APP_VERSION = "1.0.0"
MODEL_DIR = os.path.join(Path.home(), '.paddlex', 'official_models')

LANG_OPTIONS = [
    ("繁簡中文", "ch"),
    ("日文",     "japan"),
    ("英文",     "en"),
]

# ── OCR 核心 ────────────────────────────────────────────

def resize_if_needed(image_path, max_size=2000):
    from PIL import Image
    img = Image.open(image_path)
    w, h = img.size
    if max(w, h) <= max_size:
        return image_path, None
    ratio = max_size / max(w, h)
    new_w, new_h = int(w * ratio), int(h * ratio)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    resized_path = image_path + '_resized.jpg'
    resized.save(resized_path, quality=95)
    return resized_path, f"圖片已縮小：{w}×{h} → {new_w}×{new_h}"

def run_ocr(file_path, lang, log_fn):
    from paddleocr import PaddleOCR
    ext = Path(file_path).suffix.lower()

    if ext == '.pdf':
        return _ocr_pdf(file_path, lang, log_fn)
    else:
        return _ocr_image(file_path, lang, log_fn)

def _ocr_image(image_path, lang, log_fn):
    import os, sys
    from paddleocr import PaddleOCR
    resized_path, msg = resize_if_needed(image_path)
    if msg:
        log_fn(msg)
    log_fn("辨識中...")
    devnull = open(os.devnull, 'w')
    old_stderr = sys.stderr
    sys.stderr = devnull
    try:
        ocr = PaddleOCR(lang=lang)
        result = ocr.predict(resized_path)
    finally:
        sys.stderr = old_stderr
        devnull.close()
    if resized_path != image_path and os.path.exists(resized_path):
        os.remove(resized_path)
    texts = []
    for res in result:
        for line in res['rec_texts']:
            if line.strip():
                texts.append(line)
    return texts

def _ocr_pdf(pdf_path, lang, log_fn):
    import fitz
    all_texts = []
    doc = fitz.open(pdf_path)
    log_fn(f"PDF 共 {len(doc)} 頁")
    for i, page in enumerate(doc):
        log_fn(f"辨識第 {i+1} 頁...")
        tmp_path = f'/tmp/ocr_pdf_page_{i}.jpg'
        pix = page.get_pixmap(dpi=150)
        with open(tmp_path, 'wb') as f:
            f.write(pix.tobytes("jpeg"))
        resized_path, msg = resize_if_needed(tmp_path)
        if msg:
            log_fn(msg)
        texts = _ocr_image(resized_path, lang, lambda m: None)
        all_texts.append(f"=== 第 {i+1} 頁 ===")
        all_texts.extend(texts)
        all_texts.append("")
        if resized_path != tmp_path and os.path.exists(resized_path):
            os.remove(resized_path)
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
    return all_texts

# ── 首次啟動下載模型視窗 ─────────────────────────────────

class DownloadWindow:
    def __init__(self, parent, on_done):
        self.win = tk.Toplevel(parent)
        self.win.title("初始化")
        self.win.geometry("420x180")
        self.win.resizable(False, False)
        self.win.grab_set()
        self.on_done = on_done

        tk.Label(self.win, text="首次使用，正在下載辨識模型",
                 font=('Helvetica', 14, 'bold'), pady=20).pack()
        tk.Label(self.win, text="下載完成後即可離線使用，約需 1–3 分鐘",
                 font=('Helvetica', 11), fg='#666').pack()

        self.progress = ttk.Progressbar(self.win, mode='indeterminate', length=340)
        self.progress.pack(pady=15)
        self.progress.start(10)

        self.status = tk.Label(self.win, text="連線中...", font=('Helvetica', 11), fg='#444')
        self.status.pack()

        threading.Thread(target=self._download, daemon=True).start()

    def _download(self):
        try:
            self.status.config(text="下載中文模型...")
            from paddleocr import PaddleOCR
            PaddleOCR(lang='ch')
            self.progress.stop()
            self.status.config(text="✅ 完成！")
            self.win.after(800, self._finish)
        except Exception as e:
            self.progress.stop()
            self.status.config(text=f"❌ 下載失敗：{e}")

    def _finish(self):
        self.win.destroy()
        self.on_done()

def model_exists():
    return os.path.exists(MODEL_DIR) and len(os.listdir(MODEL_DIR)) > 0

# ── 主介面 ───────────────────────────────────────────────

class OCRApp:
    def __init__(self, root):
        self.root = root
        self.root.title(APP_NAME)
        self.root.geometry("720x640")
        self.root.resizable(True, True)
        self.root.configure(bg='#f0f0f0')
        self.file_path = tk.StringVar()
        self.lang = tk.StringVar(value='ch')
        self.result_texts = []
        self._build_ui()
        self._check_model()

    def _check_model(self):
        if not model_exists():
            self.root.after(300, lambda: DownloadWindow(self.root, self._on_model_ready))
        else:
            self._on_model_ready()

    def _on_model_ready(self):
        self.run_btn.config(state='normal')
        self._log("就緒，請選擇圖片或 PDF 開始辨識。")

    def _build_ui(self):
        # ── ttk 樣式（確保 macOS 顏色正確）──
        style = ttk.Style()
        style.theme_use('default')
        style.configure('Blue.TButton',   font=('Helvetica', 12), padding=6)
        style.configure('Green.TButton',  font=('Helvetica', 14, 'bold'), padding=8)
        style.configure('Gray.TButton',   font=('Helvetica', 12), padding=6)
        style.configure('Red.TButton',    font=('Helvetica', 12), padding=6)
        style.configure('About.TButton',  font=('Helvetica', 11), padding=4)

        # ── 頂部標題 ──
        header = tk.Frame(self.root, bg='#2c3e50', height=60)
        header.pack(fill='x')
        header.pack_propagate(False)
        tk.Label(header, text=f"  {APP_NAME}", font=('Helvetica', 17, 'bold'),
                 bg='#2c3e50', fg='white').pack(side='left', padx=10, pady=12)
        ttk.Button(header, text="關於", command=self._show_about,
                   style='About.TButton').pack(side='right', padx=12, pady=14)

        # ── 檔案選擇 ──
        file_frame = tk.Frame(self.root, bg='#f0f0f0', pady=12)
        file_frame.pack(fill='x', padx=25)

        tk.Label(file_frame, text="檔案：", font=('Helvetica', 13),
                 bg='#f0f0f0').pack(side='left')

        self.file_entry = tk.Entry(file_frame, textvariable=self.file_path,
                                   font=('Helvetica', 12), width=44,
                                   relief='solid', bd=1)
        self.file_entry.pack(side='left', padx=(5, 8), ipady=4)

        ttk.Button(file_frame, text="選擇檔案", command=self._browse,
                   style='Blue.TButton').pack(side='left')

        # 拖曳提示
        tk.Label(self.root, text="支援 JPG・PNG・PDF　（可直接拖曳檔案到視窗）",
                 font=('Helvetica', 10), fg='#888', bg='#f0f0f0').pack()

        # ── 拖曳區域 ──
        drop_zone = tk.Label(self.root,
                             text="📂  把檔案拖曳到這裡",
                             font=('Helvetica', 13), fg='#888',
                             bg='white', relief='solid', bd=1,
                             height=3, cursor='hand2')
        drop_zone.pack(fill='x', padx=25, pady=(8, 0))
        drop_zone.bind('<Button-1>', lambda e: self._browse())

        # 嘗試啟用拖曳
        try:
            drop_zone.drop_target_register('DND_Files')
            drop_zone.dnd_bind('<<Drop>>', self._on_drop)
        except Exception:
            pass

        # ── 語言選擇 ──
        lang_frame = tk.Frame(self.root, bg='#f0f0f0', pady=10)
        lang_frame.pack()
        tk.Label(lang_frame, text="語言：", font=('Helvetica', 13),
                 bg='#f0f0f0').pack(side='left', padx=(0, 8))
        for text, val in LANG_OPTIONS:
            tk.Radiobutton(lang_frame, text=text, variable=self.lang, value=val,
                           font=('Helvetica', 13), bg='#f0f0f0',
                           activebackground='#f0f0f0').pack(side='left', padx=10)

        # ── 開始按鈕 + 進度條 ──
        self.run_btn = ttk.Button(self.root, text="▶  開始辨識",
                                  command=self._start_ocr, state='disabled',
                                  style='Green.TButton')
        self.run_btn.pack(pady=(4, 6), ipadx=20)

        self.progress = ttk.Progressbar(self.root, mode='indeterminate', length=440)
        self.progress.pack(pady=(0, 6))

        # ── 結果區 ──
        result_header = tk.Frame(self.root, bg='#f0f0f0')
        result_header.pack(fill='x', padx=25)
        tk.Label(result_header, text="辨識結果", font=('Helvetica', 12, 'bold'),
                 bg='#f0f0f0').pack(side='left')
        self.line_count = tk.Label(result_header, text="",
                                   font=('Helvetica', 11), fg='#666', bg='#f0f0f0')
        self.line_count.pack(side='right')

        self.output = scrolledtext.ScrolledText(
            self.root, font=('Helvetica', 12), wrap='word',
            height=12, relief='solid', bd=1, bg='white', fg='#222'
        )
        self.output.pack(fill='both', expand=True, padx=25, pady=(4, 6))

        # ── 底部按鈕 ──
        btn_frame = tk.Frame(self.root, bg='#f0f0f0')
        btn_frame.pack(pady=(0, 15))

        for text, cmd, style_name in [
            ("複製全部", self._copy_all, 'Gray.TButton'),
            ("儲存 TXT", self._save_txt, 'Blue.TButton'),
            ("清除",     self._clear,    'Red.TButton'),
        ]:
            ttk.Button(btn_frame, text=text, command=cmd,
                       style=style_name).pack(side='left', padx=8)

    def _on_drop(self, event):
        path = event.data.strip('{}').strip()
        self.file_path.set(path)

    def _browse(self):
        path = filedialog.askopenfilename(
            filetypes=[("圖片/PDF", "*.jpg *.jpeg *.png *.pdf"), ("所有檔案", "*.*")]
        )
        if path:
            self.file_path.set(path)

    def _log(self, msg):
        self.output.insert('end', msg + '\n')
        self.output.see('end')
        self.root.update_idletasks()

    def _start_ocr(self):
        path = self.file_path.get().strip()
        if not path or not os.path.exists(path):
            messagebox.showwarning("提示", "請先選擇有效的檔案")
            return
        lang = self.lang.get()
        # 若選日文/英文，先確認模型
        if lang != 'ch':
            self._ensure_lang_model(lang, lambda: self._do_ocr(path, lang))
        else:
            self._do_ocr(path, lang)

    def _ensure_lang_model(self, lang, callback):
        lang_name = {'japan': '日文', 'en': '英文'}.get(lang, lang)
        win = tk.Toplevel(self.root)
        win.title("下載語言模型")
        win.geometry("380x150")
        win.resizable(False, False)
        win.grab_set()
        tk.Label(win, text=f"正在下載{lang_name}模型...",
                 font=('Helvetica', 13, 'bold'), pady=20).pack()
        pb = ttk.Progressbar(win, mode='indeterminate', length=300)
        pb.pack(pady=8)
        pb.start(10)

        def _dl():
            try:
                from paddleocr import PaddleOCR
                PaddleOCR(lang=lang)
                pb.stop()
                win.destroy()
                callback()
            except Exception as e:
                pb.stop()
                win.destroy()
                messagebox.showerror("錯誤", f"模型下載失敗：{e}")

        threading.Thread(target=_dl, daemon=True).start()

    def _do_ocr(self, path, lang):
        self.run_btn.config(state='disabled')
        self.progress.start(10)
        self.output.delete('1.0', 'end')
        self.result_texts = []
        self.line_count.config(text="")
        threading.Thread(target=self._ocr_thread, args=(path, lang), daemon=True).start()

    def _ocr_thread(self, path, lang):
        try:
            self._log(f"檔案：{os.path.basename(path)}")
            texts = run_ocr(path, lang, self._log)
            self.result_texts = texts
            self._log("\n── 辨識結果 ──\n")
            for line in texts:
                self._log(line)
            count = len([t for t in texts if t.strip()])
            self._log(f"\n✅ 完成，共 {count} 行")
            self.line_count.config(text=f"共 {count} 行")
            # 自動儲存到原檔資料夾
            self._auto_save(path, texts)
        except Exception as e:
            self._log(f"\n❌ 錯誤：{e}")
        finally:
            self.progress.stop()
            self.run_btn.config(state='normal')

    def _auto_save(self, src_path, texts):
        out_path = str(Path(src_path).with_suffix('')) + '_ocr.txt'
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(texts))
        self._log(f"📄 已自動儲存：{out_path}")

    def _copy_all(self):
        text = '\n'.join(self.result_texts) if self.result_texts else self.output.get('1.0', 'end')
        self.root.clipboard_clear()
        self.root.clipboard_append(text)
        self._log("（已複製到剪貼簿）")

    def _save_txt(self):
        if not self.result_texts:
            messagebox.showwarning("提示", "沒有辨識結果可儲存")
            return
        src = self.file_path.get().strip()
        default = Path(src).stem + '_ocr.txt' if src else 'ocr_result.txt'
        save_path = filedialog.asksaveasfilename(
            defaultextension='.txt', initialfile=default,
            filetypes=[("文字檔", "*.txt")]
        )
        if save_path:
            with open(save_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(self.result_texts))
            self._log(f"✅ 已儲存：{save_path}")
            os.system(f'open "{save_path}"') if sys.platform == 'darwin' else os.startfile(save_path)

    def _clear(self):
        self.output.delete('1.0', 'end')
        self.file_path.set('')
        self.result_texts = []
        self.line_count.config(text="")

    def _show_about(self):
        messagebox.showinfo(
            f"關於 {APP_NAME}",
            f"{APP_NAME} v{APP_VERSION}\n\n"
            "支援 JPG、PNG、PDF\n"
            "語言：繁簡中文、日文、英文\n\n"
            "Powered by PaddleOCR\n"
            "Apache License 2.0\n"
            "github.com/PaddlePaddle/PaddleOCR"
        )

# ── 啟動 ─────────────────────────────────────────────────

if __name__ == '__main__':
    # 嘗試啟用拖曳支援
    try:
        from tkinterdnd2 import TkinterDnD
        root = TkinterDnD.Tk()
    except ImportError:
        root = tk.Tk()

    app = OCRApp(root)
    root.mainloop()
