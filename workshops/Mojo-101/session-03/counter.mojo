from std.collections import Counter

def main():
    var counts = Counter[String]("1", "2", "2", "3", "3", "3", "4", "4", "4", "4")
    print(counts["3"])   # 3
    print(counts["4"])   # 4
    print(counts["9"])   # 0 — missing key returns 0, no raise