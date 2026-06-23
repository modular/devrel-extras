# Session 1 — Problem 6: Sum Square Difference
# Concepts: optional arguments with defaults, keyword arguments, ** power operator
# Ref: https://mojolang.org/docs/manual/functions/


def sum_powers(n: Int, power: Int = 1) -> Int:
    """Sum of the first n natural numbers, each raised to `power`."""
    # TODO: implement this function
    return 0


def main():
    var n = 100
    var square_of_sum = sum_powers(n) ** 2          # power defaults to 1
    var sum_of_squares = sum_powers(n, power=2)     # passed by keyword
    print(square_of_sum - sum_of_squares)
