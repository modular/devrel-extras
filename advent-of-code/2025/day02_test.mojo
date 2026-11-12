# Tests for day02_p1.mojo and day02_p2.mojo.
# Run from this folder with:   mojo day02_test.mojo
#
# `TestSuite` finds every function whose name starts with `test_` and runs it.
# Check the example by hand here before spending a submission attempt.

from std.testing import assert_equal, assert_true, assert_false, assert_raises, TestSuite

# Both files define `IdRange`, `ProductId`, `GiftShopAudit`, `parse_ranges`,
# and `solve`, so import each module under a short name.
import day02_p1 as p1
import day02_p2 as p2

# The worked example from the puzzle, wrapped as it is on the puzzle page.
# Real input is one long line; the parser handles both.
comptime EXAMPLE = """11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
1698522-1698528,446443-446449,38593856-38593862,565653-565659,
824824821-824824827,2121212118-2121212124
"""


# Part 1


def test_p1_example() raises:
    assert_equal(p1.solve(p1.parse_ranges(EXAMPLE)).invalid_total, 1227775554)


def test_p1_doubled_ids() raises:
    assert_true(p1.ProductId(55).is_doubled())
    assert_true(p1.ProductId(6464).is_doubled())
    assert_true(p1.ProductId(123123).is_doubled())


def test_p1_not_doubled_ids() raises:
    assert_false(p1.ProductId(101).is_doubled())
    # Repeated three times, not twice, so Part 1 ignores it.
    assert_false(p1.ProductId(111).is_doubled())
    assert_false(p1.ProductId(7).is_doubled())


# From the example: 95-115 has one invalid ID, 99.
def test_p1_single_range() raises:
    var audit = p1.GiftShopAudit()
    audit.check(p1.IdRange(95, 115))
    assert_equal(audit.invalid_total, 99)


# Part 2


def test_p2_example() raises:
    var audit = p2.solve(p2.parse_ranges(EXAMPLE))
    assert_equal(audit.doubled_total, 1227775554)
    assert_equal(audit.repeated_total, 4174379265)


def test_p2_repeating_ids() raises:
    assert_true(p2.ProductId(12341234).has_repeating_pattern())   # 1234 x2
    assert_true(p2.ProductId(123123123).has_repeating_pattern())  # 123 x3
    assert_true(p2.ProductId(1212121212).has_repeating_pattern()) # 12 x5
    assert_true(p2.ProductId(1111111).has_repeating_pattern())    # 1 x7


def test_p2_not_repeating_ids() raises:
    assert_false(p2.ProductId(101).has_repeating_pattern())
    assert_false(p2.ProductId(1231234).has_repeating_pattern())
    # A single digit isn't a sequence repeated at least twice.
    assert_false(p2.ProductId(7).has_repeating_pattern())


def test_p2_repeated_exact_times() raises:
    var id = p2.ProductId(121212)
    assert_false(id.is_repeated(2))  # 121 + 212
    assert_true(id.is_repeated(3))   # 12 + 12 + 12
    assert_false(id.is_repeated(4))  # 6 digits don't split into 4 chunks


# From the example: 95-115 now has two invalid IDs, 99 and 111.
def test_p2_single_range() raises:
    var audit = p2.GiftShopAudit()
    audit.check(p2.IdRange(95, 115))
    assert_equal(audit.doubled_total, 99)
    assert_equal(audit.repeated_total, 99 + 111)


# Input handling. `IdRange` and `parse_ranges` are the same in both files,
# so these check Part 1's copy, plus one rejection check on Part 2's.


def test_parse_wrapped_input() raises:
    var ranges = p1.parse_ranges(EXAMPLE)
    assert_equal(len(ranges), 11)
    assert_equal(ranges[5].first, 1698522)
    assert_equal(ranges[5].last, 1698528)


def test_range_rejects_backward() raises:
    with assert_raises(contains="backward"):
        _ = p1.IdRange(22, 11)


def test_parse_rejects_malformed_range() raises:
    with assert_raises(contains="Malformed range"):
        _ = p1.parse_ranges("11-22-33")
    with assert_raises(contains="Malformed range"):
        _ = p2.parse_ranges("1122")


def test_parse_rejects_bad_number() raises:
    with assert_raises():
        _ = p1.parse_ranges("11-2x")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
