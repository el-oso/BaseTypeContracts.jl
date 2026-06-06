# Checking Types

Because the Base contracts are ordinary TypeContracts contracts, every TypeContracts
tool works on them. This page shows the three you will reach for most.

## Structural checks — `satisfies`

`satisfies(T, B)` answers "does `T` implement every mandatory method of contract
`B`?" and returns a `NamedTuple` describing the result.

```julia
using TypeContracts, BaseTypeContracts

r = satisfies(Vector{Int}, AbstractArray)
r.satisfied        # true

satisfies(Int, AbstractArray).satisfied   # false — Int has no size/getindex
```

To run every applicable Base contract for a type at once, use [`check`](@ref BaseTypeContracts.check). It
matches with `<:`, so it works for parametric instantiations:

```julia
BaseTypeContracts.check(Dict{Symbol,Int})
# Dict(AbstractDict => (satisfied = true, …))

BaseTypeContracts.check(Float64)
# Dict(Number => (satisfied = true, …))
```

[`base_contract_types`](@ref BaseTypeContracts.base_contract_types) returns the Base types `check` iterates over (the
`Iterable` marker is excluded, since nothing is `<: Iterable`):

```julia
base_contract_types()
# (AbstractArray, AbstractDict, AbstractSet, AbstractString, Number)
```

## Behavioral testing — `test_behavior`

Structural checks confirm methods *exist*; invariants confirm they *behave*. Pass
real objects and the registered invariants are run against copies of them:

```julia
test_behavior(Vector{Int}, AbstractArray, [[1, 2, 3], Int[]])
# (passed = true, results = …, mandatory_failures = …)

test_behavior(Int, Number, [0, 1, -5, 42])
# checks x + zero(x) == x and x * one(x) == x
```

For the iteration marker, query it explicitly:

```julia
test_behavior(String, Iterable, ["abc", ""])
```

## Trait dispatch — `interface_trait`

For dispatch on whether a type satisfies a contract, `interface_trait(B, T)` returns
`Implemented{B}()` or `NotImplemented{B}()`. It checks method existence only and is
`juliac --trim` safe, so it works in statically-compiled binaries:

```julia
interface_trait(AbstractArray, Vector{Int})   # Implemented{AbstractArray}()
interface_trait(AbstractArray, Int)            # NotImplemented{AbstractArray}()

# Holy-trait pattern:
flatten(x) = _flatten(interface_trait(AbstractArray, typeof(x)), x)
_flatten(::Implemented{AbstractArray}, x) = vec(x)
_flatten(::NotImplemented{AbstractArray}, x) = [x]
```

## Introspection — `describe`

`describe` prints a contract's methods and invariants — handy when you are not sure
what a Base protocol expects:

```julia
describe(AbstractSet)             # mandatory + optional methods
describe(Number, Val(:all))       # also lists behavioral invariants
```
