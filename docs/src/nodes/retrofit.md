# [CO₂ capture retrofit](@id nodes-CCS_retrofit)

A specific CO₂ source node is required as the default implementation of a [`RefSource`](@extref EnergyModelsBase.RefSource) does not allow for the CO₂ instance to be an output, as declared in the function [`constraints_flow_out`](@extref EnergyModelsBase man-con-flow).
This is due to the implementation using [`CaptureData`](@extref EnergyModelsBase.CaptureData) in which the CO₂ oulet flow is calculated through the implementation of the capture rate.

Hence, it is necessary to implement a CO₂ source node if one wants to model only a CO₂ source.

## [Introduced type and its field](@id nodes-CCS_retrofit-fields)

CO₂ capture retrofit requires the implementation of two additional node types, [`RefNetworkNodeRetrofit`](@ref) and [`CCSRetroFit`](@ref) both nodes are quite similar to a [`RefNetworkNode`](@extref EnergyModelsBase.RefNetworkNode) although their application differs:

- [`RefNetworkNodeRetrofit`](@ref) can be best seen as an existing technology to which CO₂ capture should be fitted.
- [`CCSRetroFit`](@ref) is the CO₂ capture unit.

!!! danger "Implementation of retrofit"
    It is necessary to include both [`RefNetworkNodeRetrofit`](@ref) and [`CCSRetroFit`](@ref) if one wants to implement the additional installation of CO₂ capture.
    It is not possible to only use one of them.

    If you want to include several retrofit options, it is of absolute importance that you:

    1. directly couple the [`RefNetworkNodeRetrofit`](@ref) and [`CCSRetroFit`](@ref) nodes through a [`Link`](@extref EnergyModelsBase.Link) and
    2. do **not** include the CO₂ proxy resource (*[see below](@ref nodes-CCS_retrofit-fields-new)*) as a product in the `Availability` node.

    It would be otherwise possible to use a single CO₂ capture unit for all process with the option for retrofit, neglecting potential peak capacity requirements and economies of scale.

### [Standard fields](@id nodes-CCS_retrofit-fields-stand)

Both introduced nodes use the same fields, although their meaning may potentially differ.
The standard fields are given as:

- **`id`**:\
  The field **`id`** is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.
- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the potential usage of the node.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
  !!! info "Meaning in boths nodes"
      - [`RefNetworkNodeRetrofit`](@ref):\
        The capacity corresponds to the production capacity of a process.
      - [`CCSRetroFit`](@ref):\
        The capacity corresponds to the CO₂ flow rate handling capacity, **not** the CO₂ capture capacity
- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
  !!! info "Meaning in boths nodes"
      - [`RefNetworkNodeRetrofit`](@ref):\
        The variable OPEX is relative to the production of the main product.
      - [`CCSRetroFit`](@ref):\
        The variable OPEX is relative to the amount of flue gas handled, that is **not** the amount of CO₂ captured.
