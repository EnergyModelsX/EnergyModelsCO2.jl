# Definition of the CO2 resource
CO2 = ResourceEmit("CO2", 1.0)
CO2_proxy = ResourceCarrier("CO2 proxy", 0)
NG = ResourceCarrier("NG", 0.2)
Power = ResourceCarrier("Power", 0.2)
products = [CO2, NG, Power, CO2_proxy]

function CO2_retrofit(emissions; feed = Dict(CO2_proxy => 1))

    # Creation of the time structure
    T = TwoLevel(1, 1, SimpleTimes(3, 2))

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    ng_source = RefSource(
        "ng",
        FixedProfile(20),
        FixedProfile(3),
        FixedProfile(1),
        Dict(NG => 1),
        [],
    )

    process_unit = NetworkCCSRetrofit(
        "process",
        FixedProfile(10),
        FixedProfile(5.5),
        FixedProfile(0),
        Dict(NG => 2),
        Dict(Power => 1, CO2_proxy => 0),
        emissions["process"],
        0.9,
        CO2_proxy,
        [],
    )

    ccs_unit = CCSRetroFit(
        "ccs",
        FixedProfile(5),
        FixedProfile(0),
        FixedProfile(0),
        feed,
        Dict(CO2 => 0),
        emissions["ccs"],
        0.9,
        CO2_proxy,
        [],
    )

    co2_storage = CO2Storage(
        "co2",
        FixedProfile(10),
        FixedProfile(2000),
        FixedProfile(2),
        FixedProfile(1),
        CO2,
        Dict(CO2 => 1),
        [],
    )

    demand = RefSink(
        "demand",
        FixedProfile(10),
        Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)),
        Dict(Power => 1),
    )

    nodes =
        [GenAvailability(1, 𝒫₀, 𝒫₀), ng_source, process_unit, ccs_unit, demand, co2_storage]
    links = [
        Direct("ng-pu", ng_source, process_unit)
        Direct("pu-demand", process_unit, demand)
        Direct("pu-ccs", process_unit, ccs_unit)
        Direct("ccs-co2", ccs_unit, co2_storage)
        Direct("co2-av", co2_storage, nodes[1])
    ]

    modeltype = OperationalModel(Dict(CO2 => FixedProfile(10)), CO2)

    case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)
    return case, modeltype
end

@testset "CO2 retrofit wo process emissions" begin

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})

    # Create the emissions file
    emissions = Dict("process" => 𝒫ᵉᵐ₀, "ccs" => 𝒫ᵉᵐ₀)

    case, modeltype = CO2_retrofit(emissions)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    @test sum(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * NG.CO2_int +
            value.(m[:cap_use][process, t]) * process.Emissions[CO2]
        ) * process.CO2_capture for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the process node
    @test sum(
        value.(m[:emissions_node][process, t, CO2]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * NG.CO2_int +
            value.(m[:cap_use][process, t]) * process.Emissions[CO2]
        ) * (1 - process.CO2_capture) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the ccs node
    @test sum(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * ccs.CO2_capture +
        value.(m[:cap_use][ccs, t]) * ccs.Emissions[CO2] for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the capture is correct in the ccs node
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈ value.(m[:cap_use][ccs, t]) * ccs.CO2_capture
        for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
end

@testset "CO2 retrofit with process emissions" begin

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})

    # Create the emissions file
    emissions = Dict("process" => Dict(CO2 => 0.1), "ccs" => Dict(CO2 => 0.1))

    case, modeltype = CO2_retrofit(emissions)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    @test sum(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * NG.CO2_int +
            value.(m[:cap_use][process, t]) * process.Emissions[CO2]
        ) * process.CO2_capture for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the process node
    @test sum(
        value.(m[:emissions_node][process, t, CO2]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * NG.CO2_int +
            value.(m[:cap_use][process, t]) * process.Emissions[CO2]
        ) * (1 - process.CO2_capture) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the ccs node
    @test sum(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * ccs.CO2_capture +
        value.(m[:cap_use][ccs, t]) * ccs.Emissions[CO2] for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the capture is correct in the ccs node
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈ value.(m[:cap_use][ccs, t]) * ccs.CO2_capture
        for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
end

@testset "CO2 retrofit with process emissions and additional input" begin

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})

    # Create the emissions file
    emissions = Dict("process" => Dict(CO2 => 0.1), "ccs" => 𝒫ᵉᵐ₀)

    case, modeltype = CO2_retrofit(emissions, feed = Dict(CO2_proxy => 1, NG => 0.1))
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    # Extract the input data
    nodes = case[:nodes]
    process = nodes[3]
    ccs = nodes[4]
    T = case[:T]

    # Test that the outflow of the proxy is correct based on the capture rate
    @test sum(
        value.(m[:flow_out][process, t, CO2_proxy]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * NG.CO2_int +
            value.(m[:cap_use][process, t]) * process.Emissions[CO2]
        ) * process.CO2_capture for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the process node
    @test sum(
        value.(m[:emissions_node][process, t, CO2]) ≈
        (
            value.(m[:flow_in][process, t, NG]) * NG.CO2_int +
            value.(m[:cap_use][process, t]) * process.Emissions[CO2]
        ) * (1 - process.CO2_capture) for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the emissions are correct in the ccs node
    @test sum(
        value.(m[:emissions_node][ccs, t, CO2]) ≈
        value.(m[:flow_in][ccs, t, CO2_proxy]) -
        value.(m[:cap_use][ccs, t]) * ccs.CO2_capture +
        value.(m[:cap_use][ccs, t]) * ccs.Emissions[CO2] +
        value.(m[:flow_in][ccs, t, NG]) * NG.CO2_int for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)

    # Test that the capture is correct in the ccs node
    @test sum(
        value.(m[:flow_out][ccs, t, CO2]) ≈ value.(m[:cap_use][ccs, t]) * ccs.CO2_capture
        for t ∈ T, atol ∈ TEST_ATOL
    ) == length(T)
end
