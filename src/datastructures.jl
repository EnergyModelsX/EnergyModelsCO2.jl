
"""
    AccumulatingStrategic <: EMB.Accumulating

`StorageBehavior` which accumulates all inflow witin a strategic period and transfers the
level to the next strategic period. This approach is used for [`CO2Storage`](@ref) nodes.
"""
struct AccumulatingStrategic <: EMB.Accumulating end

"""
    CO2Source <: Source

A CO₂ `Source` node. Its only difference from a [`RefSource`](@extref EnergyModelsBase.RefSource)
is that is allows for CO₂ as outlet.

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
increase during all strategic periods (sp), *i.e.*, the stored resource can not be
taken out of the storage.

The initial storage level in a strategic period is set to the storage level at
the end of the prevoious sp. Note that the increased storage level during a sp
is multiplied with the length of the sp when the initial storage level for the
next sp is set.

This is achieved through the parametric input [`AccumulatingStrategic`](@ref). This input
is not a required input due to the utilization of an inner constructor.

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
- **`data::Array{<:Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct CO2Storage{T} <: Storage{T}
    id::Any

    charge::EMB.UnionCapacity
    level::EMB.UnionCapacity

    stor_res::ResourceEmit
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Array{<:Data}

    function CO2Storage(
        id::Any,
        charge::EMB.UnionCapacity,
        level::EMB.UnionCapacity,
        stor_res::ResourceEmit,
        input::Dict{<:Resource,<:Real},
        data::Array{<:Data},
    )
        new{AccumulatingStrategic}(
            id,
            charge,
            level,
            stor_res,
            input,
            Dict(stor_res => 0),
            data
        )
    end
end
function CO2Storage(
    id,
    charge::EMB.UnionCapacity,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
)
    return CO2Storage(
        id,
        charge,
        level,
        stor_res,
        input,
        Data[],
    )
end
EMB.has_emissions(n::CO2Storage) = true

"""
    NetworkNodeWithRetrofit <:NetworkNode

Abstract supertype for allowing retrofitting CO₂ capture to a node.
Its application requires the user to

1. define their own node as subtype of `NetworkNodeWithRetrofit` and
2. include a field `co2_proxy` in said node or alternatively define a method for `co2_proxy`
   for the node.

The application is best explained by [`RefNetworkNodeRetrofit`](@ref) which illustrates it
for a [`RefNetworkNode`](@extref EnergyModelsBase.RefNetworkNode) node.
"""
abstract type NetworkNodeWithRetrofit <:NetworkNode end

"""
    RefNetworkNodeRetrofit <: NetworkNodeWithRetrofit

This node allows for retrofitting CO₂ capture to a `NetworkNode`.

It corresponds to a [`RefNetworkNode`](@extref EnergyModelsBase.RefNetworkNode) node in
which the CO₂ is not emitted. Instead, it is transferred to a `co2_proxy` that is fed
subsequently to a node ([`CCSRetroFit`](@ref)) in which it is either captured, or emitted.

The `co2_proxy` does not have to be specified as `output` resource.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operational costs.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
  `co2_proxy` is required to be included to be available to have CO₂ capture applied properly.
- **`co2_proxy::Resource`** is the instance of the `Resource` used for calculating internally
  the CO₂ flow from the `RefNetworkNodeRetrofit` to the `CCSRetroFit` node.
- **`data::Array{<:Data}`** is the additional data (e.g. for investments).
"""
struct RefNetworkNodeRetrofit <: NetworkNodeWithRetrofit
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
    EMB.outputs(n::CCSRetroFit)

When the node is a [`NetworkNodeWithRetrofit`](@ref), it returns the `co2_proxy` resource in
addition to the keys of the `output` dictionary.
"""
EMB.outputs(n::NetworkNodeWithRetrofit) = unique(append!(Resource[n.co2_proxy], keys(n.output)))
"""
    EMB.outputs(n::NetworkNodeWithRetrofit, p::Resource)

When the node is a [`NetworkNodeWithRetrofit`](@ref), it returns the value of `output`
resource `p`. If `p` is the `co2_proxy` resource, it returns 0.
"""
EMB.outputs(n::NetworkNodeWithRetrofit, p::Resource) = haskey(n.output, p) ? n.output[p] : 0

"""
    CCSRetroFit <: Network

This node allows for investments into CO₂ capture retrofit to a [`RefNetworkNodeRetrofit`](@ref)
node. The capture process is implemented through the variable `:cap_use`

The `co2_proxy` does not have to be specified as `input` resource.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variational operational costs per unit CO2 captured.
- **`opex_fixed::TimeProfile`** is the fixed operational costs.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
  The CO₂ instance is required to be included to be available to have CO₂ capture applied
  properly.
- **`co2_proxy::Resource`** is the instance of the `Resource` used for calculating internally
  the CO₂ flow from the `RefNetworkNodeRetrofit` to the `CCSRetroFit` node.
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
    EMB.inputs(n::CCSRetroFit)

When the node is a [`CCSRetroFit`](@ref), it returns the `co2_proxy` resource in addition to
the keys of the `input` dictionary.
"""
EMB.inputs(n::CCSRetroFit) = unique(append!(Resource[n.co2_proxy], keys(n.input)))
"""
    EMB.inputs(n::CCSRetroFit, p::Resource)

When the node is a [`CCSRetroFit`](@ref), it returns the value of `input` resource `p`.
If `p` is the `co2_proxy` resource, it returns 0.
"""
EMB.inputs(n::CCSRetroFit, p::Resource) = haskey(n.input, p) ? n.input[p] : 0

"""
    co2_proxy(n::EMB.Node)

Extract the instance of the CO₂ proxy. This function is available for all node types but
will provide an error if the node type does not support CO₂ capture retrofit.
"""
function co2_proxy(n::EMB.Node)
    if hasfield(typeof(n), :co2_proxy)
        return n.co2_proxy
    else
        @error("Composite type $(typeof(n)) does not support CO₂ capture retrofit.")
    end
end

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
