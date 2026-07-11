@testitem "Behavioral invariants" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts

    @testset "AbstractArray invariants hold" begin
        result = test_behavior(Vector{Int}, AbstractArray, [[1, 2, 3], Int[], [10]])
        @test result.passed
    end

    @testset "Matrix invariants hold" begin
        result = test_behavior(Matrix{Int}, AbstractArray, [[1 2; 3 4], reshape(1:6, 2, 3) |> collect])
        @test result.passed
    end

    @testset "AbstractDict invariants hold" begin
        result = test_behavior(
            Dict{String, Int}, AbstractDict,
            [Dict("a" => 1, "b" => 2), Dict{String, Int}()]
        )
        @test result.passed
    end

    @testset "AbstractSet invariants hold" begin
        result = test_behavior(Set{Int}, AbstractSet, [Set([1, 2, 3]), Set{Int}()])
        @test result.passed
    end

    @testset "Number invariants hold" begin
        result = test_behavior(Int, Number, [0, 1, -5, 42])
        @test result.passed

        result = test_behavior(Float64, Number, [0.0, 1.5, -3.25])
        @test result.passed
    end

    @testset "Number invariants are NaN-safe and promotion-aware" begin
        # NaN fails every equality, including its own identity laws — the
        # invariant must not spuriously fail here.
        result = test_behavior(Float64, Number, [NaN, Inf, -0.0])
        @test result.passed

        # zero(π)/one(π) are Bool, narrower than π itself, so `x + zero(x)`
        # promotes to Float64 — the invariant must compare in the promoted type.
        result = test_behavior(typeof(pi), Number, [pi])
        @test result.passed
    end

    @testset "AbstractRange invariants hold" begin
        result = test_behavior(UnitRange{Int}, AbstractRange, [1:10, 1:0, 5:5])
        @test result.passed

        result = test_behavior(StepRange{Int, Int}, AbstractRange, [1:2:10, 10:-1:1])
        @test result.passed
    end

    @testset "Exception invariants hold" begin
        result = test_behavior(ErrorException, Exception, [ErrorException("boom")])
        @test result.passed

        result = test_behavior(
            BoundsError, Exception, [BoundsError([1, 2, 3], 5)]
        )
        @test result.passed
    end

    @testset "Random.AbstractRNG invariants hold" begin
        using Random: AbstractRNG, MersenneTwister, Xoshiro
        result = test_behavior(MersenneTwister, AbstractRNG, [MersenneTwister(42)])
        @test result.passed

        result = test_behavior(Xoshiro, AbstractRNG, [Xoshiro(42)])
        @test result.passed
    end

    @testset "Iterable invariants hold" begin
        result = test_behavior(Vector{Int}, Iterable, [[1, 2, 3], Int[]])
        @test result.passed

        result = test_behavior(String, Iterable, ["hello", ""])
        @test result.passed
    end
end
