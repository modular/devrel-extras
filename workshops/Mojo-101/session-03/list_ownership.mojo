def total(values: List[Int]) -> Int:
    # `values` is passed by immutable reference (the default)
    var t = 0
    for v in values:
        t += v
    return t

def push(mut values: List[Int], var x: Int):
    # `mut` lets this function mutate the caller's list directly (no copy)
    # `var x` takes ownership of the argument.
    values.append(x)

def main():
    var nums: List[Int] = [10, 20, 30]
    push(nums, 40)              # nums is now [10, 20, 30, 40], mutated in place
    print(total(nums))          # 100