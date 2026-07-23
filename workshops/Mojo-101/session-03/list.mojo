def main():
    # List is a dynamically-sized, growable collection (unlike InlineArray).
    var nums: List[Int] = [4, 1, 7, 3, 9, 2]
    nums.append(5)
    print(len(nums))             # 7
    print(nums[0])               # 4

    # O(n): scan every element once to find the maximum by hand.
    var largest: Int = nums[0]
    for n in nums:
        if n > largest:
            largest = n
    print(largest)               # 9

    # O(n log n): sort the whole list instead, which also gives us
    # ordering information (e.g. the top-k largest values) for free.
    sort(nums)                       # ascending, in place
    print(nums[len(nums) - 1])       # 9 — largest is now last
    print(nums[len(nums) - 3:])      # [5, 7, 9] — the three largest via slicing