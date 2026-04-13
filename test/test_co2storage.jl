# Definition of the CO2 resource
power = ResourceCarrier("power", 1.0)
CO2 = ResourceEmit("CO2", 1.0)

function co2_stor_case(𝒯; source_cap = 9, stor_cap=20000)
    𝒫 = [CO2, power]

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
        StorCap(FixedProfile(stor_cap)),
        CO2,
        Dict(CO2 => 1, power => 0.02),
    )

    𝒩 = [co2_source, co2_storage, el_source]
    ℒ = [
        Direct("source_stor", co2_source, co2_storage),
        Direct("el_source_stor", el_source, co2_storage)
    ]

    modeltype =
        OperationalModel(Dict(CO2 => FixedProfile(3)), Dict(CO2 => FixedProfile(20)), CO2)
    case = Case(𝒯, 𝒫, [𝒩, ℒ])
    return case, modeltype
end

@testset "Constructor methods" begin
    # Strictly speaking, not test set, but just to check that there are no errors
    @test isa(
        CO2Storage(
            "storage",
            StorCapOpex(FixedProfile(10), FixedProfile(2), FixedProfile(1)),
            StorCap(FixedProfile(10)),
            CO2,
            Dict(CO2 => 1, power => 0.02),
        ),
        CO2Storage{EMC.AccumulatingStrategic},
    )
    @test isa(
        CO2Storage(
            "storage",
            StorCapOpex(FixedProfile(10), FixedProfile(2), FixedProfile(1)),
            StorCap(FixedProfile(10)),
            CO2,
            Dict(CO2 => 1, power => 0.02),
            [EmissionsEnergy()],
        ),
        CO2Storage{EMC.AccumulatingStrategic},
    )
    @test isa(
        CO2Storage{AccumulatingEmissions}(
            "storage",
            StorCapOpex(FixedProfile(10), FixedProfile(2), FixedProfile(1)),
            StorCap(FixedProfile(10)),
            CO2,
            Dict(CO2 => 1, power => 0.02),
        ),
        CO2Storage{AccumulatingEmissions},
    )
    @test isa(
        CO2Storage{AccumulatingEmissions}(
            "storage",
            StorCapOpex(FixedProfile(10), FixedProfile(2), FixedProfile(1)),
            StorCap(FixedProfile(10)),
            CO2,
            Dict(CO2 => 1, power => 0.02),
            [EmissionsEnergy()],
        ),
        CO2Storage{AccumulatingEmissions},
    )
end

@testset "Utility functions" begin
    𝒯 = TwoLevel(2, 1, SimpleTimes(3, 2), op_per_strat = 6)

    @testset "Utility - Check functions" begin
        # Set the global to true to suppress the error message
        EMB.TEST_ENV = true

        # Capacity violation
        @test_throws AssertionError create_model(co2_stor_case(𝒯; stor_cap=-1000)...)

        # Set the global to true to suppress the error message
        EMB.TEST_ENV = false
    end

    # Create the model and extract the parameters
    case, modeltype = co2_stor_case(𝒯);
    storage = get_nodes(case)[2]

    @testset "Utility - Identification functions" begin
        # Test that all identification functions are working
        @test EMB.is_storage(storage)
        @test EMB.has_input(storage)
        @test EMB.has_emissions(storage)
        @test !EMB.has_output(storage)
        @test EMB.has_charge(storage)
        @test EMB.has_charge_cap(storage)
        @test !EMB.has_discharge(storage)
    end

    @testset "Utility - Extraction functions" begin
        # Test the capacity extraction functions
        @test isa(charge(storage), StorCapOpex)
        @test capacity(charge(storage)) == FixedProfile(10)
        @test all(capacity(charge(storage), t) == 10 for t ∈ 𝒯)
        @test opex_var(charge(storage)) == FixedProfile(2)
        @test all(opex_var(charge(storage), t) == 2 for t ∈ 𝒯)
        @test opex_fixed(charge(storage)) == FixedProfile(1)
        @test all(opex_fixed(charge(storage), t) == 1 for t ∈ 𝒯)
        @test isa(level(storage), StorCap)
        @test capacity(level(storage)) == FixedProfile(20000)
        @test all(capacity(level(storage), t) == 20000 for t ∈ 𝒯)

        # Test the input extraction functions
        @test inputs(storage) == [CO2, power]
        @test inputs(storage, CO2) == 1
        @test inputs(storage, power) == 0.02

        # Test additional extraction functions
        @test storage_resource(storage) == CO2
        @test isempty(node_data(storage))
    end
end

@testset "Constraint implementation" begin
    @testset "CO2 source and storage" begin
        # Creation of the time structure
        T = TwoLevel(2, 1, SimpleTimes(3, 2), op_per_strat = 6)

        case, modeltype = co2_stor_case(T)
        m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

        𝒩 = get_nodes(case)
        T = get_time_struct(case)

        source = 𝒩[1]
        storage = 𝒩[2]

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
        case, modeltype = co2_stor_case(T, source_cap = source_cap)
        m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

        𝒩 = get_nodes(case)
        T = get_time_struct(case)

        source = 𝒩[1]
        storage = 𝒩[2]

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
        case, modeltype = co2_stor_case(T, source_cap = source_cap)
        m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

        𝒩 = get_nodes(case)
        T = get_time_struct(case)

        source = 𝒩[1]
        storage = 𝒩[2]

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
end
