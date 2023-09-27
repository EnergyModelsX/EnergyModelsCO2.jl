"""
    CO2Storage <: Storage

This node has an install injection rate capacity `Rate_cap` and a storage capacity
`Stor_cap`.

The storage level (accountet by the optimization variable `stor_level`) will
increase during all strategic periods (sp), i.e. the stored resource can not be
taken out of the storage.

The initial storage level in a strategic period is set to the storage level at
the end of the prevoious sp. Note that the increased storage level during a sp
is multiplied with the length of the sp when the initial storage level for the
next sp is set.


# Fields
 - **`id`** is the name/identifyer of the node.\n
 - **`Rate_cap::TimeProfile`** is the installed rate capacity, that is e.g. power or mass flow.\n
 - **`Stor_cap::TimeProfile`** is the installed storage capacity, that is e.g. energy or mass.\n
 - **`Opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
 - **`Opex_fixed::TimeProfile`** is the fixed operational costs.\n
 - **`Stor_res::Resource`** is the stored `Resource`.\n
 - **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
 - **`Output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
   Requires that the stored resource `Stor_res` is set here.\n
 - **`Data::Array{Data}`** is the additional data (e.g. for investments).
"""
struct CO2Storage <: Storage
    id::Any

    Rate_cap::TimeProfile
    Stor_cap::TimeProfile

    Opex_var::TimeProfile
    Opex_fixed::TimeProfile

    Stor_res::ResourceEmit
    # Stor_res::ResourceCarrier get from global_data.CO2
    Input::Dict{Resource,Real}
    Output::Dict{Resource,Real}
    Data::Array{Data}
end

"""
    CO2Storage(id, Rate_cap, Stor_cap, Opex_var, Opex_fixed, Stor_res, Input, Data)

Constructor for the struct [`CO2Storage`](@ref).

Sets the field `Output` to the default value `Dict(Stor_res=>1)`.

# Fields
- **`id`** is the name/identifyer of the node.\n
- **`Rate_cap::TimeProfile`** is the installed rate capacity, that is e.g. power or mass flow.\n
- **`Stor_cap::TimeProfile`** is the installed storage capacity, that is e.g. energy or mass.\n
- **`Opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`Opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`Stor_res::Resource`** is the stored `Resource`.\n
- **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
- **`Data::Dict{String, Data}`** is the additional data (e.g. for investments).
"""
function CO2Storage(id, Rate_cap, Stor_cap, Opex_var, Opex_fixed, Stor_res, Input, Data)
    return CO2Storage(
        id,
        Rate_cap,
        Stor_cap,
        Opex_var,
        Opex_fixed,
        Stor_res,
        Input,
        Dict(Stor_res => 1),
        Data,
    )
end

"""
    NetworkCCSRetrofit <: Network

This node allows for retrofitting CCS to a `Network` node.

It corresponds to a `RefNetwork` node in which the CO2 is not emitted. Instead, it is
transferred to a `CO2_proxy` that is fed subsequently to a node in which it is either
captured, or emitted.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`Cap::TimeProfile`** is the installed capacity.\n
- **`Opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`Opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.\n
- **`Output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
CO2_proxy is required to be included to be available to have CO2 capture applied properly.\n
- **`Emissions::Dict{ResourceEmit, Real}`**: emissions per unit produced.\n
- **`CO2_capture::Real`** is the fraction of CO2 that is sent to the capture unit.\n
- **`CO2_proxy::Resource`** is the instance of the `Resource` used for emissions.\n
- **`Data::Array{Data}`** is the additional data (e.g. for investments).
"""
struct NetworkCCSRetrofit <: Network
    id::Any
    Cap::TimeProfile
    Opex_var::TimeProfile
    Opex_fixed::TimeProfile
    Input::Dict{Resource,Real}
    Output::Dict{Resource,Real}
    Emissions::Dict{ResourceEmit,Real}
    CO2_capture::Real
    CO2_proxy::Resource
    Data::Array{Data}
end

"""
    CCSRetroFit <: Network

This node allows for investments into CCS retrofit to a `NetworkCCSRetrofit` node. The
capture process is implemented through the variable `cap_use`

# Fields
- **`id`** is the name/identifier of the node.\n
- **`Cap::TimeProfile`** is the installed capacity.\n
- **`Opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`Opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.\n
- **`Output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
CO2 is required to be included to be available to have CO2 capture applied properly.\n
- **`Emissions::Dict{ResourceEmit, Real}`**: emissions per unit produced.\n
- **`CO2_capture::Real`** is the fraction of CO2 that is sent to the capture unit.\n
- **`CO2_proxy::Resource`** is the instance of the `Resource` used for emissions.\n
- **`Data::Array{Data}`** is the additional data (e.g. for investments).
"""
struct CCSRetroFit <: Network
    id::Any
    Cap::TimeProfile
    Opex_var::TimeProfile
    Opex_fixed::TimeProfile
    Input::Dict{Resource,Real}
    Output::Dict{Resource,Real}
    Emissions::Dict{ResourceEmit,Real}
    CO2_capture::Real
    CO2_proxy::Resource
    Data::Array{Data}
end
