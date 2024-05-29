"""
    CO2Storage(
        id,
        rate_cap::TimeProfile,
        stor_cap::TimeProfile,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        stor_res::ResourceCarrier,
        input::Dict{<:Resource,<:Real},
        output::Dict{<:Resource,<:Real},
        data::Array{<:Data},
    )

Legacy constructor for a `CO2Storage`.
This version will be discontinued in the near future and replaced with the new version of
`CO2Storage{AccumulatingStrategic}` in which the parametric input defines the behaviour of
the storage. In addition, the new version supports variable and fixed operating expenses
for both the charge capacity and the level.
"""
function CO2Storage(
    id,
    rate_cap::TimeProfile,
    stor_cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Array{<:Data},
)
    @warn(
        "The used implementation of a `CO2Storage` will be discontinued in the near future.\n" *
        "In practice, only a single change has to be incorporated: \n 1. the application " *
        " of `StorCapOpex(rate_cap, opex_var, opex_fixed)` as 2ⁿᵈ field as well as " *
        "`StorCap(stor_cap)` as 3ʳᵈ field instead of using `rate_cap`, `stor_cap`, " *
        "`opex_var`, and `opex_fixed` as 2ⁿᵈ-5ᵗʰ fields.\n" *
        "It is recommended to update the existing implementation to the new version.",
        maxlog = 1
    )

    return CO2Storage{AccumulatingStrategic}(
        id,
        StorCapOpex(rate_cap, opex_var, opex_fixed),
        StorCap(stor_cap),
        stor_res,
        input,
        output,
        data,
    )
end
function CO2Storage(
    id,
    rate_cap::TimeProfile,
    stor_cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    data::Array{<:Data},
)
    @warn(
        "The used implementation of a `CO2Storage` will be discontinued in the near future.\n" *
        "In practice, only a single change has to be incorporated: \n 1. the application " *
        " of `StorCapOpex(rate_cap, opex_var, opex_fixed)` as 2ⁿᵈ field as well as " *
        "`StorCap(stor_cap)` as 3ʳᵈ field instead of using `rate_cap`, `stor_cap`, " *
        "`opex_var`, and `opex_fixed` as 2ⁿᵈ-5ᵗʰ fields.\n" *
        "It is recommended to update the existing implementation to the new version.",
        maxlog = 1
    )

    return CO2Storage{AccumulatingStrategic}(
        id,
        StorCapOpex(rate_cap, opex_var, opex_fixed),
        StorCap(stor_cap),
        stor_res,
        input,
        Dict(stor_res => 0),
        data,
    )
end
