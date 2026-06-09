@testitem "describe base contracts" setup = [BTCFixtures] begin
    using Test
    using TypeContracts
    using BaseTypeContracts

    @testset "describe base contract" begin
        buf = IOBuffer()
        describe(Number; io = buf)
        output = String(take!(buf))
        @test occursin("Number", output)
        @test occursin("Mandatory methods:", output)
        @test occursin("zero(::Self)", output)
        @test occursin("Optional methods:", output)
        @test occursin("Behavioral invariants:", output)
    end
end
