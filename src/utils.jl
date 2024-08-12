"""
    EMB.previous_level(
        m,
        n::CO2Storage,
        prev_pers::PreviousPeriods,
        cyclic_pers::CyclicPeriods,
        modeltype::EnergyModel,
    )

Adding methods for the function [`EnergyModelsBase.previous_level`](@extref) for a
[`CO2Storage`](@ref) node. the additional methods are only relevant for the first operational
period of a strategic period while the framework utilizes the functions from
`EneryModelsBase` for all other periods.

    prev_pers::PreviousPeriods{Nothing,Nothing,Nothing}

The previous level in the first operational period in the first representative period in the
first strategic period is set to 0.

The reason for that is that the storage is considered to be empty in the beginning of the
analysis.
"""
function EMB.previous_level(
    m,
    n::CO2Storage,
    prev_pers::PreviousPeriods{Nothing,Nothing,Nothing},
    cyclic_pers::CyclicPeriods,
    modeltype::EnergyModel,
)
    return @expression(m, 0)
end
"""
    prev_pers::PreviousPeriods{<:TS.AbstractStrategicPeriod,Nothing,Nothing}

The previous level in the first operational period in the first representative period in all
strategic periods except for the first is set to the accumulated value in the previous
strategic periods.
"""
function EMB.previous_level(
    m,
    n::CO2Storage,
    prev_pers::PreviousPeriods{<:TS.AbstractStrategicPeriod,Nothing,Nothing},
    cyclic_pers::CyclicPeriods,
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
