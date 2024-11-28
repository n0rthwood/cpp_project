pybind11_add_module(js_ext 
    src/cpp_ext.cpp
)

target_link_libraries(js_ext
    PRIVATE
        js_lib
)

# Set platform-specific output settings
if(WIN32)
    set_target_properties(js_ext PROPERTIES
        SUFFIX ".pyd"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/$<CONFIG>"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/$<CONFIG>"
    )
else()
    set_target_properties(js_ext PROPERTIES
        SUFFIX ".so"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/$<CONFIG>"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/$<CONFIG>"
    )
endif()

# Add post-build command to copy js_lib.dll to the Python extension directory
add_custom_command(TARGET js_ext POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:js_lib>"
        "$<TARGET_FILE_DIR:js_ext>"
    COMMENT "Copying js_lib.dll to Python extension directory"
)
