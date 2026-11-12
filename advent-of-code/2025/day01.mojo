# Advent of Code 2025, Day 1: Secret Entrance
# https://adventofcode.com/2025/day/1
#
# A safe dial shows 0-99 and starts at 50. Each input line is a rotation:
# `L` or `R` followed by a number of clicks.
#   Part 1: count the rotations that leave the dial pointing at 0.
#   Part 2: count every click that lands on 0, including during a rotation.
#
# Run from this folder with:   mojo day01.mojo

from std.pathlib import Path
from std.testing import assert_equal

# `comptime` values are compile-time constants.
comptime DIAL_SIZE = 100
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


struct Dial(Movable):
    var reading: Int
    var zero_stops: Int  # Part 1: rotations that end on 0
    var zero_clicks: Int  # Part 2: clicks that land on 0

    # `out self` marks the value being constructed; `reading` defaults to 50.
    def __init__(out self, reading: Int = 50):
        self.reading = reading
        self.zero_stops = 0
        self.zero_clicks = 0

    # `mut self` lets `turn` update the fields. Instead of stepping one click
    # at a time, split the turn into laps for constant time complexity.
    def turn(mut self, direction: StringSpan, clicks: Int) raises:
        # Every full lap passes 0 exactly once.
        var laps = clicks // DIAL_SIZE
        var leftover = clicks % DIAL_SIZE
        self.zero_clicks += laps

        if direction == "R":
            # The leftover reaches 0 if it carries the dial past 99.
            if self.reading + leftover >= DIAL_SIZE:
                self.zero_clicks += 1
            self.reading = (self.reading + leftover) % DIAL_SIZE
        elif direction == "L":
            # The leftover reaches 0 if it covers the distance back to 0.
            if self.reading > 0 and leftover >= self.reading:
                self.zero_clicks += 1
            # Like Python, Mojo's `%` never returns a negative here: -5 % 100 == 95.
            self.reading = (self.reading - leftover) % DIAL_SIZE
        else:
            raise Error(t"Unknown direction: {direction}")

        if self.reading == 0:
            self.zero_stops += 1


# Turn a fresh dial through every line of the input.
def solve(text: String) raises -> Dial:
    var dial = Dial()
    # `splitlines()` returns views into `text`, so no line is copied.
    for line in text.splitlines():
        # `strip()` drops stray whitespace; skip any blank lines.
        var rotation = line.strip()
        if not rotation:
            continue
        # `byte=` indexes the string's bytes, which suits ASCII input.
        # `Int()` raises if the number can't be parsed.
        dial.turn(rotation[byte=0], Int(rotation[byte=1:]))
    # `^` moves the dial out to the caller instead of copying it.
    return dial^


def main() raises:
    # Check the puzzle's example with a known output first.
    var example = solve(EXAMPLE)
    assert_equal(example.zero_stops, 3)
    assert_equal(example.zero_clicks, 6)

    var dial = solve(Path("input/day01.txt").read_text())
    print(t"Part 1: {dial.zero_stops}")
    print(t"Part 2: {dial.zero_clicks}")
