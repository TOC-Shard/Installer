; Installer for TOC Shard.
; Makes use of the Modern UI for NSIS.

;;;;;;;;;;;;
; Includes ;
;;;;;;;;;;;;
!include MUI2.nsh
!include WinVer.nsh

;;;;;;;;;;;;;;;;;;;;;;
; Installer Settings ;
;;;;;;;;;;;;;;;;;;;;;;
BrandingText            "TOC-MOUL"
CRCCheck                on
InstallDir              "$PROGRAMFILES\TOC-Moul"
OutFile                 "TOC-Moul.exe"
RequestExecutionLevel   admin

;;;;;;;;;;;;;;;;;;;;
; Meta Information ;
;;;;;;;;;;;;;;;;;;;;
Name                "TOC-MOUL"
VIAddVersionKey     "CompanyName"       "The Open Cave"
VIAddVersionKey     "FileDescription"   "The Open Cave"
VIAddVersionKey     "FileVersion"       "2.18"
VIAddVersionKey     "LegalCopyright"    "The Open Cave"
VIAddVersionKey     "ProductName"       "The Open Cave"
VIProductVersion    "2.18.0.0"

;;;;;;;;;;;;;;;;;;;;;
; MUI Configuration ;
;;;;;;;;;;;;;;;;;;;;;
!define MUI_ABORTWARNING
!define MUI_ICON                        "Resources\Icon.ico"
!define MUI_FINISHPAGE_RUN              "$INSTDIR\UruLauncher.exe"

; Custom Images :D
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP          "Resources\Header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP    "Resources\WelcomeFinish.bmp"

;;;;;;;;;;;;;
; Variables ;
;;;;;;;;;;;;;
Var InstallToUru
Var InstDirUru
Var LaunchRepair

;;;;;;;;;;;;;
; Functions ;
;;;;;;;;;;;;;

; Tries to find the Uru Live directory in the registry.
Function FindUruDir
    StrCmp      $InstallToUru "true" skip_this_step
    ReadRegStr  $InstDirUru HKLM "Software\MOUL" "Install_Dir"
    Goto done
    skip_this_step:
        Abort
    done:
FunctionEnd

; Checks if the installation directory is an existing Uru Live directory.
; The check for the PhysX DLL is required to ensure it is a valid Uru Live
; installation, and not just an Uru installation.
Function CheckIfDirIsUru
    FindFirst   $0 $1 "$INSTDIR\UruExplorer.exe"
    StrCmp      $1 "" done
    FindClose   $0
    FindFirst   $0 $1 "$INSTDIR\NxExtensions.dll"
    StrCmp      $1 "" done
    FindClose   $0
    MessageBox  MB_YESNO|MB_ICONEXCLAMATION \
        "$(CheckMessage)" \
        IDYES set_have_urudir
    Abort
    set_have_urudir:
        StrCpy  $InstallToUru "true"
    done:
FunctionEnd

;;;;;;;;;
; Pages ;
;;;;;;;;;
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE                   "Resources\GPLv3.txt"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE           CheckIfDirIsUru
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;;;;;;;;;;;;;;;;;;;;;;
; Interface Settings ;
;;;;;;;;;;;;;;;;;;;;;;
;Show all languages, despite user's codepage
!define MUI_LANGDLL_ALLLANGUAGES

;;;;;;;;;;;;;
; Languages ;
;;;;;;;;;;;;;
!insertmacro MUI_LANGUAGE "English" ;first language is the default language
!insertmacro MUI_LANGUAGE "German"

LangString CheckMessage ${LANG_ENGLISH} "Your install folder appears to be a previous Uru Live installation. \
										This will work, but you will be unable to use this installation to \
										access Cyan's MOULagain shard anymore. Are you sure you want to \
										continue?"
LangString CheckMessage ${LANG_GERMAN} "Das Installationsverzeichnis scheint eine frühere \
										Uru Live Installation zu sein. Das funktioniert, \
										aber Sie werden nicht mehr in der Lage sein Cyan's \
										MOULagain Shard zu erreichen. Sind Sie sicher, \
										dass Sie fortfahren wollen?"
LangString OSCheckMessage ${LANG_ENGLISH} "Windows Vista or above is required to run TOC Shard.$\r$\n\
                                           You may install the client but will be unable to run it on this OS.$\r$\n$\r$\n\
                                           Do you still wish to install?"
