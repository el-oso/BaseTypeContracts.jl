# BaseTypeContracts.jl

Ready-made [TypeContracts.jl](https://github.com/el_oso/TypeContracts.jl) contracts
for Julia's `Base` types — analogous to `BaseInterfaces.jl` for `Interfaces.jl`.

Load the package and the core standard-library abstract types carry structural
contracts and behavioral invariants, so you don't have to write them yourself.

| Contract target  | Protocol    | Example satisfying type |
|------------------|-------------|-------------------------|
| `AbstractArray`  | indexing    | `Vector{Int}`           |
| `AbstractDict`   | associative | `Dict{String,Int}`      |
| `AbstractSet`    | set         | `Set{Int}`              |
| `AbstractString` | string      | `String`                |
| `Number`         | arithmetic  | `Int`, `Float64`        |
| `Iterable`       | iteration   | queried explicitly      |

## Installation

```julia
using Pkg
Pkg.add(["TypeContracts", "BaseTypeContracts"])
```

## Usage

Loading the package registers everything — there is nothing to declare.

```julia
using TypeContracts, BaseTypeContracts

# Does a type satisfy a Base protocol?
satisfies(Vector{Int}, AbstractArray).satisfied      # true
satisfies(Dict{String,Int}, AbstractDict).satisfied  # true
satisfies(Set{Int}, AbstractSet).satisfied           # true
satisfies(String, AbstractString).satisfied          # true
satisfies(Int, Number).satisfied                     # true
```

### Check every applicable contract at once

`check` matches with `<:`, so it works with parametric types:

```julia
BaseTypeContracts.check(Vector{Int})
# Dict(AbstractArray => (satisfied = true, …))

BaseTypeContracts.check(Float64)
# Dict(Number => (satisfied = true, …))
```

### Behavioral invariants

The contracts encode real laws, not just method existence — validate them against
real objects:

```julia
test_behavior(Vector{Int}, AbstractArray, [[1, 2, 3], Int[]])
# checks length == prod(size), eachindex covers length

test_behavior(Int, Number, [0, 1, -5, 42])
# checks x + zero(x) == x and x * one(x) == x
```

### The iteration marker

Iteration has no `Base` abstract supertype, so `BaseTypeContracts` provides the
`Iterable` marker. Nothing is `<: Iterable` — query it explicitly:

```julia
satisfies(Vector{Int}, Iterable).satisfied   # true
test_behavior(String, Iterable, ["abc", ""]) # iterate returns nothing or a 2-tuple
```

### Trait dispatch (juliac-safe)

`interface_trait` is `--trim` clean, so it works in statically-compiled binaries:

```julia
interface_trait(AbstractArray, Vector{Int})  # Implemented{AbstractArray}()
interface_trait(AbstractArray, String)        # NotImplemented{AbstractArray}()
```

(Note: numbers such as `Int` *do* satisfy the structural `AbstractArray` contract —
`Base` defines `size`, `getindex` and `length` for scalars — so `String` is used
here as a type that genuinely lacks the indexing methods.)

### Inspect a contract

```julia
describe(AbstractArray)         # mandatory + optional methods
describe(Number, Val(:all))     # also lists behavioral invariants
```

## Documentation

Full documentation is built with
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl); see the
`docs/` directory. The guide covers [the exact contracts](docs/src/guide/base-contracts.md)
and [how to check types](docs/src/guide/checking.md).

## License

See the repository for license details.
