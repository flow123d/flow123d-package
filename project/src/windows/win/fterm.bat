@echo off
SET "cdir=\%CD:~0,1%\%CD:~3,256%"
docker run -ti --rm -v "%~d0\:/%CD:~0,1%/" -v "C:\:/c/" -w "%cdir:\=/%" flow123d/2.2.1 %*
pause