- **`input::Dict{<:Resource, <:Real}`** and **`output::Dict{<:Resource, <:Real}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  All values have to be non-negative.
  !!! info "Meaning in boths nodes"
      - [`RefNetworkNodeRetrofit`](@ref):\
        No special meaning.
        The CO₂ proxy resource is automatically included in the `output` dictionary through providing additional methods to `EMB.outputs`.
      - [`CCSRetroFit`](@ref):\
        The CO₂ proxy resource is automatically included in the `input` dictionary through providing additional methods to `EMB.inputs`.
        Requires the incorporation of the  CO₂ resource in the `output` dictionary, although the exact value is not relevant.
        It is furthermore possible to specify additional reenergy required for capturing CO₂ using a conversion factor (*e.g.*, MWh/t CO₂).
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  The `data` vector must include [`CaptureData`](@extref EnergyModelsBase.CaptureData) for both [`RefNetworkNodeRetrofit`](@ref) and [`CCSRetroFit`](@ref).
  It can include additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) is used.
  !!! info "Meaning of the capture rate in both nodes"
      - [`RefNetworkNodeRetrofit`](@ref):\
        The capture rate corresponds to the fraction of the flue gas which is sent to the `CCSRetroFit` node.
        Hence, if the value is below 1, only a fraction of the flue gas can be captured.
      - [`CCSRetroFit`](@ref):\
        The capture rate corresponds to
        1. the fraction captured from the flue gas ([`CaptureFlueGas`](@ref)),
        2. the fraction captured from the flue gas and the energy input to the unit ([`CaptureEnergyEmissions`](@ref)),
        3. the fraction captured from the flue gas and the process emissions ([`CaptureProcessEmissions`](@ref)), or
        4. the fraction captured from the flue gas, the energy input to the unit, and the process emissions ([`CaptureProcessEnergyEmissions`](@ref))

### [Additional fields](@id nodes-CCS_retrofit-fields-new)

Both introduced nodes have one additional field:

- **`co2_proxy::Resource`**:\
  The CO₂ proxy resource is introduced to simplify the analyses and seperate all streams corresponding to CO₂ from the CO₂ streams considered in CO₂ capture retrofit.
  It should be specified as [`ResourceCarrier`](@extref EnergyModelsBase.ResourceCarrier) with a CO₂ intensity of 0.

## [Mathematical description](@id nodes-CCS_retrofit-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-CCS_retrofit-math-var)

#### [Standard variables](@id nodes-CCS_retrofit-math-var-stand)

Both introduced nodes utilize all standard variables from the `RefNetworkNode`, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)

#### [Additional variables](@id nodes-CCS_retrofit-math-add)

Both introduced nodes do not add additional variables.

### [Constraints](@id nodes-CCS_retrofit-math-con)

The following sections omit the direction inclusion of the vector of any node.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`RefNetworkNodeRetrofit`](@ref) or [`CCSRetroFit`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-CCS_retrofit-math-con-stand)

Both introduced nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase man-con)*.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

- `constraints_flow_in`:

  ```math
  \texttt{flow\_in}[n, t, p] = inputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in inputs(n)
  ```

  !!! warning "This standard constraint is only included for `RefNetworkNodeRetrofit`."

- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, p] =
  outputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in outputs(n) \setminus \{\text{CO}_2\}
  ```

  !!! warning "This standard constraint is only included for `CCSRetroFit`."

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` ise declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex_var(n, t) \times \texttt{cap\_use}[n, t] \times EMB.multiple(t_{inv}, t)
  ```

- `constraints_data`:\
  This function is only called for specified data of the nodes, see above.
  This function is extended with multiple methods for both `CCSRetroFit` and `RefNetworkNodeRetrofit`.
  The individual methods are explained below.

The outlet flow constraint for a [`RefNetworkNodeRetrofit`](@ref) node is requires introducing new methods for the function `constraints_flow_out` as the outlet flow of the CO₂ proxy is calculated in the function `constraints_data` as outlined in *[Standard constraints](@ref nodes-CCS_retrofit-math-con-stand)*.
This constraint is given by:

```math
\texttt{flow\_out}[n, t, p] =
outputs(n, p) \times \texttt{cap\_use}[n, t]
\qquad \forall p \in outputs(n) \setminus \{co2\_proxy(n)\}
```

The introduction of the CO₂ capture unit as retrofit option requires introducing new methods for the function `constraints_data` for all [`CaptureData`](@extref EnergyModelsBase.CaptureData) as described on *[Data functions](@extref EnergyModelsBase man-data_fun-emissions)*.
In all methods, the process emissions of the other [`ResourceEmit`](@extref EnergyModelsBase.ResourceEmit)s, that is all emissions resources except for CO₂, are calculated as

```math
\begin{aligned}
  \texttt{emissions\_node}&[n, t, p_{em}] = \\ &
    \texttt{cap\_use}[n, t] \times process\_emissions(data, p_{em}, t)
    \qquad \forall p_{em} \in P^{em} \setminus \{\text{CO}_2\}
\end{aligned}
```

[`RefNetworkNodeRetrofit`](@ref) introduces methods for [`CaptureProcessEmissions`](@extref EnergyModelsBase.CaptureProcessEmissions), [`CaptureEnergyEmissions`](@extref EnergyModelsBase.CaptureEnergyEmissions), and [`CaptureProcessEnergyEmissions`](@extref EnergyModelsBase.CaptureProcessEnergyEmissions).

