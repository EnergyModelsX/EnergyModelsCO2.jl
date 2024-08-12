using EnergyModelsCO2
using EnergyModelsBase
using HiGHS
using JuMP
using Test
using TimeStruct

const EMB = EnergyModelsBase
const EMC = EnergyModelsCO2

TEST_ATOL = 1e-6

@testset "CO2" begin
    @testset "CO2 - Storage" begin
        include("test_co2storage.jl")
    end

    @testset "CO2 - Capture retrofit" begin
        include("test_ccs_retrofit.jl")
    end

    @testset "CO2 - Checks" begin
        include("test_checks.jl")
    end

    @testset "CO2 - examples" begin
        include("test_examples.jl")
    end
end
