cmake_minimum_required(VERSION 3.16)
project(js_lib)

# Find required packages
find_package(OpenCV REQUIRED)
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)
find_package(MMDeploy REQUIRED)

# Include FetchContent for downloading tabulate
include(FetchContent)

# Download tabulate
FetchContent_Declare(
    tabulate
    GIT_REPOSITORY https://github.com/p-ranav/tabulate.git
    GIT_TAG v1.4
)
FetchContent_MakeAvailable(tabulate)

# Create the library
add_library(js_lib
    src/mm_processor.cpp
)

# Set library properties
set_target_properties(js_lib PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    PUBLIC_HEADER "include/js_lib/mm_processor.h"
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

# Set output directories
set_target_properties(js_lib PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

if(MSVC)
    set_property(TARGET js_lib PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
    )
endif()

# Set include directories
target_include_directories(js_lib 
    PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
        ${OpenCV_INCLUDE_DIRS}
        ${CUDA_INCLUDE_DIRS}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Link libraries
target_link_libraries(js_lib
    PUBLIC
        ${OpenCV_LIBS}
        cudart
        fmt::fmt
        spdlog::spdlog
        tabulate::tabulate
        mmdeploy
)

# Install
install(TARGETS js_lib
    EXPORT ${PROJECT_NAME}Targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include/js_lib
)
