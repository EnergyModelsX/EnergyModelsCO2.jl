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
`CO2Storage` in which the parametric input (not included due to inner constructor) defines
the behaviour of the storage. In addition, the new version supports variable and fixed
operating expenses for both the charge capacity and the level.
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

    return CO2Storage(
        id,
        StorCapOpex(rate_cap, opex_var, opex_fixed),
        StorCap(stor_cap),
        stor_res,
        input,
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

    return CO2Storage(
        id,
        StorCapOpex(rate_cap, opex_var, opex_fixed),
        StorCap(stor_cap),
        stor_res,
        input,
        Dict(stor_res => 0),
        data,
    )
end


"""
    NetworkCCSRetrofit(args)

Legacy constructor `NetworkCCSRetrofit`
This type was renamed to `RefNetworkNodeRetrofit` while everything else remains the same.
"""
function NetworkCCSRetrofit(args...)
    @warn(
        "The used implementation of a `NetworkCCSRetrofit` will be discontinued in the near future.\n" *
        "Its name is changed to `RefNetworkNodeRetrofit`",
        maxlog = 1
    )
    return RefNetworkNodeRetrofit(args...)
end

"""
    CaptureNone(emissions::Dict{ResourceEmit,T}, co2_capture::Float64)

Legacy constructor for a `CaptureNone`.
This type was renamed to `CaptureFlueGas` while everything else remains the same.
"""
function CaptureNone(emissions::Dict{ResourceEmit,T}, co2_capture::Float64) where {T}
    @warn(
        "The used implementation of a `CaptureNone` will be discontinued in the near future.\n" *
        "Its name is changed to `CaptureFlueGas`",
        maxlog = 1
    )
    return CaptureFlueGas(emissions, co2_capture)
end
function CaptureNone(co2_capture::Float64)
    @warn(
        "The used implementation of a `CaptureNone` will be discontinued in the near future.\n" *
        "Its name is changed to `CaptureFlueGas`",
        maxlog = 1
    )
    return CaptureFlueGas(Dict{ResourceEmit,Float64}(), co2_capture)
end
