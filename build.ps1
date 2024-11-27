# PowerShell script for Windows, but also works on Linux/macOS with pwsh
param(
    [switch]$Clean,
    [switch]$Release,
    [switch]$Debug,
    [switch]$Install
)

# Error handling
$ErrorActionPreference = "Stop"

# Get script directory
$SCRIPT_DIR = $PSScriptRoot

# Determine OS
$IS_WINDOWS = $env:OS -eq "Windows_NT"
$IS_LINUX = $IsLinux
$IS_MACOS = $IsMacOS

# Function to compute configuration hash
function Get-ConfigHash {
    $hashInput = @(
        Get-Content "$SCRIPT_DIR/vcpkg.json" -Raw
        $env:VCPKG_ROOT
        if ($IS_WINDOWS) { $env:VSINSTALLDIR } else { "" }
    ) -join "|"
    
    return ($hashInput | Get-FileHash -Algorithm SHA256).Hash
}

# Function to check if reconfiguration is needed
function Should-Reconfigure {
    $hashFile = Join-Path $SCRIPT_DIR "build/.config_hash"
    if (-not (Test-Path $hashFile)) { return $true }
    
    $currentHash = Get-ConfigHash
    $savedHash = Get-Content $hashFile -Raw
    return $currentHash -ne $savedHash
}

# Prepare environment based on OS
if ($IS_LINUX) {
    & "$SCRIPT_DIR/scripts/linux_env_prepare.sh"
} elseif ($IS_MACOS) {
    if (Test-Path "$SCRIPT_DIR/scripts/macos_env_prepare.sh") {
        & "$SCRIPT_DIR/scripts/macos_env_prepare.sh"
    }
} elseif ($IS_WINDOWS) {
    if (Test-Path "$SCRIPT_DIR/scripts/windows_env_prepare.ps1") {
        & "$SCRIPT_DIR/scripts/windows_env_prepare.ps1"
    }
}

# Detect OS and select appropriate vcpkg config
if ($IsMacOS) {
    $vcpkgConfig = "vcpkg.macos.json"
}
elseif ($IsLinux) {
    $vcpkgConfig = "vcpkg.linux.json"
}
else {
    $vcpkgConfig = "vcpkg.windows.json"
}

# Copy appropriate vcpkg config
Copy-Item $vcpkgConfig vcpkg.json

# Setup vcpkg
if (-not $env:VCPKG_ROOT) {
    $vcpkgPaths = @(
        "/opt/vcpkg",
        (Join-Path $SCRIPT_DIR "../vcpkg"),
        (Join-Path $SCRIPT_DIR "vcpkg")
    )
    
    foreach ($path in $vcpkgPaths) {
        if (Test-Path $path) {
            $env:VCPKG_ROOT = $path
            break
        }
    }
    
    if (-not $env:VCPKG_ROOT) {
        Write-Host "vcpkg not found. Installing..."
        git clone https://github.com/Microsoft/vcpkg.git (Join-Path $SCRIPT_DIR "vcpkg")
        if ($IS_WINDOWS) {
            & (Join-Path $SCRIPT_DIR "vcpkg/bootstrap-vcpkg.bat") -disableMetrics
        } else {
            & (Join-Path $SCRIPT_DIR "vcpkg/bootstrap-vcpkg.sh") -disableMetrics
        }
        $env:VCPKG_ROOT = Join-Path $SCRIPT_DIR "vcpkg"
    }
}

# Set CMake toolchain file
$env:CMAKE_TOOLCHAIN_FILE = Join-Path $env:VCPKG_ROOT "scripts/buildsystems/vcpkg.cmake"

# Create build directory
$BUILD_DIR = Join-Path $SCRIPT_DIR "build"
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null

# Determine build type
$BUILD_TYPE = if ($Debug) { "Debug" } else { "Release" }

# Clean build if requested
if ($Clean) {
    Remove-Item -Path (Join-Path $BUILD_DIR "*") -Recurse -Force
}

# Configure if needed
if (Should-Reconfigure) {
    Write-Host "Changes detected in configuration, reconfiguring..."
    
    # Preserve hash file if it exists
    $hashFile = Join-Path $BUILD_DIR ".config_hash"
    $hashBackup = if (Test-Path $hashFile) { Get-Content $hashFile -Raw } else { $null }
    
    # Clean build directory
    Remove-Item -Path (Join-Path $BUILD_DIR "*") -Recurse -Force
    
    # Restore hash file
    if ($hashBackup) {
        $hashBackup | Set-Content $hashFile
    }
    
    # Configure with CMake
    $cmakeArgs = @(
        "-B", $BUILD_DIR,
        "-S", $SCRIPT_DIR,
        "-DCMAKE_TOOLCHAIN_FILE=$env:CMAKE_TOOLCHAIN_FILE",
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE",
        "-DVCPKG_MANIFEST_MODE=ON",
        "-DVCPKG_INSTALLED_DIR=$(Join-Path $BUILD_DIR 'vcpkg_installed')"
    )
    
    # Add platform-specific arguments
    if ($IS_WINDOWS) {
        # Add Windows-specific CMake arguments here if needed
    } elseif ($IS_MACOS) {
        $cmakeArgs += @("-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15")
    }
    
    & cmake $cmakeArgs
    
    # Update hash
    Get-ConfigHash | Set-Content (Join-Path $BUILD_DIR ".config_hash")
} else {
    Write-Host "No changes in configuration, using existing build..."
}

# Build the project
$buildArgs = @(
    "--build", $BUILD_DIR,
    "--config", $BUILD_TYPE
)

if ($IS_WINDOWS) {
    $buildArgs += @("--parallel", $env:NUMBER_OF_PROCESSORS)
} else {
    $buildArgs += @("--parallel", (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors)
}

& cmake $buildArgs

# Install if requested
if ($Install) {
    & cmake --install $BUILD_DIR --config $BUILD_TYPE
}

# Clean up temporary vcpkg.json
Remove-Item vcpkg.json
