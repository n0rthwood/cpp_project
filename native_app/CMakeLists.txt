cmake_minimum_required(VERSION 3.16)
project(native_app)

# Find required packages
find_package(OpenCV REQUIRED)
find_package(CUDA REQUIRED)
find_package(MMDeploy REQUIRED)

# Create executable
add_executable(native_app
    src/main.cpp
)

# Set include directories
target_include_directories(native_app
    PRIVATE
        ${OpenCV_INCLUDE_DIRS}
        ${CUDA_INCLUDE_DIRS}
)

# Link libraries
target_link_libraries(native_app
    PRIVATE
        js_lib
        ${OpenCV_LIBS}
        ${CUDA_LIBRARIES}
        mmdeploy
)

# Set output directories
set_target_properties(native_app PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
