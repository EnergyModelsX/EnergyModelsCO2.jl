using EnergyModelsCO2
using EnergyModelsBase
using HiGHS
using JuMP
using Test
using TimeStruct

const EMB = EnergyModelsBase
const EMC = EnergyModelsCO2

TEST_ATOL = 1e-6

@testset "EnergyModelsCO2" begin
    include("test_co2storage.jl")
    include("test_ccs_retrofit.jl")
    include("test_examples.jl")
end
