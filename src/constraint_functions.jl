"""
    EMB.constraints_flow_out(m, n::CO2Source, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the outlet flow from `CO2Source`.
The standard `constraints_flow_out` function does not allow CO₂ as an outlet flow as the
CO₂ outlet flow is specified in the `constraints_data` function to implement CO₂ capture.
"""
function EMB.constraints_flow_out(m, n::CO2Source, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = outputs(n)

    # Constraint for the individual output stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵒᵘᵗ],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )
end

"""
    EMB.constraints_flow_out(
        m,
        n::NetworkNodeWithRetrofit,
        𝒯::TimeStructure,
        modeltype::EnergyModel
    )

Function for creating the constraint on the outlet flow from `NetworkNodeWithRetrofit`.
The standard `constraints_flow_out` function does allow for the CO₂ proxy as an outlet flow.
In the case of retrofitting CO2 capture, this flow constraint is handlded
"""
function EMB.constraints_flow_out(
    m,
    n::NetworkNodeWithRetrofit,
    𝒯::TimeStructure,
    modeltype::EnergyModel
)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = outputs(n)
    CO2_proxy = co2_proxy(n)

    # Constraint for the individual output stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ setdiff(𝒫ᵒᵘᵗ, [CO2_proxy])],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )
end

"""
    EMB.constraints_level_aux(m, n::Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Function for creating the Δ constraint for the level of a reference storage node with a
`ResourceCarrier` resource.
"""
function EMB.constraints_level_aux(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)
    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    p_stor = storage_resource(n)

    # Constraint for the change in the level in a given operational period
    @constraint(m, [t ∈ 𝒯],
        m[:stor_level_Δ_op][n, t] ==
            m[:stor_charge_use][n, t]
    )

    # Constraint for the change in the level in a strategic period
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:stor_level_Δ_sp][n, t_inv] ==
            sum(m[:stor_level_Δ_op][n, t] * scale_op_sp(t_inv, t) for t ∈ t_inv)
    )

    # Set the lower bound for the operational change in the level (:stor_level_Δ_op) to
    # avoid that emissions larger than the flow into the storage.
    for t ∈ 𝒯
        set_lower_bound(m[:stor_level_Δ_op][n, t], 0)
    end
end

"""
    EMB.constraints_capacity(m, n::CO2Storage, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the maximum level of a `CO2Storage` node.
As a `CO2Storage` node is accumulating, the upper bound is provided as well by the sum of
the changes in all strategic periods.
"""
function EMB.constraints_capacity(m, n::CO2Storage, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @constraint(m, [t ∈ 𝒯],
        m[:stor_level][n, t] <= m[:stor_level_inst][n, t]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_charge_use][n, t] <= m[:stor_charge_inst][n, t]
    )

    # Constraint for the change in the level in a strategic period
    @constraint(m, [t_inv_1 ∈ 𝒯ᴵⁿᵛ],
        sum(
            m[:stor_level_Δ_sp][n, t_inv_2] * duration_strat(t_inv_2)
        for t_inv_2 ∈ 𝒯ᴵⁿᵛ if t_inv_2 ≤ t_inv_1) ≤
            m[:stor_level_inst][n, first(t_inv_1)]
    )

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end
