# Advent of Code 2025, Day 1: Secret Entrance
# https://adventofcode.com/2025/day/1
#
# A safe dial shows 0-99 and starts at 50. Each input line is a rotation:
# `L` or `R` followed by a number of clicks.
#   Part 1: count the rotations that leave the dial pointing at 0.
#   Part 2: count every click that lands on 0, including during a rotation.
#
# Run from this folder with:   mojo day01_p2.mojo
# Test with:                   mojo day01_test.mojo

from std.pathlib import Path

# `comptime` values are compile-time constants.
comptime DIAL_SIZE = 100
comptime START_POSITION = 50


# One parsed input line: a direction (`L` or `R`) and a number of clicks.
struct Rotation(Copyable):
    var direction: String
    var clicks: Int

    # Constructor requires direction to be valid L or R
    def __init__(out self, direction: StringSpan, clicks: Int) raises:
        self.direction = String(direction)
        self.clicks = clicks
        if self.direction != "L" and self.direction != "R":
            raise Error(t"Unknown direction: {direction}")


# Input handling: turn raw text into rotations, skipping blank lines and
# rejecting anything malformed, so the solver only sees clean data.
def parse_rotations(text: String) raises -> List[Rotation]:
    var rotations = List[Rotation]()
    # `splitlines()` returns views into `text`, so no line is copied.
    for line in text.splitlines():
        var stripped = line.strip()
        if not stripped:
            continue
        # `byte=` indexes the string's bytes, which suits ASCII input.
        # `Int()` raises if the number can't be parsed.
        # `Rotation()`raises if the direction isn't L or R.
        rotations.append(Rotation(stripped[byte=0], Int(stripped[byte=1:])))
    # `^` moves the list out to the caller instead of copying it.
    return rotations^


struct Dial(Movable):
    var reading: Int
    var zero_stops: Int   # Part 1: rotations that end on 0
    var zero_clicks: Int  # Part 2: clicks that land on 0

    # `out self` marks the value being constructed.
    def __init__(out self, reading: Int = START_POSITION):
        self.reading = reading
        self.zero_stops = 0
        self.zero_clicks = 0

    # `mut self` lets `turn` update the fields. Instead of stepping one click
    # at a time, split the turn into full laps plus the clicks left over, so
    # every turn takes constant time however many clicks it has.
    def turn(mut self, rotation: Rotation):
        # Every full lap passes 0 exactly once.
        var laps = rotation.clicks // DIAL_SIZE
        var leftover = rotation.clicks % DIAL_SIZE
        self.zero_clicks += laps

        if rotation.direction == "R":
            # Turning right, the leftover clicks pass 0 if they take reading past 99.
            if self.reading + leftover >= DIAL_SIZE:
                self.zero_clicks += 1
            self.reading = (self.reading + leftover) % DIAL_SIZE
        else:
            # Turning left, the leftover clicks pass 0 if there are at least
            # as many of them as the reading.
            if leftover >= self.reading > 0:
                self.zero_clicks += 1
            # Like Python, Mojo's `%` never returns a negative here: -5 % 100 == 95.
            self.reading = (self.reading - leftover) % DIAL_SIZE

        if self.reading == 0:
            self.zero_stops += 1


# Problem solving: turn a fresh dial through every rotation.
def solve(rotations: List[Rotation]) -> Dial:
    var dial = Dial()
    for rotation in rotations:
        dial.turn(rotation)
    return dial^


def main() raises:
    var rotations = parse_rotations(Path("input/day01.txt").read_text())
    var dial = solve(rotations)
    print(t"Part 1: {dial.zero_stops}")
    print(t"Part 2: {dial.zero_clicks}")
