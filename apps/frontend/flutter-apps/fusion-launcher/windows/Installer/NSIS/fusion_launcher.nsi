; Fusion Launcher Installer Script

SetCompressor /SOLID lzma

!include "FileFunc.nsh"
!include "MUI2.nsh"
!include "x64.nsh"

!define FILE_VERSION "1.0.0.0"
!define PRODUCT_NAME "Fusion Algorithms"
!define PRODUCT_PUBLISHER "Bose Professional"
!define PRODUCT_ID "{39c63eca-6dd3-4db7-86b4-f607e8eaf6b3}"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_WEB_SITE "http://www.boseprofessional.com"

Var ProductVersionShort
Var ProductUninstallKey

!macro SetProductVersionShort
	StrCpy $ProductVersionShort "${PRODUCT_VERSION}"
!macroend

!macro SetProductUninstallKey
	StrCpy $ProductUninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME} $ProductVersionShort"
!macroend

Function .onInit
	!insertmacro SetProductVersionShort
	!insertmacro SetProductUninstallKey
	StrCpy $INSTDIR "$LOCALAPPDATA\${PRODUCT_PUBLISHER}\${PRODUCT_NAME}"
FunctionEnd

Function un.onInit
	!insertmacro SetProductVersionShort
	!insertmacro SetProductUninstallKey
FunctionEnd

Name "${PRODUCT_NAME} $ProductVersionShort"
OutFile "FusionLauncherInstaller.exe"
RequestExecutionLevel user

;--------------------------------
; Interface Settings

!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "Banner.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "Banner.bmp"
!define MUI_HEADERIMAGE_BITMAP "Icon.ico"
!define MUI_HEADERIMAGE_UNBITMAP "Icon.ico"
!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch Fusion Launcher"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchApp"

!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create desktop shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION "CreateShortcut"

!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Section

Section "Install"

	; Kill if app is running
	nsExec::ExecToLog 'taskkill /F /IM fusion_design_tool_prototype.exe'

	; Clear old AppData (user data)
	RMDir /r "$APPDATA\Fusion Launcher"

	; Set install directory
	SetOutPath "$INSTDIR"

	; Copy files from Flutter build
	!define BUILD_DIR "${__FILE__}"
	!searchparse /noerrors "${BUILD_DIR}" "\" fusion_launcher.nsi" "" $0
	DetailPrint "DEBUG: \$0 is $0"
	File /r "C:\Users\Administrator\Documents\fusion-monorepo-build\apps\frontend\flutter-apps\fusion-launcher\build\windows\x64\runner\Release\*"

	; Start menu shortcut always created
	SetShellVarContext all
	CreateDirectory "$SMPROGRAMS\Fusion Launcher"
	CreateShortCut "$SMPROGRAMS\Fusion Launcher\Fusion Launcher.lnk" "$INSTDIR\fusion_design_tool_prototype.exe"

	; Uninstaller
	WriteUninstaller "$INSTDIR\uninstall.exe"

	; Add to registry
	Var /GLOBAL estimatedSize
	${GetSize} "$INSTDIR" "/S=0K" $estimatedSize $0 $1
	IntFmt $estimatedSize "0x%08X" $estimatedSize

	WriteRegStr HKCU "$ProductUninstallKey" "DisplayName" "${PRODUCT_NAME}"
	WriteRegStr HKCU "$ProductUninstallKey" "UninstallString" "$INSTDIR\uninstall.exe"
	WriteRegStr HKCU "$ProductUninstallKey" "InstallLocation" "$INSTDIR"
	WriteRegStr HKCU "$ProductUninstallKey" "Publisher" "${PRODUCT_PUBLISHER}"
	WriteRegStr HKCU "$ProductUninstallKey" "DisplayVersion" "${PRODUCT_VERSION}"
	WriteRegStr HKCU "$ProductUninstallKey" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
	WriteRegDWORD HKCU "$ProductUninstallKey" "EstimatedSize" $estimatedSize
	WriteRegStr HKCU "$ProductUninstallKey" "DisplayIcon" "$INSTDIR\fusion_design_tool_prototype.exe"

SectionEnd

;--------------------------------
; Launch App After Install

Function LaunchApp
	ExecShell "" "$INSTDIR\fusion_design_tool_prototype.exe"
FunctionEnd

;--------------------------------
; Create Desktop Shortcut

Function CreateShortcut
	SetShellVarContext all
	CreateShortCut "$DESKTOP\Fusion Launcher.lnk" "$INSTDIR\fusion_design_tool_prototype.exe"
FunctionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"

	; Kill app if running
	nsExec::ExecToLog 'taskkill /F /IM fusion_design_tool_prototype.exe'

	; Remove installed files
	RMDir /r "$INSTDIR"

	; Remove shortcuts
	SetShellVarContext all
	Delete "$DESKTOP\Fusion Launcher.lnk"
	Delete "$SMPROGRAMS\Fusion Launcher\Fusion Launcher.lnk"
	RMDir "$SMPROGRAMS\Fusion Launcher"

	; Remove AppData
	RMDir /r "$APPDATA\Fusion Launcher"

	; Remove uninstaller
	Delete "$INSTDIR\uninstall.exe"

	; Remove from registry
	DeleteRegKey HKCU "$ProductUninstallKey"

SectionEnd