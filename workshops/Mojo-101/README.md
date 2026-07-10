# Mojo 101: Language Fundamentals

A hands-on workshop series for Python developers and CUDA/C++ engineers new to Mojo.

**Version target:** Mojo 1.0.0b2

## Sessions

| Session | Topic | Date |
|---------|-------|------|
| 1 | Language Fundamentals | July 9, 2026 |

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
```

> **Note:** Per Project Euler's rules, complete solutions are not published here.
