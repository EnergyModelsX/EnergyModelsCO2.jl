
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
    par_level = level(n)
    par_charge = charge(n)

    # Mass/energy balance constraints for stored energy carrier.
    constraints_level(m, n, 𝒯, 𝒫, modeltype)

    # The CO2Storage has no outputs.
    @constraint(m, [t ∈ 𝒯, p ∈ outputs(n)], m[:flow_out][n, t, p] == 0)

    # Constraint for additional required input
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
        m[:flow_in][n, t, p] == m[:flow_in][n, t, p_stor] * inputs(n, p)
    )

    # Constraint for storage rate use
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_charge_use][n, t] ==
        m[:flow_in][n, t, p_stor] - m[:emissions_node][n, t, p_stor]
    )

    # Bounds for the storage level and storage rate used.
    constraints_capacity(m, n, 𝒯, modeltype)

    # The fixed OPEX should depend on the injection rate capacity.
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)

    # Extracts the contribution from the individual components
    if isa(par_level, EMB.UnionOpexVar)
        opex_var_level = @expression(
            m,
            [t_inv ∈ 𝒯ᴵⁿᵛ],
            sum(
                m[:stor_level][n, t] * opex_var(par_level, t) * multiple(t_inv, t) for
                t ∈ t_inv
            )
        )
    else
        opex_var_level = @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ], 0)
    end
    if isa(par_charge, EMB.UnionOpexVar)
        opex_var_charge = @expression(
            m,
            [t_inv ∈ 𝒯ᴵⁿᵛ],
            sum(
                (m[:flow_in][n, t, p_stor] - m[:emissions_node][n, t, p_stor]) *
                opex_var(par_charge, t) *
                multiple(t_inv, t) for t ∈ t_inv
            )
        )
    else
        opex_var_charge = @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ], 0)
    end

    # Create the overall constraint
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] == opex_var_level[t_inv] + opex_var_charge[t_inv]
    )
end

"""
    create_node(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `NetworkCCSRetrofit`.
"""
function EMB.create_node(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒫ᵒᵘᵗ = outputs(n)
    CO2_proxy = co2_proxy(n)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Call of the function for the inlet flow to and outlet flow from the `Network` node
    constraints_flow_in(m, n, 𝒯, modeltype)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Outlet constraints for all other resources
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ᵒᵘᵗ, CO2_proxy)],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
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
    𝒫ᵒᵘᵗ = outputs(n)
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Outlet constraints for all other resources
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ᵒᵘᵗ, CO2)],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )

    # Call of the function for the inlet flow to the `RefNetworkEmissions`
    # All CO2_proxy input goes in, independently of cap_use
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ⁱⁿ, CO2_proxy)],
        m[:flow_in][n, t, p] == m[:cap_use][n, t] * inputs(n, p)
    )

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
