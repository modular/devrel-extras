# factor is defined at compile time and x at run time
def multiplier[factor: Int](x: Int) -> Int:
    return x * factor

# compare to def multiplier(factor: Int, x: Int) -> Int:

def main():
    # times_ten is a specialized function defined at compile time
    comptime times_ten = multiplier[10]
    
    # these variables call the function with runtime arguments
    var three_times_ten = times_ten(3)
    var ten_times_ten = times_ten(10)
    print("three times ten", three_times_ten)
    print("ten times ten", ten_times_ten)