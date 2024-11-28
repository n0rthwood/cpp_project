import sys
import os

# Get the absolute paths
project_root = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(project_root, "build", "lib", "Release")
bin_path = os.path.join(project_root, "build", "bin", "Release")
vcpkg_bin_path = os.path.join(project_root, "build", "vcpkg_installed", "x64-windows-custom", "bin")

print(f"Looking for extension in: {lib_path}")
print(f"Looking for DLLs in: {bin_path}")
print(f"Looking for vcpkg DLLs in: {vcpkg_bin_path}")

# Add the DLL directories to the PATH
os.environ['PATH'] = os.pathsep.join([
    lib_path,
    bin_path,
    vcpkg_bin_path,
    os.environ.get('PATH', '')
])

# Add the library path to Python's path
if lib_path not in sys.path:
    sys.path.insert(0, lib_path)

try:
    import js_ext
    print(f"Successfully imported js_ext from {js_ext.__file__}")
    
    # Create a logger instance
    logger = js_ext.Logger()
    
    # Test logging
    print("\nTesting js_ext Python bindings...")
    logger.log("Hello from Python!")
    
    print("\nPython extension test completed successfully!")
    
except ImportError as e:
    print(f"Error importing js_ext: {e}")
    print(f"Python executable: {sys.executable}")
    print(f"Python version: {sys.version}")
    print(f"Python path: {sys.path}")
    print(f"System PATH: {os.environ['PATH']}")
    
    # List files in relevant directories
    for check_path in [lib_path, bin_path, vcpkg_bin_path]:
        if os.path.exists(check_path):
            files = os.listdir(check_path)
            print(f"\nFiles in {check_path}:")
            for f in files:
                print(f"  {f}")
        else:
            print(f"\nDirectory does not exist: {check_path}")
    sys.exit(1)
