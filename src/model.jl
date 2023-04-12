
"""
    create_node(m, n::Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `Storage`. Can serve as fallback option for all unspecified
subtypes of `Storage`.
"""
function EMB.create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)
    # 𝒫ᵃᵈᵈ   = setdiff(keys(n.Input), [CO2])

    # Constraint for additional required input.
    # @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ], 
        # m[:flow_in][n, t, p] == m[:flow_in][n, t, CO2] * n.Input[p])


    p_stor = n.Stor_res
    # 𝒫ᵉᵐ    = EMB.res_sub(𝒫, ResourceEmit)
    𝒯ᴵⁿᵛ   = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    for t_inv ∈ 𝒯ᴵⁿᵛ, t ∈ t_inv
        if t == first_operational(t_inv)
            if isfirst(t_inv)
                @constraint(m,
                    m[:stor_level][n, t] ==  (m[:flow_in][n, t , p_stor] -
                                            - m[:flow_out][n, t, p_stor]) * 
                                                duration(t)
                )
            else
                previous_operational = last_operational(previous(t_inv, 𝒯))
                @constraint(m,
                    m[:stor_level][n, t] ==  m[:stor_level][n, previous_operational] + 
                                                (m[:flow_in][n, t , p_stor] 
                                                - m[:flow_out][n, t, p_stor]) * 
                                                duration(t)
                )
            end
        else
            @constraint(m,
                m[:stor_level][n, t] ==  m[:stor_level][n, previous(t, 𝒯)] + 
                                            (m[:flow_in][n, t , p_stor] 
                                            - m[:flow_out][n, t, p_stor]) * 
                                            duration(t)
            )
        end
    end
    
    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ keys(n.Output)],
        m[:emissions_node][n, t, p_em] == 0)

    # The sink has no outputs.
    @constraint(m, [t ∈ 𝒯, p ∈ keys(n.Output)],
         m[:flow_out][n, t, p] == 0)

    # Constraint for storage rate use
    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_use][n, t] == m[:flow_in][n, t, p_stor]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_use][n, t] <= m[:stor_rate_inst][n, t]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_level][n, t] <= m[:stor_cap_inst][n, t]
    )

    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_fixed][n, t_inv] == 
            n.Opex_fixed[t_inv] * m[:stor_cap_inst][n, first(t_inv)]
    )

    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] == 
            sum(m[:flow_in][n, t , p_stor] * n.Opex_var[t] * t.duration for t ∈ t_inv)
    )

end
