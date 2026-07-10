"""
If we list all the natural numbers below 10 that are multiples of 3 or 5 we get 3, 5, 6, and 9.
The sum of these multiples is 23.
Find the sum of all the multiples of 3 or 5 below 1000.
"""

# Includes arguments, default values, and keyword only arguments
def sum_multiples(limit: Int, a : Int = 3, b: Int = 5, *, verbose: Bool = False) -> Int:
    """Return the Int sum of all multiples of two divisors below a given limit."""
    var total = 0
    for n in range(limit):
        #check if n is a multiple of a or b
        if n % a == 0 or n % b ==0:
            if verbose:
                print(n)
            total += n
    return total

# Program entry point
def main():
    # Print the returned total
    print(sum_multiples(10, verbose=True))