#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "js_lib/logger.h"

namespace py = pybind11;

PYBIND11_MODULE(js_ext, m) {
    m.doc() = "Python bindings for js_lib"; // Module docstring
    
    // Expose the Logger class
    py::class_<js_lib::Logger>(m, "Logger")
        .def(py::init<>())  // Expose constructor
        .def("log", &js_lib::Logger::log, "Log a message");
}
