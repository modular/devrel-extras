from std.math import iota
from std.sys import exit, has_accelerator
from max.gpu.host import DeviceContext
from max.gpu import block_dim, block_idx, thread_idx

def matrix_add(
    matrix: Pointer[Float32, MutAnyOrigin],
    rows: Int8,
    cols: Int8,
    scalar: Float32,
):
    # Two-dimensional global index: one thread per matrix element.
    var row = Int8(block_dim.y * block_idx.y + thread_idx.y)
    var col = Int8(block_dim.x * block_idx.x + thread_idx.x)
    if row < rows and col < cols:
        matrix[unsafe_offset=row * cols + col] += scalar   # flatten (row, col) into the buffer


comptime num_rows = 4
comptime num_cols = 5
comptime num_elements = num_rows * num_cols

def main() raises:
    comptime assert has_accelerator(), "No accelerator available"

    var ctx = DeviceContext()

    # 1. Host buffer, filled with matrix [0, 1, 2, 3, 4]...
    var host_buffer = ctx.enqueue_create_host_buffer[DType.float32](num_elements)
    ctx.synchronize()
    iota(host_buffer.as_span())
    print("Original matrix:")
    for row in range(num_rows):
        var row_start = row * num_cols
        print(host_buffer.as_span()[row_start : row_start + num_cols])

    # 2. Device buffer, copy host -> device
    var device_buffer = ctx.enqueue_create_buffer[DType.float32](num_elements)
    ctx.enqueue_copy(src_buf=host_buffer, dst_buf=device_buffer)

    # 3. Compile and launch the kernel across multiple 2D blocks, so
    # both block_idx and thread_idx contribute to the global (row, col).
    ctx.enqueue_function[matrix_add](
        device_buffer,
        Int8(num_rows),
        Int8(num_cols),
        Float32(20.0),
        grid_dim=(2, 2),
        block_dim=(3, 2),
    )

    # 4. Copy device -> host
    ctx.enqueue_copy(src_buf=device_buffer, dst_buf=host_buffer)

    # 5. Wait for the GPU to finish
    ctx.synchronize()
    print("Result:")
    for row in range(num_rows):
        var row_start = row * num_cols
        print(host_buffer.as_span()[row_start : row_start + num_cols])