# Advent of Code 2025, Day 1: Secret Entrance (Part 1)
# https://adventofcode.com/2025/day/1
#
# A safe dial shows 0-99 and starts at 50. Each input line is a rotation:
# `L` or `R` followed by a number of clicks.
#   Part 1: count the rotations that leave the dial pointing at 0.
#
# Run from this folder with:   mojo day01_p1.mojo
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
        # `Rotation()` raises if the direction isn't L or R.
        rotations.append(Rotation(stripped[byte=0], Int(stripped[byte=1:])))
    # `^` moves the list out to the caller instead of copying it.
    return rotations^


struct Dial(Movable):
    var reading: Int
    var zero_stops: Int  # rotations that end on 0

    # `out self` marks the value being constructed.
    def __init__(out self, reading: Int = START_POSITION):
        self.reading = reading
        self.zero_stops = 0

    # `mut self` lets `turn` update the fields. Part 1 only cares where each
    # turn ends, so one `%` handles any number of clicks, including full laps.
    def turn(mut self, rotation: Rotation):
        if rotation.direction == "R":
            self.reading = (self.reading + rotation.clicks) % DIAL_SIZE
        else:
            # Like Python, Mojo's `%` never returns a negative here: -5 % 100 == 95.
            self.reading = (self.reading - rotation.clicks) % DIAL_SIZE

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
