
"""
    EMB.variables_node(m, 𝒩::Vector{<:CO2Storage}, 𝒯, modeltype::EnergyModel)

Create the optimization variable `:stor_level_Δ_sp` for every [`CO2Storage`](@ref) node.
This variable accounts the increase in `stor_level` during a strategic period.

This method is called from `EnergyModelsBase.jl`.
"""
function EMB.variables_node(m, 𝒩::Vector{<:CO2Storage}, 𝒯, modeltype::EnergyModel)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    # Variable for keeping track of the increased storage_level during a
    # strategic period.
    @variable(m, stor_level_Δ_sp[𝒩, 𝒯ᴵⁿᵛ] >= 0)
end

"""
    create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a [`CO2Storage`](@ref) node.
"""
function EMB.create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    p_stor = storage_resource(n)
    𝒫ᵃᵈᵈ = setdiff(inputs(n), [p_stor])
    𝒫ᵉᵐ = setdiff(EMB.res_sub(𝒫, ResourceEmit), [p_stor])

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Set the lower bound for the CO2 emissions in the storage node (:emissions_node)
    # Fix all other emissions to a value of 0
    for t ∈ 𝒯
        set_lower_bound(m[:emissions_node][n, t, p_stor], 0)
        for p_em ∈ 𝒫ᵉᵐ
            fix(m[:emissions_node][n, t, p_em], 0,; force=true)
        end
    end

    # Mass/energy balance constraints for stored energy carrier.
    constraints_level(m, n, 𝒯, 𝒫, modeltype)

    # Constraint for additional required input
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
        m[:flow_in][n, t, p] == m[:stor_charge_use][n, t, p_stor] * inputs(n, p)
    )

    # Constraint for storage rate use
    @constraint(m, [t ∈ 𝒯],
       m[:flow_in][n, t, p_stor] ==
            m[:stor_charge_use][n, t] + m[:emissions_node][n, t, p_stor]
    )

    # The CO2Storage has no outputs.
    for t ∈ 𝒯, p ∈ outputs(n)
        fix(m[:flow_out][n, t, p], 0,; force=true)
    end

    # Bounds for the storage level and storage rate used.
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the default functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end

"""
    create_node(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `CCSRetroFit`.
"""
function EMB.create_node(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets
    𝒫ⁱⁿ = inputs(n)
    CO2_proxy = co2_proxy(n)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Inlet constraints for all other resources
    # The value for `CO2_proxy` is calculated in `constraints_data`.
    @constraint(m, [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ⁱⁿ, CO2_proxy)],
        m[:flow_in][n, t, p] == m[:cap_use][n, t] * inputs(n, p)
    )

    # Call of the function for the outlet flow from the `RefNetworkNodeRetrofit` node
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
