"""
    BaseTypeContracts

Ready-made [`TypeContracts`](https://github.com/el_oso/TypeContracts.jl) contracts
for Julia `Base` types — analogous to `BaseInterfaces.jl` for `Interfaces.jl`.

Loading this package registers structural contracts and behavioral invariants for
the core `Base` abstract types so you don't have to write them yourself:

| Contract target      | Protocol      |
|----------------------|---------------|
| `AbstractArray`      | indexing      |
| `AbstractDict`       | associative   |
| `AbstractSet`        | set           |
| `AbstractString`     | string        |
| `Number`             | arithmetic    |
| `Iterable` (marker)  | iteration     |

# Access pattern

TypeContracts' automatic supertype walk (`check_contract`, `@verify`) keys the
registry on concrete instantiations like `AbstractArray{Int,1}`, whereas these
contracts are registered on the bare `AbstractArray` UnionAll. Use the
[`check`](@ref) helper, which matches via `<:`, or call `satisfies`/`test_behavior`
with an explicit Base type:

```julia
using TypeContracts, BaseTypeContracts

satisfies(Vector{Int}, AbstractArray)        # (satisfied=true, ...)
satisfies(Dict{String,Int}, AbstractDict)    # (satisfied=true, ...)
satisfies(Vector{Int}, Iterable)             # iteration marker

BaseTypeContracts.check(Vector{Int})         # all applicable base contracts
```
"""
module BaseTypeContracts

using TypeContracts

export Iterable

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

const BASE_ABSTRACT_TYPES = (AbstractArray, AbstractDict, AbstractSet, AbstractString, Number)

"""
    check(T::Type) -> Dict{Type, NamedTuple}

Run `satisfies(T, B)` for every registered `Base` contract `B` where `T <: B`.
Returns a dict mapping each applicable Base type to its `satisfies` result.

This is the `BaseTypeContracts` equivalent of `check_contract`, using `<:`
matching so it works with parametric Base types (where the automatic supertype
walk would miss the bare UnionAll registry key).
"""
function check(::Type{T}) where {T}
    out = Dict{Type, NamedTuple}()
    for B in BASE_ABSTRACT_TYPES
        T <: B && (out[B] = satisfies(T, B))
    end
    out
end

"""
    base_contract_types() -> Tuple

Return the `Base` abstract types for which contracts are registered
(excludes the `Iterable` marker).
"""
base_contract_types() = BASE_ABSTRACT_TYPES

# ── Registration ──────────────────────────────────────────────────────
# Contracts mutate `TypeContracts`' global registry. Cross-module mutation at
# top level does not survive precompilation, so we register in `__init__`,
# which runs on every load.

function __init__()
    _register_contracts()
    _register_invariants()
    return nothing
end

function _register_contracts()
    # Only the one-arg `iterate` can be required structurally — the two-arg
    # form's state type is implementation-defined (e.g. `Int` for String),
    # so a fixed `iterate(::Self, ::Any)` signature would falsely fail. The
    # behavioral invariant below validates the full protocol instead.
    @contract Iterable begin
        iterate(::Self)
        :optional
        length(::Self)
        eltype(::Self)
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

    return nothing
end

function _register_invariants()
    @invariants Iterable begin
        "iterate returns nothing or a 2-tuple" => x -> begin
            r = iterate(x)
            isnothing(r) || (r isa Tuple && length(r) == 2)
        end
    end

    @invariants AbstractArray begin
        "length equals prod(size)" => x -> length(x) == prod(size(x))
        "eachindex covers length"  => x -> length(collect(eachindex(x))) == length(x)
    end

    @invariants AbstractDict begin
        "length equals number of keys" => x -> length(x) == length(keys(x))
        "every key is present"         => x -> all(k -> haskey(x, k), keys(x))
    end

    @invariants AbstractSet begin
        "every element is a member"    => x -> all(e -> e in x, x)
        "length equals element count"  => x -> length(x) == length(collect(x))
    end

    @invariants Number begin
        "zero is the additive identity"       => x -> x + zero(x) == x
        "one is the multiplicative identity"  => x -> x * one(x) == x
    end

    return nothing
end

end # module BaseTypeContracts
