# Objectives

By the end of this session, learners should understand the GPU programming model and be able to read and reason about a complete Mojo GPU program:

1. **The execution model** — host vs. device, the thread hierarchy (thread, block, grid), and reading grid and block dimensions from a running program
2. **A kernel function** — computing a global thread index and doing one element of work per thread
3. **The host workflow** — `DeviceContext`, allocating buffers, copying data, launching a kernel, and synchronizing
4. **Multidimensional grids** — extending the thread-index formula to 2D so one thread maps to one element of a matrix