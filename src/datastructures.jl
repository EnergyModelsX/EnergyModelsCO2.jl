""" A CO2 `Source` node.

Its only difference from a RefSource is that is allows for CO2 as outlet.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed capacity.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`..\n
- **`data::Array{Data}`** is the additional data (e.g. for investments).\n
- **`emissions::Dict{ResourceEmit, Real}`**: emissions per energy unit produced.

"""
struct CO2Source <: Source
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{Resource,Real}
    data::Array{Data}
end

"""
    CO2Storage <: Storage

This node has an install injection rate capacity `rate_cap` and a storage capacity
`stor_cap`.

The storage level (accountet by the optimization variable `stor_level`) will
increase during all strategic periods (sp), i.e. the stored resource can not be
taken out of the storage.

The initial storage level in a strategic period is set to the storage level at
the end of the prevoious sp. Note that the increased storage level during a sp
is multiplied with the length of the sp when the initial storage level for the
next sp is set.


# Fields
 - **`id`** is the name/identifyer of the node.\n
 - **`rate_cap::TimeProfile`** is the installed rate capacity, that is e.g. power or mass flow.\n
 - **`stor_cap::TimeProfile`** is the installed storage capacity, that is e.g. energy or mass.\n
 - **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
 - **`opex_fixed::TimeProfile`** is the fixed operational costs.\n
 - **`stor_res::Resource`** is the stored `Resource`.\n
 - **`input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
 - **`output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
   Requires that the stored resource `stor_res` is set here.\n
 - **`data::Array{Data}`** is the additional data (e.g. for investments).
"""
struct CO2Storage <: Storage
    id::Any

    rate_cap::TimeProfile
    stor_cap::TimeProfile

    opex_var::TimeProfile
    opex_fixed::TimeProfile

    stor_res::ResourceEmit
    # stor_res::ResourceCarrier get from global_data.CO2
    input::Dict{Resource,Real}
    output::Dict{Resource,Real}
    data::Array{<:Data}
end
EMB.has_emissions(n::CO2Storage) = true

"""
    CO2Storage(id, rate_cap, stor_cap, opex_var, opex_fixed, stor_res, input, Data)

Constructor for the struct [`CO2Storage`](@ref).

Sets the field `output` to the default value `Dict(stor_res=>1)`.

# Fields
- **`id`** is the name/identifyer of the node.\n
- **`rate_cap::TimeProfile`** is the installed rate capacity, that is e.g. power or mass flow.\n
- **`stor_cap::TimeProfile`** is the installed storage capacity, that is e.g. energy or mass.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`stor_res::Resource`** is the stored `Resource`.\n
- **`input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
- **`data::Dict{String, Data}`** is the additional data (e.g. for investments).
"""
function CO2Storage(id, rate_cap, stor_cap, opex_var, opex_fixed, stor_res, input, Data)
    return CO2Storage(
        id,
        rate_cap,
        stor_cap,
        opex_var,
        opex_fixed,
        stor_res,
        input,
        Dict(stor_res => 1),
        Data,
    )
end

"""
    NetworkCCSRetrofit <: NetworkNode

This node allows for retrofitting CCS to a `Network` node.

It corresponds to a `RefNetwork` node in which the CO2 is not emitted. Instead, it is
transferred to a `co2_proxy` that is fed subsequently to a node in which it is either
captured, or emitted.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed capacity.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.\n
- **`output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
co2_proxy is required to be included to be available to have CO2 capture applied properly.\n
- **`Emissions::Dict{ResourceEmit, Real}`**: emissions per unit produced.\n
- **`CO2_capture::Real`** is the fraction of CO2 that is sent to the capture unit.\n
- **`co2_proxy::Resource`** is the instance of the `Resource` used for emissions.\n
- **`data::Array{Data}`** is the additional data (e.g. for investments).
"""
struct NetworkCCSRetrofit <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{Resource,Real}
    output::Dict{Resource,Real}
    co2_proxy::Resource
    data::Array{<:Data}
end

"""
    CCSRetroFit <: Network

This node allows for investments into CCS retrofit to a `NetworkCCSRetrofit` node. The
capture process is implemented through the variable `cap_use`

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed capacity.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.\n
- **`output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
CO2 is required to be included to be available to have CO2 capture applied properly.\n
- **`Emissions::Dict{ResourceEmit, Real}`**: emissions per unit produced.\n
- **`CO2_capture::Real`** is the fraction of CO2 that is sent to the capture unit.\n
- **`co2_proxy::Resource`** is the instance of the `Resource` used for emissions.\n
- **`data::Array{Data}`** is the additional data (e.g. for investments).
"""
struct CCSRetroFit <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{Resource,Real}
    output::Dict{Resource,Real}
    co2_proxy::Resource
    data::Array{<:Data}
end

"""
    co2_proxy(n)

Extract the instance of the CO2 proxy
"""
co2_proxy(n) = n.co2_proxy

"""
Capture the proxy CO2 instance but not the energy usage related emissions and the process
emissions. Does not require `emissions` as input, but can be supplied.

# Fields
- **`emissions::Dict{ResourceEmit, T}`**: emissions per unit produced.\n
- **`co2_capture::Float64`** is the CO2 capture rate.
"""
struct CaptureNone{T} <: CaptureData{T}
    emissions::Dict{ResourceEmit,T}
    co2_capture::Float64
end
CaptureNone(co2_capture::Float64) = CaptureNone(Dict{ResourceEmit,Float64}(), co2_capture)
