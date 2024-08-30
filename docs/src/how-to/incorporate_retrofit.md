# [Incorporate CO₂ capture retrofit in other nodes](@id how_to-incorp_retrofit)

You can find the mathematical description of the incorporation on the [CO₂ capture retrofit](@ref nodes-CCS_retrofit) page.
The mathematical description explains as well the required changes to a `RefNetworkNode` to allow for incorporating CO₂ capture retrofit.
All created methods for the existing functions are however created for the abstract supertype [`NetworkNodeWithRetrofit`](@ref)
Hence, it is also possible for the user to create separate nodes that allow for CO₂ capture retrofit.

Creating a new type for retrofit, that is, *e,g,*, with differing additional constraints is in general simple.
The new type only has the following requirements:

1. Is has to be a subtype of [`NetworkNodeWithRetrofit`](@ref).
   This implies that said node is a `NetworkNode`, although we are currently thinking about changing the overall structure.
2. The type **must** have either a field called `co2_proxy` or you have to add a method to the function [`EnergyModelsCO2.co2_proxy`](@ref) of `EnergyModelsCO2`.
3. CO₂ capture data has to be incorporated as one of the [`CaptureData`](@extref EnergyModelsBase.CaptureData) subtypes  as described on *[Data functions](@extref EnergyModelsBase man-data_fun)*.
4. If you have created a new method for  [`EnergyModelsBase.create_node`](@extref EnergyModelsBase), you have to include in said method the following code lines

   ```julia
   for data ∈ node_data(n)
       constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
   end
   ```

   and the node **must** have either a field called `data` or you have to add a method to the function [`EnergyModelsBase.node_data`](@extref EnergyModelsBase) to be able to access the data.\
   Alternatively, you can also manually extract the capture data and call directlty the functions [`constraints_data`](@extref EnergyModelsBase.constraints_data)
