#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "sample.h"

namespace py = pybind11;

// Example function to test Python binding
int add(int a, int b) {
    return a + b;
}

PYBIND11_MODULE(cpp_ext, m) {
    m.doc() = "Python bindings for cpp_project"; // Module docstring
    
    m.def("add", &add, "Add two numbers",
          py::arg("a"), py::arg("b"));
    m.def("get_greeting", &get_greeting, "Get a greeting message",
          py::arg("name"));
}
