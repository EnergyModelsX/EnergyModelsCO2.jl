# [Examples](@id man-exampl)

For the content of the example, see the *[examples](https://github.com/EnergyModelsX/EnergyModelsCO2.jl/tree/main/examples)* directory in the project repository.

## The package is installed with `] add`

From the Julia REPL, run

```julia
# Starts the Julia REPL
julia> using EnergyModelsCO2
# Get the path of the examples directory
julia> exdir = joinpath(pkgdir(EnergyModelsCO2), "examples")
# Include the code into the Julia REPL to run the first example of the implementation of
# CCS retrofit
julia> include(joinpath(exdir, "ccs_retrofit.jl"))
# Include the code into the Julia REPL to run the first example of the CO₂ Storage node
julia> include(joinpath(exdir, "co2_storage.jl"))
```

## The code was downloaded with `git clone`

The examples can then be run from the terminal with

```shell script
/path/to/EnergyModelsCO2.jl/examples $ julia ccs_retrofit.jl
/path/to/EnergyModelsCO2.jl/examples $ julia co2_storage.jl
```
