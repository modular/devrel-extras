from std.sys import has_accelerator

from std.gpu.host import DeviceContext
from std.gpu import block_dim, block_idx, global_idx, thread_idx


def print_threads():
    """Print thread block and thread indices."""

    # GPU hierarchy: a grid is made of blocks, and each block is made of threads.
    # block_idx  - which block this thread's block occupies within the grid (per axis).
    # thread_idx - which thread this is within its own block (per axis).
    # global_idx - this thread's unique position across the ENTIRE grid, precomputed
    #              for us (equivalent to block_dim * block_idx + thread_idx).
    print(
        block_idx.x,
        block_idx.y,
        block_idx.z,
        thread_idx.x,
        thread_idx.y,
        thread_idx.z,
        global_idx.x,
        global_idx.y,
        global_idx.z,
        # Manually derive the same global index from block_dim (threads per
        # block), block_idx, and thread_idx, to show how global_idx is computed.
        block_dim.x * block_idx.x + thread_idx.x,
        block_dim.y * block_idx.y + thread_idx.y,
        block_dim.z * block_idx.z + thread_idx.z,
        sep="\t",
    )


def main() raises:
    comptime if not has_accelerator():
        print("No compatible GPU found")
    else:
        # Initialize GPU context for device 0 (default GPU device).
        ctx = DeviceContext()

        print("block_idx\t\tthread_idx\t\tglobal_idx\t\tcalculated global_idx")
        print("x\ty\tz", "x\ty\tz", "x\ty\tz", "x\ty\tz", sep="\t")
        print("-" * 20, "-" * 20, "-" * 20, "-" * 20, sep="\t")
        # grid_dim and block_dim together define the full hierarchy launched:
        # a (2,2,1) grid of blocks, each block containing (4,4,2) threads —
        # 4 blocks x 32 threads/block = 128 threads total across the grid.
        ctx.enqueue_function[print_threads](
            grid_dim=(2, 2, 1),  # 2x2x1 blocks per grid
            block_dim=(4, 4, 2),  # 4x4x2 threads per block
        )

        ctx.synchronize()
        print("Done")