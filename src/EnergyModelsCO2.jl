"""
`EnergyModelsCO2` is representing several technologies that are relevant within CO₂
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

# Export all developed nodes
export CO2Source, CO2Storage
export NetworkNodeWithRetrofit, RefNetworkNodeRetrofit, CCSRetroFit

# Export the new `CaptureData`
export CaptureFlueGas

# Export the legacy constructor
export NetworkCCSRetrofit

end # module
