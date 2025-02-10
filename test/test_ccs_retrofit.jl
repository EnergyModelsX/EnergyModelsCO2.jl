# Definition of the CO2 resource
CO2 = ResourceEmit("CO2", 1.0)
CO2_proxy = ResourceCarrier("CO2 proxy", 0)
NG = ResourceCarrier("NG", 0.2)
Power = ResourceCarrier("Power", 0.2)
products = [CO2, NG, Power, CO2_proxy]

function CO2_retrofit(emissions_data; process_unit=nothing)

    # Creation of the time structure
    T = TwoLevel(1, 1, SimpleTimes(3, 2); op_per_strat = 6)

    ng_source =
        RefSource("ng", FixedProfile(25), FixedProfile(3), FixedProfile(1), Dict(NG => 1))

    if isnothing(process_unit)
        process_unit = RefNetworkNodeRetrofit(
            "process",
            FixedProfile(10),
            FixedProfile(5.5),
            FixedProfile(0),
            Dict(NG => 2),
            Dict(Power => 1),
            CO2_proxy,
            [emissions_data["process"]],
        )
    end

    ccs_unit = CCSRetroFit(
        "ccs",
        FixedProfile(5),
        FixedProfile(0),
        FixedProfile(0),
        Dict(NG => 0.05),
        Dict(CO2 => 0),
        CO2_proxy,
        [emissions_data["ccs"]],
    )

    co2_storage = CO2Storage(
        "co2",
        StorCapOpex(FixedProfile(10), FixedProfile(-2), FixedProfile(1)),
        StorCap(FixedProfile(100)),
        CO2,
        Dict(CO2 => 1),
    )

    demand = RefSink(
        "demand",
        FixedProfile(10),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(Power => 1),
    )

    nodes = [
        ng_source,
        process_unit,
        ccs_unit,
        demand,
        co2_storage,
    ]
    links = [
        Direct("ng-pu", ng_source, process_unit)
        Direct("ng-ccs", ng_source, ccs_unit)
        Direct("pu-demand", process_unit, demand)
        Direct("pu-ccs", process_unit, ccs_unit)
        Direct("ccs-co2", ccs_unit, co2_storage)
    ]

    modeltype =
        OperationalModel(Dict(CO2 => FixedProfile(60)), Dict(CO2 => FixedProfile(30)), CO2)

    case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)

    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    return m, case, modeltype
end

function general_tests(m, case, modeltype)

    # Extract the input data
    process, ccs = case[:nodes][[2,3]]
    T = case[:T]

    # General tests of the results and that the model producses
    @test termination_status(m) == MOI.OPTIMAL
    @test all(value.(m[:flow_out][process, t, CO2_proxy]) > 0 for t ∈ T)
end

@testset "RefNetworkNodeRetrofit - CaptureEnergyEmissions, CCSRetroFit - CaptureFlueGas" begin

    # Create the emissions dictionary
    emissions_data =
        Dict("process" => CaptureEnergyEmissions(0.9), "ccs" => EMC.CaptureFlueGas(0.9))

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    process, ccs = case[:nodes][[2,3]]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        value.(m[:flow_in][process, t, NG]) * co2_int(NG) * co2_capture(process.data[1]) for
        t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:emissions_node][process, t, CO2]) ≈
        value.(m[:flow_in][process, t, NG]) *
        co2_int(NG) *
        (1 - co2_capture(process.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureFlueGas)
    @test all(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
        value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) for t ∈ T,
        atol ∈ TEST_ATOL
    )

    # Test that the capture is correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureFlueGas)
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )
end

@testset "RefNetworkNodeRetrofit - CaptureEnergyEmissions, CCSRetroFit - CaptureEnergyEmissions" begin

    # Create the emissions file
    emissions_data = Dict(
        "process" => CaptureEnergyEmissions(Dict(CO2 => 0.1), 0.9),
        "ccs" => CaptureEnergyEmissions(Dict(CO2 => 0.1), 0.9),
    )

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    process, ccs = case[:nodes][[2,3]]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        value.(m[:flow_in][process, t, NG]) * co2_int(NG) * co2_capture(process.data[1]) for
        t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:emissions_node][process, t, CO2]) ≈
        value.(m[:flow_in][process, t, NG]) *
        co2_int(NG) *
        (1 - co2_capture(process.data[1])) +
        value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t) for
        t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) * (1 - co2_capture(ccs.data[1])) +
        value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) for t ∈ T,
        atol ∈ TEST_ATOL
    )

    # Test that the capture is correct in the ccs node and at its maximum
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        (value.(m[:cap_use][ccs, t]) + value.(m[:flow_in][ccs, t, NG]) * co2_int(NG)) *
        co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            ((20*.2)*.9)*(1+.05*.2)*.9 for t ∈ T, atol ∈ TEST_ATOL
    )
