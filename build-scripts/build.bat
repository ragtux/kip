@echo off
REM Build script for Pikchr WASM module (Windows)
REM
REM Prerequisites:
REM - Emscripten SDK (emcc)
REM - wasi-stub (cargo install wasi-stub)
REM - pikchr.c (download from pikchr.org)

setlocal enabledelayedexpansion

echo =========================================
echo Pikchr WASM Build Script (Windows)
echo =========================================

REM Check for emcc
echo Checking for emcc...
where emcc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [X] Error: emcc not found
    echo Please install Emscripten SDK and activate it:
    echo   emsdk install latest
    echo   emsdk activate latest
    echo   emsdk_env.bat
    exit /b 1
)
echo [OK] emcc found

REM Check for wasi-stub
echo Checking for wasi-stub...
where wasi-stub >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [X] Error: wasi-stub not found
    echo Install with: cargo install --git https://github.com/astrale-sharp/wasm-minimal-protocol wasi-stub
    exit /b 1
)
echo [OK] wasi-stub found

REM Check for pikchr.c
echo Checking for pikchr.c...
if not exist "pikchr.c" (
    echo [X] Error: pikchr.c not found in current directory
    echo Download from: https://pikchr.org/home/file/pikchr.c
    exit /b 1
)
echo [OK] pikchr.c found

REM Check for pikchr_wasm.c
echo Checking for pikchr_wasm.c...
if not exist "pikchr_wasm.c" (
    echo [X] Error: pikchr_wasm.c not found in current directory
    exit /b 1
)
echo [OK] pikchr_wasm.c found

REM Clean previous builds
echo.
echo Cleaning previous builds...
if exist pikchr.wasm del /q pikchr.wasm
if exist "pikchr - stubbed.wasm" del /q "pikchr - stubbed.wasm"
if exist "pikchr - stubbed (1).wasm" del /q "pikchr - stubbed (1).wasm"
if exist *.o del /q *.o

REM Compile
echo.
echo Compiling with Emscripten...
emcc pikchr.c pikchr_wasm.c ^
  -O3 ^
  --no-entry ^
  -s WASM=1 ^
  -s EXPORTED_FUNCTIONS="['_typst_pikchr']" ^
  -s ALLOW_MEMORY_GROWTH=1 ^
  -s STANDALONE_WASM=1 ^
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 ^
  -o pikchr.wasm

if %ERRORLEVEL% NEQ 0 (
    echo [X] Compilation failed
    exit /b 1
)
echo [OK] Compilation successful

REM Stub WASI functions
echo.
echo Stubbing WASI functions...
wasi-stub --stub-function env:emscripten_notify_memory_growth pikchr.wasm

if %ERRORLEVEL% NEQ 0 (
    echo [X] Stubbing failed
    exit /b 1
)
echo [OK] Stubbing successful

REM Find stubbed file
set STUBBED_FILE=
if exist "pikchr - stubbed.wasm" (
    set STUBBED_FILE=pikchr - stubbed.wasm
) else if exist "pikchr - stubbed (1).wasm" (
    set STUBBED_FILE=pikchr - stubbed (1).wasm
)

if "!STUBBED_FILE!"=="" (
    echo [X] Could not find stubbed WASM file
    exit /b 1
)

REM Copy to plugin directory
echo.
echo Installing to plugin directory...
copy /Y "!STUBBED_FILE!" ..\pikchr.wasm >nul

if %ERRORLEVEL% NEQ 0 (
    echo [X] Installation failed
    exit /b 1
)

echo [OK] Installation successful
echo.
echo =========================================
echo Build Complete!
echo =========================================
dir ..\pikchr.wasm | find "pikchr.wasm"
echo.
echo Test with:
echo   cd ..
echo   typst compile example_simple.typ
echo =========================================
