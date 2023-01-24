# Install example dependency.
using Pkg
Pkg.add("PrettyTables")

using HiGHS
using JuMP
using PrettyTables

using EnergyModelsCO2
using EnergyModelsBase
using TimeStructures

const EMB = EnergyModelsBase
const TS = TimeStructures


NG = ResourceEmit("NG", 0.2)
CO2 = ResourceEmit("CO2", 1.0)
Power = ResourceCarrier("Power", 0.0)
Coal = ResourceCarrier("Coal", 0.35)
products = [NG, Power, CO2, Coal]
𝒫ᵉᵐ₀ = Dict(k => FixedProfile(0) for k ∈ products if typeof(k) == ResourceEmit{Float64})


function demo()
    sp_dur = 5

    products = [NG, Power, CO2, Coal]
    # Create dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)
    # Create dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})
    𝒫ᵉᵐ₀[CO2] = 0.0

    source = RefSource(
        "src",
        FixedProfile(5),
        FixedProfile(10),
        FixedProfile(5),
        Dict(Power => 1),
        Dict("" => EmptyData()))

    sink = RefSink(
        "sink",
        FixedProfile(20),
        Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)),
        Dict(Power => 1))

    stor = RefStorage("stor", FixedProfile(60), FixedProfile(600), FixedProfile(9.1),
                            FixedProfile(0), Power, Dict(Power => 1), Dict(Power => 0.9),
                            Dict("" => EmptyData()))

    co2_stor = CO2Storage(
        "co2",
        # FixedProfile(0), # Cap
        FixedProfile(1), # Rate_cap
        FixedProfile(1000), # Stor_cap

        FixedProfile(2), # Opex_var
        FixedProfile(2), # Opex_fixed
        CO2,
        Dict(CO2=>1), # Input
        Dict(CO2=>1), # Output
        Dict("" => EmptyData())
    )

    nodes = [EMB.GenAvailability(1, 𝒫₀, 𝒫₀), source, sink, stor, co2_stor]
    links = [
        EMB.Direct(21, nodes[2], nodes[1], EMB.Linear())
        EMB.Direct(13, nodes[1], nodes[3], EMB.Linear())
        EMB.Direct(14, nodes[1], nodes[4], EMB.Linear())
        EMB.Direct(14, nodes[4], nodes[1], EMB.Linear())
        EMB.Direct(15, nodes[1], nodes[5], EMB.Linear())
    ]

    T = UniformTwoLevel(1, 2, sp_dur, UniformTimes(1, 4, 1))
    em_limits =
        Dict(NG => FixedProfile(1e6), CO2 => StrategicFixedProfile([450, 400, 350, 300]))
    # em_cost = Dict(NG => FixedProfile(0), CO2 => FixedProfile(0))
    model = OperationalModel(em_limits, CO2)

    case = Dict(
        :nodes => nodes,
        :links => links,
        :products => products,
        :T => T,
    )

    # Create model and optimize
    m = EMB.create_model(case, model)
    optimizer = optimizer_with_attributes(HiGHS.Optimizer)
    set_optimizer(m, optimizer)
    optimize!(m)

    # Display some results
    pretty_table(
        JuMP.Containers.rowtable(
            value,
            m[:stor_level];
            header = [:Source, :OperationalPeriod, :stor_level],
        ),
    )

    pretty_table(
        JuMP.Containers.rowtable(
            value,
            m[:flow_in];
            header = [:Source, :OperationalPeriod, :Prod, :flow_in],
        ),
    )
    pretty_table(
        JuMP.Containers.rowtable(
            value,
            m[:flow_out];
            header = [:Source, :OperationalPeriod, :Prod, :flow_out],
        ),
    )
end



m = demo()
# print(m)
