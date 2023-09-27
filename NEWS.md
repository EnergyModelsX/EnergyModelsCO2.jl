Release Notes
=============

Version 0.4.0 (2023-09-27)
--------------------------
### Implemented two nodes related to retrofit of CCS
 * Both nodes have to be used together for proper analysis
 * `NetworkCCSRetrofit <: Network` is a `RefNetworkEmissions` node to which CCS can be implemented as a retrofit
 * `CCSRetroFit <: Network` is a node where the investments lead to the potential of utilizing CO2 capture. If the node has no capacity, then all CO2 is emitted

Version 0.3.0 (2023-06-06)
--------------------------
### Switch to TimeStruct.jl
 * Switched the time structure representation to [TimeStruct.jl](https://gitlab.sintef.no/julia-one-sintef/timestruct.jl)
 * TimeStruct.jl is implemented with only the basis features that were available in TimesStructures.jl. This implies that neither operational nor strategic uncertainty is included in the model

Version 0.2.0 (2023-05-30)
--------------------------
 * Adjustment to changes in `EnergyModelsBase` v0.4.0 related to extra input data

Version 0.1.2 (2023-05-15)
--------------------------
 * Adjustment to changes in `EnergyModelsBase` v0.3.3 related to the calls for the constraint functions

Version 0.1.1 (2023-04)
--------------------------
* Bugfix on storage level in operational periods.

Version 0.1.0 (2023-04)
--------------------------
* Implement a node `CO2Storage <: Storage`. The storage level will accumulate
  over the strategic periods.
