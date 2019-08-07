# Interactive versus Scoped Objects

ArchGDAL provides two approaches for working with GDAL objects.

The first approach is through [Scoped Objects](@ref), which uses [`do`-blocks](https://docs.julialang.org/en/v1/manual/functions/index.html#Do-Block-Syntax-for-Function-Arguments-1) as context managers. The problem with using do-blocks to manage context is that they are difficult to work with in an interactive way:
```julia
ArchGDAL.read(filename) do dataset
    # dataset exists within this scope
end
# we do not have access to dataset from here on
```
In the example above, we do not get to see information about `dataset` unless we write code to display information within the scope of the do-block. This makes it difficult to work with it in an exploratory "depth-first" manner.

The second approach is through [Interactive Objects](@ref), which are designed for use at the REPL.
```julia
dataset = ArchGDAL.read(filename)
# work with dataset
```
A potential drawback of the second approach is that the objects are managed by Julia's garbage collector. This requires ArchGDAL to keep track of objects that interactive objects have a relationship with so that the interactive objects are not prematurely destroyed. For safety, ArchGDAL might make clones/copies of the underlying data, and only allow a subset of GDAL's objects to be created in this way.

## Memory Management (Advanced)

Unlike the design of [fiona](http://toblerity.org/fiona/manual.html#introduction), `ArchGDAL` does not immediately make copies from data sources. This introduces concerns about memory management (whether objects should be managed by Julia's garbage collector, or by other means of destroying GDAL object when they are [out of scope](https://pkg.julialang.org/docs/julia/THl1k/1.1.1/manual/variables-and-scoping.html)).

### Scoped Objects
For scoped objects, they are often created within the context of a do-block. As an example, the following code block
```julia
ArchGDAL.getband(dataset, i) do rasterband
    # do something with rasterband
end
```
corresponds to the following sequence of function calls:
```julia
rasterband = ArchGDAL.unsafe_getband(dataset, i)
try
    # do something with rasterband
finally
    ArchGDAL.destroy(rasterband)
end
```
under the hood (see `src/context.jl`). Therefore, the objects themselves do not have a finalizer registered:
```julia
mutable struct RasterBand <: AbstractRasterBand
    ptr::GDALRasterBand
end

unsafe_getband(dataset::AbstractDataset, i::Integer) =
    RasterBand(GDAL.getrasterband(dataset.ptr, i))

function destroy(rb::AbstractRasterBand)
    rb.ptr = GDALRasterBand(C_NULL)
end
```

!!! note

    We use the [`unsafe_` prefix](https://docs.julialang.org/en/v1/manual/style-guide/index.html#Don't-expose-unsafe-operations-at-the-interface-level-1) to indicate those methods that return scoped objects. These methods should not be used by users directly.

### Interactive Objects
By contrast, the following code
```julia
rasterband = ArchGDAL.getband(dataset, i)
# do something with rasterband
```
returns an interactive rasterband that has `destroy()` registered with its finalizer.
```julia
mutable struct IRasterBand <: AbstractRasterBand
    ptr::GDALRasterBand
    ownedby::AbstractDataset

    function IRasterBand(
            ptr::GDALRasterBand = GDALRasterBand(C_NULL);
            ownedby::AbstractDataset = Dataset()
        )
        rasterband = new(ptr, ownedby)
        finalizer(destroy, rasterband)
        return rasterband
    end
end

getband(dataset::AbstractDataset, i::Integer) =
    IRasterBand(GDAL.getrasterband(dataset.ptr, i), ownedby = dataset)

function destroy(rasterband::IRasterBand)
    rasterband.ptr = GDALRasterBand(C_NULL)
    rasterband.ownedby = Dataset()
    return rasterband
end
```
The `I` in `IRasterBand` indicates that it is an [i]nteractive type. Other interactive types include `IDataset`, `IFeatureLayer`, `ISpatialRef` and `IGeometry`.

ArchGDAL requires all interactive types to have a finalizer that calls `destroy()` on them. All objects that have a relationship with an interactive object are required to hold a reference to the interactive object. For example, objects of type `IRasterBand` might have a relationship with an `IDataset`, therefore they have an `ownedby` attribute which might refer to such a dataset.

### Views
Sometimes, it is helpful to work with objects that are "internal references" that have restrictions on the types of methods that they support. As an example
`getlayerdefn(featurelayer)` returns a feature definition that is internal to the feature layer, and does not support methods such as `write!(featuredefn, fielddefn)` and `deletegeomdefn!(featuredefn, i)`. To indicate that they might have restrictions, some types have `View` as a postfix. Such types include `IFeatureDefnView`, `IFieldDefnView`, and `IGeomFieldDefnView`.

### Summary
To summarize,

* `ArchGDAL.unsafe_<method>(args...)` will return a scoped object. The proper way of using them is within the setting of a do-block:

```julia
ArchGDAL.<method>(args...) do result
    # result is a scoped object
end
```

* `ArchGDAL.<method>(args...)` will return an interactive object.

```julia
result = ArchGDAL.<method>(args...)
# result is an interactive object
```

!!! note

    Users are allowed to mix both "interactive" and "scoped" objects. As long as they do not manually call `ArchGDAL.destroy()` on any object, ArchGDAL is designed to avoid the pitfalls of GDAL memory management (e.g. in [PythonGotchas](https://trac.osgeo.org/gdal/wiki/PythonGotchas)).

## References
Here's a collection of references for developers who are interested.

- http://docs.julialang.org/en/release-0.4/manual/calling-c-and-fortran-code/
- https://github.com/JuliaLang/julia/issues/7721
- https://github.com/JuliaLang/julia/issues/11207
- https://trac.osgeo.org/gdal/wiki/PythonGotchas
- https://lists.osgeo.org/pipermail/gdal-dev/2010-September/026027.html
- https://sgillies.net/2013/12/17/teaching-python-gis-users-to-be-more-rational.html
- https://pcjericks.github.io/py-gdalogr-cookbook/gotchas.html#features-and-geometries-have-a-relationship-you-don-t-want-to-break
