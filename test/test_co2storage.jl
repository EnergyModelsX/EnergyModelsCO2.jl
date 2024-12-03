# Definition of the CO2 resource
power = ResourceCarrier("power", 1.0)
CO2 = ResourceEmit("CO2", 1.0)

function small_graph(T; source_cap = 9)
    products = [CO2, power]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    co2_source = CO2Source(
        "source",
        FixedProfile(source_cap),
        FixedProfile(-10),
        FixedProfile(1),
        Dict(CO2 => 1),
    )
    el_source = RefSource(
        "source",
        FixedProfile(100),
        FixedProfile(0),
        FixedProfile(1),
        Dict(power => 1),
    )

    co2_storage = CO2Storage(
        "storage",
        StorCapOpex(FixedProfile(10), FixedProfile(2), FixedProfile(1)),
        StorCap(FixedProfile(20000)),
        CO2,
        Dict(CO2 => 1, power => 0.02),
    )

    nodes = [co2_source, co2_storage, el_source]
    links = [
        Direct("source_stor", co2_source, co2_storage),
        Direct("el_source_stor", el_source, co2_storage)
    ]

    modeltype =
        OperationalModel(Dict(CO2 => FixedProfile(3)), Dict(CO2 => FixedProfile(20)), CO2)

    case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)
    return case, modeltype
end

@testset "CO2 source and storage" begin
    # Creation of the time structure
    T = TwoLevel(2, 1, SimpleTimes(3, 2), op_per_strat = 6)

    case, modeltype = small_graph(T)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    nodes = case[:nodes]
    T = case[:T]

    source = nodes[1]
    storage = nodes[2]

    for (t_inv_prev, t_inv) ∈ withprev(strategic_periods(T))
        for (t_prev, t) ∈ withprev(t_inv)
            if isnothing(t_prev)
                if isnothing(t_inv_prev)
                    @test value(m[:stor_level][storage, t]) ==
                          value(m[:flow_out][source, t, CO2]) * duration(t)
                else
                    prev = last(t_inv_prev)

                    @test value(m[:stor_level][storage, prev]) +
                          value(m[:flow_out][source, t, CO2]) * duration(t) ==
                          value(m[:stor_level][storage, t])
                end
            else
                @test value(m[:stor_level][storage, t_prev]) +
                      value(m[:flow_out][source, t, CO2]) * duration(t) ==
                      value(m[:stor_level][storage, t])
            end
        end
    end

    # Test that the source produces with max capacity in all operational periods.
    source_cap = 9
    @test all(value(m[:flow_out][source, t, CO2]) == source_cap for t ∈ T)
end

@testset "Storage accumulation over strategic periods - SimpleTimes" begin
    # Creation of the time structure
    sp_length = 3
    op_length = 4
    T = TwoLevel(4, sp_length, SimpleTimes(op_length, 1); op_per_strat = op_length)

    source_cap = 9
    case, modeltype = small_graph(T, source_cap = source_cap)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    nodes = case[:nodes]
    T = case[:T]

    source = nodes[1]
    storage = nodes[2]

    for (i, t_inv) ∈ enumerate(strategic_periods(T))
        for (t_prev, t) ∈ withprev(t_inv)
            if isnothing(t_prev)
                @test value(m[:stor_level][storage, t]) ==
                      sp_length * op_length * source_cap * (i - 1) + source_cap
            else
                @test value(m[:stor_level][storage, t_prev]) +
                      value(m[:flow_out][source, t, CO2]) ==
                      value(m[:stor_level][storage, t])
            end
        end
    end

    # Test that the source produces with max capacity in all operational periods.
    @test all(value(m[:flow_out][source, t, CO2]) == source_cap for t ∈ T)
end

@testset "Storage accumulation over strategic periods - RepresentativePeriods" begin

    # Creation of the time structure
    op_1 = SimpleTimes(2, 2)
    op_2 = SimpleTimes(2, 2)
    sp_length = 3
    ops = RepresentativePeriods(2, 1, [0.5, 0.5], [op_1, op_2])
    op_length = length(ops) * 2
    T = TwoLevel(4, sp_length, ops; op_per_strat = op_length)

    source_cap = 9
    case, modeltype = small_graph(T, source_cap = source_cap)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    nodes = case[:nodes]
    T = case[:T]

    source = nodes[1]
    storage = nodes[2]

    for (i, t_inv) ∈ enumerate(strategic_periods(T))
        𝒯ʳᵖ = repr_periods(t_inv)
        for (t_rp_prev, t_rp) ∈ withprev(𝒯ʳᵖ), (t_prev, t) ∈ withprev(t_rp)
            if isnothing(t_rp_prev) && isnothing(t_prev)
                @test value(m[:stor_level][storage, t]) ==
                      sp_length * op_length * source_cap * (i - 1) +
                      source_cap * multiple_strat(t_inv, t) * duration(t) * probability(t)

            elseif isnothing(t_prev)
                @test value(m[:stor_level][storage, t]) ==
                      sp_length * op_length * source_cap * (i - 1) +
                      source_cap * 2 * 2 +
                      source_cap * multiple_strat(t_inv, t) * duration(t) * probability(t)
            else
                @test value(m[:stor_level][storage, t_prev]) +
                      value(m[:flow_out][source, t, CO2]) * duration(t) ==
                      value(m[:stor_level][storage, t])
            end
        end
    end

    # Test that the source produces with max capacity in all operational periods.
    @test all(value(m[:flow_out][source, t, CO2]) == source_cap for t ∈ T)
end
