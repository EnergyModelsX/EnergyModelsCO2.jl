
""" 
    EMB.variables_node(m, 𝒩::Vector{CO2Storage}, 𝒯, modeltype::EnergyModel)

Create the optimization variable `:stor_usage_sp` for every CO2Storage node.
This method is called from `EnergyModelsBase.jl`."""
function EMB.variables_node(m, 𝒩::Vector{CO2Storage}, 𝒯, modeltype::EnergyModel)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    # Variable for keeping track of the increased storage_level during a
    # strategic period. 
    @variable(m, stor_usage_sp[𝒩, 𝒯ᴵⁿᵛ] >= 0)
end

"""
    create_node(m, n::Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `Storage`. Can serve as fallback option for all unspecified
subtypes of `Storage`.
"""
function EMB.create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

    p_stor = n.Stor_res
    𝒫ᵉᵐ = EMB.res_sub(𝒫, ResourceEmit)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    for t_inv ∈ 𝒯ᴵⁿᵛ, t ∈ t_inv

        # Increase in stor_level during this strategic period.
        @constraint(m,
            m[:stor_usage_sp][n, t_inv] == (
                m[:stor_level][n, last_operational(t_inv)]
                -
                m[:stor_level][n, first_operational(t_inv)]
                +
                m[:flow_in][n, first_operational(t_inv), p_stor])
        )

        if t == first_operational(t_inv)
            if isfirst(t_inv)
                @constraint(m,
                    m[:stor_level][n, t] == m[:flow_in][n, t, p_stor] * duration(t)
                )
            else
                # Previous strategic period.
                t_inv_1 = previous(t_inv, 𝒯)

                @constraint(m,
                    m[:stor_level][n, t] == (
                        # Initial storage in previous sp
                        m[:stor_level][n, first_operational(t_inv_1)] -
                        m[:flow_in][n, first_operational(t_inv_1), p_stor] +
                        # Increase in stor_level during previous strateic period.
                        m[:stor_usage_sp][n, t_inv_1] * duration(t_inv_1) +
                        # Net increased stor_level in this strategic period.
                        (m[:flow_in][n, t, p_stor]
                         -
                         m[:flow_out][n, t, p_stor]) *
                        duration(t))
                )
            end
        else
            @constraint(m,
                m[:stor_level][n, t] == (
                    m[:stor_level][n, previous(t, 𝒯)]
                    +
                    m[:flow_in][n, t, p_stor]
                ) * duration(t)
            )
        end
    end

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == 0)

    # The CO2Storage has no outputs.
    @constraint(m, [t ∈ 𝒯, p ∈ keys(n.Output)],
        m[:flow_out][n, t, p] == 0)

    # Constraint for storage rate use, and use of additional required input resources.
    EMB.constraints_flow_in(m, n, 𝒯)

    # Bounds for the storage level and storage rate used.
    EMB.constraints_capacity(m, n, 𝒯)

    # The fixed OPEX should depend on the injection rate capacity.
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_fixed][n, t_inv] == n.Opex_fixed[t_inv] * m[:stor_rate_inst][n, first(t_inv)]
    )

    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ)

end
