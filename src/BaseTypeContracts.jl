"""
    BaseTypeContracts

Ready-made [`TypeContracts`](https://github.com/el-oso/TypeContracts.jl) contracts
for Julia `Base` types — analogous to `BaseInterfaces.jl` for `Interfaces.jl`.

Loading this package registers structural contracts and behavioral invariants for
the core `Base` abstract types so you don't have to write them yourself:

| Contract target      | Protocol         |
|----------------------|------------------|
| `AbstractArray`      | indexing         |
| `AbstractDict`       | associative      |
| `AbstractSet`        | set              |
| `AbstractString`     | string           |
| `Number`             | arithmetic       |
| `Real`               | ordering         |
| `AbstractFloat`      | IEEE 754 laws    |
| `Integer`            | bitwise ops      |
| `AbstractChar`       | code point       |
| `IO`                 | byte I/O         |
| `AbstractChannel`    | messaging        |
| `AbstractRange`      | stepped sequence |
| `Base.AbstractLock`  | mutual exclusion |
| `Logging.AbstractLogger` | log sink     |
| `AbstractDisplay`    | display sink     |
| `Base.AbstractPattern` | text matching  |
| `Exception`          | error reporting (invariants only) |
| `Random.AbstractRNG` | random streams (invariants only) |
| `Iterable` (marker)  | iteration        |

# Access pattern

Every TypeContracts tool works directly against a concrete instantiation like
`Vector{Int}` — the registry key is the bare `AbstractArray` UnionAll, and
TypeContracts resolves a parameterized concrete type back to it automatically:

```julia
using TypeContracts, BaseTypeContracts

implements(Vector{Int}, AbstractArray)         # true
implements(Dict{String,Int}, AbstractDict)     # true
implements(Vector{Int}, Iterable)              # iteration marker

@verify Vector{Int} for_contract=AbstractArray # seals verified_trait(AbstractArray, Vector{Int})
```

[`check`](@ref)/[`all_implements`](@ref) are convenience wrappers scoped to exactly
the curated `Base` types this package covers: instead of naming one contract at a
time, `check(T)` returns every applicable one in a single `Dict`, and
`all_implements(T)` summarizes that dict as a `Bool`:

```julia
BaseTypeContracts.check(Vector{Int})           # Dict(AbstractArray => (satisfied=true, ...))
BaseTypeContracts.all_implements(Vector{Int})  # true if all applicable contracts pass
```
"""
module BaseTypeContracts

using Reexport
@reexport using TypeContracts
import Base: AbstractLock, AbstractPattern
using Logging: AbstractLogger, LogLevel, handle_message, shouldlog, min_enabled_level, catch_exceptions
using Random: AbstractRNG

export Iterable, all_implements

# ── Iteration marker ──────────────────────────────────────────────────
# Iteration has no `Base` abstract supertype, so we provide a marker type.
# Query it explicitly: `satisfies(T, Iterable)` — the marker is never matched
# by a subtype walk (nothing is `<: Iterable`), which is intentional.

"""
    Iterable

Marker type carrying the `Base` iteration contract. No type is `<: Iterable`;
query it explicitly with `satisfies(T, Iterable)` or `test_behavior(T, Iterable, objs)`.
"""
abstract type Iterable end

# ── Base abstract types carrying contracts ────────────────────────────

const BASE_ABSTRACT_TYPES = (
    AbstractArray, AbstractDict, AbstractSet, AbstractString,
    Number, Real, AbstractFloat, Integer,
    AbstractChar, IO, AbstractChannel,
    AbstractRange, AbstractLock, AbstractLogger,
    AbstractDisplay, AbstractPattern, Exception, AbstractRNG,
)

"""
    check(T::Type) -> Dict{Type, NamedTuple}

Run `satisfies(T, B)` for every registered `Base` contract `B` where `T <: B`.
Returns a dict mapping each applicable Base type to its `satisfies` result.

Scoped to exactly the curated `Base` types this package covers ([`base_contract_types`](@ref)):
a convenience for getting every applicable contract's result in one call, rather
than naming each one individually with `satisfies`/`implements`.

For a simple boolean result use [`all_implements`](@ref), or for a single
interface use `implements(T, AbstractArray)` etc.
"""
function check(::Type{T}) where {T}
    out = Dict{Type, NamedTuple}()
    for B in BASE_ABSTRACT_TYPES
        T <: B && (out[B] = satisfies(T, B))
    end
    return out
