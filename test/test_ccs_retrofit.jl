# Definition of the CO2 resource
CO2 = ResourceEmit("CO2", 1.0)
CO2_proxy = ResourceCarrier("CO2 proxy", 0)
NG = ResourceCarrier("NG", 0.2)
Power = ResourceCarrier("Power", 0.2)
products = [CO2, NG, Power, CO2_proxy]

function CO2_retrofit(emissions_data)

    # Creation of the time structure
    T = TwoLevel(1, 1, SimpleTimes(3, 2); op_per_strat = 6)

    ng_source =
        RefSource("ng", FixedProfile(25), FixedProfile(3), FixedProfile(1), Dict(NG => 1))

    process_unit = NetworkCCSRetrofit(
        "process",
        FixedProfile(10),
        FixedProfile(5.5),
        FixedProfile(0),
        Dict(NG => 2),
        Dict(Power => 1, CO2_proxy => 0),
        CO2_proxy,
        [emissions_data["process"]],
    )

    ccs_unit = CCSRetroFit(
        "ccs",
        FixedProfile(5),
        FixedProfile(0),
        FixedProfile(0),
        Dict(NG => 0.05, CO2_proxy => 0),
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
        GenAvailability(1, products),
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
        Direct("co2-av", co2_storage, nodes[1])
    ]

    modeltype =
        OperationalModel(Dict(CO2 => FixedProfile(15)), Dict(CO2 => FixedProfile(30)), CO2)

    case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)

    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    return m, case, modeltype
end

function general_tests(m, case, modeltype)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # General tests of the results and that the model producses
    @test termination_status(m) == MOI.OPTIMAL
    @test sum(value.(m[:flow_out][process, t, CO2_proxy]) > 0 for t ∈ T) == length(T)
end

@testset "NetworkCCSRetrofit - CaptureEnergyEmissions, CCSRetroFit - CaptureNone" begin

    # Create the emissions dictionary
    emissions_data =
        Dict("process" => CaptureEnergyEmissions(0.9), "ccs" => EMC.CaptureNone(0.9))

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test sum(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        value.(m[:flow_in][process, t, NG]) * co2_int(NG) * co2_capture(process.data[1]) for
        t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test sum(
        value.(m[:emissions_node][process, t, CO2]) ≈
        value.(m[:flow_in][process, t, NG]) *
        co2_int(NG) *
        (1 - co2_capture(process.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureNone)
    @test sum(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
        value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) for t ∈ T,
        atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the capture is correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureNone)
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
end

@testset "NetworkCCSRetrofit - CaptureEnergyEmissions, CCSRetroFit - CaptureEnergyEmissions" begin

    # Create the emissions file
    emissions_data = Dict(
        "process" => CaptureEnergyEmissions(Dict(CO2 => 0.1), 0.9),
        "ccs" => CaptureEnergyEmissions(Dict(CO2 => 0.1), 0.9),
    )

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test sum(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        value.(m[:flow_in][process, t, NG]) * co2_int(NG) * co2_capture(process.data[1]) for
        t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test sum(
        value.(m[:emissions_node][process, t, CO2]) ≈
        value.(m[:flow_in][process, t, NG]) *
        co2_int(NG) *
        (1 - co2_capture(process.data[1])) +
        value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t) for
        t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test sum(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) * (1 - co2_capture(ccs.data[1])) +
        value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t) for t ∈ T,
        atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the capture is correct in the ccs node and at its maximum
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureEnergyEmissions)
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        (value.(m[:cap_use][ccs, t]) + value.(m[:flow_in][ccs, t, NG]) * co2_int(NG)) *
        co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            ((20*.2)*.9)*(1+.05*.2)*.9 for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
end

@testset "NetworkCCSRetrofit - CaptureProcessEnergyEmissions, CCSRetroFit - CaptureProcessEnergyEmissions" begin

    # Create the emissions file
    emissions_data = Dict(
        "process" => CaptureProcessEnergyEmissions(Dict(CO2 => 0.1), 0.9),
        "ccs" => CaptureProcessEnergyEmissions(Dict(CO2 => 0.1), 0.9),
    )

    # Create and run the model
    m, case, modeltype = CO2_retrofit(emissions_data)
    general_tests(m, case, modeltype)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    # - constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test sum(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t)
        ) * co2_capture(process.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the process node
    # - constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test sum(
        value.(m[:emissions_node][process, t, CO2]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][process, t]) * process_emissions(process.data[1], CO2, t)
        ) * (1 - co2_capture(process.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the ccs node
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test sum(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        (
            value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t)
        ) * (1 - co2_capture(ccs.data[1])) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the capture is correct in the ccs node and at its maximum
    # - constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureProcessEmissions)
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈
        value.(m[:cap_use][ccs, t]) * co2_capture(ccs.data[1]) +
        (
            value.(m[:flow_in][ccs, t, NG]) * co2_int(NG) +
            value.(m[:cap_use][ccs, t]) * process_emissions(ccs.data[1], CO2, t)
        ) * co2_capture(ccs.data[1]) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈
            ((20*.2+10*.1)*.9)*(1+.05*.2+.1)*.9 for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
end
