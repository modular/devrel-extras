from std.sys import has_accelerator

def main():
    comptime if has_accelerator():
        print("GPU path")
    else:
        # Else GPU branch is never compiled into binary
        print("CPU path")