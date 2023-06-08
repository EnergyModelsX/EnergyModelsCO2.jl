
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

    return EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
