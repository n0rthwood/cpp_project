cmake_minimum_required(VERSION 3.16)
project(cpp_project VERSION 1.0.0)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directories for all targets
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Set MMDeploy and dependency paths
set(MMDEPLOY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/mmdeploy/mmdeploy-1.1.0-linux-x86_64-cxx11abi-cuda11.3)
set(TENSORRT_DIR ${MMDEPLOY_DIR}/thirdparty/tensorrt)
set(ONNXRUNTIME_DIR ${MMDEPLOY_DIR}/thirdparty/onnxruntime)
list(APPEND CMAKE_PREFIX_PATH ${MMDEPLOY_DIR})

# Find CUDA
find_package(CUDA 11.3 REQUIRED)
include_directories(${CUDA_INCLUDE_DIRS})

# Set CUDA runtime library path
link_directories(${CUDA_TOOLKIT_ROOT_DIR}/lib64)

# Add subdirectories
add_subdirectory(js_lib)
add_subdirectory(native_app)
