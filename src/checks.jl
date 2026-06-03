"""
    EMB.check_node(n::CO2Source, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a [`CO2Source`](@ref) node is valid.

It reuses the standard checks of a `Source` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds an
additional check on the data.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The field `data` does not include [`CaptureData`](@extref EnergyModelsBase.CaptureData).
"""
function EMB.check_node(n::CO2Source, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    @assert_or_log(
        !any(typeof.(node_data(n)) .<: CaptureData),
        "The `data` cannot include a `CaptureData`."
    )
end

"""
    EMB.check_node(n::CO2Storage, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a [`CO2Storage`](@ref) node is valid.

It reuses the standard checks of a `Source` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds an
additional check on the parametric type.

## Checks
- The `TimeProfile` of the field `capacity` in the type in the field `charge` is required
  to be non-negative..
- The `TimeProfile` of the field `capacity` in the type in the field `level` is required
  to be non-negative`.
- The `TimeProfile` of the field `fixed_opex` is required to be non-negative and
  accessible through a `StrategicPeriod` as outlined in the function
  `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)` for the chosen composite type.
- The values of the dictionary `input` are required to be non-negative.
- The specified storage [`Resource`](@extref EnergyModelsBase.Resource) must be included in
  the dictionary `input`.
- The specified [`StorageBehavior`](@extref EnergyModelsBase.StorageBehavior) must be a
  subtype of `Accumulating`.
"""
function EMB.check_node(n::CO2Storage{T}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool) where {T}

    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    @assert_or_log(
        T <: EMB.Accumulating,
        "The `StorageBehavior` must be Accumulating."
    )
end
