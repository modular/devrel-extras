# Demonstrates Python Interop
from std.python import Python

def main() raises:
    var time = Python.import_module("time")
    var now = time.time()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(now)))
