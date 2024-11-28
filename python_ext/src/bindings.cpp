#include <pybind11/pybind11.h>
#include "js_lib/logger.h"

namespace py = pybind11;

PYBIND11_MODULE(py_core_lib, m) {
    m.doc() = "Python bindings for js_lib"; // optional module docstring
    
    // Add bindings here
    py::class_<js_lib::Logger>(m, "Logger")
        .def(py::init<>())
        .def("log", &js_lib::Logger::log);
}
