# EnergyModelsCO2

[![Build Status](https://github.com/EnergyModelsX/EnergyModelsCO2.jl/workflows/CI/badge.svg)](https://github.com/EnergyModelsX/EnergyModelsCO2.jl/actions?query=workflow%3ACI)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://energymodelsx.github.io/EnergyModelsCO2.jl/stable/)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://energymodelsx.github.io/EnergyModelsCO2.jl/dev/)

`EnergyModelsCO2` is a package extending `EnergyModelsBase` to model technologies from the CO₂ value chain.
These technologies are

1. `CO2Source :< Source`, a source node that allows for CO₂ as output,
2. `CO2Storage{T} <: Storage{T}`, a storage node in which the stored CO₂ is accumulating over the strategic periods,
3. `RefNetworkNodeRetrofit <: NetworkNodeWithRetrofit`, a network node with the potential for retrofitting CO₂ capture, and
4. `CCSRetroFit <: NetworkNode`, a network node that corresponds to a CO₂ capture unit.

`RefNetworkNodeRetrofit` and `CCSRetroFit` have to be coupled to each other for proper functioning as they require a proxy resource for CO2.
Further information can be found in the _[corresponding documentation](https://energymodelsx.github.io/EnergyModelsCO2.jl/stable/)_.

## Usage

The usage of the package is best illustrated through the commented [`examples`](examples).
The examples are minimum working examples highlighting how to build simple energy system models.

## Cite

If you find `EnergyModelsBase` useful in your work, we kindly request that you cite the following [publication](https://doi.org/10.21105/joss.06619):

```bibtex
@article{hellemo2024energymodelsx,
  title = {EnergyModelsX: Flexible Energy Systems Modelling with Multiple Dispatch},
  author = {Hellemo, Lars and B{\o}dal, Espen Flo and Holm, Sigmund Eggen and Pinel, Dimitri and Straus, Julian},
  journal = {Journal of Open Source Software},
  volume = {9},
  number = {97},
  pages = {6619},
  year = {2024},
  doi = {https://doi.org/10.21105/joss.06619},
}
```

For earlier work, see our [paper in Applied Energy](https://www.sciencedirect.com/science/article/pii/S0306261923018482):

```bibtex
@article{boedal_2024,
  title = {Hydrogen for harvesting the potential of offshore wind: A {N}orth {S}ea case study},
  journal = {Applied Energy},
  volume = {357},
  pages = {122484},
  year = {2024},
  issn = {0306-2619},
  doi = {https://doi.org/10.1016/j.apenergy.2023.122484},
  url = {https://www.sciencedirect.com/science/article/pii/S0306261923018482},
  author = {Espen Flo B{\o}dal and Sigmund Eggen Holm and Avinash Subramanian and Goran Durakovic and Dimitri Pinel and Lars Hellemo and Miguel Mu{\~n}oz Ortiz and Brage Rugstad Knudsen and Julian Straus}
}
```

## Project Funding

The development of `EnergyModelsBase` was funded by the Norwegian Research Council in the project [Clean Export](https://www.sintef.no/en/projects/2020/cleanexport/), project number [308811](https://prosjektbanken.forskningsradet.no/project/FORISS/308811)
