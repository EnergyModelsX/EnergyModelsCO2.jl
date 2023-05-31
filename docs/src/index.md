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
and [TimeStructures](https://clean_export.pages.sintef.no/timestructures.jl/),
and implements a new technology node [`CO2Storage`](@ref) representing a
CO₂-storage. The main difference from a regular `Storage`-node is that the
`CO2Storage` will not reset the storage level at the beginning of each strategic
period, but the level will accumulate across the strategic periods.


## Manual outline
```@contents
Pages = [
    "manual/quick-start.md",
]
```

## Library outline
```@contents
Pages = [
    "library/public.md",
    "library/internals.md",
]
```