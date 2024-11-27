set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/custom-toolchain.cmake")

if(PORT MATCHES "opencv4|boost|qt5-base")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

# Use the newer baseline for macOS
set(VCPKG_MANIFEST_OVERRIDE "{
    \"builtin-baseline\": \"068d45478f5536589e19f83344749379724b3225\"
}")
