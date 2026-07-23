from std.collections import Set

# Returns the first candidate that's also in `allowed`, or None if none match.
# Optional[Int] lets us represent "no match" without a sentinel value.
def first_allowed(candidates: List[Int], allowed: Set[Int]) -> Optional[Int]:
    for c in candidates:
        # Set membership: roughly O(1), unlike List's O(n) `in`
        if c in allowed:
            return c
    # return Optional[Int](None)
    return None

def main():
    # Set dedups automatically at construction time, so order isn't
    # guaranteed and repeated values collapse into one.
    var allowed: Set[Int] = {2, 4, 4, 6, 8}
    print(len(allowed))

    var hit = first_allowed([1, 3, 4, 5], allowed)
    # Optional is truthy when it holds a value; .value() unwraps it.
    if hit:
        print("first allowed:", hit.value())
    else:
        print("none allowed")