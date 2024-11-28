#!/bin/bash

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if environment is already prepared
ENV_PREPARED_FLAG=".linux_env_prepared"
if [ -f "$ENV_PREPARED_FLAG" ]; then
    echo "Linux environment already prepared. Skipping..."
    exit 0
fi

echo "Preparing Linux development environment..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo privileges"
    exit 1
fi

# Update package list
apt-get update

# Install basic build tools
BASIC_TOOLS="build-essential cmake g++ make git pkg-config"
echo "Installing basic build tools: $BASIC_TOOLS"
apt-get install -y $BASIC_TOOLS

# Install additional development tools required by vcpkg and dependencies
DEV_TOOLS="bison flex gperf libx11-dev libxft-dev libxext-dev libwayland-dev \
           libxkbcommon-dev libglu1-mesa-dev python3-dev libgtk-3-dev libssl-dev"

echo "Installing additional development tools: $DEV_TOOLS"
apt-get install -y $DEV_TOOLS
apt-get install -y python3-dev python3-pip python3.8-dev python3.8-distutils python3.8-venv


# Create flag file to indicate environment is prepared
touch "$ENV_PREPARED_FLAG"

echo "Linux development environment prepared successfully!"
