
"""
    AccumulatingStrategic <: EMB.Accumulating

`StorageBehavior` which accumulates all inflow witin a strategic period and transfers the
level to the next strategic period. This approach is used for [`CO2Storage`](@ref) nodes.
"""
struct AccumulatingStrategic <: EMB.Accumulating end

"""
    CO2Source <: Source

A CO₂ `Source` node. Its only difference from a RefSource is that is allows for CO₂ as outlet.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operational costs.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
- **`data::Array{<:Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct CO2Source <: Source
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{<:Resource,<:Real}
    data::Array{<:Data}
end
function CO2Source(
    id::Any,
    cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real},
)
    return CO2Source(id, cap, opex_var, opex_fixed, output, Data[])
end

"""
    CO2Storage{T} <: Storage{T}

This node has an installed injection rate capacity through `charge` and a storage capacity
`level`.

The storage level (accountet by the optimization variable `stor_level`) will
increase during all strategic periods (sp), _i.e._, the stored resource can not be
taken out of the storage.

The initial storage level in a strategic period is set to the storage level at
the end of the prevoious sp. Note that the increased storage level during a sp
is multiplied with the length of the sp when the initial storage level for the
next sp is set.

This is achieved through the parametric input [`AccumulatingStrategic`](@ref). This input
is not a reqired input due to the utilization of a constructor.

# Fields
- **`id`** is the name/identifyer of the node.
- **`charge::EMB.UnionCapacity`** are the charging parameters of the `CO2Storage` node.
  Depending on the chosen type, the charge parameters can include variable OPEX and/or
  fixed OPEX.
- **`level::EMB.UnionCapacity`** are the level parameters of the `CO2Storage` node.
  Depending on the chosen type, the charge parameters can include variable OPEX and/or
  fixed OPEX.
- **`stor_res::Resource`** is the stored `Resource`.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
  Requires that the stored resource `stor_res` is set here.
- **`data::Array{<:Data}`** is the additional data (e.g. for investments).

The fields `output::Dict{<:Resource, <:Real}` and `data::Array{<:Data}` are not required as
constructors are introduced to facilitate constructing `CO2Storage` nodes.
"""
struct CO2Storage{T} <: Storage{T}
    id::Any

    charge::EMB.UnionCapacity
    level::EMB.UnionCapacity

    stor_res::ResourceEmit
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Array{<:Data}
end
function CO2Storage(
    id,
    charge::EMB.UnionCapacity,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
)
    return CO2Storage{AccumulatingStrategic}(
        id,
        charge,
        level,
        stor_res,
        input,
        Dict(stor_res => 0),
        Data[],
    )
end
function CO2Storage(
    id,
    charge::EMB.UnionCapacity,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    data::Array{<:Data},
)
    return CO2Storage{AccumulatingStrategic}(
        id,
        charge,
        level,
        stor_res,
        input,
        Dict(stor_res => 0),
        data,
    )
end
function CO2Storage(
    id,
    charge::EMB.UnionCapacity,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return CO2Storage{AccumulatingStrategic}(
        id,
        charge,
        level,
        stor_res,
        input,
        output,
        Data[],
    )
end
function CO2Storage(
    id,
    charge::EMB.UnionCapacity,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Array{<:Data},
)
    return CO2Storage{AccumulatingStrategic}(
        id,
        charge,
        level,
        stor_res,
        input,
        output,
        data,
    )
end
EMB.has_emissions(n::CO2Storage) = true

"""
    NetworkCCSRetrofit <: NetworkNode

This node allows for retrofitting CCS to a `Network` node.

It corresponds to a `RefNetwork` node in which the CO₂ is not emitted. Instead, it is
transferred to a `co2_proxy` that is fed subsequently to a node in which it is either
captured, or emitted.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operational costs.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
  `co2_proxy` is required to be included to be available to have CO₂ capture applied properly.
- **`co2_proxy::Resource`** is the instance of the `Resource` used for emissions.
- **`data::Array{<:Data}`** is the additional data (e.g. for investments).
"""
struct NetworkCCSRetrofit <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    co2_proxy::Resource
    data::Array{<:Data}
end

"""
    CCSRetroFit <: Network

This node allows for investments into CCS retrofit to a `NetworkCCSRetrofit` node. The
capture process is implemented through the variable `cap_use`

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operational costs.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
  The CO₂ instance is required to be included to be available to have CO₂ capture applied
  properly.
- **`co2_proxy::Resource`** is the instance of the `Resource` used for emissions.
- **`data::Array{<:Data}`** is the additional data (e.g. for investments).
"""
struct CCSRetroFit <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    co2_proxy::Resource
    data::Array{<:Data}
end

"""
    co2_proxy(n)

Extract the instance of the CO₂ proxy
"""
co2_proxy(n) = n.co2_proxy

"""
    CaptureFlueGas{T} <: CaptureData{T}

Capture the proxy CO₂ instance but not the energy usage related emissions and the process
emissions. Does not require `emissions` as input, but can be supplied.

# Fields
- **`emissions::Dict{ResourceEmit, T}`** are the emissions per unit produced.
- **`co2_capture::Float64`** is the CO₂ capture rate.
"""
struct CaptureFlueGas{T} <: CaptureData{T}
    emissions::Dict{ResourceEmit,T}
    co2_capture::Float64
end
CaptureFlueGas(co2_capture::Float64) = CaptureFlueGas(Dict{ResourceEmit,Float64}(), co2_capture)
