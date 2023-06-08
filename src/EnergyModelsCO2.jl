"""
`EnergyModelsCO2.jl` implements a node [`CO2Storage`](@ref) for representing storage of CO₂.
"""
module EnergyModelsCO2

using EnergyModelsBase
using JuMP
using TimeStruct

const EMB = EnergyModelsBase
const TS = TimeStruct

include("datastructures.jl")
include("model.jl")
include("checks.jl")

export CO2Storage

end # module
