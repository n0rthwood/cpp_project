#!/bin/bash

# Exit on error
set -e

# Detect number of CPU cores
if [ "$(uname)" == "Darwin" ]; then
    NUM_CORES=$(sysctl -n hw.ncpu)
else
    NUM_CORES=$(nproc)
fi

# Function for installing the built artifacts
install_artifacts() {
    echo "Installing artifacts..."
    if [ "$(uname)" == "Darwin" ] || [ "$(uname)" == "Linux" ]; then
        sudo cmake --install build
    else
        cmake --install build
    fi
}

# Function for quick rebuild
quick_rebuild() {
    if [ ! -d "build" ]; then
        echo "Build directory not found. Running full build..."
        full_build
        return
    fi
    echo "Performing quick rebuild..."
    cd build
    cmake --build . --config Release -j${NUM_CORES}
    cd ..
}

# Function for full build
full_build() {
    # Disable vcpkg telemetry
    export VCPKG_DISABLE_METRICS=1

    # Check for vcpkg
    if [ -z "$VCPKG_ROOT" ]; then
        if [ -d "/opt/vcpkg" ]; then
            export VCPKG_ROOT="/opt/vcpkg"
        elif [ -d "../vcpkg" ]; then
            export VCPKG_ROOT="../vcpkg"
        elif [ -d "./vcpkg" ]; then
            export VCPKG_ROOT="./vcpkg"
        else
            echo "vcpkg not found. Installing..."
            git clone https://github.com/Microsoft/vcpkg.git
            if [ "$(uname)" == "Darwin" ] || [ "$(uname)" == "Linux" ]; then
                ./vcpkg/bootstrap-vcpkg.sh -disableMetrics
            else
                ./vcpkg/bootstrap-vcpkg.bat -disableMetrics
            fi
            export VCPKG_ROOT="./vcpkg"
        fi
    fi

    # Set CMake toolchain file
    export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"

    # Create build directory
    rm -rf build
    mkdir -p build
    cd build

    # Configure with CMake
    if [ "$(uname)" == "Darwin" ]; then
        # macOS configuration
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
            -DCMAKE_CXX_COMPILER="$(which g++)" \
            -DCMAKE_C_COMPILER="$(which gcc)" \
            -DCMAKE_MAKE_PROGRAM="$(which make)" \
            -DBUILD_PYTHON_BINDINGS=ON
    else
        # Linux/Unix configuration
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
            -DBUILD_PYTHON_BINDINGS=ON
    fi

    # Build
    cmake --build . --config Release -j${NUM_CORES}

    # Create release directory
    cd ..
    mkdir -p release

    # Package core library
    if [ -d "build/lib" ]; then
        mkdir -p build/include
        cp src/include/*.hpp build/include/
        cd build
        if [ "$(uname)" == "Darwin" ]; then
            tar czf ../release/core_lib.tar.gz \
                lib/libcore_lib.dylib \
                include/*.hpp
        else
            tar czf ../release/core_lib.tar.gz \
                lib/libcore_lib.so* \
                include/*.hpp
        fi
        cd ..
    fi

    # Package main application
    if [ -f "build/bin/main_app" ] || [ -f "build/bin/main_app.exe" ]; then
        cd build/bin
        if [ "$(uname)" == "Darwin" ] || [ "$(uname)" == "Linux" ]; then
            tar czf ../../release/main_app.tar.gz main_app
        else
            tar czf ../../release/main_app.tar.gz main_app.exe
        fi
        cd ../..
    fi

    # Package Python bindings
    if [ -d "build/python" ]; then
        cd build/python
        tar czf ../../release/python_bindings.tar.gz *.so *.pyd
        cd ../..
    fi
}

# Parse command line arguments
if [ "$1" == "quick" ]; then
    quick_rebuild
elif [ "$1" == "install" ]; then
    install_artifacts
else
    full_build
fi
