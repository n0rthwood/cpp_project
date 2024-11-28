set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

if(PORT MATCHES "opencv4|boost|qt5-base")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

# Use the same baseline as other platforms
set(VCPKG_MANIFEST_OVERRIDE "{
    \"builtin-baseline\": \"068d45478f5536589e19f83344749379724b3225\"
}")
