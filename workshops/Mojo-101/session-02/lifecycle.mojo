# using the copy() method requires the Copyable trait
struct Tracked(Copyable):
    #field
    var id: Int

    # constructor method
    def __init__(out self, id: Int):
        self.id = id
        print("init", id)

    # copy method overloads init
    def __init__(out self, *, copy: Self):
        self.id = copy.id
        print("copy", self.id)

    # destructor method
    def __del__(deinit self):
        print("del", self.id)

def main():
    var a = Tracked(1)
    var b = a.copy()
    print("using a", a.id)
    print("using b", b.id)