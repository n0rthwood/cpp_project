add_executable(native_app
    src/main.cpp
)

target_link_libraries(native_app
    PRIVATE
        js_lib
)
