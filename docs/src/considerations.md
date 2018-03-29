# Design Considerations

## Data Serialization

As modern [builds](https://trac.osgeo.org/gdal/wiki/BuildHints) of GDAL (e.g. by [Homebrew](https://github.com/OSGeo/homebrew-osgeo4mac) and [Conda-Forge](https://github.com/conda-forge/gdal-feedstock)) comes pre-compiled with support for PROJ.4 and GEOS, one of the goals of `ArchGDAL.jl` is for it to enjoy the full spectrum of GIS functionality, while avoiding the price of data serialization in [duck-typing proposals](https://gist.github.com/sgillies/2217756).

In the long term, this decouples (i) the development and maintenance of a high-level interface for GDAL from (ii) the development and maintenance of other projects relying on customized builds of GDAL. `ArchGDAL.jl` and [`GDAL.jl`](https://github.com/visr/GDAL.jl) are only concerned with (i), and will only be developed and tagged in accordance with [release changes](https://trac.osgeo.org/gdal/wiki/NewsAndStatus) in GDAL's C API.

## Code Defensiveness

Although GDAL provides a unified data model for different data formats, there are still significant differences between their implementations such that each driver is effectively its own application. This has the following implications:

- Not all configuration options works for all drivers.
- Not all capabilities are available for all drivers.
- Performance characteristics may vary significantly depending on the driver.

`ArchGDAL.jl` provides mechanisms similar to those of mapbox/rasterio for setting GDAL's configuration options, and does not maintain its own list of *sanctioned* options for each driver. Although [ongoing work is underway](https://github.com/yeesian/GDALUtils.jl/issues/1) to make this an easier experience for the user, it remains the responsibility of the user to check that a particular configuration exists and works for their choice of driver.

Here's a collection of references for developers who are interested:
- https://trac.osgeo.org/gdal/wiki/ConfigOptions
- https://github.com/mapbox/rasterio/pull/665
- https://github.com/mapbox/rasterio/issues/875
- https://mapbox.github.io/rasterio/topics/configuration.html
