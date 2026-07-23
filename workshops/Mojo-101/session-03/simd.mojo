from std.time import perf_counter_ns

comptime width = 8

def simd_sum(immut data: List[Float32]) -> Float32:
    var acc = SIMD[DType.float32, width](0)
    var i = 0
    # main loop: 8 lanes at a time
    while i + width <= len(data):
        var chunk = data.unsafe_ptr().load[width=width](i)
        acc += chunk
        i += width
    var total = acc.reduce_add()
    # tail: leftover elements
    while i < len(data):
        total += data[i]
        i += 1
    return total

def scalar_sum(immut data: List[Float32]) -> Float32:
    var total: Float32 = 0
    for i in range(len(data)):
        total += data[i]
    return total


def main():
    comptime n = 100_000_000
    var data = List[Float32](capacity=n)
    for i in range(n):
        data.append(Float32(i % 97) * 0.5)

    var t0 = perf_counter_ns()
    var simd_result = simd_sum(data)
    var t1 = perf_counter_ns()
    var scalar_result = scalar_sum(data)
    var t2 = perf_counter_ns()

    var simd_ms = (t1 - t0) / 1_000_000
    var scalar_ms = (t2 - t1) / 1_000_000

    print("SIMD sum:  ", simd_result, " (", simd_ms, "ms)")
    print("Scalar sum:", scalar_result, " (", scalar_ms, "ms)")
    print("Speedup:   ", scalar_ms / simd_ms, "x")