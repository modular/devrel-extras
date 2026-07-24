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

    # O(n): scan every element once to find the maximum by hand.
    var nums: InlineArray[Int, 6] = [4, 1, 7, 3, 9, 2]
    var largest: Int = nums[0]
    for n in nums:
        if n > largest:
            largest = n
    print(largest)                              # 9