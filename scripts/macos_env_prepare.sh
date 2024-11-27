#!/bin/bash

# Exit on error
set -e

# Check if environment is already prepared
ENV_PREPARED_FLAG=".macos_env_prepared"
if [ -f "$ENV_PREPARED_FLAG" ]; then
    echo "macOS environment already prepared. Skipping..."
    exit 0
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Homebrew
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Xcode Command Line Tools if needed
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    
    # Wait for installation to complete
    echo "Please complete the Xcode Command Line Tools installation and press any key to continue..."
    read -n 1
fi

# Install required packages
BREW_PACKAGES="cmake ninja pkg-config"
echo "Installing build tools: $BREW_PACKAGES"
brew install $BREW_PACKAGES

# Install Python if needed
if ! command_exists python3; then
    echo "Installing Python..."
    brew install python
fi

# Create flag file to indicate environment is prepared
touch "$ENV_PREPARED_FLAG"

echo "macOS development environment prepared successfully!"
