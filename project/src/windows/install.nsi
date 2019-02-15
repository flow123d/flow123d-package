# Flow123d nsi build script for Windows


#----------------------------------------------------------
# GENERAL
#----------------------------------------------------------
  # Name and file
  # Read version information from file.
  !searchparse /file "version" '' VERSION ''

  # Name and file
  Name "Flow123d ${VERSION}"
  Caption "Flow123d ${VERSION} Setup"
  OutFile "flow123d_${VERSION}_win_install.exe"


  # Admin access
  # RequestExecutionLevel admin

  # Change the default Modern UI icons
  # !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-blue.ico"
  # !define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\classic-uninstall.ico"

  # Default installation folder
  InstallDir "$LOCALAPPDATA\Flow123d\v${VERSION}"
  !define UninstName "Uninstall"

  # Maximum compression
  # https://nsis.sourceforge.io/Reference/SetCompressor
  # In our case the final exe:
  #   zlib (default): 58 MB in 20 sec
  #   bzip2:          43 MB in 1 min
  #   lzma:           28 MB in 5 min
  SetCompressor /SOLID zlib

Var DOCKER_EXE
!define DOCKER_PATH "C:\Program Files\Docker\Docker"
!define DOCKER_HK   "Software\Docker Inc.\Docker\1.0"


#----------------------------------------------------------
# Interface Settings
#----------------------------------------------------------
  # installation only for current user

  # Include the tools we use.
  !include MUI2.nsh
  !include LogicLib.nsh
  !include WinMessages.nsh
  !include x64.nsh
  !include FileFunc.nsh
  !include nsis\EnvVarUpdate.nsh
  !insertmacro GetDrives
  # !include MultiUser.nsh

  !define MUI_ICON "nsis\logo.ico"
  !define MULTIUSER_EXECUTIONLEVEL Standard
  !define MULTIUSER_INSTALLMODE_INSTDIR   "Flow123d"

  !define MUI_WELCOMEFINISHPAGE_BITMAP    "nsis\back.bmp" # 170x320
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP  "nsis\back.bmp" # 170x320

#----------------------------------------------------------
# PAGES
#----------------------------------------------------------
  # Define the different pages.
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE     "LICENSE.txt"
  #!insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  # uninstall
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_LANGUAGE         "English"

#----------------------------------------------------------
# Functions
#----------------------------------------------------------
Function COPY_FILES
  SetOutPath $INSTDIR
  File "version"
  File "license.txt"
  File "readme.txt"

  File /r "win"
  File /r "tests"
  File /r "nsis"

  SetOutPath "$INSTDIR\doc"
  File /r "htmldoc"
  File /r "flow123d_${VERSION}_doc.pdf"

  # install fterm.bat
  CreateDirectory "$INSTDIR\bin"
  SetOutPath "$INSTDIR\bin"
  FileOpen $0 "fterm.bat" w
    FileWrite $0 '@echo off$\r$\n'
    FileWrite $0 'SET "cdir=\%CD:~0,1%\%CD:~3,256%"$\r$\n'
    FileWrite $0 'docker run -ti --rm -v "%~d0\:/%CD:~0,1%/" -v "C:\:/c/" -w "%cdir:\=/%" flow123d/${VERSION} %*$\r$\n'
    FileWrite $0 'pause$\r$\n'
  FileClose $0

  # fterm with version
  CopyFiles "fterm.bat" "f-${VERSION}.bat"
FunctionEnd


Function REMOVE_OLD
  nsExec::Exec '"powershell" -WindowStyle hidden -ExecutionPolicy RemoteSigned -File $INSTDIR\remove-docker-toolbox.ps1'
FunctionEnd