end

"""
    all_implements(T::Type) -> Bool

Return `true` if `T` satisfies every applicable `Base` contract.
Equivalent to `all(r -> r.satisfied, values(check(T)))`. Designed for
direct use with `@test`:

```julia
@test all_implements(Vector{Int})
@test all_implements(Dict{String, Int})
```

Returns `true` (vacuously) for a type with no applicable `Base` contract at all —
unlike TypeContracts' own `implements(T)`, which throws `ArgumentError` in that case.
A typo'd or unrelated type therefore "passes" silently; if that matters, check
`!isempty(check(T))` first, or use `implements(T)` for the throwing variant.
"""
all_implements(T::Type) = all(r -> r.satisfied, values(check(T)))

"""
    base_contract_types() -> Tuple

Return the `Base` abstract types for which contracts are registered
(excludes the `Iterable` marker).
"""
base_contract_types() = BASE_ABSTRACT_TYPES

# ── Registration ──────────────────────────────────────────────────────

# Only the one-arg `iterate` can be required structurally — the two-arg
# form's state type is implementation-defined (e.g. `Int` for String),
# so a fixed `iterate(::Self, ::Any)` signature would falsely fail. The
# behavioral invariant below validates the full protocol instead.
# `eltype` is deliberately not listed: `Base.eltype(x) = eltype(typeof(x))` is a
# generic fallback for `::Any`, so `hasmethod` is always true and the "optional"
# marker would never do anything but add noise to `describe`.
@contract Iterable begin
    iterate(::Self)
    :optional
    length(::Self)
end

@contract AbstractArray begin
    size(::Self)
    getindex(::Self, ::Int)
    length(::Self)
    :optional
    setindex!(::Self, ::Any, ::Int)
    similar(::Self)
    axes(::Self)
end

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

@contract AbstractSet begin
    in(::Any, ::Self)
    length(::Self)
    iterate(::Self)
    :optional
    push!(::Self, ::Any)
    union(::Self, ::Self)
    intersect(::Self, ::Self)
end

@contract AbstractString begin
    ncodeunits(::Self)
    codeunit(::Self)
    isvalid(::Self, ::Int)
    iterate(::Self)
    iterate(::Self, ::Int)
    :optional
    length(::Self)
end

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


@invariants Iterable begin
    "iterate returns nothing or a 2-tuple" => x -> begin
        r = iterate(x)
        isnothing(r) || (r isa Tuple && length(r) == 2)
    end
end

@invariants AbstractArray begin
    "length equals prod(size)" => x -> length(x) == prod(size(x))
    "eachindex covers length" => x -> length(collect(eachindex(x))) == length(x)
end

@invariants AbstractDict begin
    "length equals number of keys" => x -> length(x) == length(keys(x))
    "every key is present" => x -> all(k -> haskey(x, k), keys(x))
end

@invariants AbstractSet begin
    "every element is a member" => x -> all(e -> e in x, x)
    "length equals element count" => x -> length(x) == length(collect(x))
end

@invariants Number begin
    # `x != x` guards NaN (which fails every equality, including its own identity
    # laws). `oftype(..., x)` makes the comparison promotion-aware: `zero(x)`/`one(x)`
    # can have a narrower type than `x` (e.g. `zero(π) isa Bool`), so `x + zero(x)`
    # promotes to a wider type than `x` itself — compare in that promoted type.
    "zero is the additive identity" => x -> x != x || x + zero(x) == oftype(x + zero(x), x)
    "one is the multiplicative identity" => x -> x != x || x * one(x) == oftype(x * one(x), x)
end

# Real: adds ordering on top of Number
@contract Real begin
    <(::Self, ::Self)::Bool
    rem(::Self, ::Self)
    mod(::Self, ::Self)
end

@invariants Real begin
    "< is irreflexive" => x -> !(x < x)
end

# AbstractFloat: no new mandatory methods beyond Real; only IEEE 754 invariants
@invariants AbstractFloat begin
    "NaN is not equal to itself" => x -> isnan(x) || x == x
    "isfinite is consistent with isnan and isinf" => x -> isfinite(x) == (!isnan(x) && !isinf(x))
