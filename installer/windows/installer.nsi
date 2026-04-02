Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"

Name "OCR Tool"
OutFile "ocr-tool-windows.exe"
InstallDir "$LOCALAPPDATA\OCRTool"
RequestExecutionLevel user

!define MUI_FINISHPAGE_RUN "$INSTDIR\ocr_launcher.bat"
!define MUI_FINISHPAGE_RUN_TEXT "Launch OCR Tool"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "TradChinese"

Section
  SetOutPath "$INSTDIR"
  File "ocr.py"
  File "ocr_ui.py"
  File /oname=setup.bat "install_windows.bat"
  File "ocr_launcher.bat"

  ExecWait '"$COMSPEC" /c start "OCR Installer" /wait "$INSTDIR\setup.bat"' $0

  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Installation failed. Please check your internet connection and try again."
    Abort
  ${EndIf}

  Delete "$INSTDIR\setup.bat"
SectionEnd