!!! info "data::CaptureProcessEmissions"
    The total produced CO₂ is calculated through an auxiliary expression as

    ```math
      CO2\_tot[n, t] =
        \texttt{cap\_use}[n, t] \times process\_emissions(data, \text{CO}_2, t)
    ```

    This auxiliary variable is subsequently used to calculate the CO₂ emissions of the node as

    ```math
    \begin{aligned}
      \texttt{emissions\_node}&[n, t, \text{CO}_2] = \\ &
        (1-co2\_capture(data)) \times  CO2\_tot[n, t] + \\ &
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}]
    \end{aligned}
    ```

!!! info "data::CaptureEnergyEmissions"
    The total produced CO₂ is calculated through an auxiliary expression as

    ```math
      CO2\_tot[n, t] =
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}]
    ```

    This auxiliary variable is subsequently used to calculate the CO₂ emissions of the node as

    ```math
    \begin{aligned}
      \texttt{emissions\_node}&[n, t, \text{CO}_2] = \\ &
        (1-co2\_capture(data)) \times  CO2\_tot[n, t] + \\ &
        \texttt{cap\_use}[n, t] \times process\_emissions(data, \text{CO}_2, t)
    \end{aligned}
    ```

!!! info "data::CaptureProcessEnergyEmissions"
    The total produced CO₂ is calculated through an auxiliary expression as

    ```math
    \begin{aligned}
      CO2\_tot&[n, t] = \\ &
        \texttt{cap\_use}[n, t] \times process\_emissions(data, \text{CO}_2, t) + \\ &
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}]
    \end{aligned}
    ```

    This auxiliary variable is subsequently used to calculate the CO₂ emissions of the node as

    ```math
    \begin{aligned}
      \texttt{emissions\_node}&[n, t, \text{CO}_2] = \\ &
        (1-co2\_capture(data)) \times  CO2\_tot[n, t] + \\ &
    \end{aligned}
    ```

These constraints are the same as it is the case for other nodes.
The only difference is the calculation of the the outlet flow of the CO₂ proxy resource.
It is for all `CaptureData` calculated as

```math
  \texttt{flow\_out}[n, t, co2\_proxy(n)] = CO2\_tot[n, t] * co2\_capture(data)
```

[`CCSRetroFit`](@ref) introduces methods for [`CaptureFlueGas`](@ref), [`CaptureProcessEmissions`](@extref EnergyModelsBase.CaptureProcessEmissions), [`CaptureEnergyEmissions`](@extref EnergyModelsBase.CaptureEnergyEmissions), and [`CaptureProcessEnergyEmissions`](@extref EnergyModelsBase.CaptureProcessEnergyEmissions).

All types utilize similar functions although there is a variation in the individual calculations.
The model introduces two auxiliaty expressiones, ``CO2\_tot_[n, t]`` and ``CO2\_captured[n, t]``.
``CO2\_tot_[n, t]`` representes the total produced CO₂ (flue gas from the `RefNetworkNodeRetrofit` and potentially energy usage related emissions and/or process emissions) in the capture unit.
Hence, its calculation differes depending on the `CaptureData`.
``CO2\_captured[n, t]`` is calculated as:

```math
  CO2\_captured[n, t] =
    co2\_capture(data) \times CO2\_tot[n, t]
```

The CO₂ emissions are calculated for all types using the auxiliary variable ``CO2\_captured[n, t]`` as

```math
\begin{aligned}
  \texttt{emissions\_node}&[n, t, \text{CO}_2] = \\ &
    \texttt{flow\_in}[n, t, co2\_proxy(n)] + \\ &
    \texttt{cap\_use}[n, t] \times process\_emissions(data, \text{CO}_2, t) + \\ &
    \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}] - \\ &
    CO2\_captured[n, t]
\end{aligned}
```

while the CO₂ outlet flow is given as:

```math
  \texttt{flow\_out}[n, t, \text{CO}_2] = CO2\_captured[n, t]
```

