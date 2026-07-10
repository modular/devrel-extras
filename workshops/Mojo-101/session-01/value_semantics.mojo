def main():
    var a = "hello"
    var b = a         # implicit copy
    b = b + " world"
    print(a)          # hello
    print(b)          # hello world
