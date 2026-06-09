@testitem "Base type contracts" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts

    @testset "AbstractArray contract" begin
        @test satisfies(Vector{Int}, AbstractArray).satisfied
        @test satisfies(Matrix{Float64}, AbstractArray).satisfied
        @test satisfies(BitVector, AbstractArray).satisfied
    end

    @testset "AbstractDict contract" begin
        @test satisfies(Dict{String, Int}, AbstractDict).satisfied
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
        @test satisfies(Tuple{Int, Int}, Iterable).satisfied
        @test satisfies(Dict{String, Int}, Iterable).satisfied
    end
end
