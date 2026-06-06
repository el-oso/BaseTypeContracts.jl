using Test
using TypeContracts
using BaseTypeContracts
using BaseTypeContracts: check, base_contract_types
using JET: @test_opt
import TrimCheck

@testset "BaseTypeContracts.jl" begin

    # ── Registration happened in __init__ ─────────────────────────────

    @testset "contracts registered for all base types" begin
        reg = registered_contracts()
        for B in base_contract_types()
            @test haskey(reg, B)
        end
        @test haskey(reg, Iterable)
    end

    @testset "invariants registered" begin
        @test !isempty(list_behaviors(AbstractArray))
        @test !isempty(list_behaviors(Number))
        @test !isempty(list_behaviors(Iterable))
    end

    # ── Base types satisfy their own contracts (structural) ───────────

    @testset "AbstractArray contract" begin
        @test satisfies(Vector{Int}, AbstractArray).satisfied
        @test satisfies(Matrix{Float64}, AbstractArray).satisfied
        @test satisfies(BitVector, AbstractArray).satisfied
    end

    @testset "AbstractDict contract" begin
        @test satisfies(Dict{String,Int}, AbstractDict).satisfied
        @test satisfies(IdDict, AbstractDict).satisfied
    end

    @testset "AbstractSet contract" begin
        @test satisfies(Set{Int}, AbstractSet).satisfied
        @test satisfies(BitSet, AbstractSet).satisfied
    end

    @testset "AbstractString contract" begin
        @test satisfies(String, AbstractString).satisfied
        @test satisfies(SubString{String}, AbstractString).satisfied
    end

    @testset "Number contract" begin
        @test satisfies(Int, Number).satisfied
        @test satisfies(Float64, Number).satisfied
        @test satisfies(Rational{Int}, Number).satisfied
    end

    @testset "Iterable marker" begin
        @test satisfies(Vector{Int}, Iterable).satisfied
        @test satisfies(String, Iterable).satisfied
        @test satisfies(Tuple{Int,Int}, Iterable).satisfied
        @test satisfies(Dict{String,Int}, Iterable).satisfied
    end

    # ── check() helper (<:-based access) ──────────────────────────────

    @testset "check() finds applicable contracts via <:" begin
        result = check(Vector{Int})
        @test haskey(result, AbstractArray)
        @test result[AbstractArray].satisfied
        @test !haskey(result, AbstractDict)  # Vector is not a Dict
    end

    @testset "check() on a Number" begin
        result = check(Int)
        @test haskey(result, Number)
        @test result[Number].satisfied
    end

    @testset "check() on a String" begin
        result = check(String)
        @test haskey(result, AbstractString)
        @test result[AbstractString].satisfied
    end

    # ── Behavioral testing on real Base instances ─────────────────────

    @testset "AbstractArray invariants hold" begin
        result = test_behavior(Vector{Int}, AbstractArray, [[1,2,3], Int[], [10]])
        @test result.passed
    end

    @testset "Matrix invariants hold" begin
        result = test_behavior(Matrix{Int}, AbstractArray, [[1 2; 3 4], reshape(1:6, 2, 3) |> collect])
        @test result.passed
    end

    @testset "AbstractDict invariants hold" begin
        result = test_behavior(Dict{String,Int}, AbstractDict,
                               [Dict("a"=>1, "b"=>2), Dict{String,Int}()])
        @test result.passed
    end

    @testset "AbstractSet invariants hold" begin
        result = test_behavior(Set{Int}, AbstractSet, [Set([1,2,3]), Set{Int}()])
        @test result.passed
    end

    @testset "Number invariants hold" begin
        result = test_behavior(Int, Number, [0, 1, -5, 42])
        @test result.passed

        result = test_behavior(Float64, Number, [0.0, 1.5, -3.25])
        @test result.passed
    end

    @testset "Iterable invariants hold" begin
        result = test_behavior(Vector{Int}, Iterable, [[1,2,3], Int[]])
        @test result.passed

        result = test_behavior(String, Iterable, ["hello", ""])
        @test result.passed
    end

    # ── Negative: incomplete types are caught ─────────────────────────

    @testset "non-conforming type fails satisfies" begin
        struct NotAnArray end
        result = satisfies(NotAnArray, AbstractArray)
        @test !result.satisfied
        @test !isempty(result.missing_methods)
    end

    @testset "non-iterable type fails Iterable marker" begin
        struct NotIterable end
        result = satisfies(NotIterable, Iterable)
        @test !result.satisfied
    end

    # ── describe() works on base contracts ────────────────────────────

    @testset "describe base contract" begin
        buf = IOBuffer()
        describe(Number; io=buf)
        output = String(take!(buf))
        @test occursin("Number", output)
        @test occursin("Mandatory methods:", output)
        @test occursin("zero(::Self)", output)
        @test occursin("Optional methods:", output)
        @test occursin("Behavioral invariants:", output)
    end

    include("trim_compat.jl")

end
