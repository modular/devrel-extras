from std.collections import InlineArray

def main():
    # InlineArray has a fixed size baked into its type (here, 3), unlike List
    # which can grow or shrink. This means no heap allocation is needed.
    var arr: InlineArray[Int, 3] = [1, 2, 3]   # size is part of the type
    print(arr[0])                               # 1
    print(len(arr))                             # 3

    # `fill=0` initializes every element to the same value instead of
    # listing them all out individually.
    var zeros = InlineArray[Int, 5](fill=0)     # [0, 0, 0, 0, 0]
    print(len(zeros))                           # 5