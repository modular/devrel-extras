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

# Defining constants up top makes them easier to reuse and change if needed
comptime DIAL_SIZE = 100
comptime START_POSITION = 50
comptime DEFAULT_INPUT = "input/day01.txt"

# Small example input with known output
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


# Count how many clicks of a single rotation land on 0.
# Checking each step would be linear time but integer division is constant time.
def clicks_through_zero(position: Int, step: Int) -> Int:
    # Every full lap of the dial passes 0 exactly once.
    var distance = abs(step)
    var laps = distance // DIAL_SIZE
    var remainder = distance % DIAL_SIZE
    if step >= 0:
        # Turning right, the partial turn reaches 0 if it goes past 99.
        return laps + Int(position + remainder >= DIAL_SIZE)
    # Turning left, the partial turn reaches 0 if it covers the distance back to 0.
    return laps + Int(position > 0 and remainder >= position)


# One solve function returns both solutions as a Tuple.
def solve(text: String) raises -> Tuple[Int, Int]:
    var position = START_POSITION
    var stops_at_zero = 0  # Part 1
    var clicks_at_zero = 0  # Part 2

    # `splitlines()` returns views into `text` (no copies) and handles both
    # `\n` and `\r\n` line endings.
    for line in text.splitlines():
        # Tolerate stray whitespace or blank lines at the end of a file.
        var rotation = line.strip()
        if not rotation:
            continue

        var step = parse_rotation(rotation)
        # Count Part 2 from the position *before* the move is applied.
        clicks_at_zero += clicks_through_zero(position, step)

        # Like Python, Mojo's `%` never returns a negative here: (-5) % 100 == 95.
        # That handles wrapping left past 0 with no special case.
        position = (position + step) % DIAL_SIZE
        if position == 0:
            stops_at_zero += 1

    return (stops_at_zero, clicks_at_zero)


# `def main() raises` lets errors propagate up with a message.
def main() raises:
    # Check the example first: `assert_equal` raises with both values shown.
    var example = solve(EXAMPLE)
    assert_equal(example[0], EXAMPLE_PART1)
    assert_equal(example[1], EXAMPLE_PART2)
    # The puzzle's warning case: R1000 from 50 passes 0 ten times.
    assert_equal(clicks_through_zero(START_POSITION, 1000), 10)

    # Let the input path be overridden on the command line, but default to a
    # conventional location so a plain `mojo day01.mojo` still works.
    var args = argv()
    var path = Path(args[1]) if len(args) > 1 else Path(DEFAULT_INPUT)

    # Read the whole file at once. AoC inputs are small, and one `String`
    # owning all the bytes keeps the `splitlines()` slices above valid.
    var text = path.read_text()
    var answers = solve(text)
    print(t"Part 1: {answers[0]}")
    print(t"Part 2: {answers[1]}")
