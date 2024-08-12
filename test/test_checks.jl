# Set the global to true to suppress the error message
EMB.TEST_ENV = true

# Test that the fields of a CO2Source are correctly checked
# - EMB.check_node(n::CO2Source, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testset "Test checks - CO2Source" begin

    # Resources used in the checks
    CO2 = ResourceEmit("CO2", 1.0)
    Power = ResourceCarrier("Power", 0.0)

    # Simple graph for testing the individual checks
    function simple_graph(;
        cap = FixedProfile(10),
        opex_fixed = FixedProfile(0),
        output = Dict(CO2 => 1),
        data = Data[],

    )
        resources = [CO2]
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
        case = Dict(
                    :T => T,
                    :nodes => nodes,
                    :links => links,
                    :products => resources,
        )
        return create_model(case, model), case, model
    end

    # Test that a wrong capacity is caught by the checks.
    @test_throws AssertionError simple_graph(;cap=StrategicProfile([10, -10]))

    # Test that a wrong output dictionary is caught by the checks.
    @test_throws AssertionError simple_graph(;output = Dict(CO2 => 1, Power => -5))

    # Test that a wrong fixed data is caught by the checks.
    @test_throws AssertionError simple_graph(;data=Data[CaptureEnergyEmissions(0.9)])

end

# Set the global again to false
EMB.TEST_ENV = false