Function CHECK_DOCKER
  SetRegView 64
  ReadRegStr $DOCKER_EXE HKLM "${DOCKER_HK}" "AppPath"
  DetailPrint "DOCKER_EXE $DOCKER_EXE"

  ${If} $DOCKER_EXE == ""
    DetailPrint "Downloading Docker for Windows installer"
    # download the file
    SetOutPath "$INSTDIR\win"
    ExecWait '"powershell" -ExecutionPolicy RemoteSigned -File "$INSTDIR\win\download-dfw.ps1"'
    # run the installer
    ExecWait '"$INSTDIR\win\dfw.exe"'
    # load the reg value
    ReadRegStr $DOCKER_EXE HKLM "${DOCKER_HK}" "AppPath"
  ${Endif}
FunctionEnd


Function START_DOCKER_DEAMON
  # try to run docker ps to determine whther deamon is running
  DetailPrint "Docker installed in $DOCKER_EXE"
  nsExec::Exec 'docker ps'
  Pop $0

  # if is running continue
  ${If} $0 == "0"
    DetailPrint "Docker deamon running"
  # otherwise lanch the deamon
  ${Else}
    DetailPrint "Starting Docker deamon, this'll take about a minute for the first time."
    Exec '"$DOCKER_EXE\Docker for Windows.exe"'
    Sleep 5000
    MessageBox MB_OK "The Docker is now starting, wait until it's ready before pressing OK$\r$\nYou should see a notification at the bottom right."
  ${EndIf}
FunctionEnd


Function PULL_IMAGE
  # pull image
  DetailPrint "Pulling docker image"
  nsExec::Exec 'docker pull flow123d/${VERSION}'
FunctionEnd


Function MAKE_DOCKERD
    # install dockerd.bat
    SetOutPath "$INSTDIR\bin"
    FileOpen $0 "dockerd.bat" w
      FileWrite $0 '@echo off$\r$\n'
      FileWrite $0 'Start "" "$DOCKER_EXE\Docker for Windows.exe"$\r$\n'
    FileClose $0
FunctionEnd

Function REGISTER_APP

  # Update path
  ${EnvVarUpdate}  $0 "PATH" "P" "HKCU" "$INSTDIR\bin"
  # Update global FLOW123D env variable version list
  ${EnvVarUpdate}  $0 "FLOW123D" "A" "HKCU" "${VERSION}"

  #----------------------------------------------------------

  # Write the installation path into the registry
  WriteRegStr HKCU "SOFTWARE\Flow123d-${VERSION}" "Install_Dir" "$INSTDIR"
  # Write the uninstall keys for Windows
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flow123d-${VERSION}" "DisplayName" "Flow123d-${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flow123d-${VERSION}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flow123d-${VERSION}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flow123d-${VERSION}" "NoRepair" 1
FunctionEnd

#----------------------------------------------------------
# Section
#----------------------------------------------------------
Section

  RMDir /r $INSTDIR
  Call REMOVE_OLD
  Call COPY_FILES
  Call CHECK_DOCKER
  Call START_DOCKER_DEAMON
  Call PULL_IMAGE
  Call MAKE_DOCKERD
  Call REGISTER_APP

  CreateShortcut "$DESKTOP\Flow-${VERSION}.lnk" "$INSTDIR\bin\fterm.bat" "" "$INSTDIR\nsis\logo-64.ico"

  #----------------------------------------------------------

  WriteUninstaller "uninstall.exe"

SectionEnd



# Uninstaller
Section "Uninstall"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flow123d-${VERSION}"
  DeleteRegKey HKCU "SOFTWARE\Flow123d-${VERSION}"
  Delete "$DESKTOP\Flow-${VERSION}.lnk"

  ${un.EnvVarUpdate} $0 "PATH"     "R" "HKCU" "$INSTDIR\bin"
  ${un.EnvVarUpdate} $0 "FLOW123D" "R" "HKCU" "${VERSION}"

  # Remove docker image
  ExecWait 'docker rmi -f flow123d/${VERSION}'
  # Remove Flow123d installation directory and all files within.
  RMDir /r "$INSTDIR"

SectionEnd
