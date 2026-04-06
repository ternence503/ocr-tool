# OCR 辨識工具

將圖片或 PDF 中的文字辨識成可複製的文字，支援繁簡中文、日文、英文。

Powered by [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) (Apache 2.0)

---

## 下載

<table>
<tr>
<td align="center">
<a href="https://github.com/ternence503/ocr-tool/releases/latest/download/ocr-tool-mac.pkg">
<img src="https://img.shields.io/badge/安裝程式-Mac_.pkg-black?style=for-the-badge&logo=apple" alt="下載 Mac 安裝程式"/>
</a>
<br/><sub>macOS 11 以上｜雙擊即可安裝</sub>
</td>
<td align="center">
<a href="https://github.com/ternence503/ocr-tool/releases/latest/download/ocr-tool-windows.exe">
<img src="https://img.shields.io/badge/安裝程式-Windows_.exe-0078D4?style=for-the-badge&logo=windows" alt="下載 Windows 安裝程式"/>
</a>
<br/><sub>Windows 10 以上｜雙擊即可安裝</sub>
</td>
</tr>
</table>

---

## 系統需求

| 項目 | Mac | Windows |
|------|-----|---------|
| 系統版本 | macOS 11 以上 | Windows 10 以上 |
| Python | 需安裝 Python 3.8–3.12 | 安裝程式自動處理，無需手動安裝 |
| 磁碟空間 | 約 1.5 GB（含模型）| 約 1.5 GB（含模型）|
| 網路 | 安裝時需要 | 安裝時需要 |

---

## 安裝步驟

### Windows

1. 下載 `ocr-tool-windows.exe`
2. 雙擊執行安裝精靈
3. 安裝程式會自動完成所有設定（**約 5–15 分鐘**，請保持網路連線）
4. 安裝完成後桌面會建立「OCR辨識工具」捷徑，點兩下即可啟動

> **出現「Windows 已保護您的電腦」提示：**
> 點「更多資訊」→「仍要執行」

---

### Mac

1. 下載 `ocr-tool-mac.pkg`
2. 雙擊執行

3. **若出現「無法打開，因為無法驗證開發者」**：
   - 在 .pkg 上按右鍵（或 Control + 點一下）→ 選「開啟」→ 再點「開啟」

4. 跟隨安裝精靈，安裝過程會自動下載套件與繁中／日文／英文辨識模型（**約 5–15 分鐘**，請保持網路連線）

5. **若安裝後出現「應用程式已損毀」或無法開啟：**
   - 前往「系統設定」→「隱私權與安全性」
   - 下方找到「已封鎖 OCR辨識工具，因為來自不明的開發者」
   - 點「仍要開啟」→ 輸入密碼確認

6. 安裝完成後，**OCR 辨識工具** 會出現在「應用程式」資料夾，可從 Launchpad 或 Spotlight 搜尋啟動

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

**Q：Mac 說「無法驗證開發者」怎麼辦？**
A：在 .pkg 上按右鍵 → 選「開啟」→ 再點「開啟」確認即可。

**Q：Mac 安裝後打不開，說「應用程式已損毀」？**
A：前往「系統設定」→「隱私權與安全性」→ 找到被封鎖的項目 → 點「仍要開啟」。這是 macOS 對未經 Apple 認證程式的標準提示，並非真的損毀。

**Q：出現「Windows 已保護您的電腦」怎麼辦？**
A：點「更多資訊」→「仍要執行」即可。

**Q：第一次啟動很慢？**
A：安裝時會先下載繁中、日文、英文模型。安裝完成後即可離線使用，首次啟動只會花時間載入模型。

**Q：圖片太大辨識很慢？**
A：超過 2000px 的圖片會自動縮小再辨識，不影響準確率。

**Q：辨識結果存在哪裡？**
A：自動儲存在原圖片同一個資料夾，檔名為 `原檔名_ocr.txt`，也可手動點「儲存 TXT」另存。

---

## 版權聲明

本工具使用 [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR)，授權條款為 Apache License 2.0。
