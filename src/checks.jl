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
