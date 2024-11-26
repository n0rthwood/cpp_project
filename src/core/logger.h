#pragma once

#include <string>

namespace core {

class Logger {
public:
    Logger();
    void log(const std::string& message);
};

} // namespace core
