@testitem "verified_trait on Base contracts" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts

    @testset "unverified Base types stay NotImplemented" begin
        @test interface_trait(AbstractArray, Matrix{Int}) isa Implemented{AbstractArray}
        @test verified_trait(AbstractArray, Matrix{Int}) isa NotImplemented{AbstractArray}
    end

    @testset "@verify seals a concrete Base instantiation" begin
        @verify Vector{Int}
        @test verified_trait(AbstractArray, Vector{Int}) isa Implemented{AbstractArray}
    end

    @testset "@verify on a numeric type seals its whole supertype chain at once" begin
        @verify Int
        @test verified_trait(Number, Int) isa Implemented{Number}
        @test verified_trait(Real, Int) isa Implemented{Real}
        @test verified_trait(Integer, Int) isa Implemented{Integer}
        # Float64 was never @verify'd in this testitem — must not be sealed.
        @test verified_trait(Number, Float64) isa NotImplemented{Number}
    end
end
