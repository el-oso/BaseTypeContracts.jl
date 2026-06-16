@testitem "Registration" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts
    using BaseTypeContracts: base_contract_types

    @testset "contracts registered for all base types" begin
        reg = registered_contracts()
        for B in base_contract_types()
            # Most base types declare a `@contract` (appears in `registered_contracts`);
            # invariants-only types (e.g. AbstractFloat: no new mandatory methods beyond
            # Real, only IEEE 754 laws) appear via `list_behaviors` instead.
            @test haskey(reg, B) || !isempty(list_behaviors(B))
        end
        @test haskey(reg, Iterable)
    end

    @testset "invariants registered" begin
        @test !isempty(list_behaviors(AbstractArray))
        @test !isempty(list_behaviors(Number))
        @test !isempty(list_behaviors(Iterable))
    end
end