!!! info "data::CaptureFlueGas"
    The total produced CO₂ is calculated as

    ```math
      CO2\_tot[n, t] =
        \texttt{cap\_use}[n, t]
    ```

    In addition, we have to provide an upper limit on the outlet CO₂ flow to avoid achieving a higher capture rate than specified when the capture unit is dimensioned for a larger CO₂ proxy inlet flow rate:

    ```math
    \begin{aligned}
      \texttt{flow\_out}&[n, t, \text{CO}_2] \leq \\ &
        co2\_capture(data) \times \\ &
        \texttt{flow\_in}[n, t, co2\_proxy(n)]
    \end{aligned}
    ```

!!! info "data::CaptureProcessEmissions"
    The total produced CO₂ is calculated as

    ```math
    \begin{aligned}
      CO2\_tot&[n, t] = \\ &
        \texttt{cap\_use}[n, t] \times (1 + process\_emissions(data, \text{CO}_2, t))
    \end{aligned}
    ```

    In addition, we have to provide an upper limit on the outlet CO₂ flow to avoid achieving a higher capture rate than specified when the capture unit is dimensioned for a larger CO₂ proxy inlet flow rate:

    ```math
    \begin{aligned}
      \texttt{flow\_out}&[n, t, \text{CO}_2] \leq \\ &
        co2\_capture(data) \times \\ &
        (\texttt{flow\_in}[n, t, co2\_proxy(n)] + \\ &
        \texttt{cap\_use}[n, t] \times process\_emissions(data, \text{CO}_2, t))
    \end{aligned}
    ```

!!! info "data::CaptureEnergyEmissions"
    The total produced CO₂ is calculated as

    ```math
    \begin{aligned}
      CO2\_tot&[n, t] = \\ &
        \texttt{cap\_use}[n, t] + \\ &
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}]
    \end{aligned}
    ```

    In addition, we have to provide an upper limit on the outlet CO₂ flow to avoid achieving a higher capture rate than specified when the capture unit is dimensioned for a larger CO₂ proxy inlet flow rate:

    ```math
    \begin{aligned}
      \texttt{flow\_out}&[n, t, \text{CO}_2] \leq \\ &
        co2\_capture(data) \times \\ &
        (\texttt{flow\_in}[n, t, co2\_proxy(n)] + \\ &
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}])
    \end{aligned}
    ```


!!! info "data::CaptureProcessEnergyEmissions"
    The total produced CO₂ is calculated through an auxiliary expression as

    ```math
    \begin{aligned}
      CO2\_tot&[n, t] = \\ &
        \texttt{cap\_use}[n, t] \times (1 + process\_emissions(data, \text{CO}_2, t)) + \\ &
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}]
    \end{aligned}
    ```


    This auxiliary variable is subsequently used to calculate the CO₂ emissions of the node as

    ```math
    \begin{aligned}
      \texttt{flow\_out}&[n, t, \text{CO}_2] \leq  \\ &
        co2\_capture(data) \times \\ &
        (\texttt{flow\_in}[n, t, co2\_proxy(n)] + \\ &
        \texttt{cap\_use}[n, t] \times process\_emissions(data, \text{CO}_2, t) + \\ &
        \sum_{p_{in} \in P^{in}} co2\_int(p_{in}) \times \texttt{flow\_in}[n, t, p_{in}])
    \end{aligned}
    ```


#### [Additional constraints](@id nodes-CCS_retrofit-math-con-add)

##### [Constraints calculated in `create_node`](@id nodes-CCS_retrofit-math-con-add-node)

The inlet flow constraint for a [`CCSRetroFit`](@ref) node is calculated separately as the inlet flow of the CO₂ proxy is calculated in the function `constraints_data` as outlined in *[Standard constraints](@ref nodes-CCS_retrofit-math-con-stand)*.
This constraint is given by:

```math
\texttt{flow\_in}[n, t, p] =
inputs(n, p) \times \texttt{cap\_use}[n, t]
\qquad \forall p \in inputs(n) \setminus \{co2\_proxy(n)\}
```

##### [Constraints through separate functions](@id nodes-CCS_retrofit-math-con-add-fun)

Neither [`RefNetworkNodeRetrofit`](@ref) nor [`CCSRetroFit`](@ref) nodes introduce new functions.
