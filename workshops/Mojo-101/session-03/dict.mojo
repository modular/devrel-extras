def main():
    # String of digits whose per-character frequency we want to count.
    var digits: String = "1223334444"

    # Dict mapping each digit (as a String) to how many times it has appeared.
    # `{}` creates an empty dict
    var counts: Dict[String, Int] = {}

    for i in range(digits.byte_length()):
        # Extract the single-byte character at index i as its own String.
        var d = String(digits[byte=i])

        # Look up the current count (defaulting to 0 if d is new) and increment it.
        counts[d] = counts.get(d, 0) + 1

    # Dict.items() yields key/value entries; order matches insertion order.
    for entry in counts.items():
        print(entry.key, "appears", entry.value, "times")