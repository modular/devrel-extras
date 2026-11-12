# Advent of Code 2025, Day 2: Gift Shop (Part 1)
# https://adventofcode.com/2025/day/2
#
# The input is one line of product ID ranges like `11-22,95-115`. Each range
# gives its first and last ID, inclusive.
#   Part 1: add up every ID made of some sequence of digits repeated twice,
#           like 55, 6464, or 123123.
#
# Run from this folder with:   mojo day02_p1.mojo
# Test with:                   mojo day02_test.mojo

from std.pathlib import Path


# One parsed range of product IDs, from `first` to `last` inclusive.
struct IdRange(Copyable):
    var first: Int
    var last: Int

    # Constructor requires the range to run forward.
    def __init__(out self, first: Int, last: Int) raises:
        self.first = first
        self.last = last
        if first > last:
            raise Error(t"Range runs backward: {first}-{last}")


# Input handling: split the text into `first-last` pieces, skipping empty
# pieces and rejecting anything malformed, so the solver only sees clean data.
def parse_ranges(text: String) raises -> List[IdRange]:
    var ranges = List[IdRange]()
    # Ranges are separated by commas. `split()` returns views into `text`.
    for piece in text.split(","):
        # `strip()` drops newlines, so wrapped input works too.
        var stripped = piece.strip()
        if not stripped:
            continue
        var ends = stripped.split("-")
        if len(ends) != 2:
            raise Error(t"Malformed range: {stripped}")
        # `Int()` raises if a number can't be parsed.
        ranges.append(IdRange(Int(ends[0]), Int(ends[1])))
    # `^` moves the list out to the caller instead of copying it.
    return ranges^


# A product ID, kept as its digits because the puzzle is about digit patterns.
# IDs never have leading zeros, so `String(value)` gives exactly the digits.
struct ProductId:
    var digits: String

    def __init__(out self, value: Int):
        self.digits = String(value)

    # True if the digits are one sequence written twice: the first half
    # matches the second half. An odd number of digits can't split evenly.
    def is_doubled(self) -> Bool:
        var length = self.digits.byte_length()
        if length % 2 != 0:
            return False
        var half = length // 2
        # `byte=` slices the string's bytes, which suits ASCII digits.
        return self.digits[byte=:half] == self.digits[byte=half:]


# Checks ranges one at a time and keeps a running total of invalid IDs.
struct GiftShopAudit(Movable):
    var invalid_total: Int  # sum of IDs repeated twice

    def __init__(out self):
        self.invalid_total = 0

    # `mut self` lets `check` update the total. Every ID in the range is
    # checked directly: simple to follow, and fast enough for puzzle inputs.
    def check(mut self, id_range: IdRange):
        for value in range(id_range.first, id_range.last + 1):
            if ProductId(value).is_doubled():
                self.invalid_total += value


# Problem solving: run a fresh audit over every range.
def solve(ranges: List[IdRange]) -> GiftShopAudit:
    var audit = GiftShopAudit()
    for id_range in ranges:
        audit.check(id_range)
    return audit^


def main() raises:
    var ranges = parse_ranges(Path("input/day02.txt").read_text())
    var audit = solve(ranges)
    print(t"Part 1: {audit.invalid_total}")
