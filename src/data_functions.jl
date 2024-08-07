
"""
    EMB.constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::EmissionsData)

Constraints functions for calculating both the emissions and amount of CO₂ captured in the
process. There exist several configurations, in which there is no capture, but process
emissions, capture of the energy usage related emissions, capture of the process emissions,
and capture of both the process emissions and energy usage related emissions.

The functions are updated for a `NetworkCCSRetrofit`-node as the output is the CO₂ proxy and
not CO₂.
"""
function EMB.constraints_data(
    m,
    n::NetworkCCSRetrofit,
    𝒯,
    𝒫,
    modeltype,
    data::CaptureProcessEnergyEmissions,
)

    # Declaration of the required subsets.
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = inputs(n)
    𝒫ᵉᵐ = setdiff(EMB.res_em(𝒫), [CO2])

    # Calculate the total amount of CO2 to be considered for capture
    CO2_tot = @expression(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] * process_emissions(data, CO2, t) +
        sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ)
    )

    # Constraint for the emissions based on the assumed capture rate
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] == (1 - co2_capture(data)) * CO2_tot[t]
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(
        m,
        [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] ==
        m[:cap_use][n, t] * process_emissions.(data, p_em, t)
    )

    # Constraint for the outlet of the CO2 proxy
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2_proxy] == CO2_tot[t] * co2_capture(data))
end

function EMB.constraints_data(
    m,
    n::NetworkCCSRetrofit,
    𝒯,
    𝒫,
    modeltype,
    data::CaptureEnergyEmissions,
)

    # Declaration of the required subsets.
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = inputs(n)
    𝒫ᵉᵐ = setdiff(EMB.res_em(𝒫), [CO2])

    # Calculate the total amount of CO2 to be considered for capture
    CO2_tot = @expression(m, [t ∈ 𝒯], sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ))

    # Constraint for the emissions based on the assumed capture rate and process emissions
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] ==
        (1 - co2_capture(data)) * CO2_tot[t] +
        m[:cap_use][n, t] * process_emissions(data, CO2, t)
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(
        m,
        [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * process_emissions(data, p_em)
    )

    # Constraint for the outlet of the CO2 proxy
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2_proxy] == CO2_tot[t] * co2_capture(data))
end

function EMB.constraints_data(
    m,
    n::NetworkCCSRetrofit,
    𝒯,
    𝒫,
    modeltype,
    data::CaptureProcessEmissions,
)

    # Declaration of the required subsets.
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = inputs(n)
    𝒫ᵉᵐ = setdiff(EMB.res_em(𝒫), [CO2])

    # Calculate the total amount of CO2 to be considered for capture
    CO2_tot = @expression(m, [t ∈ 𝒯], m[:cap_use][n, t] * process_emissions(data, CO2, t))

    # Constraint for the emissions based on the assumed capture rate and energy usage
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] ==
        (1 - co2_capture(data)) * CO2_tot[t] +
        sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ)
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(
        m,
        [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * process_emissions(data, p_em)
    )

    # Constraint for the outlet of the CO2 proxy
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2_proxy] == CO2_tot[t] * co2_capture(data))
end

