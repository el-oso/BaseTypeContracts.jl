# Getting Started

## Installation

BaseTypeContracts depends on [TypeContracts](https://github.com/el_oso/TypeContracts.jl).
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

To see every Base contract that applies to a type — matched by `<:`, so parametric
types work — use [`check`](@ref BaseTypeContracts.check):

```julia
BaseTypeContracts.check(Vector{Int})
# Dict{Type, NamedTuple} with 1 entry:
#   AbstractArray => (satisfied = true, …)
```

## Why `<:` matching matters

TypeContracts' automatic supertype walk keys the registry on concrete
instantiations such as `AbstractArray{Int,1}`, but these contracts are registered on
the bare `AbstractArray` UnionAll. Pass an explicit Base type to `satisfies` /
`test_behavior`, or use [`check`](@ref BaseTypeContracts.check), which matches with `<:` and therefore finds
the contract for `Vector{Int}`.

## Next steps

- [The Base Contracts](base-contracts.md) — the exact methods and invariants behind each protocol.
- [Checking Types](checking.md) — structural checks, behavioral testing, and trait dispatch.
