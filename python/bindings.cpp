#include <pybind11/pybind11.h>
#include "../src/include/core_lib.hpp"

namespace py = pybind11;

PYBIND11_MODULE(py_core_lib, m) {
    m.doc() = "JoySort Core Library Python Bindings"; // Module docstring

    m.def("helloworld", &joysort::CoreLib::helloWorld, 
          "Print Hello World message using spdlog");
}
