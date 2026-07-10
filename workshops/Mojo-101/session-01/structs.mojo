"""
Find the difference between the square of the sum and the sum of squares
of the first one hundred natural numbers.
"""

struct SumTracker:
    #Fields
    var total: Int
    var sum_of_squares: Int
    
    #Methods
    def __init__(out self):
        """Constructor method to initialize the two fields"""
        self.total = 0
        self.sum_of_squares = 0

    def add(mut self, n: Int):
        """Add n to both accumulators."""
        self.total += n
        self.sum_of_squares += n * n
    
    def difference(self) -> Int:
        """Return the square of the sum minus the sum of squares."""
        return self.total * self.total - self.sum_of_squares

def main():
    var tracker = SumTracker()
    for n in range(1,101):
        tracker.add(n)
    print(tracker.difference())
