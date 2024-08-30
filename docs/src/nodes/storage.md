# [CO₂ storage node](@id nodes-co2_storage)

The reference storage node, [`RefStorage`](@extref EnergyModelsBase.RefStorage) is quite flexible with respect to the individual storage behaviours, that is cyclic (both representative and strategic) or accumulating as it is included as parametric type using the individual *[storage behaviours](@extref EnergyModelsBase lib-pub-nodes-stor_behav)*.
In addition, it allows for both charge and level different *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)*.
It is however not possible at the moment to consider a storage balance between different strategic periods and the accumulation of CO₂ in the storage node.

Hence, it is necessary to include a specific CO₂ storage node

## [Introduced type and its field](@id nodes-co2_storage-fields)

The [`CO2Storage`](@ref) node is similar to a [`RefStorage`](@extref EnergyModelsBase.RefStorage) with minor modifications to the implemented constraints.
It introduces a new *[storage behavior](@extref EnergyModelsBase lib-pub-nodes-stor_behav)* to accomodate for the implementation of coupling the storage level balances between different strategic periods.
This storage behavior is called [`EnergyModelsCO2.AccumulatingStrategic`](@ref).

!!! info "`StorageBehaviour` for `CO2Storage` nodes"
    [`CO2Storage`](@ref) nodes utilize an inner constructor for specifying the storage behavior.
    This means that they can only be created with [`EnergyModelsCO2.AccumulatingStrategic`](@ref).
    If you plan to include a temporary CO₂ storage node, *e.g.* for storing captured CO₂ for subsequent  utilization, it is best to utilize the [`RefStorage`](@extref EnergyModelsBase.RefStorage) node.

### [Standard fields](@id nodes-co2_storage-fields-stand)

The standard fields are given as:

- **`id`**:\
  The field **`id`** is only used for providing a name to the node. This is similar to the approach utilized in `EnergyModelsBase`.
- **`charge::EMB.UnionCapacity`**:\
  The charge storage parameters must include a capacity for charging.
  More information can be found on *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)*.
- **`level::EMB.UnionCapacity`**:\
  The level storage parameters must include a capacity for charging.
  More information can be found on *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)*.
  !!! note "Permitted values for storage parameters in `charge` and `level`"
      If the node should contain investments through the application of [`EnergyModelsInvestments`](https:// energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
      Similarly, you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
      In addition, all capacity and fixed OPEX values have to be non-negative.
- **`stor_res::ResourceEmit`**:\
  The `stor_res` is the stored [`Resource`](@extref EnergyModelsBase.Resource).
  It must correspond to your CO₂ instance specified in the `EnergyModel`.
- **`input::Dict{<:Resource, <:Real}`**:\
  The field `input` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a CO₂ storage node, `input` should always include *CO₂* (the actual conversion value is not relevant as it is not utilized).
  It is also possible to include other resources which are required with a given correlation to the stored CO₂.
  One example would be *Power* in the case of electricity requirements for storing CO₂.\
  All values have to be non-negative.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) is used.

!!! danger "The field `output`"
    CO₂ storage nodes do not allow for the specification of an outlet field.
    Their sole intention is to serve as permanent storage nodes.
    Hence, although the field `output` is included in the composite type, it cannot be provided.

### [Additional fields](@id nodes-co2_storage-fields-new)

[`CO2Storage`](@ref) nodes do not add additional fields compared to [`RefStorage`](@extref EnergyModelsBase.RefStorage) nodes.

## [Mathematical description](@id nodes-co2_storage-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-co2_storage-math-var)

#### [Standard variables](@id nodes-co2_storage-math-var-stand)

The CO₂ storage node types utilize all standard variables from the `RefStorage`, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{stor\_level}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{stor\_level\_Δ\_op}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level\_Δ\_rp}``](@extref EnergyModelsBase man-opt_var-cap) if the `TimeStruct` includes `RepresentativePeriods`
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions)

Neither ``\texttt{stor\_discharge\_inst}`` nor ``\texttt{stor\_discharge\_use}`` are created for `CO2Storage` nodes as we do not specify a `discharge` field

#### [Additional variables](@id nodes-co2_storage-math-add)

[`CO2Storage`](@ref) nodes have to keep track of the stored CO₂ in each strategic period.
Hence, a single additional variable is declared through dispatching on the method [`EnergyModelsBase.variables_node()`](@ref):

- ``\texttt{stor\_level\_Δ\_sp}[n, t_{inv}]``: Stored CO₂ in storage node ``n`` in strategic period ``t_{inv}`` with a typical unit of t/a.\
  The stored CO₂ in each strategic period is a rate specifying how much CO₂ is stored within a given strategic period.
  Hence, it is important to consider the used duration for strategic periods (see *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)* for an explanation)

