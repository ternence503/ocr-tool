# OCR 辨識工具 專案交接紀錄

本機 PaddleOCR 辨識工具：`ocr.py`（CLI，支援圖片與 PDF）與 `ocr_ui.py`（Tk 桌面介面，支援拖曳）。語言 ch／japan／en。辨識在本機執行，圖片與結果不會送出；只有首次執行會下載模型到 `~/.paddlex`。

## 現況（2026-10-05）
最後 commit `f19b0e9`，已 push、工作樹乾淨。這天用 ai-studio runner 的唯讀審查找出 5 類問題，已修前 5 項核心問題（commit 2255ee7、f19b0e9）：
- **暫存檔**：PDF 頁面圖改放 `TemporaryDirectory`（檔名不可預測、同時開兩個實例不互相覆蓋）；縮圖暫存檔用 `try/finally` 保證出錯也清掉；`ocr.py` 不再把 `_resized.jpg` 寫在原圖旁邊。
- **開檔**：兩處 `os.system(f'open "{路徑}"')` 改成 `open_file()`（`subprocess` argv、不經 shell；macOS／Windows／Linux）。
- **圖片**：縮圖前轉 RGB（透明 PNG 不再崩）、依 EXIF 方向校正（手機直拍）、`with Image.open`。
- **PDF**：渲染 dpi 依頁面大小 `max(36,min(150,2000*72/長邊pt))`；加密與損毀的 PDF 給明確中文錯誤；`ocr.py` 新增 `get_ocr()` 模型快取（多頁不再每頁重載）。
- **UI**：拖曳路徑改用 Tk `splitlist`（多檔取第一個並提示）；輸出檔名遇同名不同副檔名（a.jpg／a.png）改為 `a_jpg_ocr.txt`；桌面備援寫入失敗不崩潰。

## 驗證狀態
- **已實測**：40 項單元測試全過（用假的 paddleocr／fitz／tkinter 模組驗清理邏輯、EXIF、dpi、加密／損毀 PDF、輸出檔名、開檔指令不經 shell、拖曳解析邏輯）。
- **未驗證**：**沒用真的 PaddleOCR、PyMuPDF、tkinter 跑過**（這台沒裝）；Tk 實際的 `splitlist` 對 `{含空白路徑}` 的拆解只驗了我們這邊的邏輯，沒真的拖檔進視窗。請在裝好環境的電腦上辨識一份多頁 PDF，並拖一個檔名含空白的檔進視窗。

## 待辦
- **背景執行緒直接操作 Tk**（`_log`、`config` 在 worker thread 呼叫）：Tk 不是 thread-safe，macOS 可能偶發當機；建議改 `root.after(0, …)` 或 queue。未動，風險較高。
- 模型是否已完整下載（`model_exists()` 只檢查資料夾是否非空）：下載到一半時可能悄悄連網補下載。
