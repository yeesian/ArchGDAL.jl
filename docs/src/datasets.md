# GDAL Datasets

The following code demonstrates the general workflow for reading in a dataset:

```julia
ArchGDAL.read(filename) do dataset
    # work with dataset
end
```

We defer the discussion on `ArchGDAL.read(filename)` to the section on [Working with Files](@ref).

!!! note

    In this case, a handle to the dataset is obtained, and no further data was requested. It is only when we run `print(dataset)` that calls will be made through GDAL's C API to obtain information about `dataset` for display.

## Vector Datasets
```@setup vector_example
import ArchGDAL
filepath = download("https://raw.githubusercontent.com/yeesian/ArchGDALDatasets/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson", "point.geojson")
```
In this section, we work with the [`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson) dataset via
```@example vector_example
ArchGDAL.read(filepath) do dataset
    print(dataset)
end
```

The display indicates
* the **type** of the object (`GDAL Dataset`)
* the **driver** used to open it (shortname/longname: `GeoJSON/GeoJSON`)
* the **files** that it corresponds to (`point.geojson`)
* the **number of layers** in the dataset, and their brief summary.

You can also programmatically retrieve them using
* `typeof(dataset)`: the **type** of the object
* `ArchGDAL.filelist(dataset)`: the **files** that it corresponds to
* `ArchGDAL.nlayer(dataset)`: the **number of layers** in the dataset
* `drv = ArchGDAL.getdriver(dataset)`: the **driver** used to open it
* `ArchGDAL.shortname(drv)`: the short name of a driver
* `ArchGDAL.longname(drv)`: the long name of a driver
* `layer = ArchGDAL.getlayer(dataset, i)`: the `i`-th layer in `dataset`.
* `ArchGDAL.getgeomtype(layer)`: the geometry type for `layer` (i.e. `wkbPoint`)
* `ArchGDAL.getname(layer)`: the name of `layer` (i.e. `OGRGeoJSON`)
* `ArchGDAL.nfeature(layer)`: the number of features in `layer` (i.e. `4`)

For more on working with features and vector data, see the Section on `Feature Data`.

## Raster Datasets
```@setup raster_example
import ArchGDAL
filepath = download("https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif?raw=true", "world.tif")
```
In this section, we work with the [`gdalworkshop/world.tif`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif) dataset:
```@example raster_example
ArchGDAL.read(filepath) do dataset
    print(dataset)
end
```

The display indicates
* the **type** of the object (`GDAL Dataset`)
* the **driver** used to open it (shortname/longname: `GTiff/GeoTIFF`)
* the **files** that it corresponds to (`world.tif`)
* the **number of raster bands** in the dataset, and their brief summary.

You can also programmatically retrieve them using
* `typeof(dataset)`: the type of the object
* `ArchGDAL.filelist(dataset)`: the files that it corresponds to
* `ArchGDAL.nraster(dataset)`: the number of rasters
* `ArchGDAL.width(dataset)` the width (`2048` pixels)
* `ArchGDAL.height(dataset)` the height (`1024` pixels)
* `drv = ArchGDAL.getdriver(dataset)`: the driver used to open it
* `ArchGDAL.shortname(drv)`: the short name of a driver
* `ArchGDAL.longname(drv)`: the long name of a driver
* `band = ArchGDAL.getband(dataset, i)`: the `i`-th raster band
* `i = ArchGDAL.indexof(band)`: the index of `band`.
* `ArchGDAL.accessflag(band)`: the access flag (i.e. `GA_ReadOnly`)
* `ArchGDAL.getname(ArchGDAL.getcolorinterp(rasterband))`: the color channel (e.g. `Red`)
* `ArchGDAL.width(band)` the width (`2048` pixels) of the band
* `ArchGDAL.height(band)` the height (`1024` pixels) of the band
* `ArchGDAL.pixeltype(band)`: the pixel type (i.e. `UInt8`)

For more on working with raster data, see the Section on `Raster Data`.

## Working with Files
We provide the following methods for working with files:

* `ArchGDAL.copy()`: create a copy of a raster dataset. This is often used with a virtual source dataset allowing configuration of band types, and other information without actually duplicating raster data.
* `ArchGDAL.create()`: creates a new dataset Note: many sequential write-once formats (such as JPEG and PNG) don't implement the `Create()` method but do implement the `CreateCopy()` method. If the driver doesn't implement `CreateCopy()`, but does implement `Create()` then the default `CreateCopy()` mechanism built on calling `Create()` will be used.
* `ArchGDAL.read()`: opens a dataset in read-only mode. The returned dataset should only be accessed by one thread at a time. To use it from different threads, you must add all necessary code (mutexes, etc.) to avoid concurrent use of the object. (Some drivers, such as GeoTIFF, maintain internal state variables that are updated each time a new block is read, preventing concurrent use.)
* `ArchGDAL.update()`: opens a dataset with the possibility of updating it. If you open a dataset object with update access, it is not recommended to open a new dataset on the same underlying file.

For each one of them, we will call `ArchGDAL.destroy` at the end of the `do`-block which will dispatch to the corresponding GDAL method. For example,

```julia
ArchGDAL.read(filename) do dataset
    # work with dataset
end
```

will correspond to

```julia
dataset = ArchGDAL.unsafe_read(filename)
# work with dataset
ArchGDAL.destroy(dataset) # the equivalent of GDAL.close(dataset.ptr)
```

!!! note

    In GDAL, datasets are closed by calling `GDAL.close()`. This will result in proper cleanup, and flushing of any pending writes. Forgetting to call `GDAL.close()` on a dataset opened in update mode in a popular format like `GTiff` will likely result in being unable to open it afterwards.

!!! note

    This pattern of using `do`-blocks to manage context plays a big way into the way we handle memory in this package. For details, see the section on Memory Management.
