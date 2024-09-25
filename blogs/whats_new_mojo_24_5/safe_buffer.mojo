from memory import memset_zero


struct SafeBuffer(Stringable, Formattable):
    var _data: UnsafePointer[UInt8]
    var size: Int

    fn __init__(inout self, size: Int):
        debug_assert(size > 0, "size must be greater than zero")
        self._data = UnsafePointer[UInt8].alloc(size)
        memset_zero(self._data, size)
        self.size = size

    @staticmethod
    fn initialize_with_value(size: Int, value: UInt8) -> Self as output:
        output = SafeBuffer(size)
        for i in range(size):
            output.write(i, value)

        return

    fn __del__(owned self):
        self._data.free()

    fn _get_ref(ref [_]self: Self, index: Int) -> Reference[UInt8, __lifetime_of(self)]:
        return Reference[UInt8, __lifetime_of(self)](self._data[index])

    fn write(inout self, index: Int, value: UInt8):
        self._get_ref(index)[] = value

    fn read(self, index: Int) -> UInt8:
        return self._get_ref(index)[]

    fn __str__(self) -> String:
        return String.format_sequence(self)

    fn format_to(self, inout writer: Formatter):
        debug_assert(self.size > 0, "size must be greater than zero")
        writer.write("[")
        for i in range(self.size - 1):
            writer.write(self._data[i], ", ")

        writer.write(self._data[self.size - 1])
        writer.write("]")


fn process_buffers(buffer1: SafeBuffer, inout buffer2: SafeBuffer):
    debug_assert(buffer1.size == buffer2.size, "buffer sizes much match")
    for i in range(buffer1.size):
        buffer2.write(i, buffer1.read(i))


fn main():
    sb = SafeBuffer(10)
    sb.write(0, 255)
    sb.write(1, 128)
    print("safe buffer outputs:")
    print(sb.read(0))
    print(sb.read(1))

    buffer1 = SafeBuffer.initialize_with_value(size=10, value=128)
    buffer2 = SafeBuffer(10)
    # process_buffers(buffer1, buffer1) # <-- argument exclusivity detects such errors at compile time
    process_buffers(buffer1, buffer2)
    print("buffer2:")
    print(buffer2)
