!include "MUI2.nsh"
!include "nsProcess.nsh"

!define MUI_ICON "../../resources/icons/ykman.ico"

;Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "Yubico\Yubikey Manager"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Yubico\Yubikey Manager"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!define MUI_ABORTWARNING

;Checkbox on finish page, "Run YubiKey Manager"
!define MUI_FINISHPAGE_RUN "$INSTDIR\ykman-gui.exe"

Var STARTMENU_FOLDER

!ifdef INNER
  !echo "Inner invocation"
  OutFile "$%TEMP%\tempinstaller.exe"
  SetCompress off
!else
  !echo "Outer invocation"
  
  ; Call makensis again, defining INNER.  This writes an installer for us which, when
  ; it is invoked, will just write the uninstaller to some location, and then exit.
  !system "$\"${NSISDIR}\makensis$\" /DINNER win-installer.nsi" = 0
 
  ; Run temp installer. Since it calls quit the return value isn't zero.
  !system "$%TEMP%\tempinstaller.exe" = 2
 
  ; Sign real uninstaller.
  !system "signtool.exe sign /fd SHA256 /t http://timestamp.verisign.com/scripts/timstamp.dll $%TEMP%\ykman-uninstall.exe" = 0
 
  ; The name of the installer
  Name "YubiKey Manager"
  
  ; The file to write
  OutFile "../../yubikey-manager-qt-${VERSION}-win.exe"
  
  ; The default installation directory
  InstallDir "$PROGRAMFILES\Yubico\YubiKey Manager"
  
  ; Registry key to check for directory (so if you install again, it will 
  ; overwrite the old one automatically)
  InstallDirRegKey HKLM "Software\Yubico\yubikey-manager" "Install_Dir"
  
  SetCompressor /SOLID lzma
  
  ShowInstDetails show
  
  ;Interface Settings

  ; Pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

  ;Languages
  !insertmacro MUI_LANGUAGE "English"

  Section "Start Menu"
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
      ;Create shortcuts
      SetShellVarContext all
      SetOutPath "$SMPROGRAMS\$STARTMENU_FOLDER"
      CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
      CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\YubiKey Manager.lnk" "$INSTDIR\ykman-gui.exe"
      CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall YubiKey Manager.lnk" "$INSTDIR\ykman-uninstall.exe"
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd
  
  Section "Kill process" KillProcess
  ${nsProcess::FindProcess} "ykman-gui.exe" $R0
  ${If} $R0 == 0
    DetailPrint "YubiKey Manager (CLI) is running. Closing..."
    ${nsProcess::CloseProcess} "ykman-gui.exe" $R0
    Sleep 2000
  ${EndIf}
  ${nsProcess::FindProcess} "ykman-gui.exe" $R0
  ${If} $R0 == 0
    DetailPrint "YubiKey Manager is running. Closing..."
    ${nsProcess::CloseProcess} "ykman-gui.exe" $R0
    Sleep 2000
  ${EndIf}
   ${nsProcess::Unload}
   SectionEnd
!endif
 
Function .onInit
  !ifdef INNER
    WriteUninstaller "$%TEMP%\ykman-uninstall.exe"
    Quit
  !endif
FunctionEnd
 
Var MYTMP
Section "YubiKey Manager"
  SectionIn RO
  SetOutPath $INSTDIR
  FILE /r "..\..\ykman-gui\release\*"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM "Software\Yubico\yubikey-manager" "Install_Dir" "$INSTDIR"
  
  ; Windows Add/Remove Programs support
  StrCpy $MYTMP "Software\Microsoft\Windows\CurrentVersion\Uninstall\yubikey-manager"
  WriteRegStr       HKLM $MYTMP "DisplayName"     "YubiKey Manager"
  WriteRegExpandStr HKLM $MYTMP "UninstallString" '"$INSTDIR\ykman-uninstall.exe"'
  WriteRegExpandStr HKLM $MYTMP "InstallLocation" "$INSTDIR"
  WriteRegStr       HKLM $MYTMP "DisplayVersion"  "${VERSION}"
  WriteRegStr       HKLM $MYTMP "Publisher"       "Yubico AB"
  WriteRegStr       HKLM $MYTMP "URLInfoAbout"    "https://www.yubico.com"
  WriteRegDWORD     HKLM $MYTMP "NoModify"        "1"
  WriteRegDWORD     HKLM $MYTMP "NoRepair"        "1"
SectionEnd
 
Section  
  !ifndef INNER
    SetOutPath $INSTDIR
    File $%TEMP%\ykman-uninstall.exe
  !endif
SectionEnd

!ifdef INNER  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
!endif

!ifdef INNER
  Var MUI_TEMP
  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER
  Name "YubiKey Manager"
  
  Section "Uninstall"
    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\yubikey-manager"
    DeleteRegKey HKLM "Software\Yubico\yubikey-manager"

    ; Kill processes
    ${nsProcess::FindProcess} "ykman.exe" $R0
    ${If} $R0 == 0
      DetailPrint "YubiKey Manager (CLI) is running. Closing..."
      ${nsProcess::CloseProcess} "ykman.exe" $R0
      Sleep 2000
    ${EndIf}
    ${nsProcess::FindProcess} "ykman-gui.exe" $R0
    ${If} $R0 == 0
      DetailPrint "YubiKey Manager (GUI) is running. Closing..."
      ${nsProcess::CloseProcess} "ykman-gui.exe" $R0
      Sleep 2000
    ${EndIf}
    ${nsProcess::Unload}

    ; Remove the installation directory recursively
    ; NOTE! This behaviour assumes installation directory is hardcoded.
    RMDir /r "$INSTDIR"

    ; Remove shortcuts, if any
    !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP
    SetShellVarContext all
    Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall YubiKey Manager.lnk"
    Delete "$SMPROGRAMS\$MUI_TEMP\YubiKey Manager.lnk"

    ;Delete empty start menu parent diretories
    StrCpy $MUI_TEMP "$SMPROGRAMS\$MUI_TEMP"

    startMenuDeleteLoop:
      ClearErrors
      RMDir $MUI_TEMP
      GetFullPathName $MUI_TEMP "$MUI_TEMP\.."
      IfErrors startMenuDeleteLoopDone
      StrCmp $MUI_TEMP $SMPROGRAMS startMenuDeleteLoopDone startMenuDeleteLoop
    startMenuDeleteLoopDone:

    DeleteRegKey /ifempty HKCU "Software\Yubico\yubikey-manager"
  SectionEnd
!endif
