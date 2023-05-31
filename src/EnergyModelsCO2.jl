"""
`EnergyModelsCO2.jl` implements a node [`CO2Storage`](@ref) for representing storage of CO₂.
"""
module EnergyModelsCO2

using EnergyModelsBase
using JuMP
using TimeStructures

const EMB = EnergyModelsBase
const TS = TimeStructures

include("datastructures.jl")
include("model.jl")
include("checks.jl")

export CO2Storage

end # module
