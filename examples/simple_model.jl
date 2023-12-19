using Pkg
# Activate the test-environment, where PrettyTables and HiGHS are added as dependencies.
Pkg.activate(joinpath(@__DIR__, "../test"))
# Install the dependencies.
Pkg.instantiate()
# Add the package EnergyModelsInvestments to the environment.
Pkg.develop(path = joinpath(@__DIR__, ".."))

using EnergyModelsCO2
using EnergyModelsBase
using HiGHS
using JuMP
using PrettyTables
using TimeStruct

const EMB = EnergyModelsBase

CO2 = ResourceEmit("CO2", 1.0)
products = [CO2]

function small_graph()
    co2_source = CO2Source(
        "co2_source",
        FixedProfile(9),
        FixedProfile(-3),
        FixedProfile(1),
        Dict(CO2 => 1),
        Array{Data}([]),
    )

    co2_storage = CO2Storage(
        "co2_Storage",
        FixedProfile(10),
        FixedProfile(1000),
        FixedProfile(2),
        FixedProfile(1),
        CO2,
        Dict(CO2 => 1),
        Dict(CO2 => 1),
        Array{Data}([]),
    )

    nodes = [co2_source, co2_storage]
    links = [Direct("source-storage", co2_source, co2_storage)]

    # Creation of the time structure and the used global data
    T = TwoLevel(2, 1, SimpleTimes(3, 1), op_per_strat = 3)
    modeltype =
        OperationalModel(Dict(CO2 => FixedProfile(3)), Dict(CO2 => FixedProfile(0)), CO2)

    case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)
    return case, modeltype
end

case, modeltype = small_graph()
m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

# Display some results
pretty_table(
    JuMP.Containers.rowtable(
        value,
        m[:stor_level];
        header = [:Source, :OperationalPeriod, :stor_level],
    ),
)

pretty_table(
    sort(
        filter(
            x -> x.product == CO2,
            JuMP.Containers.rowtable(
                value,
                m[:flow_in];
                header = [:node, :tp, :product, :flow_in],
            ),
        ),
        by = x -> x.tp,
    ),
)

pretty_table(
    sort(
        filter(
            x -> x.product == CO2,
            JuMP.Containers.rowtable(
                value,
                m[:flow_out];
                header = [:node, :tp, :product, :flow_out],
            ),
        ),
        by = x -> x.tp,
    ),
)
