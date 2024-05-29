"""
`EnergyModelsCO2.jl` is representing several technologies that are relevant within CO₂
capture, transport, utilization, and storage chains.
"""
module EnergyModelsCO2

using EnergyModelsBase
using JuMP
using TimeStruct

const EMB = EnergyModelsBase
const TS = TimeStruct

include("datastructures.jl")
include("legacy_constructor.jl")
include("model.jl")
include("constraint_functions.jl")
include("checks.jl")
include("data_functions.jl")
include("utils.jl")

export CO2Source, CO2Storage, NetworkCCSRetrofit, CCSRetroFit

end # module
