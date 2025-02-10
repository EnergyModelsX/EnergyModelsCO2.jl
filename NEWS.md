# Release Notes

## Version 0.7.6 (2025-02-10)

* Adjusted to [`EnergyModelsBase` v0.9.0](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.9.0):
  * Increased version nubmer for EMB.
  * Model worked without adjustments.
  * Adjustments only required for simple understanding of changes.

## Version 0.7.5 (2024-11-03)

* Fix of a bug introduced in 0.7.4.
* Adjusted the tests to identify similar bugs in later stages.

## Version 0.7.4 (2024-11-29)

* Included changes for `CO2Storage` to not require the definition of variables that are not used.
* Included check changes from `EnergyModelsBase`.
* Fixed minor errors in the documentation.

## Version 0.7.3 (2024-10-16)

* Minor changes to the documentation and docstrings.
* Minor rewriting of constraints and fixing variables.
* Adjusted to [`EnergyModelsBase` v0.8.1](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.8.1):
  * Use of the function `scale_op_sp`.
  * Rework based on the introduction of `:stor_level_Δ_sp` in `EnergyModelsBase` as sparse variable.

## Version 0.7.2 (2024-09-03)

* Dependency increase for `EnergyModelsBase` as the changes do not directly affect `EnergyModelsCO2`.
* Adjustment of the interlinks to the changes in the structure of `EnergyModelsBase`.
* Fixed additional errors in the documentation.
* Added page for the examples in the documentation.

## Version 0.7.1 (2024-08-16)

* Removed requirement for specifying the `co2_proxy` resource as output of the `NetworkNodeWithRetrofit` node and input to the `CCSRetroFit` node through addding methods for `EMB.outputs` and `EMB.inputs`.
  This implies that both are no longer specified within the `input` and `output` dictionary, and all functionality directly accessing the fields may result in errors.
* Adjusted documentation to deploy to the proper site.
* Removed pre-release statements.

## Version 0.7.0 (2024-08-15)

### Feature

* Added support for `CaptureProcessEmissions` for `CCSRetroFit` nodes.
* Changed the name of `CaptureNone` to `CaptureFlueGas` while incorporating a constructor for the old version.
* Changed the name of `NetworkCCSRetrofit` to `RefNetworkNodeRetrofit` while incorporating a constructor for the old version.
  The aim is to follow more closely the names in `EnergyModelsBase`.
* Introduced supertype `NetworkNodeWithRetrofit` to allow the application of the functionality in other packages.

### Bugfix

* Upper limit of the capacity of CO₂ storage nodes:
  * It was in previous analyses never active, but may result in errors, if the duration of strategic periods is large.
  * It can result in overestimating the storage potential as the last strategic period in which the storage is filled is not fully included in the bound.
* Maximum CO₂ capture when using `CaptureEnergyEmissions` or `CaptureProcessEnergyEmissions`:
  * The maximum capture limit was to tight as it did not include potential additional capture fom energy related or process emissions within the node.
  * Both were included now.

### Documentation

* Restructured the examples:
  * Added the examples to the testing routine.
  * Added an exasmple for CO₂ capture retrofit.
  * Extended extensively the comments of the examples to improve understandability.
* Incorporated a new structure for the documentation, including usage of @docs blocks and a structured approach.
* Provided separate pages for all introduced nodal types.
* Added a "how to contribute" page.

## Version 0.6.0 (2024-05-28)

* Adjustment to changes in EMB v0.7.0 introducing the concept of `StorageBehavior` and `AbstractStorageParameters`.
  * `CO2Storage` nodes should only use `AccumulatingStrategic`, an internal subtype.
  * `CO2Storage` nodes have now the potential for both `charge` and `level` OPEX, also the latter seems irrelevant
* Inclusion of `CO2Storage` nodes as potential CO₂ emitter.

## Version 0.5.2 (2024-01-18)

* Adjustment to changes in EMB v0.6.4 allowing for allowing time dependent process emissions.

## Version 0.5.1 (2024-01-17)

* Update the methods `constraints_level_aux` and `constraints_level` to match the signature updates for these methods in `EnergyModelsBase`. This includes renaming `constraints_level` to `constraints_level_sp`.

## Version 0.5.0 (2023-12-19)

* Adjusted to changes in `EnergyModelsBase` v0.6.
* Included handling of representative periods for `CO2Storage`.
* Added a new idea for reducing repetitions in `Storage` nodes. This implementation can be, if considered robust, included for all `Storage` nodes.
* Added a new node `CO2Source <: Source`. The recent changes of `EnergyModelsBase` required that a potential CO₂ source could no longer be modelled using the `RefSource` node.

## Version 0.4.0 (2023-09-27)

### Implemented two nodes related to retrofit of CCS

* Both nodes have to be used together for proper analysis.
* `NetworkCCSRetrofit <: NetworkNode` is a node to which CCS can be implemented as a retrofit.
* `CCSRetroFit <: NetworkNode` is a node where the investments lead to the potential of utilizing CO2 capture. If the node has no capacity, then all CO₂ is emitted.

## Version 0.3.0 (2023-06-06)

### Switch to `TimeStruct`

* Switched the time structure representation to `TimeStruct`.
* `TimeStruct` is implemented with only the basis features that were available in `TimesStructures`. This implies that neither operational nor strategic uncertainty is included in the model.

## Version 0.2.0 (2023-05-30)

* Adjustment to changes in `EnergyModelsBase` v0.4.0 related to extra input data.

## Version 0.1.2 (2023-05-15)

* Adjustment to changes in `EnergyModelsBase` v0.3.3 related to the calls for the constraint functions.

## Version 0.1.1 (2023-04)

* Bugfix on storage level in operational periods.

## Version 0.1.0 (2023-04)

* Implement a node `CO2Storage <: Storage`. The storage level will accumulate over the strategic periods.
