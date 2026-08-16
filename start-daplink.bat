@echo off
setlocal
cd /d "%~dp0"

if exist "stlink-tool\stlink-tool.exe" (
  "stlink-tool\stlink-tool.exe"
) else if exist "stlink-tool\stlink-tool" (
  "stlink-tool\stlink-tool"
) else (
  echo stlink-tool not found.
  echo Build it first, then run this script again:
  echo   cd stlink-tool
  echo   make
  exit /b 1
)

timeout /t 1 /nobreak >nul

where pyocd >nul 2>&1
if %ERRORLEVEL%==0 (
  pyocd list
) else (
  py -m pyocd list
)
