#include "js_lib/logger.h"
#include <spdlog/spdlog.h>

namespace js_lib {

Logger::Logger() {
    spdlog::set_pattern("[%H:%M:%S %z] [%^%L%$] [thread %t] %v");
    spdlog::set_level(spdlog::level::debug);
}

void Logger::log(const std::string& message) {
    spdlog::info(message);
}

} // namespace js_lib
