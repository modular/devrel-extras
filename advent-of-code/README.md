# Advent of Code in Mojo

Solutions to [Advent of Code](https://adventofcode.com/) puzzles in Mojo. Each
solution has comments explaining the Mojo idioms it uses. For a guided
introduction, see [Advent of Mojo](https://advent.mojolang.org/).

## Setup

You need macOS on Apple silicon or Linux (x86-64 or ARM64). On Windows, use
WSL.

1. Install [pixi](https://pixi.sh):

   ```sh
   curl -fsSL https://pixi.sh/install.sh | sh
   ```

2. From this folder, install Mojo. `pixi.lock` pins the version, so everyone
   gets the same one:

   ```sh
   pixi install
   pixi run mojo --version
   ```

## Add your puzzle input

Advent of Code asks people not to share their puzzle inputs, so `input/`
folders are gitignored. For each day, save your input from the puzzle page:

```text
2025/input/day01.txt
```

## Run a solution

Run from the year's folder, because solutions read `input/` relative to where
you run them:

```sh
cd 2025
pixi run mojo day01_p1.mojo   # Part 1 only
pixi run mojo day01_p2.mojo   # both parts
```

## Run the tests

Each day has a test file that checks the puzzle's worked example and some edge
cases:

```sh
cd 2025
pixi run mojo day01_test.mojo
```
