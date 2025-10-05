@echo off
setlocal enabledelayedexpansion

:: Read environment variables from .env file
call :loadEnvVar "HTTP_PROXY"
call :loadEnvVar "HTTPS_PROXY"
call :loadEnvVar "USE_NATIVE_TLS" "UV_NATIVE_TLS"

cd /d "%~dp0"

echo Starting Act-AIO...
echo Current directory: %CD%
echo.
call :showEnvVariables

echo.
echo Running Act-AIO...
uv run python -m act_aio.main

echo.
echo Act-AIO has finished.
goto :end

:loadEnvVar
:: Function to load environment variable from .env file
:: Usage: call :loadEnvVar "KEY_NAME" [VARIABLE_NAME]
:: If VARIABLE_NAME is provided, sets that variable instead of KEY_NAME

setlocal enabledelayedexpansion
set "search_key=%~1"
set "var_name=%~2"
if "%var_name%"=="" set "var_name=%~1"
set "found_value="

:: Check if .env file exists
if not exist ".env" (
    goto :endLoadEnvVar
)

:: Read the .env file line by line
for /f "usebackq tokens=* delims=" %%i in (".env") do (
    set "line=%%i"

    :: Skip empty lines
    if not "!line!"=="" (
        :: Skip comments (lines starting with #)
        set "first_char=!line:~0,1!"
        if not "!first_char!"=="#" (
            :: Look for = sign
            for /f "tokens=1,* delims==" %%a in ("!line!") do (
                set "current_key=%%a"
                set "current_value=%%b"

                :: Remove leading and trailing spaces from key
                for /f "tokens=* delims= " %%x in ("!current_key!") do set "current_key=%%x"
                if "!current_key!"=="!search_key!" (
                    :: Remove leading spaces from value if any
                    if defined current_value (
                        for /f "tokens=* delims= " %%y in ("!current_value!") do set "found_value=%%y"
                    ) else (
                        set "found_value="
                    )
                    goto :endLoadEnvVar
                )
            )
        )
    )
)

:endLoadEnvVar
endlocal & set "%var_name%=%found_value%"
goto :eof

:showEnvVariables
:: Function to display all environment variables loaded from .env
setlocal enabledelayedexpansion
set "count=0"

echo Environment variables loaded from .env:
echo =======================================

:: Check if .env file exists
if not exist ".env" (
    echo   ^(no .env file found^)
    goto :endShowEnvVariables
)

:: Read the .env file line by line and display each key=value pair
for /f "usebackq tokens=* delims=" %%i in (".env") do (
    set "line=%%i"

    :: Skip empty lines
    if not "!line!"=="" (
        :: Skip comments (lines starting with #)
        set "first_char=!line:~0,1!"
        if not "!first_char!"=="#" (
            :: Look for = sign
            for /f "tokens=1,* delims==" %%a in ("!line!") do (
                set "current_key=%%a"
                set "current_value=%%b"

                :: Remove leading and trailing spaces from key
                for /f "tokens=* delims= " %%x in ("!current_key!") do set "current_key=%%x"

                :: Remove leading spaces from value if any
                if defined current_value (
                    for /f "tokens=* delims= " %%y in ("!current_value!") do set "current_value=%%y"
                ) else (
                    set "current_value="
                )

                :: Increment counter
                set /a count+=1

                :: Display the key=value pair
                echo   [!count!] !current_key!=!current_value!
            )
        )
    )
)

if !count! equ 0 (
    echo   ^(no valid environment variables found^)
) else (
    echo   ^(loaded !count! environment variables^)
)

:endShowEnvVariables
goto :eof

:end


pause