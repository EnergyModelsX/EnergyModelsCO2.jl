using Test

@testset "EnergyModelsCO2" begin
    include("test_co2storage.jl")
    include("test_examples.jl")
end
