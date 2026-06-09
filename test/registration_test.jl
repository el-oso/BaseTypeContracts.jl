@testitem "Registration" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts
    using BaseTypeContracts: base_contract_types

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
end
