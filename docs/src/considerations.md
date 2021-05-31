# Design Considerations

## Code Defensiveness

Although GDAL provides a unified data model for different data formats, there are still significant differences between their implementations such that each driver is effectively its own application. This has the following implications:

- Not all configuration options works for all drivers.
- Not all capabilities are available for all drivers.
- Performance characteristics may vary significantly depending on the driver.

`ArchGDAL.jl` provides mechanisms for setting GDAL's configuration options, and does not maintain its own list of sanctioned options for each driver. Although work is underway to make this an easier experience for the user, it remains the responsibility of the user to check that a particular configuration exists and works for their choice of drivers.

Here's a collection of references for developers who are interested:
- [https://trac.osgeo.org/gdal/wiki/ConfigOptions](https://trac.osgeo.org/gdal/wiki/ConfigOptions)
- [https://github.com/mapbox/rasterio/pull/665](https://github.com/mapbox/rasterio/pull/665)
- [https://github.com/mapbox/rasterio/issues/875](https://github.com/mapbox/rasterio/issues/875)
- [https://rasterio.readthedocs.io/en/latest/topics/configuration.html](https://rasterio.readthedocs.io/en/latest/topics/configuration.html)

## Tables.jl Interface

The interface is implemented in [`src/tables.jl`](https://github.com/yeesian/ArchGDAL.jl/blob/master/src/tables.jl). The current API from GDAL makes it row-based in the conventions of Tables.jl. Therefore,

* `ArchGDAL.Feature` meets the criteria for an [`AbstractRow`](https://tables.juliadata.org/dev/#Tables.AbstractRow-1) based on https://github.com/yeesian/ArchGDAL.jl/blob/a665f3407930b8221269f8949c246db022c3a85c/src/tables.jl#L31-L58.
* `ArchGDAL.FeatureLayer` meets the criteria for an `AbstractRow`-iterator based on the previous bullet and meeting the criteria for [`Iteration`](https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration) in https://github.com/yeesian/ArchGDAL.jl/blob/a665f3407930b8221269f8949c246db022c3a85c/src/base/iterators.jl#L1-L18
