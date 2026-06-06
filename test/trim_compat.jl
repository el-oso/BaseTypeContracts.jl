# Trim / juliac compatibility for the Base contracts registered by this package.
#
# The trim-safe query path is TypeContracts.interface_trait (method-existence
# only, a @generated function). check/satisfies additionally use Base.return_types
# and are not --trim-clean, so they are intentionally not validated here.
#
# JET and TrimCheck are imported at the top of runtests.jl. The Base contracts
# were registered by BaseTypeContracts.__init__ when it was loaded there.

# ── JET: no runtime dispatch when querying Base contracts ─────────────────────

@testset "JET.@test_opt — interface_trait on Base contracts" begin
    @testset "Vector satisfies AbstractArray" begin
        @test_opt target_modules = (TypeContracts,) interface_trait(AbstractArray, Vector{Int})
    end
    @testset "Dict satisfies AbstractDict" begin
        @test_opt target_modules = (TypeContracts,) interface_trait(AbstractDict, Dict{String,Int})
    end
    @testset "Int does not satisfy AbstractArray" begin
        @test_opt target_modules = (TypeContracts,) interface_trait(AbstractArray, Int)
    end
end

# ── TrimCheck: interface_trait passes juliac --trim against Base contracts ────
#
# `init` is a self-contained module so its body evaluates incrementally:
# `using BaseTypeContracts` runs its __init__ (registering the contracts) before
# the validated calls are generated. The calls reach interface_trait through the
# module; the Base types are global.
TrimCheck.@validate(
    BaseTrimFixture.interface_trait(Type{AbstractArray}, Type{Vector{Int}}),
    BaseTrimFixture.interface_trait(Type{AbstractDict}, Type{Dict{String,Int}}),
    BaseTrimFixture.interface_trait(Type{Number}, Type{Int}),
    BaseTrimFixture.interface_trait(Type{AbstractArray}, Type{Int}),
    errors_limit = Inf,
    warnings_limit = Inf,
    init = module BaseTrimFixture
        using TypeContracts
        using BaseTypeContracts   # __init__ registers the Base contracts
    end,
)
