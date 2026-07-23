# a List's element type must conform to Copyable and Movable.
# `@fieldwise_init` auto-generates an __init__ that takes x and y directly.
@fieldwise_init
struct Point():
    var x: Int
    var y: Int

def main():
    # Error: Point conforms to Movable but not Copyable
    var points: List[Point] = [Point(1, 2)]   # error
    print("x: ", points[0].x)
    print("y: ", points[0].y)