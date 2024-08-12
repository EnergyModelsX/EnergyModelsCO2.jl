```@meta
CurrentModule = EnergyModelsCO2
```

# EnergyModelsCO2

Documentation for [EnergyModelsCO2](https://gitlab.sintef.no/clean_export/EnergyModelsCO2.jl).

```@docs
EnergyModelsCO2
```

This package depends on
[EnergyModelsBase](https://clean_export.pages.sintef.no/energymodelsbase.jl/)
and [TimeStruct](https://clean_export.pages.sintef.no/timestructures.jl/).

It implements the following new technology nodes:

1. a `Source` node [`CO2Source`](@ref),
2. a `Storage` node [`CO2Storage`](@ref),
3. a `Network` node [`RefNetworkNodeRetrofit`](@ref) to which CCS can be retrofitted, and
4. a `Network` node [`CCSRetroFit`](@ref) that corresponds to the unit that captures CCS.

## Developed nodes

### [`CO2Source`](@ref)

The main difference from a regular `RefSource`-node is that the `CO2Source` allows for the CO₂ instance to be an output

### [`CO2Storage`](@ref)

The main difference from a regular `Storage`-node is that the `CO2Storage` will not reset the storage level at the beginning of each strategic period, but the level will accumulate across the strategic periods.
This allows for proper accounting for the total stored CO₂.
In addition, it takes the total storage limit into account.

### [`RefNetworkNodeRetrofit`](@ref)

The main difference from a regular `RefNetworkNode`-node is that it does not directly emit CO₂.
Instead, a proxy CO₂ is produced that leaves the node in the output.
It cannot be used as standalone, but instead requires the inclusion of a [`CCSRetroFit`](@ref), either directly coupled, or alternatively _via_ an `Availability` node.

### [`CCSRetroFit`](@ref)

The `CCSRetroFit`-node has to be coupled with a `RefNetworkNodeRetrofit` node.
In the base case, when the installed capacity is 0, all CO₂ entering the node is emitted.
The CO₂ is captured, if a given capacity is installed.
However, it only captures the proxy CO₂ resource and not process or energy use related emissions.

## Manual outline

```@contents
Pages = [
    "manual/quick-start.md",
    "manual/NEWS.md",
]
Depth = 1
```

## Description of the nodes

```@contents
Pages = [
    "nodes/source.md",
    "nodes/storage.md",
    "nodes/retrofit.md",
]
Depth = 1
```

## How to guides

```@contents
Pages = [
    "how-to/contribute.md",
    "how-to/incorporate_retrofit.md",
]
Depth = 1
```

## Library outline

```@contents
Pages = [
    "library/public.md",
    "library/internals.md",
]
Depth = 1
```