### [Constraints](@id nodes-co2_storage-math-con)

The following sections omit the direction inclusion of the vector of CO₂ storage nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{\text{CO}_2\_storage}`` for all [`CO2Source`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-co2_storage-math-con-stand)

CO₂ storages nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase man-con)* for `RefStorage` nodes.
These standard constraints are:

- `constraints_capacity_installed`:

  ```math
  \begin{aligned}
  \texttt{stor\_level\_inst}[n, t] & = capacity(level(n), t) \\
  \texttt{stor\_charge\_inst}[n, t] & = capacity(charge(n), t)
  \end{aligned}
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_level`:
  The level constraints are in general following the default approach with minor modifications.
  They are explained in detail below in *[Level constraints](@ref nodes-co2_storage-math-con-add-level)*.

- `constraints_opex_fixed`:

  ```math
  \begin{aligned}
  \texttt{opex\_fixed}&[n, t_{inv}] = \\ &
    opex\_fixed(level(n), t_{inv}) \times \texttt{stor\_level\_inst}[n, first(t_{inv})] + \\ &
    opex\_fixed(charge(n), t_{inv}) \times \texttt{stor\_charge\_inst}[n, first(t_{inv})] +
  \end{aligned}
  ```

  !!! tip "Why do we use `first()`"
      The variables ``\texttt{stor\_level\_inst}`` are declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacities in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \begin{aligned}
  \texttt{opex\_var}&[n, t_{inv}] = \\ \sum_{t \in t_{inv}}&
    opex\_var(level(n), t) \times \texttt{stor\_level}[n, t] \times EMB.multiple(t_{inv}, t) + \\ &
    opex\_var(charge(n), t) \times \texttt{stor\_charge\_use}[n, t] \times EMB.multiple(t_{inv}, t) +
  \end{aligned}
  ```

  !!! tip "The function `EMB.multiple`"
      The function [``EMB.multiple(t_{inv}, t)``](@extref EnergyModelsBase.multiple) calculates the scaling factor between operational and strategic periods.
      It also takes into accoun potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the CO₂ storage node, see above.

!!! info "Implementation of OPEX"
    The fixed and variable OPEX constribubtion for the level and the charge capacities are only included if the corresponding *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)* have a field `opex_fixed` and `opex_var`, respectively.
    Otherwise, they are omitted.

The function `constraints_capacity` is extended with a new method for CO₂ storage nodes to allow for accounting for the upper bound of stored CO₂ in strategic periods.

The standard constraints given by

```math
\begin{aligned}
\texttt{stor\_level\_inst}[n, t] & \geq \texttt{stor\_level}[n, t] \\
\texttt{stor\_charge\_inst}[n, t] & \geq \texttt{stor\_charge\_use}[n, t] \\
\end{aligned}
```

are extended with a constraint on the total stored amount of CO₂ given as:

```math
\texttt{stor\_level\_inst}[n, first(t_{inv})] \geq \sum_{k=first(T^{inv})}^{t_{inv}} \texttt{stor\_level\_Δ\_sp}[n, k] \times duration\_strat(k)
```

This constraint ensures that the sum off all stored CO₂ up to and including a given strategic period ``t_{inv}`` is constrained to the upper limit, even when considering the duration of the strategic periods.

#### [Additional constraints](@id nodes-co2_storage-math-con-add)

##### [Constraints calculated in `create_node`](@id nodes-co2_storage-math-con-add-node)

The inlet flow constraints are given as

```math
\begin{aligned}
  \texttt{flow\_in}[n, t, p] & =
  inputs(n, p) \times \texttt{stor\_charge\_use}[n, t]
  \qquad \forall p \in inputs(n) \setminus \{\text{CO}_2\} \\

  \texttt{flow\_in}[n, t, \text{CO}_2] & =
  \texttt{stor\_charge\_use}[n, t] + \texttt{emissions\_node}[n, t, \text{CO}_2]
