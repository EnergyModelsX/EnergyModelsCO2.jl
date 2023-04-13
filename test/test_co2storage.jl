using EnergyModelsCO2
using EnergyModelsBase
using HiGHS
using JuMP
using Test
using TimeStructures


const EMB = EnergyModelsBase


CO2 = ResourceEmit("CO2", 1.)


function small_graph(T)
    products = [CO2]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})

    ng_source = RefSource("ng", FixedProfile(9), FixedProfile(-3), FixedProfile(1),
        Dict(CO2 => 1), Dict("" => EMB.EmptyData()), 𝒫ᵉᵐ₀)

    co2_storage = CO2Storage("co2", FixedProfile(10), FixedProfile(2000),
        FixedProfile(2), FixedProfile(1), CO2, Dict(CO2=>1), Dict(CO2=>1), Dict(""=>EmptyData()))

    nodes = [GenAvailability(1, 𝒫₀, 𝒫₀), ng_source, co2_storage]
    links = [
        Direct("ng-av", ng_source, nodes[1])
        Direct("av-co2", nodes[1], co2_storage)
        Direct("co2-av", co2_storage, nodes[1])
    ]

    modeltype = OperationalModel(
        Dict(CO2=>FixedProfile(3)),
        CO2)

    case = Dict(
        :nodes => nodes,
        :links => links,
        :products => products,
        :T => T,
    )
    return case, modeltype
end


@testset "CO2 source and storage" begin
    # Creation of the time structure
    T = UniformTwoLevel(1, 2, 1, UniformTimes(1, 3, 1))
   
    case, modeltype = small_graph(T)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    nodes = case[:nodes]
    T = case[:T]

    source = nodes[2]
    storage = nodes[3]

    for t_inv in strategic_periods(T)
        for t in t_inv
            if t == first_operational(t_inv)
                if isfirst(t_inv)
                    @test value(m[:stor_level][storage, t]) == value(m[:flow_out][source, t, CO2])
                else
                    prev = last_operational(previous(t_inv, T))

                    @test value(m[:stor_level][storage, prev]) + 
                        value(m[:flow_out][source, t, CO2]) == value(m[:stor_level][storage, t])
                end
            else
                @test value(m[:stor_level][storage, previous(t, T)]) + 
                    value(m[:flow_out][source, t, CO2]) == value(m[:stor_level][storage, t])
            end
        end
    end

    # Test that the source produces with max capacity in all operational periods.
    source_cap = 9
    @test sum(value(m[:flow_out][source, t, CO2]) == source_cap for t ∈ T) == length(T)

end

@testset "Storage accumulation over strategic periods" begin
    # Creation of the time structure
    sp_length = 3
    op_length = 4
    source_cap = 9
    T = UniformTwoLevel(1, 4, sp_length, UniformTimes(1, op_length, 1))
   
    case, modeltype = small_graph(T)
    m = EMB.run_model(case, modeltype, HiGHS.Optimizer)

    nodes = case[:nodes]
    T = case[:T]

    source = nodes[2]
    storage = nodes[3]

    for (i, t_inv) in enumerate(strategic_periods(T))
        for t in t_inv
            if t == first_operational(t_inv)
                @test value(m[:stor_level][storage, t]) == 
                    sp_length * op_length * source_cap * (i - 1) + source_cap
            else
                @test value(m[:stor_level][storage, previous(t, T)]) + 
                    value(m[:flow_out][source, t, CO2]) == value(m[:stor_level][storage, t])
            end
        end
    end

    # Test that the source produces with max capacity in all operational periods.
    @test sum(value(m[:flow_out][source, t, CO2]) == source_cap for t ∈ T) == length(T)

end
