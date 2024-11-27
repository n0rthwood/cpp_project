cmake_minimum_required(VERSION 3.16)

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
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

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
    # Add debug symbols in Release build
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g")
endif()

# Options
option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)
option(BUILD_TESTS "Build tests" OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

# Find required packages using vcpkg
find_package(CURL CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(yaml-cpp CONFIG REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(cpprestsdk CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)

# Find pthread package
find_package(Threads REQUIRED)

# Python support
option(WITH_PYTHON "Build Python bindings" OFF)

if(WITH_PYTHON)
    # Platform-specific Python configuration
    if(WIN32)
        # Windows-specific Python settings
        if(DEFINED ENV{CONDA_PREFIX})
            set(Python3_EXECUTABLE "$ENV{CONDA_PREFIX}/python.exe")
        else()
            set(Python3_EXECUTABLE "C:/Python38/python.exe")  # Default Windows Python location
        endif()
    elseif(APPLE)
        # macOS-specific Python settings
        if(DEFINED ENV{CONDA_PREFIX})
            set(Python3_EXECUTABLE "$ENV{CONDA_PREFIX}/bin/python")
        else()
            set(Python3_EXECUTABLE "/usr/local/opt/python@3.8/bin/python3.8")  # Homebrew Python location
        endif()
    else()
        # Linux-specific Python settings
        if(DEFINED ENV{CONDA_PREFIX})
            set(Python3_EXECUTABLE "$ENV{CONDA_PREFIX}/bin/python")
        else()
            # Check for common Linux Python locations
            if(EXISTS "/opt/miniconda3/envs/cpp_project_env/bin/python")
                set(Python3_EXECUTABLE "/opt/miniconda3/envs/cpp_project_env/bin/python")
            elseif(EXISTS "/usr/bin/python3.8")
                set(Python3_EXECUTABLE "/usr/bin/python3.8")
            else()
                message(FATAL_ERROR "Python 3.8 not found in expected locations. Please specify Python3_EXECUTABLE.")
            endif()
        endif()
    endif()

    # Explicitly set Python include directories
    set(Python3_INCLUDE_DIRS "/opt/miniconda3/envs/cpp_project_env/include/python3.8")
    set(Python3_LIBRARIES "/opt/miniconda3/envs/cpp_project_env/lib/libpython3.8.so")

    # Find Python3 with Development headers
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    
    message(STATUS "Python executable: ${Python3_EXECUTABLE}")
    message(STATUS "Python include dirs: ${Python3_INCLUDE_DIRS}")
    message(STATUS "Python libraries: ${Python3_LIBRARIES}")
    
    # Find pybind11 with explicit configuration
    find_package(pybind11 CONFIG REQUIRED)
    
    # Add Python extension module with explicit include and link directories
    add_library(cpp_ext MODULE 
        src/python/cpp_ext.cpp
    )
    
    # Set Python extension module properties
    set_target_properties(cpp_ext PROPERTIES
        PREFIX ""
        SUFFIX ".so"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/python"
    )
    
    # Include Python headers and link against Python libraries
    target_include_directories(cpp_ext PRIVATE 
        ${Python3_INCLUDE_DIRS}
    )
    
    target_link_libraries(cpp_ext PRIVATE 
        pybind11::module
        ${Python3_LIBRARIES}
        project_lib
    )
endif()

if(Threads_FOUND)
    message(STATUS "Threads found: ${CMAKE_THREAD_LIBS_INIT}")
endif()

# Library target
add_library(project_lib STATIC
    src/lib/sample.cpp
)

target_include_directories(project_lib
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(project_lib
    PUBLIC
        CURL::libcurl
        spdlog::spdlog
        nlohmann_json::nlohmann_json
        yaml-cpp
        ${OpenCV_LIBS}
        cpprestsdk::cpprest
        OpenSSL::SSL
        OpenSSL::Crypto
    PRIVATE
        Threads::Threads
)

if(WITH_PYTHON)
    #target_link_libraries(cpp_ext PRIVATE project_lib)
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
