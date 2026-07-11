# Checking Types

Because the Base contracts are ordinary TypeContracts contracts, every TypeContracts
tool works directly against a concrete instantiation like `Vector{Int}` — the
registry key is the bare `AbstractArray` UnionAll, and TypeContracts resolves a
parameterized concrete type back to it automatically. This page covers the main
patterns.

## Boolean checks — `implements`

`implements(T, B)` is the idiomatic test-time check. It returns a plain `Bool` and
errors if `B` has no registered contract:

```julia
using Test, TypeContracts, BaseTypeContracts

@test implements(Vector{Int}, AbstractArray)
@test implements(Dict{String,Int}, AbstractDict)
@test implements(Int, Number)

@test !implements(String, AbstractArray)   # String has no size/getindex
```

`all_implements(T)` checks every applicable Base contract at once via `<:` matching:

```julia
@test all_implements(Vector{Int})    # checks AbstractArray
@test all_implements(Dict{Symbol,Int})   # checks AbstractDict
```

## Detailed inspection — `satisfies`

`satisfies(T, B)` returns a `NamedTuple` with the full diagnostic when you need to
know *which* methods are missing:

```julia
r = satisfies(Vector{Int}, AbstractArray)
r.satisfied        # true
r.missing_methods  # []
r.missing_optional # ["setindex!(::Self, ::Any, ::Int)", ...]

satisfies(String, AbstractArray).satisfied   # false — String has no size/getindex
```

!!! note
    Scalar numbers such as `Int` and `Float64` *do* satisfy the structural
    `AbstractArray` contract: `Base` defines `size`, `getindex` and `length` for
    them. Use `test_behavior` (and the array-specific invariants) if you need to
    distinguish a genuine array from a scalar that merely answers the same methods.

[`check`](@ref BaseTypeContracts.check) runs `satisfies` against every applicable Base contract and
returns the results as a `Dict`:

```julia
BaseTypeContracts.check(Dict{Symbol,Int})
# Dict(AbstractDict => (satisfied = true, …))

BaseTypeContracts.check(Float64)
# Dict(Number => (satisfied = true, …))
```

[`base_contract_types`](@ref BaseTypeContracts.base_contract_types) returns the Base types `check` iterates over (the
`Iterable` marker is excluded, since nothing is `<: Iterable`):

```julia
BaseTypeContracts.base_contract_types()
# (AbstractArray, AbstractDict, AbstractSet, AbstractString, Number, Real,
#  AbstractFloat, Integer, AbstractChar, IO, AbstractChannel)
```

## Behavioral testing — `behavior_passes` and `test_behavior`

Structural checks confirm methods *exist*; invariants confirm they *behave*. The
boolean helper integrates directly with `@test`:

```julia
@test behavior_passes(Vector{Int}, [[1, 2, 3], Int[]])
@test behavior_passes(Int, [0, 1, -5, 42])   # checks additive/multiplicative identity
```

For the iteration marker, query it explicitly:

```julia
@test behavior_passes(String, ["abc", ""]; S = Iterable)
```

For granular results per invariant, use `test_behavior` directly:

```julia
test_behavior(Vector{Int}, AbstractArray, [[1, 2, 3], Int[]])
# (passed = true, results = …, mandatory_failures = …)
```

## Trait dispatch — `interface_trait`

For dispatch on whether a type satisfies a contract, `interface_trait(B, T)` returns
`Implemented{B}()` or `NotImplemented{B}()`. It checks method existence only and is
`juliac --trim` safe, so it works in statically-compiled binaries:

```julia
interface_trait(AbstractArray, Vector{Int})   # Implemented{AbstractArray}()
interface_trait(AbstractArray, String)         # NotImplemented{AbstractArray}()

# Holy-trait pattern:
flatten(x) = _flatten(interface_trait(AbstractArray, typeof(x)), x)
_flatten(::Implemented{AbstractArray}, x) = vec(x)
_flatten(::NotImplemented{AbstractArray}, x) = [x]
```

## Sealing a stronger guarantee — `verified_trait`

`interface_trait` checks method *existence* only — it never inspects return types.
`verified_trait(B, T)` reflects the *full* check (existence and declared return
types) once `T` has actually been verified via `@verify`, `@verify_all`, or
`@delegate`. Unverified `(B, T)` pairs read as `NotImplemented{B}()`, even for a
type that would satisfy the contract structurally — sealing is nominal and opt-in,
not automatic:

```julia
verified_trait(AbstractArray, Vector{Int})   # NotImplemented{AbstractArray}() — not yet @verify'd

@verify Vector{Int}                          # runs check_contract, then seals on success
verified_trait(AbstractArray, Vector{Int})   # Implemented{AbstractArray}()
```

`@verify T` walks `T`'s entire supertype chain in one call, sealing every applicable
contract at once:

```julia
@verify Int
verified_trait(Number, Int)    # Implemented{Number}()
verified_trait(Real, Int)      # Implemented{Real}()
verified_trait(Integer, Int)   # Implemented{Integer}()
```

BaseTypeContracts itself does not pre-seal any Base type — which concrete
instantiations matter is up to your code, and `@verify` is one call away wherever
you already know the type. Like `interface_trait`, the sealed dispatch is
`juliac --trim` safe and allocation-free (`@verify` runs `Base.return_types` only at
module load / precompile time, never in the sealed method itself).

## Introspection — `describe`

`describe` prints a contract's methods and invariants — handy when you are not sure
what a Base protocol expects:

```julia
describe(AbstractSet)             # mandatory + optional methods
describe(Number, Val(:all))       # also lists behavioral invariants
```
