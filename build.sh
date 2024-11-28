#!/bin/bash

# Exit on error
set -e

# Script arguments
CLEAN=0
RELEASE=0
DEBUG=0
INSTALL=0
PACKAGE=0
FORCE_RECREATE_ENV=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=1
            shift
            ;;
        --release)
            RELEASE=1
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --install)
            INSTALL=1
            shift
            ;;
        --package)
            PACKAGE=1
            shift
            ;;
        --force-recreate-env)
            FORCE_RECREATE_ENV=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Get number of CPU cores for parallel build
NUM_CORES=$(nproc)

# Function to compute configuration hash
get_config_hash() {
    if [ -f "$SCRIPT_DIR/vcpkg.json" ]; then
        CONFIG_CONTENT=$(cat "$SCRIPT_DIR/vcpkg.json")
        VCPKG_ROOT=${VCPKG_ROOT:-""}
        echo "${CONFIG_CONTENT}|${VCPKG_ROOT}" | sha256sum | awk '{print $1}'
    else
        echo "Error: vcpkg.json not found"
        exit 1
    fi
}

# Function to check if reconfiguration is needed
should_reconfigure() {
    local HASH_FILE="$SCRIPT_DIR/build/.config_hash"
    if [ ! -f "$HASH_FILE" ]; then
        return 0
    fi
    
    local CURRENT_HASH=$(get_config_hash)
    local SAVED_HASH=$(cat "$HASH_FILE")
    [ "$CURRENT_HASH" != "$SAVED_HASH" ]
}

# Setup vcpkg if not already set up
if [ -z "$VCPKG_ROOT" ]; then
    VCPKG_PATHS=(
        "/opt/vcpkg"
        "$SCRIPT_DIR/../vcpkg"
        "$SCRIPT_DIR/vcpkg"
    )
    
    for path in "${VCPKG_PATHS[@]}"; do
        if [ -d "$path" ]; then
            export VCPKG_ROOT="$path"
            break
        fi
    done
    
    if [ -z "$VCPKG_ROOT" ]; then
        echo "vcpkg not found. Installing..."
        git clone https://github.com/Microsoft/vcpkg.git "$SCRIPT_DIR/vcpkg"
        "$SCRIPT_DIR/vcpkg/bootstrap-vcpkg.sh" -disableMetrics
        export VCPKG_ROOT="$SCRIPT_DIR/vcpkg"
    fi
fi

# Set CMake toolchain file and vcpkg settings
export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
export VCPKG_OVERLAY_TRIPLETS="$SCRIPT_DIR/triplets"

# Create build directory
BUILD_DIR="$SCRIPT_DIR/build"
mkdir -p "$BUILD_DIR"

# Determine build type
if [ "$DEBUG" -eq 1 ]; then
    BUILD_TYPE="Debug"
else
    BUILD_TYPE="Release"
fi

# Clean build if requested
if [ "$CLEAN" -eq 1 ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"/*
fi

# Configure and build
cd "$BUILD_DIR"

if should_reconfigure || [ "$FORCE_RECREATE_ENV" -eq 1 ]; then
    echo "Configuring CMake..."
    cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
          "$SCRIPT_DIR"
    
    # Save new configuration hash
    get_config_hash > "$BUILD_DIR/.config_hash"
fi

echo "Building..."
cmake --build . --config "$BUILD_TYPE" -j "$NUM_CORES"

if [ "$INSTALL" -eq 1 ]; then
    echo "Installing..."
    cmake --install . --config "$BUILD_TYPE"
fi

if [ "$PACKAGE" -eq 1 ]; then
    echo "Creating package..."
    cpack -C "$BUILD_TYPE"
fi

echo "Build completed successfully!"
