# Copyright (c) 2013-2014 Yubico AB
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

!include "MUI2.nsh"

!define MUI_ICON "../yubico.ico"

; The name of the installer
Name "yubico-authenticator-"

; The file to write
OutFile "../dist/Yubico Authenticator/yubico-authenticator-${YUBICOAUTHENTICATOR_VERSION}.exe"

; The default installation directory
InstallDir "$PROGRAMFILES\Yubico\Yubico Authenticator"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Yubico\yubico-authenticator" "Install_Dir"

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

;--------------------------------

Section "Yubico Authenticator"
  SectionIn RO
  SetOutPath $INSTDIR
  FILE /r "..\dist\Yubico Authenticator\*"
SectionEnd

Var MYTMP

# Last section is a hidden one.
Section
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Write the installation path into the registry
  WriteRegStr HKLM "Software\Yubico\yubco-authenticator" "Install_Dir" "$INSTDIR"

  # Windows Add/Remove Programs support
  StrCpy $MYTMP "Software\Microsoft\Windows\CurrentVersion\Uninstall\yubico-authenticator"
  WriteRegStr       HKLM $MYTMP "DisplayName"     "Yubico Authenticator"
  WriteRegExpandStr HKLM $MYTMP "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegExpandStr HKLM $MYTMP "InstallLocation" "$INSTDIR"
  WriteRegStr       HKLM $MYTMP "DisplayVersion"  "${YUBICOAUTHENTICATOR_VERSION}"
  WriteRegStr       HKLM $MYTMP "Publisher"       "Yubico AB"
  WriteRegStr       HKLM $MYTMP "URLInfoAbout"    "http://www.yubico.com"
  WriteRegDWORD     HKLM $MYTMP "NoModify"        "1"
  WriteRegDWORD     HKLM $MYTMP "NoRepair"        "1"

!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
;Create shortcuts
  SetShellVarContext all
  SetOutPath "$SMPROGRAMS\$STARTMENU_FOLDER"
  CreateShortCut "Yubico Authenticator.lnk" "$INSTDIR\Yubico Authenticator.exe" "" "$INSTDIR\Yubico Authenticator.exe" 0
  CreateShortCut "Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 1
  WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Yubico Web page.url" \
                   "InternetShortcut" "URL" "http://www.yubico.com/"
!insertmacro MUI_STARTMENU_WRITE_END

SectionEnd



; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\yubico-authenticator"
  DeleteRegKey HKLM "Software\Yubico\yubico-authenticator"

  ; Remove all
  DELETE "$INSTDIR\*"

  ; Remove shortcuts, if any
  !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP
  SetShellVarContext all

  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Yubico Web page.url"
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

  DeleteRegKey /ifempty HKCU "Software\Yubico\yubico-authenticator"

  ; Remove directories used
  RMDir "$INSTDIR"
SectionEnd