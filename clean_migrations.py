import os
import glob

base_dir = r"c:\Users\Naresh\OneDrive\Desktop\buspass"
apps = ['passes', 'users', 'routes']

for app in apps:
    path = os.path.join(base_dir, app, 'migrations', '*.py')
    for py_file in glob.glob(path):
        if not py_file.endswith('__init__.py'):
            os.remove(py_file)
            print(f"Removed {py_file}")
