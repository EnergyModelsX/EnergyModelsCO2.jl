"""
    constraints_flow_out(m, n::CO2Source, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the outlet flow from `CO2Source`.
The standard `constraints_flow_out` function does not allow CO₂ as an outlet flow as the
CO₂ outlet flow is specified in the `constraints_data` function to implement CO₂ capture.
"""
function EMB.constraints_flow_out(m, n::CO2Source, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = outputs(n)

    # Constraint for the individual output stream connections
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫ᵒᵘᵗ],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )
end

"""
    constraints_level_aux(m, n::Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Function for creating the Δ constraint for the level of a reference storage node with a
`ResourceCarrier` resource.
"""
function EMB.constraints_level_aux(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)
    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    p_stor = storage_resource(n)
    𝒫ᵉᵐ = setdiff(EMB.res_sub(𝒫, ResourceEmit), [p_stor])

    # Set the lower bound for the emissions in the storage node
    for t ∈ 𝒯
        set_lower_bound(m[:emissions_node][n, t, p_stor], 0)
    end

    # Constraint for the change in the level in a given operational period
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_level_Δ_op][n, t] ==
        m[:flow_in][n, t, p_stor] - m[:emissions_node][n, t, p_stor]
    )

    # Constraint for the change in the level in a strategic period
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:stor_level_Δ_sp][n, t_inv] ==
        sum(m[:stor_level_Δ_op][n, t] * EMB.multiple(t_inv, t) for t ∈ t_inv)
    )

    # Constraint for the emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ], m[:emissions_node][n, t, p_em] == 0)
end
