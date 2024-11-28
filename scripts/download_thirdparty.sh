#!/bin/bash

# Function to download and extract a dependency
download_thirdparty_dep() {
    local name=$1
    local url=$2
    local target_dir=$3
    local temp_file="/tmp/${name}.tar.gz"

    echo "Downloading $name from $url..."
    if ! curl -L "$url" -o "$temp_file"; then
        echo "ERROR: Failed to download $name from $url"
        return 1
    fi

    # Create target directory
    mkdir -p "$target_dir"

    # Extract based on file extension
    echo "Extracting $name to $target_dir..."
    if [[ "$url" == *".zip" ]]; then
        if ! unzip -q "$temp_file" -d "$target_dir"; then
            echo "ERROR: Failed to extract $name"
            rm -f "$temp_file"
            return 1
        fi
    else
        if ! tar xf "$temp_file" -C "$target_dir"; then
            echo "ERROR: Failed to extract $name"
            rm -f "$temp_file"
            return 1
        fi
    fi

    # Cleanup
    rm -f "$temp_file"
    return 0
}

# Main function to install all third-party dependencies
install_thirdparty_deps() {
    local config_file=$1
    local build_dir=$2
    local thirdparty_dir="${build_dir}/thirdparty"

    # Check for required tools
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 is required but not installed"
        exit 1
    fi

    if ! python3 -c "import yaml" 2>/dev/null; then
        echo "Installing PyYAML..."
        python3 -m pip install PyYAML
    fi

    # Parse YAML using Python
    local deps_json=$(python3 -c "
import yaml
import json
import sys

try:
    with open('$config_file', 'r') as f:
        data = yaml.safe_load(f)
        print(json.dumps(data['dependencies']['linux']))
except Exception as e:
    print(f'Error parsing config: {str(e)}', file=sys.stderr)
    sys.exit(1)
")

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to parse config file"
        exit 1
    fi

    # Create thirdparty directory
    mkdir -p "$thirdparty_dir"

    # Process each dependency
    echo "$deps_json" | python3 -c "
import json
import sys

deps = json.load(sys.stdin)
for name, info in deps.items():
    print(f'{name}\t{info[\"url\"]}\t{info[\"version\"]}')
" | while IFS=$'\t' read -r name url version; do
        local target_dir="${thirdparty_dir}/${name}"

        echo "Processing $name version $version..."

        # Skip if already installed
        if [ -d "$target_dir" ]; then
            echo "$name already installed at $target_dir"
            continue
        fi

        # Download and install
        if ! download_thirdparty_dep "$name" "$url" "$target_dir"; then
            echo "ERROR: Failed to install $name"
            exit 1
        fi

        echo "$name installed successfully"
    done

    echo "All third-party dependencies installed successfully"
}

# If script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <config_file> <build_dir>"
        exit 1
    fi

    install_thirdparty_deps "$1" "$2"
fi
