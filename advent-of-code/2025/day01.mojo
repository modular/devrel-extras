# Advent of Code 2025, Day 1: Secret Entrance
# https://adventofcode.com/2025/day/1
#
# A safe dial shows 0-99 and starts at 50. Each input line is a rotation:
# `L` or `R` followed by a distance.
#   Part 1: count the rotations that leave the dial pointing at 0.
#   Part 2: count every click that lands on 0, including during a rotation.
# Run with:   mojo day01.mojo
# Puzzle input defaults to `input/day01.txt`

from std.pathlib import Path
from std.sys import argv
from std.testing import assert_equal

# Defining constants up top makes them easier to reuse and change if needed.
comptime DIAL_SIZE = 100
comptime START_POSITION = 50
comptime DEFAULT_INPUT = "input/day01.txt"

# Small example input with known output.
comptime EXAMPLE = """L68
L30
R48
L5
R60
L55
L1
L99
R14
L82
"""
comptime EXAMPLE_PART1 = 3
comptime EXAMPLE_PART2 = 6


# Parse one rotation to Int: left is negative, right is positive.
# `StringSpan` enables zero-copy string operations
def parse_rotation(line: StringSpan) raises -> Int:
    # byte=index accesses individual characters
    var direction = line[byte=0]
    # `Int()` raises if the digit can't be parsed
    var distance = Int(line[byte=1:])
    if direction == "L":
        return -distance
    elif direction == "R":
        return distance
    raise Error(t"Unknown direction in rotation: {line}")


# The Dial Struct owns its position and both counters, to be updated by each turn.
struct Dial(Movable):
    var position: Int
    var stops_at_zero: Int  # Part 1
    var clicks_at_zero: Int  # Part 2

    # `out self` marks the constructor's result. By default `Dial()` starts at 50.
    def __init__(out self, position: Int = START_POSITION):
        self.position = position
        self.stops_at_zero = 0
        self.clicks_at_zero = 0

    # Apply one rotation in constant time, however large `step` is.
    # Stepping click by click would be linear time complexity.
    # `mut self` lets `turn` update the struct fields.
    def turn(mut self, step: Int):
        # Every full lap of the dial passes 0 exactly once.
        var distance = abs(step)
        var laps = distance // DIAL_SIZE
        var remainder = distance % DIAL_SIZE
        if step >= 0:
            # Turning right, the partial turn reaches 0 if it goes past 99.
            self.clicks_at_zero += laps + Int(
                self.position + remainder >= DIAL_SIZE
            )
        else:
            # Turning left, the partial turn reaches 0 if it covers the distance back to 0.
            self.clicks_at_zero += laps + Int(
                self.position > 0 and remainder >= self.position
            )

        # Like Python, Mojo's `%` never returns a negative here: (-5) % 100 == 95.
        # That handles wrapping left past 0 with no special case.
        self.position = (self.position + step) % DIAL_SIZE
        if self.position == 0:
            self.stops_at_zero += 1


# Parse each line of the input, apply it to a fresh `Dial`, and return the
# dial with both answers recorded.
def solve(text: String) raises -> Dial:
    var dial = Dial()

    # `splitlines()` returns views into `text` (no copies) and handles both
    # `\n` and `\r\n` line endings.
    for line in text.splitlines():
        # Tolerate stray whitespace or blank lines at the end of a file.
        var rotation = line.strip()
        if not rotation:
            continue
        dial.turn(parse_rotation(rotation))

    # Returning the struct moves it to the caller; `Movable` allows that.
    return dial^


# `def main() raises` lets errors propagate up with a message.
def main() raises:
    # Check the example first: `assert_equal` raises with both values shown.
    var example = solve(EXAMPLE)
    assert_equal(example.stops_at_zero, EXAMPLE_PART1)
    assert_equal(example.clicks_at_zero, EXAMPLE_PART2)
    # The puzzle's warning case: R1000 from 50 passes 0 ten times.
    var big_turn = Dial()
    big_turn.turn(1000)
    assert_equal(big_turn.clicks_at_zero, 10)

    # Let the input path be overridden on the command line, but default to a
    # conventional location so a plain `mojo day01.mojo` still works.
    var args = argv()
    var path = Path(args[1]) if len(args) > 1 else Path(DEFAULT_INPUT)

    # Read the whole file at once because AoC inputs are small.
    # One `String` input is sliced into `splitlines()` above.
    var text = path.read_text()
    var dial = solve(text)
    print(t"Part 1: {dial.stops_at_zero}")
    print(t"Part 2: {dial.clicks_at_zero}")
