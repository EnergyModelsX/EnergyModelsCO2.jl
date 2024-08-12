using Pkg
# Activate the local environment including EnergyModelsCO2, HiGHS, PrettyTables
Pkg.activate(@__DIR__)
# Use dev version if run as part of tests
haskey(ENV, "EMX_TEST") && Pkg.develop(path=joinpath(@__DIR__,".."))
# Install the dependencies.
Pkg.instantiate()

using EnergyModelsBase
using EnergyModelsCO2
using HiGHS
using JuMP
using PrettyTables
using TimeStruct

const EMB = EnergyModelsBase
const EMCO2 = EnergyModelsCO2
const TS = TimeStruct

"""
    generate_co2_retrofit_example_data()

Generate the data for an example consisting of a simple CO₂ retrofit system.
It does not directly utilize the investment potential, but showcases how the nodes should
be created.

In this case, 100 % of the CO₂ emissions from the CCGT are routed to a CO₂ capture node in
which 90 % of said CO₂ emissions are captured. In addition, this capture unit requires
1 MWh NG/t CO₂ input of which also 90 % is captured.
"""
function generate_co2_retrofit_example_data()
    @info "Generate case data - CO₂ retrofit example"

    # Define the different resources and their emission intensity in t CO₂/MWh
    # The CO2_proxy resource is required to allow for a retrofit CO₂ capture unit
    CO2       = ResourceEmit("CO2", 1.0)
    CO2_proxy = ResourceCarrier("CO2 proxy", 0)
    NG        = ResourceCarrier("NG", 0.2)
    Power     = ResourceCarrier("Power", 0.0)
    products = [CO2, CO2_proxy, NG, Power]

    # Variables for the individual entries of the time structure
    op_duration = 2 # Each operational period has a duration of 2 h
    op_number = 4   # There are in total 5 operational periods in each strategic period
    operational_periods = SimpleTimes(op_number, op_duration)

    # The total time within a strategic period is given by 8760 h
    # This implies that the individual operational period are scaled:
    # Each operational period is scaled with a factor of 8760/2/4 = 1095
    op_per_strat = 8760

    # Creation of the time structure and global data
    sp_duration = 10 # Each strategic period has a duration of 10 a
    sp_number = 2   # There are in total 8 strategic periods
    T = TwoLevel(sp_number, sp_duration, operational_periods; op_per_strat)

    # Creation of the model type with global data
    model = OperationalModel(Dict(CO2 => FixedProfile(5e5)), Dict(CO2 => FixedProfile(150)), CO2)

    # Create the individual test nodes, corresponding to a system with a natural gas source
    # (1), a natural gas combined cycle power plant (2), the CO₂ capture retrofit option (3),
    # a CO₂ storage node (4), and an electricity demand (5)
    nodes = [
        RefSource(
            "natural gas source",       # Node id
            FixedProfile(1000),         # Installed capacity in MW
            FixedProfile(5.5),          # Variable OPEX in €/MWh
            FixedProfile(0),            # Fixed OPEX in €/MW/a
            Dict(NG => 1),              # Output from the node, in this case, natural gas
        ),
        RefNetworkNodeRetrofit(
            "CCGT",                     # Node id
            FixedProfile(500),          # Installed capacity in MW
            FixedProfile(5.5),          # Variable OPEX in €/MWh
            FixedProfile(0),            # Fixed OPEX in €/MW/a
            Dict(NG => 1.66),           # Input to the node with input ratio
            Dict(Power => 1, CO2_proxy => 0), # Output from the node with input ratio
            # Line above: CO2_proxy is required as output for variable definition, but the
            # value does not matter
            CO2_proxy,                  # Instance of the `CO2_proxy`
            Data[CaptureEnergyEmissions(1.0)], # Capture data for the node.
            # All energy emissions are captured
        ),
        CCSRetroFit(
            "CCS unit",                 # Node id
            FixedProfile(200),          # Installed capacity in t/h
            FixedProfile(0),            # Variable OPEX in €/t
            FixedProfile(0),            # Fixed OPEX in €/(t/h)/a
            Dict(NG => 1.0, CO2_proxy => 0), # Input to the node with input ratio
            # Line above: CO2_proxy is required as input for variable definition, but the
            # value does not matter
            Dict(CO2 => 0),
            # Line above: CO2 is required as input for variable definition, but the
            # value does not matter
            CO2_proxy,                  # Instance of the `CO2_proxy`
            Data[CaptureEnergyEmissions(0.9)], # Capture data for the node.
            # All energy emission from the energy to the `CCSRetroFit` are captured.
        ),
        CO2Storage(
            "CO₂ storage",              # Node id
            StorCapOpex(                # Storage charge parameters
                FixedProfile(200),        # Charge capacity in t/h
                FixedProfile(9.1),        # Storage variable OPEX for the charging in €/t
                FixedProfile(0)           # Storage fixed OPEX for the charging in €/(t/h)/a
            ),
            StorCap(FixedProfile(1e8)), # Capacity of the storage node in t
            CO2,                        # Stored resource, in this case, CO₂
            Dict(CO2 => 1),             # Input to the node with input ratio
        ),
        RefSink(
            "electricity demand",       # Node id
            FixedProfile(500),          # Demand MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(250)),
            # Line above: Surplus and deficit penalty for the node in €/MWh
            Dict(Power => 1),           # Input to the electricity demand node
        )
    ]

    # Connect all nodes for the overall energy/mass balance
    # Another possibility would be to instead couple the nodes with an `Availability` node
    links = [
        Direct("ng_source-ccgt", nodes[1], nodes[2], Linear())
        Direct("ng_source-ccs", nodes[1], nodes[3], Linear())
        Direct("ccgt-ccs", nodes[2], nodes[3], Linear())
        Direct("ccgt-el_demand", nodes[2], nodes[5], Linear())
        Direct("ccs-storage", nodes[3], nodes[4], Linear())
    ]

    # WIP data structure
    case = Dict(
        :nodes => nodes,
        :links => links,
        :products => products,
        :T => T,
    )
    return case, model
