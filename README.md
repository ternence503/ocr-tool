# OCR 辨識工具

將圖片或 PDF 中的文字辨識成可複製的文字，支援繁簡中文、日文、英文。

Powered by [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) (Apache 2.0)

---

## 系統需求

| 項目 | Mac | Windows |
|------|-----|---------|
| 系統版本 | macOS 11 以上 | Windows 10 以上 |
| Python | 需安裝 Python 3.8–3.12 | 需安裝 Python 3.8–3.12 |
| 磁碟空間 | 約 1.5 GB（含模型）| 約 1.5 GB（含模型）|
| 網路 | 首次安裝需要 | 首次安裝需要 |

> ⚠️ **Python 3.13 以上不相容**，請安裝 [Python 3.12](https://www.python.org/downloads/release/python-3129/)。

---

## 安裝步驟

### Mac

1. 下載並解壓縮檔案
2. 打開「終端機」，執行以下指令開放執行權限（只需做一次）：
   ```bash
   chmod +x ~/Downloads/ocr-tool-main/*.command
   ```
   > 路徑請依實際解壓位置調整
3. 雙擊 `安裝（Mac）.command`
4. 等待安裝完成（約 5–10 分鐘，視網速而定）
5. 之後雙擊 `OCR辨識工具（Mac）.command` 啟動

> 若出現「無法開啟，因為來自未識別的開發者」：
> 右鍵點選檔案 → 點「開啟」→ 再點「開啟」確認

### Windows

1. 下載並解壓縮檔案
2. 確認已安裝 [Python 3.8+](https://www.python.org/downloads/)  
   ⚠️ 安裝 Python 時請勾選「**Add Python to PATH**」
3. 雙擊 `安裝（Windows）.bat`
4. 等待安裝完成（約 5–10 分鐘）
5. 之後雙擊 `OCR辨識工具（Windows）.bat` 啟動

---

## 使用方式

1. 啟動工具
2. 點「選擇檔案」或直接將圖片拖曳到視窗
3. 選擇語言（繁簡中文／日文／英文）
4. 點「▶ 開始辨識」
5. 結果自動顯示並儲存為 `原檔名_ocr.txt`

---

## 支援格式

| 格式 | 說明 |
|------|------|
| JPG / JPEG | 一般照片 |
| PNG | 截圖、掃描圖 |
| PDF | 多頁自動逐頁辨識 |

---

## 常見問題

**Q：第一次啟動很慢？**  
A：首次使用日文或英文時會自動下載對應模型（約 200MB），之後即可離線使用。

**Q：圖片太大辨識很慢？**  
A：超過 2000px 的圖片會自動縮小再辨識，不影響準確率。

**Q：辨識結果存在哪裡？**  
A：自動儲存在原圖片同一個資料夾，檔名為 `原檔名_ocr.txt`，也可手動點「儲存 TXT」另存。

**Q：Mac 說「無法驗證開發者」怎麼辦？**  
A：系統偏好設定 → 安全性與隱私 → 點「仍要開啟」。

---

## 版權聲明

本工具使用 [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR)，授權條款為 Apache License 2.0。
