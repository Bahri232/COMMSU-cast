@echo off
REM ComSSU Cast — Build and Run (Windows / MSYS2 MinGW-64)
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "PRESET=windows-msys2-debug"
set "BUILD_DIR=build\windows-debug"

echo === ComSSU Cast Build ^& Run ===
echo Platform: Windows (MSYS2 MinGW-64)
echo Preset:   %PRESET%
echo Build:    %BUILD_DIR%
echo.

REM --- Check MSYS2 (prefer UCRT64 matching CI, fall back to MINGW64) ---
set "MSYS2_BIN="
if exist "C:\msys64\ucrt64\bin\gcc.exe" (
    set "MSYS2_BIN=C:\msys64\ucrt64\bin"
) else if exist "C:\msys64\mingw64\bin\gcc.exe" (
    set "MSYS2_BIN=C:\msys64\mingw64\bin"
)

if "%MSYS2_BIN%"=="" (
    echo ERROR: MSYS2 UCRT64/MinGW-64 not found at C:\msys64
    echo.
    echo Install MSYS2 from https://www.msys2.org/ then run in MSYS2 UCRT64 shell:
    echo   pacman -S mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
    echo   pacman -S mingw-w64-ucrt-x86_64-pkgconf mingw-w64-ucrt-x86_64-qt6-base mingw-w64-ucrt-x86_64-qt6-declarative
    echo   pacman -S mingw-w64-ucrt-x86_64-qt6-tools mingw-w64-ucrt-x86_64-gstreamer mingw-w64-ucrt-x86_64-gst-plugins-base
    echo   pacman -S mingw-w64-ucrt-x86_64-gst-plugins-good mingw-w64-ucrt-x86_64-gst-plugins-bad
    echo   pacman -S mingw-w64-ucrt-x86_64-gst-plugins-ugly mingw-w64-ucrt-x86_64-gst-libav
    echo   pacman -S mingw-w64-ucrt-x86_64-openssl mingw-w64-ucrt-x86_64-libplist mingw-w64-ucrt-x86_64-protobuf
    echo   pacman -S mingw-w64-ucrt-x86_64-gtest mingw-w64-ucrt-x86_64-spdlog
    exit /b 1
)

REM --- Check Bonjour (runtime dependency for mDNS) ---
if not exist "%WINDIR%\System32\dnssd.dll" (
    if not exist "%WINDIR%\SysWOW64\dnssd.dll" (
        echo WARNING: Bonjour ^(dnssd.dll^) not found. AirPlay and Cast will not be discoverable.
        echo Install iTunes, iCloud, or Bonjour Print Services to enable device discovery.
        echo Build will continue, but the receiver will not appear in device pickers.
        echo.
    )
)

REM Add MSYS2 to PATH for this session
set "PATH=%MSYS2_BIN%;%PATH%"

REM --- Check tools ---
where cmake >nul 2>&1 || (
    echo ERROR: cmake not found. Install: pacman -S mingw-w64-x86_64-cmake
    exit /b 1
)
where ninja >nul 2>&1 || (
    echo ERROR: ninja not found. Install: pacman -S mingw-w64-x86_64-ninja
    exit /b 1
)

REM --- Configure ---
if not exist "%BUILD_DIR%\build.ninja" (
    echo === Configuring ^(%PRESET%^) ===
    cmake --preset %PRESET%
    if errorlevel 1 (
        echo ERROR: CMake configure failed.
        exit /b 1
    )
    echo.
)

REM --- Build ---
echo === Building ===
cmake --build %BUILD_DIR% --target ComSSUCast
if errorlevel 1 (
    echo ERROR: Build failed.
    exit /b 1
)
echo.

REM --- Run ---
set "BINARY=%BUILD_DIR%\ComSSUCast.exe"
if not exist "%BINARY%" (
    echo ERROR: Binary not found at %BINARY%
    exit /b 1
)

echo === Running ComSSU Cast ===
echo Press Ctrl+C to stop.
echo.
"%BINARY%" %*
