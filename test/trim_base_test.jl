@testitem "TrimCheck and JET (Base contracts)" setup = [BTCFixtures] tags = [:slow] begin
    using Test
    using TypeContracts
    using BaseTypeContracts
    using JET: @test_opt
    import TrimCheck

    @testset "JET.@test_opt — interface_trait on Base contracts" begin
        @testset "Vector satisfies AbstractArray" begin
            @test_opt target_modules = (TypeContracts,) interface_trait(AbstractArray, Vector{Int})
        end
        @testset "Dict satisfies AbstractDict" begin
            @test_opt target_modules = (TypeContracts,) interface_trait(AbstractDict, Dict{String, Int})
        end
        @testset "String does not satisfy AbstractArray" begin
            # NB: numbers (Int, Float64) *do* satisfy the structural AbstractArray
            # contract — Base defines size/getindex/length for scalars — so String is
            # used here to exercise the NotImplemented branch.
            @test_opt target_modules = (TypeContracts,) interface_trait(AbstractArray, String)
        end
    end

    TrimCheck.@validate(
        BaseTrimFixture.interface_trait(Type{AbstractArray}, Type{Vector{Int}}),
        BaseTrimFixture.interface_trait(Type{AbstractDict}, Type{Dict{String, Int}}),
        BaseTrimFixture.interface_trait(Type{Number}, Type{Int}),
        BaseTrimFixture.interface_trait(Type{AbstractArray}, Type{String}),
        errors_limit = Inf,
        warnings_limit = Inf,
        init = module BaseTrimFixture
        using TypeContracts
        using BaseTypeContracts   # __init__ registers the Base contracts
        end,
    )
end
