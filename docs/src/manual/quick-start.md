# Quick Start

> 1. Install the most recent version of [Julia](https://julialang.org/downloads/)
> 2. Install the package [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) and the time package [`TimeStruct`](https://sintefore.github.io/TimeStruct.jl/), by running:
>
>    ```
>    ] add TimeStruct
>    ] add EnergyModelsBase
>    ```
>
>    This will fetch the packages from the CleanExport package registry.
> 3. Install the package [`EnergyModelsCO2`](https://energymodelsx.github.io/EnergyModelsCO2.jl/)
>
>    ```julia
>    ] add EnergyModelsCO2
>    ```
>

!!! note
    If you receive the error that `EnergyModelsCO2` is not yet registered, you have to add the package using the GitHub repository through
    ```
    ] add https://github.com/EnergyModelsX/EnergyModelsCO2
    ```
    Once the package is registered, this is not required.
