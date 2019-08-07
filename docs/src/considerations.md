# Design Considerations

## Code Defensiveness

Although GDAL provides a unified data model for different data formats, there are still significant differences between their implementations such that each driver is effectively its own application. This has the following implications:

- Not all configuration options works for all drivers.
- Not all capabilities are available for all drivers.
- Performance characteristics may vary significantly depending on the driver.

`ArchGDAL.jl` provides mechanisms for setting GDAL's configuration options, and does not maintain its own list of sanctioned options for each driver. Although work is underway to make this an easier experience for the user, it remains the responsibility of the user to check that a particular configuration exists and works for their choice of drivers.

Here's a collection of references for developers who are interested:
- https://trac.osgeo.org/gdal/wiki/ConfigOptions
- https://github.com/mapbox/rasterio/pull/665
- https://github.com/mapbox/rasterio/issues/875
- https://mapbox.github.io/rasterio/topics/configuration.html
