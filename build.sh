#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/build"
BUILD_TYPE=${BUILD_TYPE:-Release}
WITH_PYTHON=0

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --with-python)
            WITH_PYTHON=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--debug] [--with-python]"
            exit 1
            ;;
    esac
done

# Function to check if we're on Linux
is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

# Function to check if we're on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Function to get configuration hash
get_config_hash() {
    if [[ -f "$SCRIPT_DIR/CMakeLists.txt" ]]; then
        echo "$(md5sum "$SCRIPT_DIR/CMakeLists.txt" | cut -d' ' -f1)"
    fi
    
    if [[ -f "$SCRIPT_DIR/vcpkg.json" ]]; then
        echo "$(md5sum "$SCRIPT_DIR/vcpkg.json" | cut -d' ' -f1)"
    fi
}

# Function to check if configuration has changed
config_changed() {
    if [[ ! -f "$BUILD_DIR/.config_hash" ]]; then
        return 0
    fi
    
    local old_hash
    old_hash=$(cat "$BUILD_DIR/.config_hash")
    local new_hash
    new_hash=$(get_config_hash)
    
    [[ "$old_hash" != "$new_hash" ]]
}

# Function to update configuration hash
update_config_hash() {
    mkdir -p "$BUILD_DIR"
    get_config_hash > "$BUILD_DIR/.config_hash"
}

# Prepare Linux environment if needed
if is_linux; then
    "$SCRIPT_DIR/scripts/linux_env_prepare.sh"
fi

# Prepare macOS environment if needed
if is_macos; then
    "$SCRIPT_DIR/scripts/macos_env_prepare.sh"
fi

# Setup vcpkg
if [[ -z "${VCPKG_ROOT}" ]]; then
    # Try common vcpkg locations
    VCPKG_LOCATIONS=(
        "/opt/vcpkg"
        "$SCRIPT_DIR/../vcpkg"
        "$SCRIPT_DIR/vcpkg"
    )
    
    for loc in "${VCPKG_LOCATIONS[@]}"; do
        if [[ -f "$loc/vcpkg" ]]; then
            export VCPKG_ROOT="$loc"
            break
        fi
    done
    
    if [[ -z "${VCPKG_ROOT}" ]]; then
        echo "Error: VCPKG_ROOT is not set and vcpkg was not found in common locations"
        exit 1
    fi
fi

# Set the appropriate triplet based on platform
if is_macos; then
    VCPKG_TRIPLET="x64-osx-custom"
    VCPKG_OVERLAY_TRIPLETS="$SCRIPT_DIR/triplets"
else
    VCPKG_TRIPLET="x64-linux"
fi

# Source the conda environment if testing Python extensions
if [ "$WITH_PYTHON" == "1" ]; then
    echo "Setting up Python environment..."
    source "$SCRIPT_DIR/scripts/python_env_manage.sh" activate || {
        echo "Failed to activate Python environment"
        exit 1
    }
fi

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Check if CMakeCache.txt exists and configuration has changed
RECONFIGURE=0
if [ ! -f CMakeCache.txt ]; then
    RECONFIGURE=1
elif [ $WITH_PYTHON -eq 1 ] && ! grep -q "WITH_PYTHON:BOOL=ON" CMakeCache.txt; then
    RECONFIGURE=1
elif [ $WITH_PYTHON -eq 0 ] && grep -q "WITH_PYTHON:BOOL=ON" CMakeCache.txt; then
    RECONFIGURE=1
fi

if [ $RECONFIGURE -eq 1 ]; then
    echo "Configuring CMake..."
    PYTHON_OPTIONS=""
    if [ $WITH_PYTHON -eq 1 ]; then
        PYTHON_OPTIONS="-DWITH_PYTHON=ON"
    fi
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
        -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
        -DVCPKG_TARGET_TRIPLET="$VCPKG_TRIPLET" \
        -DVCPKG_OVERLAY_TRIPLETS="$VCPKG_OVERLAY_TRIPLETS" \
        $PYTHON_OPTIONS || {
            echo "CMake configuration failed"
            exit 1
        }
else
    echo "No changes in configuration, using existing build..."
fi

# Run vcpkg install
echo "-- Running vcpkg install"
"$VCPKG_ROOT/vcpkg" install || {
    echo "vcpkg install failed"
    exit 1
}
echo "-- Running vcpkg install - done"

# Build the project
cmake --build "$BUILD_DIR" --config Release || {
    echo "Build failed"
    exit 1
}

echo "Build completed successfully"

# Clean up
trap 'rm -f vcpkg-configuration.json' EXIT
