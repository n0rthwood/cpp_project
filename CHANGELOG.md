# Changelog

## [0.1.0] - 2024-11-27
### Added
- Python extension module `cpp_ext` with pybind11
- Two initial Python binding functions:
  * `add(a, b)`: Simple integer addition
  * `get_greeting(name)`: Returns a greeting message with logging
- Test script `test_cpp_ext.py` for Python extension validation

### Changed
- CMakeLists.txt updated to support Python extension
  * Added explicit pthread support
  * Configured Python include and library paths
  * Updated Python module build configuration
- Refined build system for cross-platform compatibility

### Fixed
- Resolved module naming issues between CMake and pybind11
- Improved dependency management and path detection

### Dependencies
- pybind11 (version 2.10.3)
- spdlog (version 1.11.0)
- Python 3.8

### Notes
- Boost dependency warnings present (non-blocking)
- Cross-platform configuration improvements ongoing
