import sys
import os

# Add the build directory to Python path using absolute path
build_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "build", "python"))
print(f"Looking for extension in: {build_dir}")
sys.path.insert(0, build_dir)

# Import our extension
from _cpp_ext import get_greeting

# Test the extension
print(get_greeting("World"))
