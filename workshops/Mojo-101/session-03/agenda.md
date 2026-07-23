# Session 3: The Standard Library: Collections and SIMD

July 23, 2026 · 60 minutes

---

## What we'll cover

1. **`List` and `InlineArray`** — dynamic and fixed-size arrays
2. **`Dict` and `Counter`** — key-value storage and counting
3. **`Set` and `Optional`** — membership, uniqueness, and modeling absence
4. **`SIMD`** — the vector type: construction, element-wise ops, and reductions
5. **Q&A** — 15 minutes open to questions

---

## Objectives

By the end of this session you should be able to:

- Choose between `List` and `InlineArray` for dynamic vs. fixed-size collections
- Use `Dict` for key-value storage and `Counter` for tallying occurrences
- Use `Set` for membership and uniqueness, and `Optional` for possibly None values
- Construct a `SIMD` vector, apply element-wise operations, and perform reductions
- Explain why vectorized code with `SIMD` can outperform an equivalent scalar loop

---

## Resources

- [Mojo Standard Library: collections](https://mojolang.org/docs/std/collections/)
- [Mojo Standard Library: List](https://mojolang.org/docs/std/collections/list/)
- [Mojo Standard Library: Dict](https://mojolang.org/docs/std/collections/dict/)
- [Mojo Standard Library: Counter](https://mojolang.org/docs/std/collections/counter/Counter/)
- [Mojo Standard Library: Set](https://mojolang.org/docs/std/collections/set/)
- [Mojo Standard Library: Optional](https://mojolang.org/docs/std/collections/optional/)
- [Mojo Standard Library: SIMD](https://mojolang.org/docs/std/builtin/simd/SIMD/)
- [Mojo Quest](https://quest.mojolang.org/)
- [Mojo GPU Puzzles](https://puzzles.modular.com/)
- [Modular Repo](https://github.com/modular/modular)
- [Modular Forum](https://forum.modular.com/)

---

## Optional Pre-reading

- [Mojo Standard Library: collections](https://mojolang.org/docs/std/collections/)
- [Mojo Standard Library: SIMD reference](https://mojolang.org/docs/std/builtin/simd/SIMD/)
