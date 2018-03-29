# Memory Management

Unlike the [design of fiona](http://toblerity.org/fiona/manual.html#introduction), `ArchGDAL` does not automatically copy data from her data sources. This introduces concerns about memory management (whether objects should be managed by Julia's garbage collector, or by manually destroying the corresponding GDAL object).

Currently this package provides data types corresponding to GDAL's Data Model, e.g.
```julia
mutable struct ColorTable;                    ptr::GDALColorTable         end
mutable struct CoordTransform;                ptr::GDALCoordTransform     end
mutable struct Dataset;                       ptr::GDALDataset            end
mutable struct Driver;                        ptr::GDALDriver             end
mutable struct Feature;                       ptr::GDALFeature            end
mutable struct FeatureDefn;                   ptr::GDALFeatureDefn        end
mutable struct FeatureLayer;                  ptr::GDALFeatureLayer       end
mutable struct Field;                         ptr::GDALField              end
mutable struct FieldDefn;                     ptr::GDALFieldDefn          end
mutable struct Geometry <: AbstractGeometry;  ptr::GDALGeometry           end
mutable struct GeomFieldDefn;                 ptr::GDALGeomFieldDefn      end
mutable struct RasterAttrTable;               ptr::GDALRasterAttrTable    end
mutable struct RasterBand;                    ptr::GDALRasterBand         end
mutable struct SpatialRef;                    ptr::GDALSpatialRef         end
mutable struct StyleManager;                  ptr::GDALStyleManager       end
mutable struct StyleTable;                    ptr::GDALStyleTable         end
mutable struct StyleTool;                     ptr::GDALStyleTool          end
```
and makes it the responsibility of the user to free the allocation of memory from GDAL, by calling `ArchGDAL.destroy(obj)` (which sets `obj.ptr` to `C_NULL` after destroying the GDAL object corresponding to `obj`).

## Manual versus Context Management

There are two approaches for doing so.

1. The first uses the [`unsafe_` prefix](http://docs.julialang.org/en/release-0.4/manual/style-guide/#don-t-expose-unsafe-operations-at-the-interface-level) to indicate methods that returns objects that needs to be manually destroyed.

2. The second uses [`do`-blocks](https://docs.julialang.org/en/release-0.6/manual/functions/#do-block-syntax-for-function-arguments) as context managers.

The first approach will result in code that looks like
```julia
dataset = ArchGDAL.unsafe_read(filename)
# work with dataset
ArchGDAL.destroy(dataset) # the equivalent of GDAL.close(dataset.ptr)
```
This can be helpful when working interactively with `dataset` at the REPL. The second approach will result in the following code
```julia
ArchGDAL.read(filename) do dataset
    # work with dataset
end
```
which uses `do`-blocks to scope the lifetime of the `dataset` object.

## Interactive versus Scoped Geometries
There is a third option for managing memory, which is to register a finalizer with julia, which gets called by the garbage collector at some point after it is out-of-scope. This is in contrast to an approach where users manually control memory usage by destroying objects themselves. 

Therefore, we introduce an AbstractGeometry type:

```julia
abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end
```

which is then subtyped into `Geometry` and `IGeometry`

```julia
mutable struct Geometry <: AbstractGeometry
    ptr::GDALGeometry
end

mutable struct IGeometry <: AbstractGeometry
    ptr::GDALGeometry

    function IGeometry(ptr::GDALGeometry)
        geom = new(GDAL.clone(ptr))
        finalizer(geom, destroy)
        geom
    end
end
```

Objects of type `IGeometry` use the third type of memory management, where we register `ArchGDAL.destroy()` as a finalizer. This is useful for users who are interested in working with geometries in a julia session, when they wish to read it from a geospatial database into a dataframe, and want it to persist within the julia session even after the connection to the database has been closed.

!!! note

    So long as the user does not manually call `ArchGDAL.destroy()` on any object themselves, users are allowed to mix both the methods of memory management (i) using `do`-blocks for scoped geometries, and (ii) using finalizers for interactive geometries. However, there are plenty of pitfalls (e.g. in [PythonGotchas](https://trac.osgeo.org/gdal/wiki/PythonGotchas)) if users try to mix in their own custom style of calling `ArchGDAL.destroy()`.

## References
Here's a collection of references for developers who are interested:

- http://docs.julialang.org/en/release-0.4/manual/calling-c-and-fortran-code/
- https://github.com/JuliaLang/julia/issues/7721
- https://github.com/JuliaLang/julia/issues/11207
- https://trac.osgeo.org/gdal/wiki/PythonGotchas
- https://lists.osgeo.org/pipermail/gdal-dev/2010-September/026027.html
- https://sgillies.net/2013/12/17/teaching-python-gis-users-to-be-more-rational.html
