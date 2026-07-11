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

    @testset "AbstractRange contract" begin
        @test satisfies(UnitRange{Int}, AbstractRange).satisfied
        @test satisfies(StepRange{Int, Int}, AbstractRange).satisfied
        @test satisfies(Base.OneTo{Int}, AbstractRange).satisfied
    end

    @testset "Base.AbstractLock contract" begin
        @test satisfies(ReentrantLock, Base.AbstractLock).satisfied
        @test satisfies(Base.Threads.SpinLock, Base.AbstractLock).satisfied
    end

    @testset "Logging.AbstractLogger contract" begin
        using Logging: AbstractLogger, ConsoleLogger, SimpleLogger, NullLogger
        @test satisfies(ConsoleLogger, AbstractLogger).satisfied
        @test satisfies(SimpleLogger, AbstractLogger).satisfied
        @test satisfies(NullLogger, AbstractLogger).satisfied
    end

    @testset "AbstractDisplay contract" begin
        @test satisfies(Base.TextDisplay, AbstractDisplay).satisfied
    end

    @testset "Base.AbstractPattern contract" begin
        @test satisfies(Regex, Base.AbstractPattern).satisfied
    end

    @testset "Exception contract (structural, always satisfied)" begin
        @test satisfies(ErrorException, Exception).satisfied
        @test satisfies(ArgumentError, Exception).satisfied
    end

    @testset "Random.AbstractRNG contract (structural, always satisfied)" begin
        using Random: AbstractRNG, MersenneTwister, Xoshiro
        @test satisfies(MersenneTwister, AbstractRNG).satisfied
        @test satisfies(Xoshiro, AbstractRNG).satisfied
    end

    @testset "Iterable marker" begin
        @test satisfies(Vector{Int}, Iterable).satisfied
        @test satisfies(String, Iterable).satisfied
        @test satisfies(Tuple{Int, Int}, Iterable).satisfied
        @test satisfies(Dict{String, Int}, Iterable).satisfied
    end
end
