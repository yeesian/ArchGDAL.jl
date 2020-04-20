# Data Model

```@setup datasets
using ArchGDAL
```

## GDAL Datasets

The following code demonstrates the general workflow for reading in a dataset:

```julia
ArchGDAL.read(filename) do dataset
    # work with dataset
end
```

We defer the discussion on [`ArchGDAL.read(filename)`](@ref) to the section on [Working with Files](@ref).

## Vector Datasets
In this section, we work with the [`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson) dataset:

```@example datasets
dataset = ArchGDAL.read("data/point.geojson")
```

The display indicates
* the **type** of the object (`GDAL Dataset`)
* the **driver** used to open it (shortname/longname: `GeoJSON/GeoJSON`)
* the **files** that it corresponds to (`data/point.geojson`)
* the **number of layers** in the dataset (`1`), and a brief summary of each.

You can also programmatically retrieve them using
* `typeof(dataset)`: the **type** of the object (`GDAL Dataset`)
* [`ArchGDAL.filelist(dataset)`](@ref): the **files** that it corresponds to (`["data/point.geojson"]`)
* [`ArchGDAL.nlayer(dataset)`](@ref): the **number of layers** in the dataset (`1`)
* `driver = `[`ArchGDAL.getdriver(dataset)`](@ref): the **driver** used to open it
* [`ArchGDAL.shortname(driver)`](@ref): the **short name** of a driver (`"GeoJSON"`)
* [`ArchGDAL.longname(driver)`](@ref): the **long name** of a driver (`"GeoJSON"`)
* `layer = `[`ArchGDAL.getlayer(dataset, i)`](@ref): the `i`-th layer in the dataset.
* [`ArchGDAL.getgeomtype(layer)`](@ref): the **geometry type** for `layer` (i.e. `wkbPoint`)
* [`ArchGDAL.getname(layer)`](@ref): the **name** of `layer` (i.e. `point`)
* [`ArchGDAL.nfeature(layer)`](@ref): the **number of features** in the `layer` (i.e. `4`)

For more on working with features and vector data, see the Section on [Feature Data](@ref).

## Raster Datasets
In this section, we work with the [`gdalworkshop/world.tif`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif) dataset:
```@example datasets
dataset = ArchGDAL.read("gdalworkshop/world.tif")
```

The display indicates
* the **type** of the object (`GDAL Dataset`)
* the **driver** used to open it (shortname/longname: `GTiff/GeoTIFF`)
* the **files** that it corresponds to (`gdalworkshop/world.tif`)
* the **number of raster bands** in the dataset (`3`), and a brief summary of each.

You can also programmatically retrieve them using
* `typeof(dataset)`: the **type** of the object (`GDAL Dataset`)
* [`ArchGDAL.filelist(dataset)`](@ref): the **files** that it corresponds to (`["gdalworkshop/world.tif"]`)
* [`ArchGDAL.nraster(dataset)`](@ref): the **number of rasters** (`3`)
* [`ArchGDAL.width(dataset)`](@ref): the width (`2048` pixels)
* [`ArchGDAL.height(dataset)`](@ref): the height (`1024` pixels)
* `driver = `[`ArchGDAL.getdriver(dataset)`](@ref): the **driver** used to open it
* [`ArchGDAL.shortname(driver)`](@ref): the **short name** of a driver (`"GTiff"`)
* [`ArchGDAL.longname(driver)`](@ref): the **long name** of a driver (`"GeoTIFF"`)
* `band = `[`ArchGDAL.getband(dataset, i)`](@ref): the `i`-th raster band
* `i = `[`ArchGDAL.indexof(band)`](@ref): the **index** of the raster band.
* [`ArchGDAL.accessflag(band)`](@ref): the **access flag** (i.e. `GA_ReadOnly`)
* [`ArchGDAL.getname(ArchGDAL.getcolorinterp(band))`](@ref): the **color channel** (e.g. `Red`)
* [`ArchGDAL.width(band)`](@ref): the **width** of the raster band (`2048` pixels)
* [`ArchGDAL.height(band)`](@ref): the **height** of the raster band (`1024` pixels)
* [`ArchGDAL.pixeltype(band)`](@ref): the **pixel type** of the raster band (i.e. `UInt8`)

For more on working with raster data, see the Section on [Raster Data](@ref).

## Working with Files
We provide the following methods for working with files:

* [`ArchGDAL.copy`](@ref): creates a copy of a dataset. This is often used with a virtual source dataset allowing configuration of band types, and other information without actually duplicating raster data.
* [`ArchGDAL.create`](@ref): creates a new dataset.
* [`ArchGDAL.read`](@ref): opens a dataset in read-only mode.
* `ArchGDAL.update`: opens a dataset with the possibility of updating it. If you open a dataset object with update access, it is not recommended to open a new dataset on the same underlying file.

In GDAL, datasets are closed by calling `GDAL.close()`. This will result in proper cleanup, and flushing of any pending writes. Forgetting to call `GDAL.close()` on a dataset opened in update mode in a popular format like `GTiff` will likely result in being unable to open it afterwards.

In ArchGDAL, the closing of datasets is handled by the API and not by the user. ArchGDAL provides two methods for working with datasets.

The first is to use a do-block:
```julia
ArchGDAL.<copy/create/read/update>(...) do dataset
    # work with dataset
end
```
The second is to call the method directly:
```julia
dataset = ArchGDAL.<copy/create/read/update>(...)
# work with dataset
```

!!! note

    This pattern of using `do`-blocks to manage context plays a big way into the way we handle memory in this package. For details, see the section on Memory Management.
