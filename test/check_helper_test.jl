@testitem "check() helper" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts
    using BaseTypeContracts: check

    @testset "check() finds applicable contracts via <:" begin
        result = check(Vector{Int})
        @test haskey(result, AbstractArray)
        @test result[AbstractArray].satisfied
        @test !haskey(result, AbstractDict)
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
end
