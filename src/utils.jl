"""
    EMB.previous_level(
        m,
        n::CO2Storage,
        prev_pers::PreviousPeriods{Nothing, Nothing, Nothing},
        cyclic_pers::EMB.CyclicPeriods,
        modeltype::EnergyModel,
    )

The previous level in the first operational period in the first representative period in the
first strategic period is set to 0 for a [`CO2Storage`](@ref) node.

The reason for that is that the storage is considered to be empty in the beginning of the
analysis.
"""
function EMB.previous_level(
    m,
    n::CO2Storage,
    prev_pers::EMB.PreviousPeriods{Nothing,Nothing,Nothing},
    cyclic_pers::EMB.CyclicPeriods,
    modeltype::EnergyModel,
)
    return @expression(m, 0)
end
"""
    EMB.previous_level(
        m,
        n::CO2Storage,
        prev_pers::EMB.PreviousPeriods{TS.AbstractStrategicPeriod, Nothing, Nothing},
        cyclic_pers::EMB.CyclicPeriods,
        modeltype::EnergyModel,
    )

The previous level in the first operational period in the first representative period in all
strategic periods except for the first is set to the accumulated value in the previous
strategic periods for a [`CO2Storage`](@ref) node.
"""
function EMB.previous_level(
    m,
    n::CO2Storage,
    prev_pers::EMB.PreviousPeriods{<:TS.AbstractStrategicPeriod,Nothing,Nothing},
    cyclic_pers::EMB.CyclicPeriods,
    modeltype::EnergyModel,
)
    return @expression(
        m,
        # First level in the storage in previous investment period
        m[:stor_level][n, first(strat_per(prev_pers))] -
        m[:stor_level_Δ_op][n, first(strat_per(prev_pers))] *
        duration(first(strat_per(prev_pers))) +
        # Increase in stor_level during previous strategic period
        m[:stor_level_Δ_sp][n, strat_per(prev_pers)] * duration_strat(strat_per(prev_pers))
    )
end
