# Mojo 101: Language Fundamentals

A hands-on workshop series for Python developers and CUDA/C++ engineers new to Mojo.

**Version target:** Mojo 1.0.0b2

## Sessions

| Session | Topic | Date | Recording |
|---------|-------|------|-----------|
| 1 | Language Fundamentals | July 9, 2026 | [YouTube](https://www.youtube.com/live/1Jqp0BheoEQ) |
| 2 | Ownership, Lifecycle, and Metaprogramming | July 16, 2026 | |
| 3 | The Standard Library: Collections and SIMD | July 30, 2026 | |

## Setup

Install Mojo via `uv` or `pixi` following the [Mojo Quickstart](https://mojolang.org/docs/manual/quickstart/).

## Structure

``` Text
Mojo-101/
└── session-01/                  # Session 1: Language Fundamentals
    ├── agenda.md                 # Session agenda, objectives, resources
    ├── hello.mojo                 # Entry point and two run modes
    ├── static_typing.mojo          # Compiler catches a bad type assignment
    ├── uninitialized_variable.mojo # Compiler catches an uninitialized read
    ├── value_semantics.mojo        # Assignment gives independent copies
    ├── functions.mojo              # Project Euler: multiples of 3 or 5
    ├── variadics.mojo              # Project Euler: multiples of 3 or 5 (variadics)
    ├── structs.mojo                # Project Euler: sum square difference (structs)
    └── python_interop.mojo         # Calling Python modules from Mojo
└── session-02/                  # Session 2: Ownership, Lifecycle, and Metaprogramming
    ├── agenda.md                  # Session agenda, objectives, resources
    ├── ownership.mojo              # Argument conventions: immutable ref, mut, var
    ├── transfer.mojo               # Ownership transfer
    ├── lifecycle.mojo              # __init__, copy constructor, __del__
    ├── comptime.mojo                # Compile-time evaluation basics
    ├── comptime_if.mojo             # comptime if
    ├── comptime_for.mojo            # comptime for
    ├── parameters.mojo              # Parameterized structs/functions
    └── traits.mojo                  # Defining and conforming to a trait
└── session-03/                  # Session 3: The Standard Library: Collections and SIMD
    ├── agenda.md                  # Session agenda, objectives, resources
    ├── list.mojo                   # List basics: construct, append, iterate
    ├── list_traits.mojo             # Element-type trait requirements (Copyable, Movable)
    ├── list_ownership.mojo          # Passing a List with immutable ref vs. mut
    ├── inline_array.mojo            # InlineArray: fixed-size, stack-allocated arrays
    ├── dict.mojo                    # Dict: key-value storage and KeyElement
    ├── counter.mojo                 # Counter: tallying occurrences
    ├── set_and_optional.mojo        # Set membership and Optional for absent values
    └── simd.mojo                    # SIMD: construction, element-wise ops, reductions
```
