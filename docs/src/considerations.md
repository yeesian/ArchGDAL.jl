# Design Considerations

## Non-copying by default

Unlike the [design of fiona](http://toblerity.org/fiona/manual.html#introduction), `ArchGDAL` does not automatically copy data from her data sources. This introduces concerns about memory ownership (whether objects should be managed by Julia's garbage collector, or by manually destroying the corresponding GDAL object). We address those concerns in the next section on `Memory Ownership`.

## Memory Ownership

Currently this package provides data types corresponding to GDAL's Data Model, e.g.
```julia
type Geometry
    ptr::Ptr{GDAL.OGRLayerH}
end

function destroy(geom::Geometry)
    GDAL.destroygeometry(geom.ptr)
    geom.ptr = C_NULL
end
```
and makes it the responsibility of the user to free the allocation of memory from GDAL, by calling `destroy()` (which sets `obj.ptr` to `C_NULL` after destroying the GDAL object corresponding to `obj`).

There are two approaches for doing so.

1. The first uses the [`unsafe_` prefix](http://docs.julialang.org/en/release-0.4/manual/style-guide/#don-t-expose-unsafe-operations-at-the-interface-level) to indicate methods that returns objects that needs to be manually destroyed:
    ```julia
    julia> AG.unsafe_
    unsafe_boundary                   unsafe_createmultipoint            unsafe_fromWKB
    unsafe_buffer                     unsafe_createmultipolygon          unsafe_fromWKT
    unsafe_centroid                   unsafe_createmultipolygon_noholes  unsafe_fromXML
    unsafe_clone                      unsafe_createpoint                 unsafe_getcurvegeom
    unsafe_convexhull                 unsafe_createpolygon               unsafe_getfeature
    unsafe_create                     unsafe_createstylemanager          unsafe_getlineargeom
    unsafe_createRAT                  unsafe_createstyletable            unsafe_intersection
    unsafe_createcolortable           unsafe_createstyletool             unsafe_loadstringlist
    unsafe_createcoordtrans           unsafe_delaunaytriangulation       unsafe_newspatialref
    unsafe_createcopy                 unsafe_difference                  unsafe_nextfeature
    unsafe_createfeature              unsafe_executesql                  unsafe_pointalongline
    unsafe_createfeaturedefn          unsafe_forceto                     unsafe_pointonsurface
    unsafe_createfielddefn            unsafe_fromEPSG                    unsafe_polygonfromedges
    unsafe_creategeom                 unsafe_fromEPSGA                   unsafe_polygonize
    unsafe_creategeomcollection       unsafe_fromESRI                    unsafe_read
    unsafe_creategeomfielddefn        unsafe_fromGML                     unsafe_symdifference
    unsafe_createlinearring           unsafe_fromJSON                    unsafe_union
    unsafe_createlinestring           unsafe_fromPROJ4                   unsafe_update
    unsafe_createmultilinestring      unsafe_fromURL
    ```
2. The second relies on safer alternatives (without the `unsafe_` prefix) using [`do`-blocks](http://docs.julialang.org/en/release-0.4/manual/functions/#do-block-syntax-for-function-arguments) as context managers.

This differs from proposals that registers GDAL's `destroy` on the objects using [`finalizers`](http://docs.julialang.org/en/release-0.4/stdlib/base/#Base.finalizer). Based on [user-experiences with GDAL's python SWIG bindings](https://trac.osgeo.org/gdal/wiki/PythonGotchas#CertainobjectscontainaDestroymethodbutyoushouldneveruseit), we do not have any immediate plans to support mixing both styles of memory management, so users expecting it should look for other packages (e.g. [GeoDataFrames](https://github.com/yeesian/GeoDataFrames.jl)).

Here's a collection of references for developers who are interested:

- http://docs.julialang.org/en/release-0.4/manual/calling-c-and-fortran-code/
- https://github.com/JuliaLang/julia/issues/7721
- https://github.com/JuliaLang/julia/issues/11207
- https://trac.osgeo.org/gdal/wiki/PythonGotchas
- https://lists.osgeo.org/pipermail/gdal-dev/2010-September/026027.html
- https://sgillies.net/2013/12/17/teaching-python-gis-users-to-be-more-rational.html

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

## Data Serialization

As modern [builds](https://trac.osgeo.org/gdal/wiki/BuildHints) of GDAL (e.g. by [Homebrew](https://github.com/OSGeo/homebrew-osgeo4mac) and [Conda-Forge](https://github.com/conda-forge/gdal-feedstock)) comes pre-compiled with support for PROJ.4 and GEOS, `ArchGDAL.jl` enjoys the full spectrum of GIS functionality, while avoiding the price of data serialization in [duck-typing proposals](https://gist.github.com/sgillies/2217756).

In the long term, this decouples (i) the development and maintenance of a high-level interface for GDAL from (ii) the development and maintenance of other projects relying on customized builds of GDAL. `ArchGDAL.jl` and `GDAL.jl` are concerned with (i), and will only be developed and tagged in accordance with [release changes](https://trac.osgeo.org/gdal/wiki/NewsAndStatus) in GDAL's C API.
