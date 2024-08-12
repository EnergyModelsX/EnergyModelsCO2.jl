# [CO₂ source node](@id nodes-co2_source)

A specific CO₂ source node is required as the default implementation of a [`RefSource`](@extref EnergyModelsBase.RefSource) does not allow for the CO₂ instance to be an output, as declared in the function [`constraints_flow_out`](@extref EnergyModelsBase constraint_functions).
This is due to the implementation using [`CaptureData`](@extref EnergyModelsBase.CaptureData) in which the CO₂ oulet flow is calculated through the implementation of the capture rate.

Hence, it is necessary to implement a CO₂ source node if one wants to model only a CO₂ source.

## [Introduced type and its field](@id nodes-co2_source-fields)

The [`CO2Source`](@ref) is implemented as equivalent to a [`RefSource`](@extref EnergyModelsBase.RefSource).
Hence, it utilizes the same functions declared in `EnergyModelsBase`.

### [Standard fields](@id nodes-co2_source-fields-stand)

The standard fields are given as:

- **`id`**:\
  The field **`id`** is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.
- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the potential usage of the node.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase var_cap).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase utilize_timestruct)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a CO₂ source, `output` should always include *CO₂*.
  It is also possible to include other resources which are produced with a given correlation with CO₂.\
  All values have to be non-negative.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) is used or for additional emission data through [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess).
  The latter would correspond to uncaptured CO₂ that should be included in the analyses.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `EmissionsData`"
      CO₂ source nodes are not compatible with [`CaptureData`](@extref EnergyModelsBase.CaptureData).
      This is is also checked in the [`EnergyModelsBase.check_node`](@ref) function.

      CO₂ source nodes can only us [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess).

### [Additional fields](@id nodes-co2_source-fields-new)

[`CO2Source`](@ref) nodes do not add additional fields compared to a [`RefSource`](@extref EnergyModelsBase.RefSource).

## [Mathematical description](@id nodes-co2_source-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-co2_source-math-var)

#### [Standard variables](@id nodes-co2_source-math-var-stand)

The CO₂ source node types utilize all standard variables from the `RefSource`, as described on the page *[Optimization variables](@extref EnergyModelsBase optimization_variables)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase var_opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase var_opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase var_cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase var_cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase var_flow)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase var_emission) if `EmissionsData` is added to the field `data`.
  Note that CO₂ source nodes are not compatible with `CaptureData`.
  Hence, you can only provide [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess) to the node.

#### [Additional variables](@id nodes-co2_source-math-add)

[`CO2Source`](@ref) nodes do not add additional variables.

### [Constraints](@id nodes-co2_source-math-con)

The following sections omit the direction inclusion of the vector of CO₂ source nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{\text{CO}_2\_source}`` for all [`CO2Source`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-co2_source-math-con-stand)

CO₂ source nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase constraint_functions)*.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex_var(n, t) \times \texttt{cap\_use}[n, t] \times EMB.multiple(t_{inv}, t)
  ```

- `constraints_data`:\
  This function is only called for specified data of the CO₂ source, see above.

The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) to incorporate the potential for investment.
Nodes with investments are then no longer constrained by the parameter capacity.

The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase var_cap)* for further explanations).
Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

The function `constraints_flow_out` is extended with a new method for CO₂ source nodes to allow the inclusion of CO₂:

```math
\texttt{flow\_out}[n, t, p] =
outputs(n, p) \times \texttt{cap\_use}[n, t]
\qquad \forall p \in outputs(n)
```

#### [Additional constraints](@id nodes-co2_source-math-con-add)

[`CO2Source`](@ref) nodes do not add additional constraints.
