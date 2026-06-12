```@raw html
---
layout: home

hero:
  name: BaseTypeContracts.jl
  text: Ready-made contracts for Base
  tagline: The standard library's abstract types, already wired up with TypeContracts. Load the package and Vector, Dict, Set, String and Number carry their protocols.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: The Base Contracts
      link: /guide/base-contracts
    - theme: alt
      text: API Reference
      link: /reference/api

features:
  - title: Zero boilerplate
    icon: 📦
    details: "Loading the package registers structural contracts and behavioral invariants for the core Base abstract types. No declarations to write yourself."
  - title: Covers the core protocols
    icon: 🧩
    details: "AbstractArray, AbstractDict, AbstractSet, AbstractString, Number, Real, AbstractFloat, Integer, AbstractChar, IO, AbstractChannel — plus an Iterable marker for the iteration protocol."
  - title: Subtype-aware checking
    icon: 🔎
    details: "The check helper matches via <: so it works with parametric Base types like Vector{Int} and Dict{String,Int}, where a bare-UnionAll registry key would otherwise be missed."
  - title: Built on TypeContracts
    icon: 🔗
    details: "Everything is a normal TypeContracts contract — use implements, behavior_passes, describe and interface_trait exactly as you would with your own contracts."
  - title: Behavioral invariants
    icon: ✅
    details: "Beyond method existence, invariants encode real laws: length == prod(size), one is the multiplicative identity, every dict key is present. Validate them with test_behavior."
  - title: Trim / juliac safe
    icon: ⚡
    details: "interface_trait on the Base contracts passes juliac --trim verification, so the dispatch path is usable in statically-compiled binaries."
---
```

## What is BaseTypeContracts.jl?

BaseTypeContracts.jl is to [TypeContracts.jl](https://github.com/el-oso/TypeContracts.jl) what
`BaseInterfaces.jl` is to `Interfaces.jl`: a collection of pre-written contracts for
Julia's `Base` abstract types. Load it, and the standard-library protocols are
registered for you.

```julia
using TypeContracts, BaseTypeContracts

implements(Vector{Int}, AbstractArray)      # true
implements(Dict{String,Int}, AbstractDict)  # true
implements(Int, Number)                     # true

# Boolean check for all applicable Base contracts at once:
all_implements(Vector{Int})   # true

# Full diagnostic result:
BaseTypeContracts.check(Vector{Int})
# Dict(AbstractArray => (satisfied = true, …))
```

## Why a separate package?

The contracts live apart from TypeContracts so the core stays dependency-free and
unopinionated about `Base`. You opt in by adding `BaseTypeContracts` — and you get a
worked, tested reference for how non-trivial contracts (parametric types, the
iteration protocol, operator methods) are written.

## Registered contracts

| Contract target     | Protocol         | Example satisfying type |
|---------------------|------------------|-------------------------|
| `AbstractArray`     | indexing         | `Vector{Int}`           |
| `AbstractDict`      | associative      | `Dict{String,Int}`      |
| `AbstractSet`       | set              | `Set{Int}`              |
| `AbstractString`    | string           | `String`                |
| `Number`            | arithmetic       | `Int`, `Float64`        |
| `Real`              | ordering         | `Float64`, `Int64`      |
| `AbstractFloat`     | IEEE 754 laws    | `Float64`, `Float32`    |
| `Integer`           | bitwise ops      | `Int64`, `UInt8`        |
| `AbstractChar`      | code point       | `Char`                  |
| `IO`                | byte I/O         | `IOBuffer`              |
| `AbstractChannel`   | messaging        | `Channel{Int}`          |
| [`Iterable`](@ref)  | iteration        | queried explicitly      |

See [The Base Contracts](guide/base-contracts.md) for the exact method and invariant
list behind each one.
