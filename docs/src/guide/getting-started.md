# Getting Started

## Installation

BaseTypeContracts depends on [TypeContracts](https://github.com/el-oso/TypeContracts.jl).
Add both:

```julia
using Pkg
Pkg.add(["TypeContracts", "BaseTypeContracts"])
```

## Loading registers the contracts

There is nothing to declare. The moment you load the package, its `__init__`
registers structural contracts and behavioral invariants for the core `Base`
abstract types into the TypeContracts registry.

```julia
using TypeContracts, BaseTypeContracts

registered_contracts()   # now contains AbstractArray, AbstractDict, … and Iterable
```

## Checking a type

Ask whether a concrete type satisfies a Base protocol with `satisfies`:

```julia
satisfies(Vector{Int}, AbstractArray).satisfied      # true
satisfies(Matrix{Float64}, AbstractArray).satisfied  # true
satisfies(Dict{String,Int}, AbstractDict).satisfied  # true
satisfies(Set{Int}, AbstractSet).satisfied           # true
satisfies(String, AbstractString).satisfied          # true
satisfies(Int, Number).satisfied                     # true
```

`satisfies` returns a `NamedTuple`; `.satisfied` is the boolean, and the rest
explains any failure.

## The `check` convenience

`satisfies`, `implements`, `@verify`, and friends already work directly against a
parametric concrete type like `Vector{Int}` — TypeContracts resolves it back to the
registered `AbstractArray` UnionAll automatically, no special handling needed.

[`check`](@ref BaseTypeContracts.check) is a further convenience on top of that: instead of naming one Base
contract at a time, it returns *every* applicable one (matched by `<:` across the
curated `Base` types this package covers) in a single `Dict`:

```julia
BaseTypeContracts.check(Vector{Int})
# Dict{Type, NamedTuple} with 1 entry:
#   AbstractArray => (satisfied = true, …)
```

## Next steps

- [The Base Contracts](base-contracts.md) — the exact methods and invariants behind each protocol.
- [Checking Types](checking.md) — structural checks, behavioral testing, and trait dispatch.
