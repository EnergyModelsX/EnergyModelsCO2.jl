
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
    for t_inv ∈ 𝒯ᴵⁿᵛ, n ∈ 𝒩
        insertvar!(m[:stor_level_Δ_sp], n, t_inv)
    end
end

"""
    create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a [`CO2Storage`](@ref) node.

It differs from the function for a standard [`RefStorage`](@extref EnergyModelsBase.RefStorage)
node through modifying the flow to the node and not calling the functions
[`constraints_flow_in`](@extref EnergyModelsBase.constraints_flow_in) and
[`constraints_flow_out`](@extref EnergyModelsBase.constraints_flow_out). The former is
replaced with constraints directly within the function.

# Called constraint functions
- [`constraints_data`](@extref EnergyModelsBase.constraints_data) for all `node_data(n)`,
- [`constraints_level`](@extref EnergyModelsBase.constraints_level),
- [`constraints_capacity`](@extref EnergyModelsBase.constraints_capacity),
- [`constraints_opex_fixed`](@extref EnergyModelsBase.constraints_opex_fixed), and
- [`constraints_opex_var`](@extref EnergyModelsBase.constraints_opex_var).
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
        m[:flow_in][n, t, p] == m[:stor_charge_use][n, t] * inputs(n, p)
    )

    # Constraint for storage rate use
    @constraint(m, [t ∈ 𝒯],
       m[:flow_in][n, t, p_stor] ==
            m[:stor_charge_use][n, t] + m[:emissions_node][n, t, p_stor]
    )

    # The CO2Storage has no outputs.
    for t ∈ 𝒯
        fix(m[:stor_discharge_use][n, t], 0,; force=true)
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

It differs from the function for a standard `NetworkNode` node through modifying the flow
to the node for the CO₂ proxy resource. The function
[`constraints_flow_in`](@extref EnergyModelsBase.constraints_flow_in) is hence not called.

# Called constraint functions
- [`constraints_data`](@extref EnergyModelsBase.constraints_data) for all `node_data(n)`,
- [`constraints_flow_out`](@extref EnergyModelsBase.constraints_flow_out),
- [`constraints_capacity`](@extref EnergyModelsBase.constraints_capacity),
- [`constraints_opex_fixed`](@extref EnergyModelsBase.constraints_opex_fixed), and
- [`constraints_opex_var`](@extref EnergyModelsBase.constraints_opex_var).
"""
function EMB.create_node(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = setdiff(inputs(n), [CO2_proxy])
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Inlet constraints for all other resources
    # The value for `CO2_proxy` is calculated in `constraints_data`.
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ],
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