\end{aligned}
```

This constraint allows the CO₂ storage node to act as CO₂ emitter in cases in which the storage capacity is exceeded.
As the variable ``\texttt{emissions\_node}`` has by default no lower bound this is enforced in the function for CO₂:

```math
\texttt{emissions\_node}[n, t, \text{CO}_2] \geq 0
```

As a CO₂ storage node should not include emissions other CO₂.
These are hence fixed for all other [`ResourceEmit`](@extref EnergyModelsBase.ResourceEmit) ``P^{em} \setminus \{\text{CO}_2\}`` to 0:

```math
\texttt{emissions\_node}[n, t, p_{em}] = 0 \qquad \forall p_{em} \in P^{em} \setminus \{\text{CO}_2\}
```

Similarly, all outlet flows are fixed to 0:

```math
\texttt{flow\_out}[n, t, p]  = 0 \qquad \forall p \in outputs(n, p)
```

##### [Level constraints](@id nodes-co2_storage-math-con-add-level)

The level constraints are in general slightly more complex to understand.
The overall structure is outlined on *[Constraint functions](@extref EnergyModelsBase man-con-stor_level)*.
The level constraints are called through the function `constraints_level` which then calls additional functions depending on the chosen time structure (whether it includes representative periods and/or operational scenarios) and the chosen *[storage behaviour](@extref EnergyModelsBase lib-pub-nodes-stor_behav)*.

The CO₂ storage node utilizes the majority of the concepts from `EnergyModelsBase` but requires adjustment for both constraining the variable ``\texttt{stor\_level\_Δ\_sp}`` and specify how the storage node has to behave in the first operational period (of the first representative period) of a strategic period.
This is achieved through dispatching on the functions `constraints_level_aux` and `previous_level`.

The constraints introduced in `constraints_level_aux` are given by

```math
\begin{aligned}
  \texttt{stor\_level\_Δ\_op}[n, t] & =
  \texttt{flow\_in}[n, t, \text{CO}_2] - \texttt{emissions\_node}[n, t, \text{CO}_2] \\

  \texttt{stor\_level\_Δ\_sp}[n, t_{inv}] & = \sum_{t \in t_{inv}}
  \texttt{stor\_level\_Δ\_op}[n, t] \times EMB.multiple(t_{inv}, t)
\end{aligned}
```

corresponding to the change in the storage level in an operational period and strategic period, respectively.

If the time structure includes representative periods, we also calculate the change of the storage level in each representative period within the function `constraints_level_iterate` (from `EnergyModelsBase`):

```math
  \texttt{stor\_level\_Δ\_rp}[n, t_{rp}] = \sum_{t \in t_{rp}}
  \texttt{stor\_level\_Δ\_op}[n, t] \times EMB.multiple(t_{rp}, t)
```

The general level constraint is calculated in the function `constraints_level_iterate` (from `EnergyModelsBase`):

```math
\texttt{stor\_level}[n, t] = prev\_level +
\texttt{stor\_level\_Δ\_op}[n, t] \times duration(t)
```

in which the value ``prev\_level`` is depending on the type of the previous operational (``t_{prev}``) and strategic level (``t_{inv,prev}``) (as well as the previous representative period (``t_{rp,prev}``)).
It is calculated through the function `previous_level`.

In the case of CO₂ storage node, we can distinguish the following cases:

1. The first operational period in the first representative period in the first strategic period (given by ``typeof(t_{prev}) = typeof(t_{rp, prev}) = typeof(t_{inv,prev}) = nothing``):\

   ```math
   prev\_level = 0
   ```

2. The first operational period in the first representative period in subsequent strategic period (given by ``typeof(t_{prev}) = typeof(t_{rp, prev}) = nothing``):\

   ```math
   \begin{aligned}
    prev\_level = & \texttt{stor\_level}[n, first(t_{inv,prev})] - \\ &
      \texttt{stor\_level\_Δ\_op}[n, first(t_{inv,prev})] \times duration(first(t_{inv,prev})) + \\ &
      \texttt{stor\_level\_Δ\_sp}[n, t_{inv,prev}] \times duration\_strat(t_{inv,prev})
   \end{aligned}
   ```

3. The first operational period in subsequent representative periods in any strategic period (given by ``typeof(t_{prev}) = nothing``):\

   ```math
   \begin{aligned}
    prev\_level = & \texttt{stor\_level}[n, first(t_{rp,prev})] - \\ &
      \texttt{stor\_level\_Δ\_op}[n, first(t_{rp,prev})] \times duration(first(t_{rp,prev})) + \\ &
      \texttt{stor\_level\_Δ\_rp}[n, t_{rp,prev}]
   \end{aligned}
   ```

   This situation only occurs in cases in which the time structure includes representative periods.

4. All other operational periods:\

   ```math
    prev\_level = \texttt{stor\_level}[n, t_{prev}]
   ```

Cases 1 and 2 are implemented within `EnergyModelsCO2` for `CO2Storage` nodes while cases 3 and 4 are implemented in `EnergyModelsBase`.