LangString OSCheckMessage ${LANG_GERMAN} "Windows Vista oder höher wird benötigt um TOC Shard zu starten.$\r$\n\
                                          Sie können den Client installieren, aber werden ihn auf diesem Betriebssystem nicht starten können.$\r$\n$\r$\n\
                                          Wollen Sie die Installation trotzdem fortsetzen?"

;;;;;;;;;;;;;;;;;;;;;;;
; Installer Functions ;
;;;;;;;;;;;;;;;;;;;;;;;
Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY
  ${IfNot} ${AtLeastWinVista}
    MessageBox MB_YESNO|MB_ICONEXCLAMATION \
     "$(OSCheckMessage)" \
      /SD IDYES IDNO do_quit
  ${EndIf}
  Goto done
  do_quit:
    Quit
  done:
FunctionEnd

;;;;;;;;;;;;
; Sections ;
;;;;;;;;;;;;
Section "Files"
    SetOutPath  $INSTDIR
    File        "Files\UruLauncher.exe"
    File        "Files\repair.ini"
    File        "Files\server.ini"
    File        "Files\vcredist_x86.exe"
    ExecWait    "$INSTDIR\vcredist_x86.exe /q /norestart"

    WriteRegStr HKCU "Software\The Open Cave - MOUL" "" $INSTDIR
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    CreateDirectory "$SMPROGRAMS\The Open Cave - MOUL"
    CreateShortCut  "$SMPROGRAMS\The Open Cave - MOUL\The Open Cave.lnk" "$INSTDIR\UruLauncher.exe"
    CreateShortCut  "$SMPROGRAMS\The Open Cave - MOUL\Repair.lnk" "$INSTDIR\UruLauncher.exe" \
                    "/ServerIni=repair.ini /Repair"
    CreateShortCut  "$SMPROGRAMS\The Open Cave - MOUL\TOC User Profile.lnk" "$LOCALAPPDATA\The Open Cave"
    CreateShortCut  "$SMPROGRAMS\The Open Cave - MOUL\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "FigureOutDataSource"
    StrCmp          $InstallToUru "true" done
    Call            FindUruDir

    ; Check to see if we have a MOULa install. If we do, we'll want to
    ; copy the files. If not, automatically launch a patch-only repair.
    ; This will download just the files from Cyan's MOULa, then quit.
    FindFirst       $0 $1 "$InstDirUru\UruLauncher.exe"
    StrCmp          $1 "" bad_uru_dir
    FindClose       $0
    Goto            done

    bad_uru_dir:
    StrCpy          $LaunchRepair "true"

    done:
SectionEnd

Section "dat"
    StrCmp          $InstallToUru "true" skip_this_step
    StrCmp          $LaunchRepair "true" skip_this_step
    CreateDirectory "$INSTDIR\dat"
    CopyFiles       /Silent /FilesOnly "$InstDirUru\dat\*" "$INSTDIR\dat"
    skip_this_step:
SectionEnd

Section "sfx"
    StrCmp          $InstallToUru "true" skip_this_step
    StrCmp          $LaunchRepair "true" skip_this_step
    CreateDirectory "$INSTDIR\sfx"
    CopyFiles       /Silent /FilesOnly "$InstDirUru\sfx\*.ogg" "$INSTDIR\sfx"
    skip_this_step:
SectionEnd

; Give everyone permissions to write to the shard folder.
; This is needed because the patcher likes to touch itself.
Section "SetPermissions"
    ExecWait 'cacls "$INSTDIR" /t /e /g "Authenticated Users":c'
SectionEnd

; This fires up the patcher if there is no MOULa install.
Section "Repair"
    StrCmp           $LaunchRepair "true" repair
    Goto             done

    repair:
    ExecWait         "$INSTDIR\UruLauncher.exe /ServerIni=repair.ini /Repair /PatchOnly"

    done:
SectionEnd

Section "Uninstall"
    RMDir /r "$SMPROGRAMS\The Open Cave - MOUL"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir /r "$INSTDIR"
    DeleteRegKey /ifempty HKCU "Software\The Open Cave - MOUL"
SectionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;
; Uninstaller Functions ;
;;;;;;;;;;;;;;;;;;;;;;;;;
Function un.onInit
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd
