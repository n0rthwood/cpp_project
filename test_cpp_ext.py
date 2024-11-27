import sys
sys.path.append('/opt/workspace/cpp_project/build/python')

try:
    import cpp_ext
    
    # Test add function
    result = cpp_ext.add(5, 7)
    print(f"5 + 7 = {result}")
    
    # Test get_greeting function
    greeting = cpp_ext.get_greeting("World")
    print(f"Greeting: {greeting}")

except ImportError as e:
    print(f"Import error: {e}")
except Exception as e:
    print(f"Error: {e}")
