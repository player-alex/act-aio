@echo off
cd /d "%~dp0"

echo ===================================
echo Installing uv and Python
echo ===================================
echo.

REM Install uv
echo [1/2] Installing uv...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installation\install-uv.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo uv installation failed with error code: %ERRORLEVEL% >> error.log
    echo %date% %time%: uv installation failed with error code: %ERRORLEVEL% >> error.log
    echo ERROR: uv installation failed. Check error.log for details.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Installing Python from local mirror...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installation\install-python.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo Python installation failed with error code: %ERRORLEVEL% >> error.log
    echo %date% %time%: Python installation failed with error code: %ERRORLEVEL% >> error.log
    echo ERROR: Python installation failed. Check error.log for details.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================
echo Installation completed successfully!
echo ===================================
pause