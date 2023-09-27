"""
`EnergyModelsCO2.jl` is representinv several technologies that are relevant within CO₂
capture, transport, utilization, and storage chains.
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

export CO2Storage, NetworkCCSRetrofit, CCSRetroFit

end # module