end

@testset "RefNetworkNodeRetrofit - CaptureProcessEmissions, CCSRetroFit - CaptureProcessEmissions" begin

    # Create the emissions file
    emissions_data = Dict(
        "process" => CaptureProcessEmissions(Dict(CO2 => 0.5), 0.9),
        "ccs" => CaptureProcessEmissions(Dict(CO2 => 0.5), 0.9),
    )

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    process, ccs = case[:nodes][[2,3]]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test all(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
            value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t) *
            co2_capture(process.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test all(
        value.(m[:emissions_node][process, t, CO2]) ≈
            value.(m[:flow_in][process, t, NG]) * co2_int(NG) +
                value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t) *
                (1 - co2_capture(process.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test all(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
            value.(m[:flow_in][ccs, t, CO2_proxy]) -
            value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
            value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
                value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) *
                (1 - co2_capture(ccs.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the capture is correct in the ccs node and at its maximum
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
            value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) *
            co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            ((10*.5)*.9)*(1+.5)*.9 for t ∈ T, atol ∈ TEST_ATOL
    )
end

@testset "RefNetworkNodeRetrofit - CaptureProcessEnergyEmissions, CCSRetroFit - CaptureProcessEnergyEmissions" begin

    # Create the emissions file
    emissions_data = Dict(
        "process" => CaptureProcessEnergyEmissions(Dict(CO2 => 0.1), 0.9),
        "ccs" => CaptureProcessEnergyEmissions(Dict(CO2 => 0.1), 0.9),
    )

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    process, ccs = case[:nodes][[2,3]]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureProcessEnergyEmissions)
    @test all(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t)
        ) * co2_capture(process.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureProcessEnergyEmissions)
    @test all(
        value.(m[:emissions_node][process, t, CO2]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t)
        ) * (1 - co2_capture(process.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureProcessEnergyEmissions)
    @test all(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        (
            value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t)
        ) * (1 - co2_capture(ccs.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the capture is correct in the ccs node and at its maximum
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureProcessEnergyEmissions)
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        (
            value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t)
        ) * co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            ((20*.2+10*.1)*.9)*(1+.05*.2+.1)*.9 for t ∈ T, atol ∈ TEST_ATOL
    )
end

@testset "New retrofit type " begin

    struct TestRetrofit <: NetworkNodeWithRetrofit
        id::Any
        cap::TimeProfile
        opex_var::TimeProfile
        opex_fixed::TimeProfile
        input::Dict{<:Resource,<:Real}
        output::Dict{<:Resource,<:Real}
        co2_proxy::Resource
        data::Array{<:Data}
    end


    process_unit = TestRetrofit(
        "process",
        FixedProfile(10),
        FixedProfile(5.5),
        FixedProfile(0),
        Dict(NG => 2),
        Dict(Power => 1),
        CO2_proxy,
        [CaptureEnergyEmissions(Dict(CO2 => 0.1), 0.9)],
    )

    # Create the emissions file
    emissions_data = Dict(
        "ccs" => CaptureEnergyEmissions(Dict(CO2 => 0.1), 0.9),
    )

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data; process_unit)
    general_tests(m, case, modeltype)

    # Extract the input data
    process, ccs = case[:nodes][[2,3]]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        value.(m[:flow_in][process, t, NG]) * co2_int(NG) * co2_capture(process.data[1]) for
        t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::RefNetworkNodeRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:emissions_node][process, t, CO2]) ≈
        value.(m[:flow_in][process, t, NG]) *
        co2_int(NG) *
        (1 - co2_capture(process.data[1])) +
        value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t) for
        t ∈ T, atol ∈ TEST_ATOL
    )

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) * (1 - co2_capture(ccs.data[1])) +
        value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) for t ∈ T,
        atol ∈ TEST_ATOL
    )

    # Test that the capture is correct in the ccs node and at its maximum
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        (value.(m[:cap_use][ccs, t]) + value.(m[:flow_in][ccs, t, NG]) * co2_int(NG)) *
        co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    )
    @test all(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            ((20*.2)*.9)*(1+.05*.2)*.9 for t ∈ T, atol ∈ TEST_ATOL
    )
end
