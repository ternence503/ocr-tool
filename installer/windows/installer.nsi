Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"

; ── 基本設定 ────────────────────────────────────────────────
Name "OCR 辨識工具"
OutFile "ocr-tool-windows.exe"
InstallDir "$LOCALAPPDATA\OCRTool"
RequestExecutionLevel user

; ── 歡迎頁文字 ──────────────────────────────────────────────
!define MUI_WELCOMEPAGE_TITLE "OCR 辨識工具 安裝精靈"
!define MUI_WELCOMEPAGE_TEXT "本工具可將圖片或 PDF 中的文字辨識成可複製的文字，支援繁簡中文、日文、英文。$\r$\n$\r$\n安裝完成後會在桌面建立捷徑，從桌面點兩下即可啟動。$\r$\n$\r$\n⚠ 需要 Python 3.8–3.12（不支援 3.13 以上）$\r$\n若尚未安裝，請先至 python.org 下載 Python 3.12。$\r$\n$\r$\n⏱ 安裝過程需下載套件與辨識模型，約需 5–15 分鐘，請保持網路連線。"

; ── 完成頁文字 ──────────────────────────────────────────────
!define MUI_FINISHPAGE_TITLE "安裝完成"
!define MUI_FINISHPAGE_TEXT "OCR 辨識工具已安裝完成！$\r$\n$\r$\n桌面已建立「OCR辨識工具」捷徑，點兩下即可啟動。"
!define MUI_FINISHPAGE_RUN "$INSTDIR\OCR辨識工具（Windows）.bat"
!define MUI_FINISHPAGE_RUN_TEXT "立即啟動 OCR 辨識工具"

!define MUI_ABORTWARNING
!define MUI_ABORTWARNING_TEXT "確定要取消安裝嗎？"

; ── 頁面順序 ────────────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "TradChinese"

; ── 安裝內容 ────────────────────────────────────────────────
Section
  SetOutPath "$INSTDIR"
  File "ocr.py"
  File "ocr_ui.py"
  File /oname=setup.bat "安裝（Windows）.bat"
  File "OCR辨識工具（Windows）.bat"

  DetailPrint "正在開啟安裝進度視窗..."
  DetailPrint "請在另一個視窗中查看安裝進度，完成後再回到此畫面。"

  ; 用 cmd start /wait 開啟可見視窗並等待完成
  ExecWait '"$COMSPEC" /c start "OCR 辨識工具 - 安裝進度" /wait "$INSTDIR\setup.bat"' $0

  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "安裝失敗，請確認網路連線後重試。$\r$\n若持續失敗，請截圖錯誤畫面並回報問題。"
    Abort
  ${EndIf}

  ; 清理暫存安裝腳本
  Delete "$INSTDIR\setup.bat"
SectionEnd
