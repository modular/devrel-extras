# function takes ownership of the value with the var argument convention
def take_text(var text: String):
    text += "!"
    print(text)

def main():
    var message = "Hello"
    # take_text(message) would create a copy
    take_text(message^)
    # print(message)   # error: use of uninitialized value 'message'