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
    ├── hello.mojo               # Segment 1 demo: entry point and two run modes
    ├── demos/                   # Segment 2 demos: why Mojo?
    │   ├── strict_typing.mojo       # Compiler catches a bad type assignment
    │   ├── value_semantics.mojo     # Assignment gives independent copies
    │   └── uninitialized_variable.mojo  # Compiler catches an uninitialized read
    └── euler/                   # Project Euler starters (solved live during session)
        ├── problem_01.mojo      # Multiples of 3 or 5
        ├── problem_02.mojo      # Even Fibonacci Numbers
        ├── problem_04.mojo      # Largest Palindrome Product
        ├── problem_06.mojo      # Sum Square Difference
        └── problem_08.mojo      # Largest Product in a Series
```

> **Note:** Per Project Euler's rules, complete solutions are not published here.