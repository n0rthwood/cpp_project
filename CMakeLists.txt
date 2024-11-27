cmake_minimum_required(VERSION 3.15)

# Set policies before project() command
cmake_policy(SET CMP0074 NEW) # Use package_ROOT variables
if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW) # Boost policy
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
        add_compile_options(/W4 /MP)
    endif()
elseif(APPLE)
    add_compile_options(-Wall -Wextra)
    set(CMAKE_MACOSX_RPATH ON)
else()
    add_compile_options(-Wall -Wextra)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Options
option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)
option(BUILD_TESTS "Build tests" OFF)

# Find required packages using vcpkg
find_package(spdlog CONFIG REQUIRED)
find_package(CURL CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(yaml-cpp CONFIG REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(cpprestsdk CONFIG REQUIRED)  # For REST API
find_package(OpenSSL CONFIG REQUIRED)

# Python bindings
if(BUILD_PYTHON_BINDINGS)
    find_package(Python 3.8 COMPONENTS Interpreter Development REQUIRED)
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

# Install targets
install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION lib/cmake/${PROJECT_NAME}
)
