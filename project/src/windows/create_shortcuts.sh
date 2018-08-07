#!/bin/bash

# 1st argument: path to bash
# 2nd argument: path to install dir


echo "=========================================================="
echo "Creating shortcuts:"


echo " - fterm.bat"
cat > bin/fterm.bat << EOL
@echo off
docker-machine start default
@FOR /f "tokens=*" %%i IN ('docker-machine env') DO @%%i
"$1" "$2\bin\fterm.sh" %*
EOL


# flow123d.bat shortcut
echo " - flow123d.bat"
cat > bin/flow123d.bat << EOL
@echo off
docker-machine start default
@FOR /f "tokens=*" %%i IN ('docker-machine env') DO @%%i
echo "Starting Flow123d."
echo "flow123d" %* 
"$1" "$2\bin\flow123d.sh" %*
echo "Flow123d done."
EOL


# runtest.bat shortcut
echo " - runtest.bat"
cat > tests/runtest.bat << EOL
@echo off
docker-machine start default
@FOR /f "tokens=*" %%i IN ('docker-machine env') DO @%%i
"$1" "$2\tests\runtest.sh" %*
EOL


# runtest.bat shortcut
echo " - runtest.bat"
cat > bin/runtest.bat << EOL
@echo off
docker-machine start default
@FOR /f "tokens=*" %%i IN ('docker-machine env') DO @%%i
"$1" "$2\bin\runtest.sh" %*
EOL

# uninstall.bat shortcut
echo " - uninstall.bat"
cat > uninstall.bat << EOL
@echo off
docker-machine start default
@FOR /f "tokens=*" %%i IN ('docker-machine env') DO @%%i
start "uninstall" "powershell.exe" "-ExecutionPolicy" "Unrestricted" "-File" "$2\uninstall.ps1" "$1"
pause
EOL
echo "=========================================================="
