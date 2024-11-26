# Enable testing
enable_testing()

# Find GTest package
find_package(GTest REQUIRED)

# Add test executable
add_executable(test_core test_core.cpp)

# Link against Google Test and our core library
target_link_libraries(test_core 
    PRIVATE 
    GTest::gtest
    GTest::gtest_main
    core_lib
)

# Add test to CTest
add_test(NAME CoreTest COMMAND test_core)

# Set include directories
target_include_directories(test_core
    PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/core
)