end

# Integer: adds bitwise operations on top of Real
# &, |, ~ need the Base.:-qualified form — the Julia parser treats bare &(...) and
# ~(...) as prefix-operator expressions, not function calls, causing @contract to fail.
@contract Integer begin
    Base.:&(::Self, ::Self)
    Base.:(|)(::Self, ::Self)
    xor(::Self, ::Self)
    Base.:~(::Self)
    div(::Self, ::Self)
end

@invariants Integer begin
    "& is idempotent" => x -> (x & x) == x
    "bitwise complement is an involution" => x -> ~(~x) == x
end

@contract AbstractChar begin
    codepoint(::Self)::Integer
end

@invariants AbstractChar begin
    "codepoint is non-negative" => x -> codepoint(x) >= 0
    "codepoint is in valid Unicode range" => x -> codepoint(x) <= 0x0010FFFF
end

@contract IO begin
    read(::Self, ::Type{UInt8})::UInt8
    write(::Self, ::UInt8)::Int
    isopen(::Self)::Bool
    close(::Self)
    :optional
    flush(::Self)
    eof(::Self)::Bool
    bytesavailable(::Self)::Int
end

# No behavioral invariants for IO: read/write mutate state and may block,
# making them unsafe to test against deepcopy'd objects.

@contract AbstractChannel begin
    put!(::Self, ::Any)
    take!(::Self)
    isopen(::Self)::Bool
    close(::Self)
    :optional
    isready(::Self)::Bool
    fetch(::Self)
end

# No behavioral invariants for AbstractChannel: put!/take! block on
# empty/full channels, making safe predicate testing impractical.

@contract AbstractRange begin
    first(::Self)
    last(::Self)
    step(::Self)
end

@invariants AbstractRange begin
    "step is consistent with consecutive elements" =>
        x -> length(x) < 2 || x[2] - x[1] == step(x)
    "first and last bound a nonempty range" =>
        x -> isempty(x) || (first(x) in x && last(x) in x)
end

@contract AbstractLock begin
    lock(::Self)
    unlock(::Self)
    :optional
    trylock(::Self)::Bool
    islocked(::Self)::Bool
end

# No behavioral invariants for AbstractLock: lock/unlock have side effects and
# lock() blocks, making safe predicate testing impractical.

# LogLevel (not ::Any) matters here: Base's own loggers (ConsoleLogger, SimpleLogger)
# declare `level::LogLevel` in their `handle_message`/`shouldlog` methods, which is
# *more specific* than a `::Any` contract argument — TypeContracts would flag them as
# non-conforming (with a "more specific than the contract requires" warning) even
# though they implement the protocol correctly.
@contract AbstractLogger begin
    handle_message(::Self, ::LogLevel, ::Any, ::Any, ::Any, ::Any, ::Any, ::Any)
    shouldlog(::Self, ::LogLevel, ::Any, ::Any, ::Any)
    min_enabled_level(::Self)
    :optional
    catch_exceptions(::Self)
end

# No behavioral invariants for AbstractLogger: handle_message has I/O side effects.

@contract AbstractDisplay begin
    display(::Self, ::Any)
end

# No behavioral invariants for AbstractDisplay: display has I/O side effects.

@contract AbstractPattern begin
    occursin(::Self, ::AbstractString)
    findnext(::Self, ::AbstractString, ::Int)
end

# No behavioral invariants for AbstractPattern: match semantics are pattern-specific,
# there's no protocol-level law that holds for every implementer.

# Exception: `showerror(io, ex)` has a generic fallback for any `::Any`, so a
# structural contract would always pass vacuously — invariants-only, same as
# AbstractFloat.
@invariants Exception begin
    "showerror produces output" => x -> sprint(showerror, x) isa String
end

# Random.AbstractRNG: the real required methods (`rand(rng, ::SamplerTrivial{...})`)
# are sampler-machinery-specific and can't be expressed as a fixed @contract
# signature; `rand`/`seed!` on the abstract type itself have generic fallbacks, so a
# structural contract would be vacuous. Invariants-only, same rationale as Exception.
@invariants AbstractRNG begin
    "equal states produce equal streams" =>
        x -> rand(copy(x), UInt64) == rand(copy(x), UInt64)
end

end # module BaseTypeContracts
