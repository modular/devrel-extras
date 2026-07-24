from std.sys import has_accelerator

def main():
    comptime if has_accelerator():
        print("GPU detected")
        # Enable GPU processing
    else:
        print("No GPU detected")
        # Print error or fall back to CPU-only execution