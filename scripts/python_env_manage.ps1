# PowerShell script for managing Python environment

# Environment name
$ENV_NAME = "cpp_project_env"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR

# Function to initialize conda
function Initialize-Conda {
    # Check if conda is in PATH
    if (!(Get-Command conda -ErrorAction SilentlyContinue)) {
        Write-Host "Conda not found in PATH. Installing Miniconda..."
        # Download Miniconda
        $MINICONDA_URL = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
        $MINICONDA_INSTALLER = Join-Path $env:TEMP "Miniconda3-latest-Windows-x86_64.exe"
        Invoke-WebRequest -Uri $MINICONDA_URL -OutFile $MINICONDA_INSTALLER

        # Install Miniconda
        Start-Process -Wait -FilePath $MINICONDA_INSTALLER -ArgumentList "/S /D=$env:USERPROFILE\Miniconda3"
        Remove-Item $MINICONDA_INSTALLER

        # Add conda to PATH for this session
        $env:PATH = "$env:USERPROFILE\Miniconda3;$env:USERPROFILE\Miniconda3\Scripts;$env:PATH"
    }
}

# Function to create the conda environment
function New-CondaEnvironment {
    Write-Host "Creating conda environment '$ENV_NAME'..."
    # Create environment from yml file
    $ENV_FILE = Join-Path $PROJECT_ROOT "environment.yml"
    conda env create -f $ENV_FILE
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create environment from yml file"
        exit 1
    }
    Write-Host "Environment '$ENV_NAME' created successfully"
    
    # Activate the environment and install additional packages
    conda activate $ENV_NAME
    python -m pip install --upgrade pip
    python -m pip install setuptools wheel pybind11
}

# Function to activate the environment
function Activate-CondaEnvironment {
    Write-Host "Activating conda environment '$ENV_NAME'..."
    # Check if the environment exists
    $envExists = conda env list | Select-String "^$ENV_NAME\s"
    if (!$envExists) {
        Write-Host "Environment '$ENV_NAME' not found. Creating it..."
        New-CondaEnvironment
    }
    conda activate $ENV_NAME
}

# Function to remove the conda environment
function Remove-CondaEnvironment {
    Write-Host "Removing conda environment '$ENV_NAME'..."
    conda env remove -n $ENV_NAME -y
}

# Main script
switch ($args[0]) {
    "create" {
        Initialize-Conda
        Remove-CondaEnvironment
        New-CondaEnvironment
    }
    "clean" {
        Initialize-Conda
        Remove-CondaEnvironment
    }
    "activate" {
        Initialize-Conda
        Activate-CondaEnvironment
    }
    default {
        Write-Host "Usage: $($MyInvocation.MyCommand.Name) {create|clean|activate}"
        Write-Host "  create  - Create a fresh conda environment"
        Write-Host "  clean   - Remove the conda environment"
        Write-Host "  activate - Activate the conda environment"
        exit 1
    }
}
