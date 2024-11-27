#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    if [[ ! -f "$SCRIPT_DIR/build/.config_hash" ]]; then
        return 0
    fi
    
    local old_hash
    old_hash=$(cat "$SCRIPT_DIR/build/.config_hash")
    local new_hash
    new_hash=$(get_config_hash)
    
    [[ "$old_hash" != "$new_hash" ]]
}

# Function to update configuration hash
update_config_hash() {
    mkdir -p "$SCRIPT_DIR/build"
    get_config_hash > "$SCRIPT_DIR/build/.config_hash"
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

# Check if configuration has changed
if config_changed; then
    echo "Changes detected in configuration, reconfiguring..."
    
    # Create build directory
    mkdir -p "$SCRIPT_DIR/build"
    
    # Configure with CMake
    CMAKE_ARGS=(
        -B "$SCRIPT_DIR/build"
        -S "$SCRIPT_DIR"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
        -DVCPKG_TARGET_TRIPLET="$VCPKG_TRIPLET"
    )

    # Add overlay triplets if on macOS
    if is_macos; then
        CMAKE_ARGS+=(-DVCPKG_OVERLAY_TRIPLETS="$VCPKG_OVERLAY_TRIPLETS")
    fi

    cmake "${CMAKE_ARGS[@]}"
    
    # Update configuration hash
    update_config_hash
else
    echo "No changes in configuration, using existing build..."
fi

# Build the project
cmake --build "$SCRIPT_DIR/build" --config Release

# Clean up
trap 'rm -f vcpkg-configuration.json' EXIT
