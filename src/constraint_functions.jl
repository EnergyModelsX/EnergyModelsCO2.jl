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
    EMB.constraints_level_sp(
        m,
        n::CO2Storage,
        t_inv::TimeStruct.StrategicPeriod{T, U},
        t_inv_prev,
        modeltype
        ) where {T, U<:SimpleTimes}

Create the level constraint for a CO₂ storage node when the `TimeStructure`
is given as `SimpleTimes`.
"""
function EMB.constraints_level_sp(
    m,
    n::CO2Storage,
    t_inv::TimeStruct.StrategicPeriod{T,U},
    t_inv_prev,
    modeltype,
) where {T,U<:SimpleTimes}
    for (t_prev, t) ∈ withprev(t_inv)
        # Extract the previous level
        prev_level = previous_level(m, n, t_inv_prev, t_prev)

        # Mass balance constraints for stored CO2
        @constraint(
            m,
            m[:stor_level][n, t] == prev_level + m[:stor_level_Δ_op][n, t] * duration(t)
        )
    end
end

"""
    EMB.constraints_level_sp(
        m,
        n::CO2Storage,
        t_inv::TimeStruct.StrategicPeriod{T, RepresentativePeriods{U, T, SimpleTimes{T}}},
        t_inv_prev,
        modeltype
        ) where {T, U}

Create the level constraint for a CO₂ storage node when the `TimeStructure` is given as
`RepresentativePeriods`.
"""
function EMB.constraints_level_sp(
    m,
    n::CO2Storage,
    t_inv::TimeStruct.StrategicPeriod{T,RepresentativePeriods{U,T,SimpleTimes{T}}},
    t_inv_prev,
    modeltype,
) where {T,U}

    # Declaration of the required subsets
    𝒯ʳᵖ = repr_periods(t_inv)

    # Constraint for the total change in the level in a given representative period
    @constraint(
        m,
        [t_rp ∈ 𝒯ʳᵖ],
        m[:stor_level_Δ_rp][n, t_rp] == sum(
            m[:stor_level_Δ_op][n, t] * multiple_strat(t_inv, t) * duration(t) for t ∈ t_rp
        )
    )

    for (t_rp_prev, t_rp) ∈ withprev(𝒯ʳᵖ), (t_prev, t) ∈ withprev(t_rp)

        # Extract the previous level
        prev_level = previous_level(m, n, t_inv_prev, t_prev, t_rp_prev)

        # Mass balance constraints for stored CO2
        @constraint(
            m,
            m[:stor_level][n, t] == prev_level + m[:stor_level_Δ_op][n, t] * duration(t)
        )
    end
end
