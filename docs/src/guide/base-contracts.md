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

## Quick reference

| Type | Mandatory methods | Optional methods | Invariants |
|------|-------------------|-----------------|------------|
| `AbstractArray` | `size`, `getindex`, `length` | `setindex!`, `similar`, `axes` | `length == prod(size)`; eachindex covers length |
| `AbstractDict` | `getindex`, `keys`, `values`, `haskey`, `length`, `iterate` | `setindex!` | length == #keys; every key present |
| `AbstractSet` | `in`, `length`, `iterate` | `push!`, `union`, `intersect` | elements are members; length == element count |
| `AbstractString` | `ncodeunits`, `codeunit`, `isvalid`, `iterate` (×2) | `length` | — |
| `Number` | `+`, `-`, `*`, `zero`, `one` | `/`, `abs` | `x + zero(x) == x`; `x * one(x) == x` |
| `Real` | `<`, `rem`, `mod` | — | `<` is irreflexive |
| `AbstractFloat` | — (inherits `Real`) | — | NaN ≠ itself; `isfinite` consistency |
| `Integer` | `&`, `\|`, `xor`, `~`, `div` | — | `&` idempotent; `~~x == x` |
| `AbstractChar` | `codepoint :: Integer` | — | `0 ≤ codepoint ≤ 0x10FFFF` |
| `IO` | `read(::UInt8)`, `write(::UInt8)`, `isopen`, `close` | `flush`, `eof`, `bytesavailable` | — |
| `AbstractChannel` | `put!`, `take!`, `isopen`, `close` | `isready`, `fetch` | — |
| `Iterable` *(marker)* | `iterate` | `length`, `eltype` | iterate returns `nothing` or 2-tuple |

Each level of the numeric hierarchy (`Number` → `Real` → `AbstractFloat`/`Integer`) adds only what is new at that level. Checking `Float64` covers `Number`, `Real`, and `AbstractFloat` contracts; checking `Int64` covers `Number`, `Real`, and `Integer`. The detailed sections below give the exact method signatures.

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

## `Real` — ordering

Adds an ordering protocol on top of `Number`. Checked for any `T <: Real` (e.g. `Float64`, `Int64`).

```julia
@contract Real begin
    <(::Self, ::Self) :: Bool
    rem(::Self, ::Self)
    mod(::Self, ::Self)
end
```

Invariants:

- `<` is irreflexive: `!(x < x)` for all `x`

## `AbstractFloat` — IEEE 754 semantics

No additional mandatory methods beyond `Real`; only behavioral invariants encoding IEEE 754 requirements. Checked for any `T <: AbstractFloat` (e.g. `Float64`, `Float32`).

Invariants:

- `NaN` is not equal to itself: `isnan(x) || x == x`
- `isfinite` is consistent: `isfinite(x) == (!isnan(x) && !isinf(x))`

## `Integer` — bitwise operations

Adds bitwise operations on top of `Real`. Checked for any `T <: Integer` (e.g. `Int64`, `UInt8`).

```julia
@contract Integer begin
    Base.:&(::Self, ::Self)
    Base.:(|)(::Self, ::Self)
    xor(::Self, ::Self)
    Base.:~(::Self)
    div(::Self, ::Self)
end
```

Invariants:

- `&` is idempotent: `(x & x) == x`
- bitwise complement is an involution: `~(~x) == x`

## `AbstractChar` — Unicode code point

```julia
@contract AbstractChar begin
    codepoint(::Self) :: Integer
end
```

Invariants:

- codepoint is non-negative
- codepoint is in the valid Unicode scalar value range: `codepoint(x) <= 0x10FFFF`

## `IO` — byte-level I/O

```julia
@contract IO begin
    read(::Self, ::Type{UInt8}) :: UInt8
    write(::Self, ::UInt8) :: Int
    isopen(::Self) :: Bool
    close(::Self)
    :optional
    flush(::Self)
    eof(::Self) :: Bool
    bytesavailable(::Self) :: Int
end
```

No behavioral invariants: `read` and `write` mutate stream state and are unsafe to test with deep-copied objects.

## `AbstractChannel` — concurrent messaging

```julia
@contract AbstractChannel begin
    put!(::Self, ::Any)
    take!(::Self)
    isopen(::Self) :: Bool
    close(::Self)
    :optional
    isready(::Self) :: Bool
    fetch(::Self)
end
```

No behavioral invariants: `put!` and `take!` may block, making predicate testing impractical.

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
implements(Vector{Int}, Iterable)                        # true
test_behavior(Vector{Int}, Iterable, [[1, 2, 3]])
```
