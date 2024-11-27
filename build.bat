@echo off
setlocal enabledelayedexpansion

:: Set error handling
if errorlevel 1 exit /b %errorlevel%

:: Get number of CPU cores
for /f "tokens=2 delims==" %%i in ('wmic cpu get numberOfCores /value') do set NUM_CORES=%%i

:: Function to install artifacts
:install_artifacts
    echo Installing artifacts...
    cmake --install build
    exit /b 0

:: Function for quick rebuild
:quick_rebuild
    if not exist "build" (
        echo Build directory not found. Running full build...
        call :full_build
        exit /b 0
    )
    echo Performing quick rebuild...
    cd build
    cmake --build . --config Release -j%NUM_CORES%
    cd ..
    exit /b 0

:: Function for full build
:full_build
    :: Disable vcpkg telemetry
    set VCPKG_DISABLE_METRICS=1

    :: Check for vcpkg
    if not defined VCPKG_ROOT (
        if exist "\opt\vcpkg" (
            set "VCPKG_ROOT=\opt\vcpkg"
        ) else if exist "..\vcpkg" (
            set "VCPKG_ROOT=..\vcpkg"
        ) else if exist ".\vcpkg" (
            set "VCPKG_ROOT=.\vcpkg"
        ) else (
            echo vcpkg not found. Installing...
            git clone https://github.com/Microsoft/vcpkg.git
            call .\vcpkg\bootstrap-vcpkg.bat -disableMetrics
            set "VCPKG_ROOT=.\vcpkg"
        )
    )

    :: Set CMake toolchain file
    set "CMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake"

    :: Create build directory
    if exist build rd /s /q build
    mkdir build
    cd build

    :: Configure with CMake
    cmake .. ^
        -DCMAKE_BUILD_TYPE=Release ^
        -DCMAKE_TOOLCHAIN_FILE="%CMAKE_TOOLCHAIN_FILE%" ^
        -DBUILD_PYTHON_BINDINGS=ON

    :: Build
    cmake --build . --config Release -j%NUM_CORES%

    :: Create release directory
    cd ..
    if not exist release mkdir release

    :: Package core library
    if exist "build\lib" (
        if not exist "build\include" mkdir "build\include"
        copy src\include\*.hpp build\include\
        cd build
        tar -czf ..\release\core_lib.tar.gz ^
            lib\core_lib.dll ^
            include\*.hpp
        cd ..
    )

    :: Package main application
    if exist "build\bin\main_app.exe" (
        cd build\bin
        tar -czf ..\..\release\main_app.tar.gz main_app.exe
        cd ..\..
    )

    :: Package Python bindings
    if exist "build\python" (
        cd build\python
        tar -czf ..\..\release\python_bindings.tar.gz *.pyd
        cd ..\..
    )
    exit /b 0

:: Parse command line arguments
if "%1"=="quick" (
    call :quick_rebuild
) else if "%1"=="install" (
    call :install_artifacts
) else (
    call :full_build
)

endlocal
