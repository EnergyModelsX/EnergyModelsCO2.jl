using Pkg
# Activate the local environment including EnergyModelsCO2, HiGHS, PrettyTables
Pkg.activate(@__DIR__)
# Use dev version if run as part of tests
haskey(ENV, "EMX_TEST") && Pkg.develop(path=joinpath(@__DIR__,".."))
# Install the dependencies.
Pkg.instantiate()

using EnergyModelsCO2
using EnergyModelsBase
using HiGHS
using JuMP
using PrettyTables
using TimeStruct

const EMB = EnergyModelsBase
const TS = TimeStruct

"""
    generate_co2_storage_example_data()

Generate the data for an example consisting of a simple CO₂ storage system.
The CO₂ accumulates in the CO2Storage node between the strategic periods.
"""
function generate_co2_storage_example_data()
    @info "Generate case data - CO₂ storage example"

    # Define the different resources and their emission intensity in t CO₂/MWh
    CO2 = ResourceEmit("CO2", 1.0)
    products = [CO2]

    # Variables for the individual entries of the time structure
    op_duration = 2 # Each operational period has a duration of 2 h
    op_number = 5   # There are in total 5 operational periods in each strategic period
    operational_periods = SimpleTimes(op_number, op_duration)

    # The total time within a strategic period is given by 8760 h
    # This implies that the individual operational period are scaled:
    # Each operational period is scaled with a factor of 8760/2/10 = 876
    op_per_strat = 8760

    # Creation of the time structure and global data
    sp_duration = 2 # Each strategic period has a duration of 2 a
    sp_number = 8   # There are in total 8 strategic periods
    T = TwoLevel(sp_number, sp_duration, operational_periods; op_per_strat)

    # Creation of the model type with global data
    model = OperationalModel(Dict(CO2 => FixedProfile(0)), Dict(CO2 => FixedProfile(0)), CO2)

    # Specify the removal credit for CO₂
    # The credit could also be specified directly in the node
    removal_credit = StrategicProfile([-30, -20, -25, -30, -30, -30, -30, -30])

    # Create the individual test nodes, corresponding to a system with a CO₂ source (1) and
    # a CO₂ storage node
    nodes = [
        CO2Source(
            "CO₂ source",               # Node id
            FixedProfile(10),           # Installed capacity in t/h
            removal_credit,             # Variable OPEX in €/t
            FixedProfile(1),            # Fixed OPEX in €/(t/h)/a
            Dict(CO2 => 1),             # Output from the node, in this case, CO₂
        ),
        CO2Storage(
            "CO₂ storage",              # Node id
            StorCapOpex(                # Storage charge parameters
                FixedProfile(10),         # Charge capacity in t/h
                FixedProfile(9.1),        # Storage variable OPEX for the charging in €/t
                FixedProfile(1)           # Storage fixed OPEX for the charging in €/(t/h)/a
            ),
            StorCap(FixedProfile(1.1e6)),# Capacity of the storage node in t
            CO2,                        # Stored resource, in this case, CO₂
            Dict(CO2 => 1),             # Input to the node with input ratio
        )
    ]

    # Connect all nodes for the overall energy/mass balance
    # Another possibility would be to instead couple the nodes with an `Availability` node
    links = [
        Direct("source-storage", nodes[1], nodes[2], Linear())
    ]

    # Input data structure
    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
    return case, model
end

# Generate the case and model data and run the model
case, model = generate_co2_storage_example_data()
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = run_model(case, model, optimizer)

"""
    process_co2_storage_results(m, case)

Function for processing the results to be represented in the a table afterwards.
"""
function process_co2_storage_results(m, case)
    # Extract the nodes and the strategic periods from the data
    co2_stor  = get_nodes(case)[2]
    𝒯ᴵⁿᵛ = strategic_periods(get_time_struct(case))

    # Extract the first operational period of each strategic period
    first_op = [first(t_inv) for t_inv ∈ 𝒯ᴵⁿᵛ]

    # Storage variables
    # Storage usage in a strategic period
    storage_use = [value.(m[:stor_level_Δ_sp][co2_stor, t_inv]) for t_inv ∈ 𝒯ᴵⁿᵛ]./1e3
    storage_level = JuMP.Containers.rowtable(   # Storage level at beginning
        value,
        m[:stor_level][co2_stor, first_op]/1e3;
        header=[:t, :storage_level]
    )


    # Set up the individual named tuples as a single named tuple
    table = [(
            t = repr(con_2.t), storage_use = round(con_1; digits=1),
            storage_level = round(con_2.storage_level; digits=1),
        ) for (con_1, con_2) ∈ zip(storage_use, storage_level)
    ]
    return table
end

# Display some results
table = process_co2_storage_results(m, case)

@info(
    "Individual results from the storage node:\n" *
    "The initial storage level in kilotonnes is dependent on the change in the storage\n" *
    "in storage level in the previous strategic period in kilotonnes/year.\n" *
    "As each strategic perid is 2 years long, we observe directly a value of 2 x 87.6 = 175.2\n" *
    "as initial value in strategic period 2.\n" *
    "The storage node is not fully utilized due to the upper limit on storing CO₂."
)
pretty_table(table)
