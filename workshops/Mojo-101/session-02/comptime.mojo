
def main():
    # A comptime value is computed before the program runs
    comptime size = 1024 // 32
    print(size)
    
    # You can use a comptime value as as a type alias
    comptime Float16 = SIMD[DType.float16, 1]
    comptime UInt8 = SIMD[DType.uint8, 1]

    var x: Float16 = 0  # Float16 works like a "typedef"
    print(x)