# PowerShell script for downloading and managing third-party dependencies

function Download-ThirdPartyDep {
    param (
        [string]$Name,
        [string]$Url,
        [string]$TargetDir,
        [string]$Sha256,
        [string]$ExtractDir
    )

    $tempFile = Join-Path $env:TEMP "$Name.zip"
    Write-Host "Downloading $Name from $Url..."

    try {
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download $Name from $Url"
        Write-Error $_.Exception.Message
        return $false
    }

    # Verify SHA256 if provided
    if ($Sha256) {
        $hash = Get-FileHash -Path $tempFile -Algorithm SHA256
        if ($hash.Hash -ne $Sha256) {
            Write-Error "SHA256 verification failed for $Name"
            Write-Error "Expected: $Sha256"
            Write-Error "Got: $($hash.Hash)"
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            return $false
        }
    }

    # Create target directory if it doesn't exist
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    }

    # Extract
    Write-Host "Extracting $Name to $TargetDir..."
    try {
        Expand-Archive -Path $tempFile -DestinationPath $TargetDir -Force
        
        # If extract_dir is specified, move contents up
        if ($ExtractDir) {
            $extractPath = Join-Path $TargetDir $ExtractDir
            if (Test-Path $extractPath) {
                $tempDir = Join-Path $TargetDir "_temp"
                Move-Item -Path $extractPath\* -Destination $tempDir
                Remove-Item -Path $extractPath -Recurse
                Move-Item -Path $tempDir\* -Destination $TargetDir
                Remove-Item -Path $tempDir
            }
        }
    }
    catch {
        Write-Error "Failed to extract $Name"
        Write-Error $_.Exception.Message
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        return $false
    }

    # Cleanup
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    return $true
}

# Main function to install all third-party dependencies
function Install-ThirdPartyDeps {
    param (
        [string]$ConfigFile,
        [string]$BuildDir
    )

    # Check if PowerShell version supports automatic YAML parsing
    $yamlSupport = Get-Module -ListAvailable -Name "powershell-yaml"
    if (-not $yamlSupport) {
        Write-Host "Installing PowerShell YAML module..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }

    # Import YAML module
    Import-Module powershell-yaml

    # Read and parse YAML config
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Yaml
    }
    catch {
        Write-Error "Failed to parse config file: $ConfigFile"
        Write-Error $_.Exception.Message
        exit 1
    }

    $thirdpartyDir = Join-Path $BuildDir "thirdparty"
    New-Item -ItemType Directory -Force -Path $thirdpartyDir | Out-Null

    # Get platform-specific dependencies
    $platform = "windows"  # Since this is the PowerShell script, we're on Windows
    $deps = $config.dependencies.$platform

    # Download and extract each dependency
    foreach ($dep in $deps.GetEnumerator()) {
        $name = $dep.Key
        $info = $dep.Value
        $targetDir = Join-Path $thirdpartyDir $name

        Write-Host "Processing $name version $($info.version)..."

        # Skip if already installed and not forced
        if (Test-Path $targetDir) {
            Write-Host "$name already installed at $targetDir"
            continue
        }

        # Get platform-specific URL and SHA256
        $url = if ($info.urls) { $info.urls.$platform } else { $info.url }
        $sha256 = if ($info.sha256) { $info.sha256.$platform }

        # Download and install
        $success = Download-ThirdPartyDep -Name $name -Url $url -TargetDir $targetDir -Sha256 $sha256 -ExtractDir $info.extract_dir
        if (!$success) {
            Write-Error "Failed to install $name"
            exit 1
        }

        Write-Host "$name installed successfully"
    }
}

# Get the directory containing this script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# Call the main function
Install-ThirdPartyDeps -ConfigFile (Join-Path $projectRoot "thirdparty_deps.yaml") -BuildDir $projectRoot