end

# Generate the case and model data and run the model
case, model = generate_co2_retrofit_example_data()
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = run_model(case, model, optimizer)

"""
    process_results(m, case)

Function for processing the results to be represented in the a table afterwards.
"""
function process_results(m, case)
    # Extract the nodes and the strategic periods from the data
    ccgt, ccs = case[:nodes][[2,3]]
    CO2, CO2_proxy, NG, Power = case[:products]

    ccgt_out = sort(                    # Outlet CO₂ flow from the CCGT
            JuMP.Containers.rowtable(
                value,
                m[:flow_out][ccgt, :, CO2_proxy];
                header = [:t, :outlet],
        ),
        by = x -> x.t,
    )
    ccs_in = sort(                      # Inlet natural gas flow to the CO₂ capture unit
            JuMP.Containers.rowtable(
                value,
                m[:flow_in][ccs, :, NG];
                header = [:t, :inlet],
        ),
        by = x -> x.t,
    )
    ccs_out = sort(                      # Outlet CO₂ flow from the CO₂ capture unit
            JuMP.Containers.rowtable(
                value,
                m[:flow_out][ccs, :, CO2];
                header = [:t, :outlet],
        ),
        by = x -> x.t,
    )


    # Set up the individual named tuples as a single named tuple
    table = [(
            t = repr(con_1.t), ccgt_c02_out = round(Int64, con_1.outlet),
            ccs_ng_in = round(Int64, con_2.inlet),
            ccs_C02_out = round(con_3.outlet; digits=2),
        ) for (con_1, con_2, con_3) ∈ zip(ccgt_out, ccs_in, ccs_out)
    ]
    return table
end

# Display some results
table = process_results(m, case)

@info(
    "Individual results from the flow balances:\n" *
    "The results show that the CO₂ capture node requires 1 MWh NG/t CO₂. The total\n" *
    "captured CO₂ is larger than the inlet flow to the CCS node as we also capture\n" *
    "CO₂ from the natural gas feed corresponding to 0.2 x 166 = 33.2.\n" *
    "The final capture rate of 90 % is them applied to both CO₂ streams."
)
pretty_table(table)
