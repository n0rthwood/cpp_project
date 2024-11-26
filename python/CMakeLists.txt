# Python bindings for multiple Python versions
foreach(PY_VERSION "3.8" "3.9")
    find_package(Python ${PY_VERSION} EXACT COMPONENTS Interpreter Development Development.Module Development.Embed)
    if(Python_FOUND)
        set(MODULE_NAME "py_core_lib${Python_VERSION_MAJOR}${Python_VERSION_MINOR}")
        pybind11_add_module(${MODULE_NAME}
            bindings.cpp
        )

        # Link against core_lib
        target_link_libraries(${MODULE_NAME}
            PRIVATE
            core_lib
        )

        # Set Python module properties
        set_target_properties(${MODULE_NAME} PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/python"
            PREFIX ""
            OUTPUT_NAME "py_core_lib"
            SUFFIX ".so"
        )

        # Install Python module
        if(SKBUILD)
            # Installing for pip package
            install(TARGETS ${MODULE_NAME} DESTINATION .)
        else()
            # Installing for local development
            install(TARGETS ${MODULE_NAME}
                LIBRARY DESTINATION "${Python_SITEARCH}"
            )
        endif()

        # Create symbolic links for testing
        add_custom_command(TARGET ${MODULE_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/lib"
            COMMAND ${CMAKE_COMMAND} -E create_symlink 
                "${CMAKE_BINARY_DIR}/python/py_core_lib.so"
                "${CMAKE_BINARY_DIR}/lib/py_core_lib.so"
        )
    endif()
endforeach()

# Copy test script to build directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/test_joysort.py
     DESTINATION ${CMAKE_BINARY_DIR}/bin
     FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
