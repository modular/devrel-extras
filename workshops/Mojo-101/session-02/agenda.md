# Session 2: Ownership, Lifecycle, and Metaprogramming

July 16, 2026 · 60 minutes

---

## What we'll cover

1. **Ownership** — argument conventions (immutable reference, `mut`, `var`)
2. **The value lifecycle** — constructor (`__init__`), copy, and destructor (`__del__`)
3. **Compile-time evaluation** — `comptime`, `comptime if`, and `comptime for`
4. **Traits** — defining a trait, conforming a struct, and writing generic functions
5. **Q&A** — 15 minutes open to questions

---

## Objectives

By the end of this session you should be able to:

- Choose the right argument convention — immutable reference, `mut`, or `var`
- Explain argument exclusivity and why Mojo rejects aliased `mut` references
- Define a struct's lifecycle methods: `__init__`, the copy constructor, and `__del__`
- Use `comptime`, `comptime if`, and `comptime for`
- Define a trait, conform a struct to it, and write a generic function

---

## Resources

- [Mojo Manual: Value ownership](https://mojolang.org/docs/manual/values/)
- [Mojo Manual: Value lifecycle](https://mojolang.org/docs/manual/lifecycle/)
- [Mojo Manual: Metaprogramming](https://mojolang.org/docs/manual/metaprogramming/)
- [Mojo Manual: Traits](https://mojolang.org/docs/manual/traits/)
- [Mojo Quest](https://quest.mojolang.org/)
- [Mojo GPU Puzzles](https://puzzles.modular.com/)
- [Modular Repo](https://github.com/modular/modular)
- [Modular Forum](https://forum.modular.com/)

---

## Optional Pre-reading

- [Mojo Manual: Intro to value ownership](https://mojolang.org/docs/manual/values/)
- [Mojo Manual: Ownership](https://mojolang.org/docs/manual/values/ownership/)
- [Mojo Manual: Intro to metaprogramming](https://mojolang.org/docs/manual/metaprogramming/)