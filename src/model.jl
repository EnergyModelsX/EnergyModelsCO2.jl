
"""
    create_node(m, n::Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `Storage`. Can serve as fallback option for all unspecified
subtypes of `Storage`.
"""
function EMB.create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

    p_stor = n.Stor_res
    𝒫ᵉᵐ    = EMB.res_sub(𝒫, ResourceEmit)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    for t_inv ∈ 𝒯ᴵⁿᵛ, t ∈ t_inv
        if t == first_operational(t_inv)
            if isfirst(t_inv)
                @constraint(m,
                    m[:stor_level][n, t] == (m[:flow_in][n, t, p_stor] -
                                             -m[:flow_out][n, t, p_stor]) *
                                            duration(t)
                )
            else
                t_inv_1 = previous(t_inv, 𝒯)
                # Last operational period of previous strategic period.
                t_inv_1_final_op = last_operational(t_inv_1)
                t_inv_1_first_op = first_operational(t_inv_1)

                @constraint(m,
                    m[:stor_level][n, t] == m[:stor_level][n, t_inv_1_first_op] - # Initial storage in previous sp
                                            m[:flow_in][n, t_inv_1_first_op, p_stor] +
                                            (m[:stor_level][n, t_inv_1_final_op] # Increases stor_level in previous sp
                                             -
                                             m[:stor_level][n, t_inv_1_first_op]
                                             +
                                             m[:flow_in][n, t_inv_1_first_op, p_stor]) * duration(t_inv_1) +
                                            (m[:flow_in][n, t, p_stor] # Net increased stor_level in this sp
                                             -
                                             m[:flow_out][n, t, p_stor]) *
                                            duration(t)
                )
            end
        else
            @constraint(m,
                m[:stor_level][n, t] == m[:stor_level][n, previous(t, 𝒯)] +
                                        (m[:flow_in][n, t, p_stor]
                                         -
                                         m[:flow_out][n, t, p_stor]) *
                                        duration(t)
            )
        end
    end

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == 0)

    # The sink has no outputs.
    @constraint(m, [t ∈ 𝒯, p ∈ keys(n.Output)],
        m[:flow_out][n, t, p] == 0)

    # Constraint for storage rate use, and use of additional required input resources.
    EMB.constraints_flow_in(m, n, 𝒯)

    # Bounds for the storage level and storage rate used.
    EMB.constraints_capacity(m, n, 𝒯)

    # The fixed OPEX should depend on the injection rate capacity.
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_fixed][n, t_inv] ==
            n.Opex_fixed[t_inv] * m[:stor_rate_inst][n, first(t_inv)]
    )

    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ)

end
