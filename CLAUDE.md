# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Requirements

- **Easiness first** — the primary goal of this package is to make it trivially easy to check Base type conformance. Prefer the simplest API surface; avoid adding options or abstractions that users rarely need.
- **Format** all modified Julia files with Runic before committing: `runic -i .`
- **Update docs** whenever contracts, invariants, or public API change — both `docs/src/guide/base-contracts.md` (the contract table and detail sections) and `docs/src/reference/api.md`.
- **Trim compatibility** — contracts and invariants registered here must not break `juliac --trim` use of `interface_trait`. Structural contracts are fine (they only add to the `_registry` dict and `_contract_specs` methods). Avoid adding public functions that call `Base.return_types` or do abstract dispatch at runtime.

## Commands

```julia
# Format source
runic -i .

# Build documentation locally
julia --project=docs docs/make.jl

# Load and smoke-test in a REPL
julia --project=. -e 'using TypeContracts, BaseTypeContracts; println(all_implements(Vector{Int}))'
```

## Architecture

Single-file package: `src/BaseTypeContracts.jl`. No extensions. Depends on `TypeContracts` and `Reexport`.

### What this package does

Calls `@contract` and `@invariants` at top level for each Base abstract type. Because `@contract` emits method definitions (not dict mutations), these registrations survive precompilation and are safe across multi-package environments.

`BASE_ABSTRACT_TYPES` is the canonical tuple of types covered by `check` and `all_implements`. Adding a new type means: add a `@contract` block, optionally an `@invariants` block, append to `BASE_ABSTRACT_TYPES`, update the table in `base-contracts.md`.

TypeContracts' registry keys on the bare abstract-type UnionAll and resolves concrete parameterized instantiations back to it automatically — `implements`, `satisfies`, `check_contract`, `@verify`, and `verified_trait` all work directly against e.g. `Vector{Int}`, no special handling needed here. `check`/`all_implements` are convenience wrappers scoped to the curated `BASE_ABSTRACT_TYPES` list, not workarounds for a registry limitation.

### Operator names in `@contract`

Operators `&`, `|`, `~` must use the `Base.:-qualified` form (`Base.:&(...)` etc.) in `@contract` blocks. The Julia parser treats bare `&(...)` and `~(...)` as prefix-operator expressions rather than function calls, causing the macro to fail. `+`, `-`, `*`, `<` do not have this problem.

### `@contract` headers cannot be module-qualified

`@contract Base.AbstractLock begin ... end` fails to parse — `_parse_contract_header` only accepts a bare symbol or `Symbol{T,...}`. Worse, forgetting to `import` first does **not** error: `@contract`'s auto-stub silently defines a *new local* abstract type with that name and registers the contract on it instead of the intended Base/stdlib type. Always `import Base: AbstractLock` (or the stdlib equivalent) before writing `@contract AbstractLock begin ... end`.

### `Iterable` marker

`Iterable` is a locally-defined abstract type (nothing in Base is `<: Iterable`). It carries the iteration contract and must be queried explicitly with `implements(T, Iterable)` or `test_behavior(T, Iterable, objs)`.
