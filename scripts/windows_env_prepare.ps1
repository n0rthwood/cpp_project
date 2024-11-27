# Windows environment preparation script
param(
    [switch]$Force
)

# Check if environment is already prepared
$ENV_PREPARED_FLAG = ".windows_env_prepared"
if ((Test-Path $ENV_PREPARED_FLAG) -and -not $Force) {
    Write-Host "Windows environment already prepared. Use -Force to prepare again."
    exit 0
}

# Function to check if a command exists
function Test-Command($Command) {
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Check for Visual Studio
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vsWhere)) {
    Write-Host "Visual Studio not found. Please install Visual Studio 2019 or later with C++ workload."
    exit 1
}

$vsPath = & $vsWhere -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath
if (-not $vsPath) {
    Write-Host "Visual Studio C++ workload not found. Please install it."
    exit 1
}

# Check for Windows SDK
$sdkPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0" -ErrorAction SilentlyContinue
if (-not $sdkPath) {
    Write-Host "Windows SDK not found. Please install it from Visual Studio Installer."
    exit 1
}

# Check for Git
if (-not (Test-Command "git")) {
    Write-Host "Git not found. Installing..."
    winget install --id Git.Git -e --source winget
}

# Check for CMake
if (-not (Test-Command "cmake")) {
    Write-Host "CMake not found. Installing..."
    winget install --id Kitware.CMake -e --source winget
}

# Check for Python
if (-not (Test-Command "python")) {
    Write-Host "Python not found. Installing..."
    winget install --id Python.Python.3.10 -e --source winget
}

# Create flag file to indicate environment is prepared
New-Item -ItemType File -Force -Path $ENV_PREPARED_FLAG | Out-Null

Write-Host "Windows development environment prepared successfully!"
