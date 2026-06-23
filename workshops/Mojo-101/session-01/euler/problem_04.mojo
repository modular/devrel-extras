# Session 1 — Problem 4: Largest Palindrome Product
# Concepts: structs, out self constructor, mut self methods, Bool return type,
#           String construction and indexing, nested loops
# Ref: https://mojolang.org/docs/manual/structs/


def is_palindrome(value: Int) -> Bool:
    """Return True if the decimal representation of value reads the same both ways."""
    # TODO: implement this function
    return False


struct PalindromeFinder:
    var lo: Int
    var hi: Int
    var largest: Int

    def __init__(out self, lo: Int, hi: Int):
        self.lo = lo
        self.hi = hi
        self.largest = 0

    def search(mut self):
        # TODO: implement this method
        pass


def main():
    var finder = PalindromeFinder(100, 1000)
    finder.search()
    print(finder.largest)
