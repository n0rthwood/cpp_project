#include "js_lib/logger.h"
#include <iostream>

int main() {
    js_lib::Logger logger;
    
    std::cout << "Testing js_lib logger..." << std::endl;
    logger.log("Hello from native application!");
    
    return 0;
}
