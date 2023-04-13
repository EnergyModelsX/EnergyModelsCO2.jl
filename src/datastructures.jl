using EnergyModelsBase
using TimeStructures

"""
    CO2Storage <: Storage

# Fields
- **`id`** is the name/identifyer of the node.\n
- **`Rate_cap::TimeProfile`** is the installed rate capacity, that is e.g. power or mass flow.\n
- **`Stor_cap::TimeProfile`** is the installed storage capacity, that is e.g. energy or mass.\n
- **`Opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`Opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`Stor_res::Resource`** is the stored `Resource`.\n
- **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
- **`Output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
Only relevant for linking and the stored `Resource`.\n
- **`Data::Dict{String, Data}`** is the additional data (e.g. for investments).
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
    Data::Dict{Any, Data}
end

"""
    CO2Storage(id, Rate_cap, Stor_cap, Opex_var, Opex_fixed, Stor_res, Input, Data)

Constructor for the struct CO2Storage

# Fields
- **`id`** is the name/identifyer of the node.\n
- **`Rate_cap::TimeProfile`** is the installed rate capacity, that is e.g. power or mass flow.\n
- **`Stor_cap::TimeProfile`** is the installed storage capacity, that is e.g. energy or mass.\n
- **`Opex_var::TimeProfile`** is the variational operational costs per energy unit produced.\n
- **`Opex_fixed::TimeProfile`** is the fixed operational costs.\n
- **`Stor_res::Resource`** is the stored `Resource`.\n
- **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
- **`Data::Dict{String, Data}`** is the additional data (e.g. for investments).

Sets the field `Output` to a defualt value.
"""
function CO2Storage(id, Rate_cap, Stor_cap, Opex_var, Opex_fixed, Stor_res, Input, Data)
    CO2Storage(id, Rate_cap, Stor_cap, Opex_var, Opex_fixed, Stor_res, Input, Dict(Stor_res=>1), Data)
end
