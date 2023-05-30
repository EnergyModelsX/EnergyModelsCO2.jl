using Pkg
# Activate the test-environment, where PrettyTables and HiGHS are added as dependencies.
Pkg.activate(joinpath(@__DIR__, "../test"))
# Install the dependencies.
Pkg.instantiate()
# Add the package EnergyModelsInvestments to the environment.
Pkg.develop(path=joinpath(@__DIR__, ".."))

using EnergyModelsCO2
using EnergyModelsBase
using HiGHS
using JuMP
using PrettyTables
using TimeStructures


const EMB = EnergyModelsBase

NG = ResourceEmit("NG", 0.3)
CO2 = ResourceEmit("CO2", 1.)
Power = ResourceCarrier("Power", 0.)


products = [CO2]

# Creation of a dictionary with entries of 0. for all resources
𝒫₀ = Dict(k => 0 for k ∈ products)

# Creation of a dictionary with entries of 0. for all emission resources
𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})


function small_graph()

    ng_source = RefSource("ng", FixedProfile(9), FixedProfile(-3), FixedProfile(1),
        Dict(CO2=>1), [], 𝒫ᵉᵐ₀)

    co2_storage = CO2Storage("co2", FixedProfile(10), FixedProfile(1000),
        FixedProfile(2), FixedProfile(1), CO2, Dict(CO2=>1), Dict(CO2=>1), [])

    nodes = [GenAvailability(1, 𝒫₀, 𝒫₀), ng_source, co2_storage]
    links = [
        Direct("ng-av", ng_source, nodes[1])
        Direct("av-co2", nodes[1], co2_storage)
        Direct("co2-av", co2_storage, nodes[1])
        # Direct("av-sink", nodes[1], co2_sink)
    ]

    # Creation of the time structure and the used global data
    T = UniformTwoLevel(1, 2, 1, UniformTimes(1, 3, 1))
    modeltype = OperationalModel(
        Dict(
            CO2=>FixedProfile(3),
            NG=>FixedProfile(3)),
        CO2)

    case = Dict(
        :nodes => nodes,
        :links => links,
        :products => products,
        :T => T,
    )
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

pretty_table(sort(filter(x->x.product == CO2, JuMP.Containers.rowtable(
        value,
        m[:flow_in];
        header = [:node, :tp, :product, :flow_in],
    )), by = x->x.tp)
)

pretty_table(sort(filter(x->x.product == CO2, JuMP.Containers.rowtable(
        value,
        m[:flow_out];
        header = [:node, :tp, :product, :flow_out],
    )), by = x->x.tp)
)
