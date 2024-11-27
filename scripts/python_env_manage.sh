#!/bin/bash

set -e

# Environment name
ENV_NAME="cpp_project_env"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONDA_PATH="/opt/miniconda3/bin/conda"

# Function to initialize conda in shell
init_conda() {
    if [[ ! -f "$CONDA_PATH" ]]; then
        echo "Error: Conda not found at $CONDA_PATH"
        exit 1
    fi

    # Initialize conda for this shell session
    eval "$("$(dirname "$CONDA_PATH")/conda" "shell.bash" "hook")"
}

# Function to create the conda environment
create_env() {
    echo "Creating conda environment '$ENV_NAME'..."
    # Create environment from yml file
    conda env create -f "$PROJECT_ROOT/environment.yml" || {
        echo "Failed to create environment from yml file"
        return 1
    }
    echo "Environment '$ENV_NAME' created successfully"
    
    # Activate the environment
    activate_env
    
    # Determine Python path
    PYTHON_PATH=$(conda run -n $ENV_NAME which python)
    PIP_PATH="${PYTHON_PATH%/python}/pip"
    
    # Install additional Python packages
    "$PIP_PATH" install --upgrade pip
    "$PIP_PATH" install setuptools wheel pybind11
}

# Function to activate the environment
activate_env() {
    echo "Activating conda environment '$ENV_NAME'..."
    # Check if the environment exists
    if ! conda env list | grep -q "^$ENV_NAME "; then
        echo "Environment '$ENV_NAME' not found. Creating it..."
        create_env || {
            echo "Failed to create environment"
            return 1
        }
    fi
    
    # Source conda.sh if it exists
    CONDA_BASE=$(conda info --base)
    source "$CONDA_BASE/etc/profile.d/conda.sh"
    
    # Activate the environment
    conda activate $ENV_NAME || {
        echo "Failed to activate environment"
        return 1
    }
    echo "Environment '$ENV_NAME' activated"
}

# Function to remove the conda environment
clean_env() {
    echo "Cleaning up conda environment '$ENV_NAME'..."
    conda deactivate 2>/dev/null || true
    conda env remove -n $ENV_NAME -y || {
        echo "Failed to remove environment"
        return 1
    }
    echo "Environment '$ENV_NAME' removed successfully"
}

# Main script
case "$1" in
    "create")
        init_conda
        clean_env 2>/dev/null || true  # Clean existing env if it exists
        create_env
        ;;
    "clean")
        init_conda
        clean_env
        ;;
    "activate")
        init_conda
        activate_env
        ;;
    *)
        echo "Usage: $0 {create|clean|activate}"
        echo "  create  - Create a fresh conda environment"
        echo "  clean   - Remove the conda environment"
        echo "  activate - Activate the conda environment"
        exit 1
        ;;
esac
