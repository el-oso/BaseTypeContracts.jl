# BaseTypeContracts.jl
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://el-oso.github.io/BaseTypeContracts.jl/dev/)
Ready-made [TypeContracts.jl](https://github.com/el-oso/TypeContracts.jl) contracts
for Julia's `Base` types — analogous to `BaseInterfaces.jl` for `Interfaces.jl`.

Load the package and the core standard-library abstract types carry structural
contracts and behavioral invariants, so you don't have to write them yourself.

| Contract target   | Protocol         | Example satisfying type |
|-------------------|------------------|-------------------------|
| `AbstractArray`   | indexing         | `Vector{Int}`           |
| `AbstractDict`    | associative      | `Dict{String,Int}`      |
| `AbstractSet`     | set              | `Set{Int}`              |
| `AbstractString`  | string           | `String`                |
| `Number`          | arithmetic       | `Int`, `Float64`        |
| `Real`            | ordering         | `Float64`, `Int64`      |
| `AbstractFloat`   | IEEE 754 laws    | `Float64`, `Float32`    |
| `Integer`         | bitwise ops      | `Int64`, `UInt8`        |
| `AbstractChar`    | code point       | `Char`                  |
| `IO`              | byte I/O         | `IOBuffer`              |
| `AbstractChannel` | messaging        | `Channel{Int}`          |
| `Iterable`        | iteration        | queried explicitly      |

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
implements(Vector{Int}, AbstractArray)      # true
implements(Dict{String,Int}, AbstractDict)  # true
implements(Set{Int}, AbstractSet)           # true
implements(String, AbstractString)          # true
implements(Int, Number)                     # true

# Check all applicable contracts at once (returns Bool)
all_implements(Vector{Int})    # true
all_implements(Float64)        # true — covers Number, Real, AbstractFloat
```

### Detailed results

`check` returns the full `satisfies` result per applicable contract:

```julia
BaseTypeContracts.check(Vector{Int})
# Dict(AbstractArray => (satisfied = true, …))

BaseTypeContracts.check(Float64)
# Dict(Number => (satisfied = true, …), Real => (satisfied = true, …), …)
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
implements(Vector{Int}, Iterable)                        # true
test_behavior(String, Iterable, ["abc", ""])             # iterate returns nothing or a 2-tuple
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

Full documentation is available at **https://el-oso.github.io/BaseTypeContracts.jl/dev/**.

## License

See the repository for license details.