"""
    EMB.constraints_data(m, n::NetworkCCSRetrofit, 𝒯, 𝒫, modeltype, data::EmissionsData)

Constraints functions for calculating both the emissions and amount of CO₂ captured in the
process. There exist several configurations, in which there is no capture, but process
emissions, capture of the energy usage related emissions, capture of the process emissions,
and capture of both the process emissions and energy usage related emissions.

The functions are updated for a `NetworkCCSRetrofit`-node as the output is the CO₂ proxy and
not CO₂.
"""
function EMB.constraints_data(
    m,
    n::CCSRetroFit,
    𝒯,
    𝒫,
    modeltype,
    data::CaptureProcessEnergyEmissions,
)

    # Declaration of the required subsets.
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = inputs(n)
    𝒫ᵉᵐ = setdiff(EMB.res_em(𝒫), [CO2])

    # Calculate the total amount of CO2 to be considered for capture
    CO2_tot = @expression(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] * (1 + process_emissions(data, CO2, t)) +
        sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ)
    )

    # Calculate the amount of CO2 captured
    CO2_captured = @expression(m, [t ∈ 𝒯], CO2_tot[t] * co2_capture(data))

    # Constraint for the CO2 emissions
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] ==
        m[:flow_in][n, t, CO2_proxy] +
        m[:cap_use][n, t] * process_emissions(data, CO2, t) +
        sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ) - CO2_captured[t]
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(
        m,
        [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * process_emissions(data, p_em)
    )

    # Constraint for the outlet of the CO2
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2] == CO2_captured[t])

    # CO2 outlet constraint for limiting the maximum CO2 captured to the capture rate and
    # the inflow of both energy and CO2_proxy as well as the process emissions
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, CO2] ≤
            co2_capture(data) * (
                m[:flow_in][n, t, CO2_proxy] +
                sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ) +
                m[:cap_use][n, t] * process_emissions(data, CO2, t)
            )
    )
end

function EMB.constraints_data(
    m,
    n::CCSRetroFit,
    𝒯,
    𝒫,
    modeltype,
    data::CaptureEnergyEmissions,
)

    # Declaration of the required subsets.
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = inputs(n)
    𝒫ᵉᵐ = setdiff(EMB.res_em(𝒫), [CO2])

    # Calculate the total amount of CO2 to be considered for capture
    CO2_tot = @expression(m, [t ∈ 𝒯],
        m[:cap_use][n, t] + sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ)
    )

    # Calculate the amount of CO2 captured
    CO2_captured = @expression(m, [t ∈ 𝒯], CO2_tot[t] * co2_capture(data))

    # Constraint for the CO2 emissions
    @constraint(m, [t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] ==
            m[:flow_in][n, t, CO2_proxy] +
            m[:cap_use][n, t] * process_emissions(data, CO2, t) +
            sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ) - CO2_captured[t]
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * process_emissions(data, p_em)
    )

    # Constraint for the outlet of the CO2
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2] == CO2_captured[t])

    # CO2 outlet constraint for limiting the maximum CO2 captured to the capture rate and
    # the inflow of both energy and CO2_proxy
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, CO2] ≤
            co2_capture(data) * (
                m[:flow_in][n, t, CO2_proxy] +
                sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ)
            )
    )
end

function EMB.constraints_data(m, n::CCSRetroFit, 𝒯, 𝒫, modeltype, data::CaptureNone)

    # Declaration of the required subsets.
    CO2 = co2_instance(modeltype)
    CO2_proxy = co2_proxy(n)
    𝒫ⁱⁿ = inputs(n)
    𝒫ᵉᵐ = setdiff(EMB.res_em(𝒫), [CO2])

    # Calculate the total amount of CO2 to be considered for capture
    CO2_tot = @expression(m, [t ∈ 𝒯], m[:cap_use][n, t])

    # Calculate the amount of CO2 captured
    CO2_captured = @expression(m, [t ∈ 𝒯], CO2_tot[t] * co2_capture(data))

    # Constraint for the CO2 emissions
    @constraint(m,[t ∈ 𝒯],
        m[:emissions_node][n, t, CO2] ==
            m[:flow_in][n, t, CO2_proxy] +
            m[:cap_use][n, t] * process_emissions(data, CO2, t) +
            sum(co2_int(p) * m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ) - CO2_captured[t]
    )

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ 𝒫ᵉᵐ],
        m[:emissions_node][n, t, p_em] == m[:cap_use][n, t] * process_emissions(data, p_em)
    )

    # Constraint for the outlet of the CO2
    @constraint(m, [t ∈ 𝒯], m[:flow_out][n, t, CO2] == CO2_captured[t])

    # CO2 outlet constraint for limiting the maximum CO2 captured to the capture rate and
    # the inflow
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, CO2] ≤ co2_capture(data) * m[:flow_in][n, t, CO2_proxy]
    )
end
