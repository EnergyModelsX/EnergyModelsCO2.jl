"""
    EMB.check_node(n::CO2Source, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a [`CO2Source`](@ref) node is valid. It is a repetition of the
standard checks for a `Source` node, but adds an additional check on the data.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The field `data` does not include [`CaptureData`](@extref EnergyModelsBase.CaptureData).
"""
function EMB.check_node(n::CO2Source, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        sum(capacity(n, t) ≥ 0 for t ∈ 𝒯) == length(𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        sum(outputs(n, p) ≥ 0 for p ∈ outputs(n)) == length(outputs(n)),
        "The values for the Dictionary `output` must be non-negative."
    )
    EMB.check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)
    @assert_or_log(
        !any(typeof.(node_data(n)) .<: CaptureData),
        "The `data` cannot include a `CaptureData`."
    )
end
