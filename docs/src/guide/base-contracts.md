# The Base Contracts

Loading BaseTypeContracts registers one structural contract per Base abstract type,
and behavioral invariants for most of them. This page lists exactly what each
requires. Mandatory methods must exist (and, where annotated, return the declared
type); optional methods are reported by `describe` but never cause a failure.

You can always inspect a contract at the REPL:

```julia
describe(AbstractArray)        # mandatory + optional methods
describe(Number, Val(:all))    # also lists behavioral invariants
```

## `AbstractArray` — indexing

```julia
@contract AbstractArray begin
    size(::Self)
    getindex(::Self, ::Int)
    length(::Self)
    :optional
    setindex!(::Self, ::Any, ::Int)
    similar(::Self)
    axes(::Self)
end
```

Invariants:

- `length == prod(size)`
- `eachindex` covers `length`

## `AbstractDict` — associative

```julia
@contract AbstractDict begin
    getindex(::Self, ::Any)
    keys(::Self)
    values(::Self)
    haskey(::Self, ::Any)
    length(::Self)
    iterate(::Self)
    :optional
    setindex!(::Self, ::Any, ::Any)
end
```

Invariants:

- `length` equals the number of keys
- every key is present (`haskey` is true for each `keys(x)`)

## `AbstractSet` — set

```julia
@contract AbstractSet begin
    in(::Any, ::Self)
    length(::Self)
    iterate(::Self)
    :optional
    push!(::Self, ::Any)
    union(::Self, ::Self)
    intersect(::Self, ::Self)
end
```

Invariants:

- every element is a member of the set it came from
- `length` equals the collected element count

## `AbstractString` — string

```julia
@contract AbstractString begin
    ncodeunits(::Self)
    codeunit(::Self)
    isvalid(::Self, ::Int)
    iterate(::Self)
    iterate(::Self, ::Int)
    :optional
    length(::Self)
end
```

## `Number` — arithmetic

```julia
@contract Number begin
    +(::Self, ::Self)
    -(::Self, ::Self)
    *(::Self, ::Self)
    zero(::Self)
    one(::Self)
    :optional
    /(::Self, ::Self)
    abs(::Self)
end
```

Invariants:

- `zero` is the additive identity: `x + zero(x) == x`
- `one` is the multiplicative identity: `x * one(x) == x`

## `Iterable` — the iteration marker

Iteration has no `Base` abstract supertype, so BaseTypeContracts provides a marker
type, [`Iterable`](@ref). **No type is `<: Iterable`** — you query it explicitly.

```julia
@contract Iterable begin
    iterate(::Self)
    :optional
    length(::Self)
    eltype(::Self)
end
```

Only the one-argument `iterate` is required structurally: the two-argument form's
state type is implementation-defined (e.g. `Int` for `String`), so a fixed
`iterate(::Self, ::Any)` signature would falsely fail. The behavioral invariant
covers the full protocol instead:

- `iterate` returns `nothing` or a 2-tuple

Query it with an explicit type:

```julia
satisfies(Vector{Int}, Iterable).satisfied   # true
test_behavior(Vector{Int}, Iterable, [[1, 2, 3]])
```
