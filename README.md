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

- `src/` - Core library and application source files
- `python/` - Python bindings
- `include/` - Public header files
- `build/` - Build artifacts
- `release/` - Release packages

## Output Artifacts

The build process generates several artifacts in the `release/` directory:
- `core_lib.tar.gz` - Shared library and headers
- `main_app.tar.gz` - Native application executable
- `python38_bindings.tar.gz` - Python 3.8 bindings
- `python39_bindings.tar.gz` - Python 3.9 bindings

## License

[Your License]
