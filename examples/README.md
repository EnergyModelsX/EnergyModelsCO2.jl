# Running the examples

You have to add the package `EnergyModelsCO2` to your current project in order to run the examples.
It is not necessary to add the other used packages, as the example is instantiating itself.
How to add packages is explained in the *[Quick start](https://energymodelsx.github.io/EnergyModelsCO2.jl/stable/manual/quick-start/)* of the documentation

You can run from the Julia REPL the following code:

```julia
# Import EnergyModelsCO2
using EnergyModelsCO2

# Get the path of the examples directory
exdir = joinpath(pkgdir(EnergyModelsCO2), "examples")

# Include the following code into the Julia REPL to run the CO2 storage example
include(joinpath(exdir, "co2_storage.jl"))

# Include the following code into the Julia REPL to run the CO2 capture retrofit example
include(joinpath(exdir, "ccs_retrofit.jl"))
```
