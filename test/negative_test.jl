@testitem "Negative cases" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts

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
end
