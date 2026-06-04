# Set the global to true to suppress the error message
EMB.TEST_ENV = true

# Test that the fields of a CO2Source are correctly checked
# - EMB.check_node(n::CO2Source, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testset "Test checks - CO2Source" begin

    # Resources used in the checks
    CO2 = ResourceEmit("CO₂", 1.0)
    Power = ResourceCarrier("Power", 0.0)

    # Simple graph for testing the individual checks
    function simple_graph(;
        cap = FixedProfile(10),
        opex_fixed = FixedProfile(0),
        output = Dict(CO2 => 1),
        data = Data[],

    )
        products = [CO2]
        ops = SimpleTimes(5, 2)
        T = TwoLevel(2, 2, ops; op_per_strat=10)

        nodes = [
            CO2Source(
                "CO2 source",
                cap,
                FixedProfile(10),
                opex_fixed,
                output,
                data,
            ),
        ]
        links = Link[]
        model = OperationalModel(
            Dict(CO2 => FixedProfile(100)),
            Dict(CO2 => FixedProfile(0)),
            CO2
        )
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return create_model(case, model), case, model
    end

    # Test that a wrong capacity is caught by the checks.
    @test_throws AssertionError simple_graph(;cap=StrategicProfile([10, -10]))

    # Test that a wrong output dictionary is caught by the checks.
    @test_throws AssertionError simple_graph(;output = Dict(CO2 => 1, Power => -5))

    # Test that a wrong fixed data is caught by the checks.
    @test_throws AssertionError simple_graph(;data=Data[CaptureEnergyEmissions(0.9)])

end

# Test that the fields of a Storage are correctly checked
# - EMB.check_node_default(n::Storage, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testset "Test checks - CO2Storage" begin

    # Resources used in the checks
    CO2 = ResourceEmit("CO₂", 1.0)
    power = ResourceCarrier("Power", 0.0)
    CO2_2 = ResourceEmit("CO₂_2", 1.0)

    # Simple graph for testing the individual checks
    function simple_graph(;
        stor_res = CO2,
    )
        products = [CO2, power]
        ops = SimpleTimes(5, 2)
        T = TwoLevel(2, 2, ops; op_per_strat=10)

        nodes = [
            CO2Storage(
                "storage",
                StorCapOpex(FixedProfile(10), FixedProfile(2), FixedProfile(1)),
                StorCap(FixedProfile(10)),
                stor_res,
                Dict(CO2 => 1, power => 0.02),
            )
        ]
        links = Link[]
        model = OperationalModel(
            Dict(CO2 => FixedProfile(100)),
            Dict(CO2 => FixedProfile(0)),
            CO2
        )
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return create_model(case, model), case, model
    end

    # Test that `check_node_default` is correctly called
    @test_throws AssertionError simple_graph(;stor_res=CO2_2)
end

# Set the global again to false
EMB.TEST_ENV = false
