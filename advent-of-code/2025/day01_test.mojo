# Tests for day01_p1.mojo and day01_p2.mojo.
# Run from this folder with:   mojo day01_test.mojo
#
# `TestSuite` finds every function whose name starts with `test_` and runs it.
# Check the example by hand here before spending a submission attempt.

from std.testing import assert_equal, assert_raises, TestSuite

# Both files define `Dial`, `Rotation`, `parse_rotations`, and `solve`, so
# import each module under a short name instead of importing the names.
import day01_p1 as p1
import day01_p2 as p2

# The worked example from the puzzle, with its published answers.
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


# Part 1


def test_p1_example() raises:
    assert_equal(p1.solve(p1.parse_rotations(EXAMPLE)).zero_stops, 3)


# Full laps leave the dial where it started, so R1000 from 50 doesn't stop on 0.
def test_p1_full_laps() raises:
    var dial = p1.Dial()
    dial.turn(p1.Rotation("R", 1000))
    assert_equal(dial.reading, 50)
    assert_equal(dial.zero_stops, 0)


# Turning left past 0 wraps around to the high numbers.
def test_p1_left_wraps() raises:
    var dial = p1.Dial(reading=0)
    dial.turn(p1.Rotation("L", 5))
    assert_equal(dial.reading, 95)


def test_p1_stop_on_zero() raises:
    var dial = p1.Dial()
    dial.turn(p1.Rotation("L", 50))
    assert_equal(dial.zero_stops, 1)


# Part 2


def test_p2_example() raises:
    var dial = p2.solve(p2.parse_rotations(EXAMPLE))
    assert_equal(dial.zero_stops, 3)
    assert_equal(dial.zero_clicks, 6)


# The puzzle's warning: R1000 from 50 passes 0 ten times and ends back at 50.
def test_p2_full_laps() raises:
    var dial = p2.Dial()
    dial.turn(p2.Rotation("R", 1000))
    assert_equal(dial.zero_clicks, 10)
    assert_equal(dial.reading, 50)


# Leaving 0 is not landing on it.
def test_p2_left_from_zero() raises:
    var dial = p2.Dial(reading=0)
    dial.turn(p2.Rotation("L", 5))
    assert_equal(dial.zero_clicks, 0)
    assert_equal(dial.reading, 95)


# Stopping exactly on 0 counts for both parts.
def test_p2_stop_on_zero() raises:
    var dial = p2.Dial()
    dial.turn(p2.Rotation("L", 50))
    assert_equal(dial.zero_stops, 1)
    assert_equal(dial.zero_clicks, 1)


# Input handling. `Rotation` and `parse_rotations` are the same in both files,
# so these check Part 1's copy, plus one rejection check on Part 2's.


# The `Rotation` constructor is the only place directions are checked, so
# test it directly as well as through the parser.
def test_rotation_accepts_left_and_right() raises:
    assert_equal(p1.Rotation("L", 5).direction, "L")
    assert_equal(p1.Rotation("R", 5).direction, "R")


def test_rotation_rejects_unknown_direction() raises:
    with assert_raises(contains="Unknown direction"):
        _ = p1.Rotation("X", 5)
    # Directions are case-sensitive.
    with assert_raises(contains="Unknown direction"):
        _ = p1.Rotation("l", 5)


def test_parse_skips_blank_lines_and_whitespace() raises:
    var rotations = p1.parse_rotations("R5\n\n  L3  \r\n")
    assert_equal(len(rotations), 2)
    assert_equal(rotations[1].direction, "L")
    assert_equal(rotations[1].clicks, 3)


def test_parse_rejects_unknown_direction() raises:
    with assert_raises(contains="Unknown direction"):
        _ = p1.parse_rotations("X5\n")
    with assert_raises(contains="Unknown direction"):
        _ = p2.parse_rotations("X5\n")


def test_parse_rejects_bad_number() raises:
    with assert_raises():
        _ = p1.parse_rotations("R5x\n")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
