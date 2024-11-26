#include <gtest/gtest.h>
#include "core/logger.h"
#include "core_lib.hpp"

// Basic test case for logger
TEST(LoggerTest, HelloWorld) {
    // Call the function
    joysort::CoreLib coreLib;
    coreLib.helloWorld();
    
    // Since we're using spdlog, we can't easily capture the output
    // This test just verifies the function runs without crashing
    SUCCEED();
}

// Main function that runs all tests
int main(int argc, char **argv) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
