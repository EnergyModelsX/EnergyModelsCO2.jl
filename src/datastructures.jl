using EnergyModelsBase
using TimeStructures

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
    id

    Rate_cap::TimeProfile
    Stor_cap::TimeProfile

    Opex_var::TimeProfile
    Opex_fixed::TimeProfile

    Stor_res::ResourceEmit
    # Stor_res::ResourceCarrier get from global_data.CO2
    Input::Dict{Resource, Real}
    Output::Dict{Resource, Real}
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
    CO2Storage(id, Rate_cap, Stor_cap, Opex_var, Opex_fixed, Stor_res, Input, Dict(Stor_res=>1), Data)
end
