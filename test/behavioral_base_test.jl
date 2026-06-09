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

    @testset "Iterable invariants hold" begin
        result = test_behavior(Vector{Int}, Iterable, [[1, 2, 3], Int[]])
        @test result.passed

        result = test_behavior(String, Iterable, ["hello", ""])
        @test result.passed
    end
end
