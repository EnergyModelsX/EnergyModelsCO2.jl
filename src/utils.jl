"""
    previous_level(m, n, t_inv_prev::Nothing, t_prev::Nothing, t_rp_prev::Nothing)

Return the previous level depending on the input type.

The initial level in the first investment period is set to 0 for a `CO2Storage` node.
The reason for that is that the storage is considered to be empty in the beginning of the
analysis.
"""
function previous_level(
    m,
    n::CO2Storage,
    t_inv_prev::Nothing,
    t_prev::Nothing,
    t_rp_prev::Nothing,
)
    return @expression(m, 0)
end

"""
    previous_level(m, n, t_inv_prev, t_prev::Nothing, t_rp_prev)

Return the previous level depending on the input type.

The initial level in strategic periods excluding the first is given by the initial level of
the previous strategic period plus the accumulation in this period.

The substraction of stor_level_Δ_op[n, first(t_inv_prev)] is necessary to avoid treating the
first operational period differently with respect to the level as the latter is defined at
the end of the period.
"""
function previous_level(m, n::CO2Storage, t_inv_prev, t_prev::Nothing, t_rp_prev)
    return @expression(
        m,
        # First level in the storage in previous investment period
        m[:stor_level][n, first(t_inv_prev)] -
        m[:stor_level_Δ_op][n, first(t_inv_prev)] * duration(first(t_inv_prev)) +
        # Increase in stor_level during previous strategic period
        m[:stor_level_Δ_sp][n, t_inv_prev] * duration(t_inv_prev)
    )
end

"""
    previous_level(m, n, t_inv_prev, t_prev, t_rp_prev)

Return the previous level depending on the input type.

The initial level in subsequent operational periods is given by the initial level of the
previous operational period.
"""
function previous_level(m, n, t_inv_prev, t_prev, t_rp_prev)

    # Previous storage level, as there are no changes
    return @expression(m, m[:stor_level][n, t_prev])
end

"""
    previous_level(m, n, t_inv_prev, t_prev::Nothing, t_rp_prev::TS.StratReprPeriod)

Return the previous level depending on the input type.

The initial level in representative periods excluding the first is given by the initial
level of the previous representative period plus the accumulation in this period.

The substraction of stor_level_Δ_op[n, first(t_inv_prev)] is necessary to avoid treating the
first operational period differently with respect to the level as the latter is defined at
the end of the period.
"""
function previous_level(
    m,
    n::CO2Storage,
    t_inv_prev,
    t_prev::Nothing,
    t_rp_prev::TS.StratReprPeriod,
)
    return @expression(
        m,
        # Initial storage in previous sp
        m[:stor_level][n, first(t_rp_prev)] -
        m[:stor_level_Δ_op][n, first(t_rp_prev)] * duration(first(t_rp_prev)) +
        # Increase in previous representative period
        m[:stor_level_Δ_rp][n, t_rp_prev]
    )
end

previous_level(m, n, t_inv_prev, t_prev) = previous_level(m, n, t_inv_prev, t_prev, nothing)
