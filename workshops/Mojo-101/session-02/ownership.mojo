# default immutable reference
def print_list(list: List[Int]):
    print(list)

# mutable reference
def mutate_list(mut l: List[Int]):
    l.append(5)

# argument exclusivity
def combine_elements(mut a: List[Int], b: List[Int]):
    a.append(b[0])

def main():
    var values = [1, 2, 3, 4]
    mutate_list(values)

    # wrong: breaks argument exclusivity - not memoty safe
    # combine_elements(values, values)

    # fix: pass an independent copy as the immutable argument
    var new_list = values.copy()
    combine_elements(values, new_list)

    print_list(values)