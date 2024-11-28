#pragma once

#include <string>

namespace js_lib {

class Logger {
public:
    Logger();
    void log(const std::string& message);
};

} // namespace js_lib
