
"""
    EMB.variables_node(m, 𝒩::Vector{CO2Storage}, 𝒯, modeltype::EnergyModel)

Create the optimization variable `:stor_usage_sp` for every CO2Storage node.
This variable accounts the increase in `stor_level` during a strategic period.

This method is called from `EnergyModelsBase.jl`.
"""
function EMB.variables_node(m, 𝒩::Vector{CO2Storage}, 𝒯, modeltype::EnergyModel)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    # Variable for keeping track of the increased storage_level during a
    # strategic period.
    @variable(m, stor_usage_sp[𝒩, 𝒯ᴵⁿᵛ] >= 0)
end

"""
    create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `CO2Storage`.
"""
function EMB.create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)
    p_stor = n.Stor_res
    𝒫ᵉᵐ = EMB.res_sub(𝒫, ResourceEmit)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    for (t_inv_prev, t_inv) ∈ withprev(𝒯ᴵⁿᵛ)
        # Increase in stor_level during this strategic period.
        @constraint(
            m,
            m[:stor_usage_sp][n, t_inv] == (
                m[:stor_level][n, last(t_inv)] - m[:stor_level][n, first(t_inv)] +
                m[:flow_in][n, first(t_inv), p_stor]
            )
        )

        for (t_prev, t) ∈ withprev(t_inv)
            if isnothing(t_prev)
                if isnothing(t_inv_prev)
                    @constraint(
                        m,
                        m[:stor_level][n, t] == m[:flow_in][n, t, p_stor] * duration(t)
                    )
                else
                    @constraint(
                        m,
                        m[:stor_level][n, t] == (
                            # Initial storage in previous sp
                            m[:stor_level][n, first(t_inv_prev)] -
                            m[:flow_in][n, first(t_inv_prev), p_stor] +
                            # Increase in stor_level during previous strategic period.
                            m[:stor_usage_sp][n, t_inv_prev] * duration(t_inv_prev) +
                            # Net increased stor_level in this strategic period.
                            (m[:flow_in][n, t, p_stor] - m[:flow_out][n, t, p_stor]) *
                            duration(t)
                        )
                    )
                end
            else
                @constraint(
                    m,
                    m[:stor_level][n, t] ==
                    m[:stor_level][n, t_prev] + m[:flow_in][n, t, p_stor] * duration(t)
                )
            end
        end
    end

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ], m[:emissions_node][n, t, p_em] == 0)

    # The CO2Storage has no outputs.
    @constraint(m, [t ∈ 𝒯, p ∈ keys(n.Output)], m[:flow_out][n, t, p] == 0)

    # Constraint for storage rate use, and use of additional required input resources.
    EMB.constraints_flow_in(m, n, 𝒯, modeltype)

    # Bounds for the storage level and storage rate used.
    EMB.constraints_capacity(m, n, 𝒯, modeltype)

    # The fixed OPEX should depend on the injection rate capacity.
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_fixed][n, t_inv] ==
        n.Opex_fixed[t_inv] * m[:stor_rate_inst][n, first(t_inv)]
    )

    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end

"""
    create_node(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `NetworkCCSRetrofit`.
"""
function EMB.create_node(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒫ⁱⁿ = collect(keys(n.Input))
    𝒫ᵒᵘᵗ = collect(keys(n.Output))
    𝒫ᵉᵐ = EMB.res_sub(𝒫, ResourceEmit)
    CO2 = modeltype.CO2_instance
    CO2_proxy = n.CO2_proxy
    𝒯ᴵⁿᵛ = TS.strategic_periods(𝒯)

    # Call of the function for the inlet flow to and outlet flow from the `Network` node
    EMB.constraints_flow_in(m, n, 𝒯, modeltype)

    # Calculate the total amount of CO2
    tot_CO2 = @expression(
        m,
        [t ∈ 𝒯],
        sum(p.CO2_int * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ) +
        m[:cap_use][n, t] * n.Emissions[CO2]
    )

    # Constraint for the emissions associated to energy usage
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] == (1 - n.CO2_capture) * tot_CO2[t]
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(
        m,
        [t ∈ 𝒯, p_em ∈ EMB.res_not(𝒫ᵉᵐ, CO2)],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * n.Emissions[p_em]
    )

    # CO2 proxy outlet constraint
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2_proxy] == n.CO2_capture * tot_CO2[t])

    # Outlet constraints for all other resources
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ᵒᵘᵗ, CO2_proxy)],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * n.Output[p]
    )

    # Call of the function for limiting the capacity to the maximum installed capacity
    EMB.constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    EMB.constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end

"""
    create_node(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `CCSRetroFit`.
"""
function EMB.create_node(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype::EnergyModel)
    𝒫ⁱⁿ = collect(keys(n.Input))
    𝒫ᵒᵘᵗ = collect(keys(n.Output))
    𝒫ᵉᵐ = EMB.res_sub(𝒫, ResourceEmit)
    CO2 = modeltype.CO2_instance
    CO2_proxy = n.CO2_proxy
    𝒯ᴵⁿᵛ = TS.strategic_periods(𝒯)

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(
        m,
        [t ∈ 𝒯, p_em ∈ EMB.res_not(𝒫ᵉᵐ, CO2)],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * n.Emissions[p_em]
    )

    # CO2 balance in the capture unit
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] ==
        # All not captured CO2 proxy (i.e., sent to CCS sink) is emitted as CO2
        m[:flow_in][n, t, CO2_proxy] - m[:cap_use][n, t] * n.CO2_capture +
        # For other input products, CO2 intensity related emissions
        sum(p.CO2_int * m[:flow_in][n, t, p] for p ∈ EMB.res_not(𝒫ⁱⁿ, CO2_proxy)) +
        # Direct emissions of the node
        m[:cap_use][n, t] * n.Emissions[CO2]
    )

    # CO2 proxy outlet constraint
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2] == n.CO2_capture * m[:cap_use][n, t])

    # CO2 proxy outlet constraint for limiting the maximum CO2 captured
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:flow_out][n, t, CO2] <= n.CO2_capture * m[:flow_in][n, t, CO2_proxy]
    )

    # Outlet constraints for all other resources
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ᵒᵘᵗ, CO2)],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * n.Output[p]
    )

    # Call of the function for the inlet flow to the `RefNetworkEmissions`
    # All CO2_proxy input goes in, independently of cap_use
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ EMB.res_not(𝒫ⁱⁿ, CO2_proxy)],
        m[:flow_in][n, t, p] == m[:cap_use][n, t] * n.Input[p]
    )

    # Call of the function for limiting the capacity to the maximum installed capacity
    EMB.constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    EMB.constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
