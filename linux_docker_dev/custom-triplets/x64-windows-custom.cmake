set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_BUILD_TYPE release)

# Use dynamic linking for all libraries
set(VCPKG_CMAKE_SYSTEM_NAME Windows)

# Set Python paths
if(DEFINED ENV{CONDA_PREFIX})
    set(Python_ROOT_DIR "$ENV{CONDA_PREFIX}")
    set(Python_EXECUTABLE "$ENV{CONDA_PREFIX}/python.exe")
endif()
