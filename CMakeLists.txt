cmake_minimum_required(VERSION 3.15)

# Set policies before project() command
cmake_policy(SET CMP0074 NEW) # Use package_ROOT variables
if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW) # MSVC Runtime library flags
endif()
if(POLICY CMP0067)
    cmake_policy(SET CMP0067 NEW) # Honor language standard in try_compile()
endif()

project(cpp_project VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Platform-specific settings
if(WIN32)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    add_definitions(-D_WIN32_WINNT=0x0601)
    if(MSVC)
        # Use static runtime for Windows builds
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        # Enable multi-processor compilation
        add_compile_options(/MP /W4)
        # Disable specific warnings
        add_compile_options(/wd4251) # class needs to have dll-interface
    endif()
elseif(APPLE)
    # macOS specific settings
    set(CMAKE_MACOSX_RPATH ON)
    add_compile_options(-Wall -Wextra)
    # Ensure compatibility with older macOS versions
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15" CACHE STRING "Minimum OS X deployment version")
else()
    # Linux specific settings
    add_compile_options(-Wall -Wextra)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    # Add debug symbols in Release build
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g")
endif()

# Options
option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)
option(BUILD_TESTS "Build tests" OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

# Find required packages using vcpkg
find_package(spdlog CONFIG REQUIRED)
find_package(CURL CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(yaml-cpp CONFIG REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(cpprestsdk CONFIG REQUIRED)

# OpenSSL handling for different platforms
if(WIN32)
    # On Windows, prefer vcpkg-provided OpenSSL
    find_package(OpenSSL CONFIG REQUIRED)
else()
    # On Unix systems, try system OpenSSL first
    find_package(OpenSSL REQUIRED)
endif()

# Python bindings with platform-specific handling
if(BUILD_PYTHON_BINDINGS)
    # Find Python with platform-specific preferences
    if(WIN32)
        # On Windows, prefer Python from vcpkg
        find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
    else()
        # On Unix systems, try system Python first
        find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
    endif()
    
    find_package(pybind11 CONFIG REQUIRED)
endif()

# Add source directories
add_subdirectory(src)

if(BUILD_PYTHON_BINDINGS)
    add_subdirectory(python)
endif()

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Install targets with platform-specific settings
include(GNUInstallDirs)
install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)
