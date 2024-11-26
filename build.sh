#!/bin/bash

# Exit on error
set -e

# Function for installing the built artifacts
install_artifacts() {
    echo "Installing artifacts..."
    if [ "$(uname)" == "Darwin" ]; then
        sudo cmake --install build
    else
        sudo cmake --install build
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
    cmake --build . --config Release -j$(nproc)
    cd ..
}

# Function for full build
full_build() {
    # Disable vcpkg telemetry
    export VCPKG_DISABLE_METRICS=1

    # Install build essentials if not present
    if ! command -v make &> /dev/null || ! command -v g++ &> /dev/null; then
        echo "Installing build essentials..."
        if [ "$(uname)" == "Darwin" ]; then
            brew install gcc make cmake ninja
        else
            sudo apt-get update
            sudo apt-get install -y build-essential cmake ninja-build
        fi
    fi

    # Check for vcpkg
    if [ -z "$VCPKG_ROOT" ]; then
        # Check if vcpkg exists in parent directory
        if [ -d "../vcpkg" ]; then
            export VCPKG_ROOT="../vcpkg"
        elif [ -d "./vcpkg" ]; then
            export VCPKG_ROOT="./vcpkg"
        else
            echo "vcpkg not found. Installing..."
            git clone https://github.com/Microsoft/vcpkg.git
            ./vcpkg/bootstrap-vcpkg.sh -disableMetrics
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
        # On macOS, explicitly set the compiler and use Ninja generator
        cmake .. \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
            -DCMAKE_CXX_COMPILER=$(which g++) \
            -DBUILD_PYTHON_BINDINGS=ON
    else
        cmake .. \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
            -DBUILD_PYTHON_BINDINGS=ON
    fi

    # Build
    cmake --build . --config Release -j$(nproc)

    # Create release directory
    cd ..
    mkdir -p release

    # Package core library
    if [ -d "build/lib" ]; then
        mkdir -p build/include
        cp src/include/core_lib.hpp build/include/
        cd build
        tar czf ../release/core_lib.tar.gz \
            lib/libcore_lib.dylib \
            lib/libcore_lib.1.dylib \
            lib/libcore_lib.*.dylib \
            include/core_lib.hpp
        cd ..
    else
        echo "Warning: lib directory not found"
        ls -la build/
    fi

    # Package main application
    if [ -f "build/bin/main_app" ]; then
        cd build
        tar czf ../release/main_app.tar.gz bin/main_app
        cd ..
    else
        echo "Warning: main application not found"
        ls -la build/bin/
    fi

    # Package Python bindings
    mkdir -p build/temp
    for PY_VERSION in "38" "39"; do
        PY_MODULE="build/lib/py_core_lib.cpython-${PY_VERSION}-darwin.so"
        if [ "$(uname)" != "Darwin" ]; then
            PY_MODULE="build/lib/py_core_lib.cpython-${PY_VERSION}-x86_64-linux-gnu.so"
        fi

        if [ -f "$PY_MODULE" ]; then
            cp "$PY_MODULE" build/temp/
        else
            echo "Warning: Python ${PY_VERSION} module not found at $PY_MODULE"
            ls -la build/lib/
        fi
    done

    if [ -d "build/temp" ] && [ "$(ls -A build/temp)" ]; then
        cd build/temp
        tar czf ../../release/python_bindings.tar.gz *
        cd ../..
        rm -rf build/temp
    else
        echo "Warning: No Python modules found to package"
        ls -la build/lib/
    fi

    echo "Build completed successfully!"
    echo "Artifacts are available in the release directory:"
    ls -l release/
}

# Parse command line arguments
if [ "$1" == "quick" ]; then
    quick_rebuild
elif [ "$1" == "install" ]; then
    full_build
    install_artifacts
else
    full_build
fi
