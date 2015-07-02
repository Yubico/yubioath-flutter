!include "MUI2.nsh"
!include "nsProcess.nsh"

!define MUI_ICON "yubioath-desktop.ico"

; The name of the installer
Name "Yubico Authenticator"

; The file to write
OutFile "../dist/yubioath-desktop-${VERSION}-win.exe"

; The default installation directory
InstallDir "$PROGRAMFILES\Yubico\Yubico Authenticator"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Yubico\yubioath-desktop" "Install_Dir"

SetCompressor /SOLID lzma
ShowInstDetails show

Var MUI_TEMP
Var STARTMENU_FOLDER

;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------

; Pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_DIRECTORY
  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_DEFAULTFOLDER "Yubico\Yubico Authenticator"
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU"
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Yubico\Yubico Authenticator"
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;Languages
  !insertmacro MUI_LANGUAGE "English"


Section "Kill process" KillProcess
	${nsProcess::FindProcess} "yubioath.exe" $R0
  ${If} $R0 == 0
	  MessageBox MB_OK "Yubico Authenticator is currently running, an will now be closed."
    ${nsProcess::CloseProcess} "yubioath.exe" $R0
    Sleep 2000
  ${EndIf}
	${nsProcess::Unload}
SectionEnd


;--------------------------------

Section "Yubico Authenticator"
  SectionIn RO
  SetOutPath $INSTDIR
  FILE "..\dist\Yubico Authenticator\*"
SectionEnd

Var MYTMP

# Last section is a hidden one.
Section
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Write the installation path into the registry
  WriteRegStr HKLM "Software\Yubico\yubioath-desktop" "Install_Dir" "$INSTDIR"

  # Windows Add/Remove Programs support
  StrCpy $MYTMP "Software\Microsoft\Windows\CurrentVersion\Uninstall\yubioath-desktop"
  WriteRegStr       HKLM $MYTMP "DisplayName"     "Yubico Authenticator"
  WriteRegExpandStr HKLM $MYTMP "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegExpandStr HKLM $MYTMP "InstallLocation" "$INSTDIR"
  WriteRegStr       HKLM $MYTMP "DisplayVersion"  "${VERSION}"
  WriteRegStr       HKLM $MYTMP "Publisher"       "Yubico AB"
  WriteRegStr       HKLM $MYTMP "URLInfoAbout"    "http://www.yubico.com"
  WriteRegDWORD     HKLM $MYTMP "NoModify"        "1"
  WriteRegDWORD     HKLM $MYTMP "NoRepair"        "1"

!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
;Create shortcuts
  SetShellVarContext all
  SetOutPath "$SMPROGRAMS\$STARTMENU_FOLDER"
  CreateShortCut "Yubico Authenticator.lnk" "$INSTDIR\yubioath.exe" "" "$INSTDIR\yubioath.exe" 0
  CreateShortCut "Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 1
!insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\yubioath-desktop"
  DeleteRegKey HKLM "Software\Yubico\yubioath-desktop"

  ; Kill process
  ${nsProcess::FindProcess} "yubioath.exe" $R0
  ${If} $R0 == 0
    DetailPrint "Yubico Authenticator is running. Closing..."
    ${nsProcess::CloseProcess} "yubioath.exe" $R0
    Sleep 2000
  ${EndIf}
  ${nsProcess::Unload}

  ; Remove all
  DELETE "$INSTDIR\*"

  ; Remove shortcuts, if any
  !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP
  SetShellVarContext all

  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Yubico Authenticator.lnk"

  ;Delete empty start menu parent diretories
  StrCpy $MUI_TEMP "$SMPROGRAMS\$MUI_TEMP"

  startMenuDeleteLoop:
	ClearErrors
    RMDir $MUI_TEMP
    GetFullPathName $MUI_TEMP "$MUI_TEMP\.."

    IfErrors startMenuDeleteLoopDone

    StrCmp $MUI_TEMP $SMPROGRAMS startMenuDeleteLoopDone startMenuDeleteLoop
  startMenuDeleteLoopDone:

  DeleteRegKey /ifempty HKCU "Software\Yubico\yubioath-desktop"

  ; Remove directories used
  RMDir "$INSTDIR"
SectionEnd
