# PowerShell script for Windows, but also works on Linux/macOS with pwsh
param(
    [switch]$Clean,
    [switch]$Release,
    [switch]$Debug,
    [switch]$Install,
    [switch]$Package,
    [switch]$ForceRecreateEnv
)

# Error handling
$ErrorActionPreference = "Stop"

# Get script directory
$SCRIPT_DIR = $PSScriptRoot

# Determine OS
$IS_WINDOWS = $env:OS -eq "Windows_NT"
$IS_LINUX = $IsLinux
$IS_MACOS = $IsMacOS

# Get number of CPU cores for parallel build
$NUM_CORES = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# Function to compute configuration hash
function Get-ConfigHash {
    $configContent = Get-Content "$SCRIPT_DIR/vcpkg.json" -Raw
    $vcpkgRoot = if ($env:VCPKG_ROOT) { $env:VCPKG_ROOT } else { "" }
    $vsInstall = if ($IS_WINDOWS -and $env:VSINSTALLDIR) { $env:VSINSTALLDIR } else { "" }
    
    $hashInput = "${configContent}|${vcpkgRoot}|${vsInstall}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($hashInput)
    $stream = [System.IO.MemoryStream]::new($bytes)
    $hash = Get-FileHash -InputStream $stream -Algorithm SHA256
    $stream.Dispose()
    return $hash.Hash
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

# Setup vcpkg if not already set up
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

# Set CMake toolchain file and vcpkg settings
$env:CMAKE_TOOLCHAIN_FILE = Join-Path $env:VCPKG_ROOT "scripts/buildsystems/vcpkg.cmake"
$env:VCPKG_OVERLAY_TRIPLETS = Join-Path $SCRIPT_DIR "triplets"

# Create build directory
$BUILD_DIR = Join-Path $SCRIPT_DIR "build"
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null

# Determine build type
$BUILD_TYPE = if ($Debug) { "Debug" } else { "Release" }

# Clean build if requested
if ($Clean) {
    Remove-Item -Path (Join-Path $BUILD_DIR "*") -Recurse -Force
}

# Setup Python environment if on Windows
if ($IS_WINDOWS) {
    # Find conda base path
    $ENV_NAME = "cpp_project_env"
    $condaPath = if (Test-Path "$env:USERPROFILE\Miniconda3") {
        "$env:USERPROFILE\Miniconda3"
    } elseif (Test-Path "$env:USERPROFILE\anaconda3") {
        "$env:USERPROFILE\anaconda3"
    } else {
        Write-Error "Conda installation not found"
        exit 1
    }
    
    # Check if environment exists
    $envExists = & "$condaPath\Scripts\conda.exe" env list | Select-String "^$ENV_NAME\s"
    if (-not $envExists -or $ForceRecreateEnv) {
        Write-Host "Creating Python environment..."
        & "$SCRIPT_DIR/scripts/python_env_manage.ps1" create
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to set up Python environment"
            exit 1
        }
    } else {
        Write-Host "Using existing Python environment '$ENV_NAME'"
    }
    
    # Construct environment path (using forward slashes for CMake compatibility)
    $envPath = "$condaPath/envs/$ENV_NAME".Replace('\', '/')
    if (-not (Test-Path $envPath)) {
        Write-Error "Conda environment '$ENV_NAME' not found at $envPath"
        exit 1
    }
    
    # Set environment variables for CMake to find Python (using forward slashes)
    $env:Python3_EXECUTABLE = "$envPath/python.exe".Replace('\', '/')
    $env:Python3_INCLUDE_DIRS = "$envPath/include".Replace('\', '/')
    $env:Python3_LIBRARIES = "$envPath/libs/python38.lib".Replace('\', '/')
    
    Write-Host "Using Python paths:"
    Write-Host "  Executable: $env:Python3_EXECUTABLE"
    Write-Host "  Include dirs: $env:Python3_INCLUDE_DIRS"
    Write-Host "  Libraries: $env:Python3_LIBRARIES"
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
    
    Write-Host "Using custom triplets from: $env:VCPKG_OVERLAY_TRIPLETS"
    
    # Configure with CMake
    $cmakeArgs = @(
        "-B", $BUILD_DIR,
        "-S", $SCRIPT_DIR,
        "-DCMAKE_TOOLCHAIN_FILE=$env:CMAKE_TOOLCHAIN_FILE",
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE",
        "-DVCPKG_MANIFEST_MODE=ON",
        "-DVCPKG_INSTALLED_DIR=$(Join-Path $BUILD_DIR 'vcpkg_installed')",
        "-DBUILD_PYTHON_BINDINGS=ON"
    )
    
    # Add platform-specific arguments and triplets
    if ($IS_WINDOWS) {
        $cmakeArgs += @(
            "-DVCPKG_TARGET_TRIPLET=x64-windows-custom",
            "-DVCPKG_OVERLAY_TRIPLETS=$env:VCPKG_OVERLAY_TRIPLETS"
        )
    } elseif ($IS_MACOS) {
        $cmakeArgs += @("-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15")
        if (Test-Path (Join-Path $SCRIPT_DIR "triplets/x64-osx-custom.cmake")) {
            $cmakeArgs += @(
                "-DVCPKG_TARGET_TRIPLET=x64-osx-custom",
                "-DVCPKG_OVERLAY_TRIPLETS=$env:VCPKG_OVERLAY_TRIPLETS"
            )
        }
    } elseif ($IS_LINUX) {
        if (Test-Path (Join-Path $SCRIPT_DIR "triplets/x64-linux-custom.cmake")) {
            $cmakeArgs += @(
                "-DVCPKG_TARGET_TRIPLET=x64-linux-custom",
                "-DVCPKG_OVERLAY_TRIPLETS=$env:VCPKG_OVERLAY_TRIPLETS"
            )
        }
    }
    
    & cmake $cmakeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "CMake configuration failed"
        exit 1
    }
    
    # Update hash
    Get-ConfigHash | Set-Content (Join-Path $BUILD_DIR ".config_hash")
} else {
    Write-Host "No changes in configuration, using existing build..."
}

# Build the project
Write-Host "Building project..."
$buildArgs = @(
    "--build", $BUILD_DIR,
    "--config", $BUILD_TYPE,
    "--parallel", $NUM_CORES
)
& cmake $buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Package release artifacts if requested
if ($Package -and $IS_WINDOWS) {
    Write-Host "Packaging release artifacts..."
    $RELEASE_DIR = Join-Path $SCRIPT_DIR "release"
    New-Item -ItemType Directory -Force -Path $RELEASE_DIR | Out-Null

    # Package core library
    $LIB_DIR = Join-Path $BUILD_DIR "lib"
    if (Test-Path $LIB_DIR) {
        $INCLUDE_DIR = Join-Path $BUILD_DIR "include"
        New-Item -ItemType Directory -Force -Path $INCLUDE_DIR | Out-Null
        Copy-Item (Join-Path $SCRIPT_DIR "src/include/*.hpp") $INCLUDE_DIR
        
        Push-Location $BUILD_DIR
        tar -czf (Join-Path $RELEASE_DIR "core_lib.tar.gz") `
            (Join-Path "lib" "core_lib.dll") `
            (Join-Path "include" "*.hpp")
        Pop-Location
    }

    # Package main application
    $MAIN_APP = Join-Path $BUILD_DIR "bin/main_app.exe"
    if (Test-Path $MAIN_APP) {
        Push-Location (Join-Path $BUILD_DIR "bin")
        tar -czf (Join-Path $RELEASE_DIR "main_app.tar.gz") "main_app.exe"
        Pop-Location
    }

    # Package Python bindings
    $PYTHON_DIR = Join-Path $BUILD_DIR "python"
    if (Test-Path $PYTHON_DIR) {
        Push-Location $PYTHON_DIR
        tar -czf (Join-Path $RELEASE_DIR "python_bindings.tar.gz") "*.pyd"
        Pop-Location
    }
}

# Install if requested
if ($Install) {
    Write-Host "Installing..."
    & cmake --install $BUILD_DIR
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Installation failed"
        exit 1
    }
}

Write-Host "Build completed successfully!"
