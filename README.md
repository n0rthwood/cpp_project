# C++ Project with Python Bindings

This project demonstrates a modern C++ application with Python bindings, featuring:

- Logging system using spdlog
- HTTP client using libcurl
- ZIP/Unzip functionality
- JSON parsing with nlohmann/json
- YAML parsing with yaml-cpp
- OpenCV integration
- AI inference using MMDeploy
- REST API with swagger integration using cpprestsdk
- Python bindings using pybind11 (Python 3.8 and 3.9 support)
- Package management using vcpkg

## Prerequisites

- CMake 3.15 or higher
- C++17 compatible compiler
- vcpkg package manager
- Python 3.8 or 3.9 with development headers
- Git

## Dependencies

All dependencies are managed through vcpkg:
- spdlog
- curl
- nlohmann-json
- yaml-cpp
- opencv4
- mmdeploy
- cpprestsdk
- openssl
- zlib
- pybind11

## Building

1. Clone the repository:
```bash
git clone [repository-url]
cd cpp_project
```

2. Install vcpkg and dependencies:
```bash
# Clone vcpkg
git clone https://github.com/Microsoft/vcpkg.git
./vcpkg/bootstrap-vcpkg.sh

# Install dependencies
./vcpkg/vcpkg install
```

3. Build the project:
```bash
# Make the build script executable
chmod +x build.sh

# Run the build script
./build.sh
```

The build script will:
- Configure and build the project
- Generate all artifacts
- Package them into separate release files

## Project Structure

### Core Components
- `src/` - Core library and application source files
- `python/` - Python bindings
- `include/` - Public header files
- `build/` - Build artifacts
- `release/` - Release packages

### Build System
- `build.ps1` - Main build script (PowerShell)
- `build.bat` - Windows batch wrapper for build.ps1
- `CMakeLists.txt` - CMake configuration
- `vcpkg.json` - Dependencies specification

### Environment Setup Scripts
Located in `scripts/`:
- `download_thirdparty.ps1/sh` - Downloads third-party packages not available in vcpkg
- `python_env_manage.ps1/sh` - Manages Python environment setup
- `windows_env_prepare.ps1` - Prepares Windows development environment
- `linux_env_prepare.sh` - Prepares Linux development environment
- `macos_env_prepare.sh` - Prepares macOS development environment

### Third-party Dependencies
- `thirdparty/` - Contains manually downloaded dependencies not available in vcpkg
- `thirdparty_deps.yaml` - Configuration for third-party dependencies
- Dependencies are managed through:
  1. vcpkg for most packages
  2. Manual downloads (via download_thirdparty scripts) for packages not in vcpkg

### Docker Development (Linux)
Located in `linux_docker_dev/`:
- Contains Docker configuration and scripts for Linux development
- Includes remote development setup scripts

## Output Artifacts

The build process generates several artifacts in the `release/` directory:
- `core_lib.tar.gz` - Shared library and headers
- `main_app.tar.gz` - Native application executable
- `python38_bindings.tar.gz` - Python 3.8 bindings
- `python39_bindings.tar.gz` - Python 3.9 bindings

## Remote Development Environment

This project includes a robust remote development environment using Docker containers. The environment is designed to provide a consistent development experience across different machines and platforms.

### Prerequisites

1. SSH access to the remote development server
2. Docker and Docker Compose installed on the remote server
3. SSH key-based authentication set up on your local machine

### Directory Structure

```
linux_docker_dev/
├── Dockerfile           # Container configuration
├── docker-compose.yml  # Service definitions
├── dev_env.sh         # Environment management script
└── setup-ssh.sh       # SSH configuration script
```

### Environment Features

- Ubuntu 22.04 LTS base image
- GCC/G++ compiler suite
- CMake build system
- Python 3 with pip
- Non-root user setup
- SSH server for remote access
- Persistent workspace volume

### Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd cpp_project
   ```

2. Configure Remote Access:
   - Ensure your SSH public key is added to the remote server
   - Update the `REMOTE_HOST` variable in `linux_docker_dev/dev_env.sh` if needed

3. Start the Development Environment:
   ```bash
   ./linux_docker_dev/dev_env.sh start
   ```

4. Connect to the Development Container:
   ```bash
   ./linux_docker_dev/dev_env.sh ssh
   ```

### Available Commands

The `dev_env.sh` script provides several commands:

- `start`: Start the development environment
- `stop`: Stop the development environment
- `ssh`: Connect to the development container
- `status`: Show environment status
- `clean`: Clean up Docker resources

### Usage Example

1. Start the environment:
   ```bash
   ./linux_docker_dev/dev_env.sh start
   ```

2. Connect to the container:
   ```bash
   ./linux_docker_dev/dev_env.sh ssh
   ```

3. Inside the container, your workspace is mounted at `/workspace`:
   ```bash
   cd /workspace
   ./build.sh
   ```

4. When finished, stop the environment:
   ```bash
   ./linux_docker_dev/dev_env.sh stop
   ```

### Troubleshooting

1. If you can't connect to the container:
   - Check if the container is running: `./linux_docker_dev/dev_env.sh status`
   - Ensure SSH keys are properly set up
   - Try cleaning up and restarting: `./linux_docker_dev/dev_env.sh clean && ./linux_docker_dev/dev_env.sh start`

2. If the build fails:
   - Verify all dependencies are installed
   - Check if the workspace is properly mounted
   - Review build logs for specific errors

### Security Considerations

- The development container runs with a non-root user
- SSH access is key-based only
- Root login is disabled
- Container has minimal installed packages
- Workspace permissions are properly set

### Best Practices

1. Always use the provided scripts to manage the environment
2. Keep your SSH keys secure
3. Regularly update the base image and dependencies
4. Use version control for all project files
5. Back up important data outside the container

## License

[Your License]
