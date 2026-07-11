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

## In generated documentation

TypeContracts integrates with Documenter.jl so contract information appears in your
generated HTML docs. Two patterns are available:

**Pattern A — inline `@eval` block** (zero config, inject anywhere in a page):

````markdown
```@eval
using TypeContracts
TypeContracts.contract_md_string(AbstractArray)
```
````

**Pattern B — automatic `@docs` enhancement** (no per-page changes needed):

When `using Documenter` appears in `docs/make.jl`, the `TypeContractsDocumenterExt`
extension loads automatically and attaches the contract section to every registered
type's `Base.Docs` entry. A standard `@docs AbstractArray` block then shows the
contract inline.

This page is generated with Pattern B: `using Documenter` in `make.jl` is all that
was required.

See the [TypeContracts documentation integration guide](https://el-oso.github.io/TypeContracts.jl/dev/guide/documentation)
for full details.

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
| `AbstractRange` | `first`, `last`, `step` | — | step matches consecutive elements; first/last bound the range |
| `Base.AbstractLock` | `lock`, `unlock` | `trylock`, `islocked` | — |
| `Logging.AbstractLogger` | `handle_message`, `shouldlog`, `min_enabled_level` | `catch_exceptions` | — |
| `AbstractDisplay` | `display` | — | — |
| `Base.AbstractPattern` | `occursin`, `findnext` | — | — |
| `Exception` | — *(invariants only — structural check is vacuous)* | — | `showerror` produces a `String` |
| `Random.AbstractRNG` | — *(invariants only — structural check is vacuous)* | — | equal states produce equal streams |
| `Iterable` *(marker)* | `iterate` | `length` | iterate returns `nothing` or 2-tuple |

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

- `zero` is the additive identity: `x + zero(x) == x` (NaN-safe and promotion-aware,
  since `zero(x)`/`one(x)` can be narrower than `x`, e.g. `zero(π) isa Bool`)
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

## `AbstractRange` — stepped sequence

```julia
@contract AbstractRange begin
    first(::Self)
    last(::Self)
    step(::Self)
end
```

Invariants:

- `step` is consistent with consecutive elements: `x[2] - x[1] == step(x)` (for ranges with 2+ elements)
- `first` and `last` bound a nonempty range: both are members of the range

## `Base.AbstractLock` — mutual exclusion

`Base.AbstractLock` is public but unexported; import it explicitly
(`import Base: AbstractLock`) before referencing it.

```julia
@contract AbstractLock begin
    lock(::Self)
    unlock(::Self)
    :optional
    trylock(::Self) :: Bool
    islocked(::Self) :: Bool
end
```

No behavioral invariants: `lock`/`unlock` have side effects and `lock` blocks,
making predicate testing impractical.

## `Logging.AbstractLogger` — log sink

Requires the `Logging` stdlib. The level argument is typed `::LogLevel`, not `::Any`:
`Base`'s own loggers (`ConsoleLogger`, `SimpleLogger`) declare `level::LogLevel` in
`handle_message`/`shouldlog`, which is *more specific* than a `::Any` contract
argument — an `::Any` contract would flag them as non-conforming even though they
implement the protocol correctly.

```julia
@contract AbstractLogger begin
    handle_message(::Self, ::LogLevel, ::Any, ::Any, ::Any, ::Any, ::Any, ::Any)
    shouldlog(::Self, ::LogLevel, ::Any, ::Any, ::Any)
    min_enabled_level(::Self)
    :optional
    catch_exceptions(::Self)
end
```

No behavioral invariants: `handle_message` has I/O side effects.

## `AbstractDisplay` — display sink

```julia
@contract AbstractDisplay begin
    display(::Self, ::Any)
end
```

No behavioral invariants: `display` has I/O side effects.

## `Base.AbstractPattern` — text matching

`Base.AbstractPattern` is public but unexported; import it explicitly
(`import Base: AbstractPattern`) before referencing it.

```julia
@contract AbstractPattern begin
    occursin(::Self, ::AbstractString)
    findnext(::Self, ::AbstractString, ::Int)
end
```

No behavioral invariants: match semantics are pattern-specific — there's no
protocol-level law that holds for every implementer.

## `Exception` — error reporting

Structural-contract territory is vacuous here: `Base.showerror(io, ex)` has a
generic fallback for any `::Any`, so `hasmethod` is always `true` regardless of
whether a type actually implements anything meaningful. Registered as
invariants-only, the same pattern used for `AbstractFloat`:

```julia
@invariants Exception begin
    "showerror produces output" => x -> sprint(showerror, x) isa String
end
```

## `Random.AbstractRNG` — random streams

Also invariants-only: the real required methods (`rand(rng, ::SamplerTrivial{...})`)
are sampler-machinery-specific and can't be expressed as a fixed `@contract`
signature, and `rand`/`seed!` on the abstract type itself have generic fallbacks
that would make a structural contract vacuous.

```julia
@invariants AbstractRNG begin
    "equal states produce equal streams" =>
        x -> rand(copy(x), UInt64) == rand(copy(x), UInt64)
end
```

## `Iterable` — the iteration marker

Iteration has no `Base` abstract supertype, so BaseTypeContracts provides a marker
type, [`Iterable`](@ref). **No type is `<: Iterable`** — you query it explicitly.

```julia
@contract Iterable begin
    iterate(::Self)
    :optional
    length(::Self)
end
```

Only the one-argument `iterate` is required structurally: the two-argument form's
state type is implementation-defined (e.g. `Int` for `String`), so a fixed
`iterate(::Self, ::Any)` signature would falsely fail. The behavioral invariant
covers the full protocol instead. (`eltype` is not listed at all: `Base.eltype`
has a generic fallback for any type, so it would always be reported as present.)

- `iterate` returns `nothing` or a 2-tuple

Query it with an explicit type:

```julia
implements(Vector{Int}, Iterable)                        # true
test_behavior(Vector{Int}, Iterable, [[1, 2, 3]])
```
