"""
If we list all the natural numbers below 10 that are multiples of 3 or 5 we get 3, 5, 6, and 9.
The sum of these multiples is 23
Find the sum of all the multiples of 3 or 5 below 1000.
"""

# Generalize to any number of divisors with variadic arguments
def sum_multiples(limit: Int, *divisors : Int) -> Int:
    """Find the sum of all multiples of aby number of divisors below a given limit."""
    var total = 0
    for n in range(limit):
        for d in divisors:
            if n % d == 0:
                total += n
    return total

# Any number of positional arguments (after the limit) will be acceptes as divisors
def main():
    print(sum_multiples(10, 3, 5, 7, 11))