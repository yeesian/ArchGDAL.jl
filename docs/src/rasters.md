# Raster Data

```@setup rasters
using ArchGDAL
const AG = ArchGDAL
```

In this section, we revisit the [`gdalworkshop/world.tif`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif) dataset.
```@example rasters
dataset = AG.read("gdalworkshop/world.tif")
```
A description of the display is available in [Raster Datasets](@ref).

## Raster Bands
We can examine an individual raster band
```@example rasters
band = ArchGDAL.getband(dataset, 1)
```

You can programmatically retrieve the information in the header using
* [`ArchGDAL.accessflag(band)`](@ref): the access flag for this band. (`GA_ReadOnly`)
* `colorinterp = `[`ArchGDAL.getcolorinterp(band)`](@ref): color interpretation of the values in the band (`GCI_RedBand`)
* [`ArchGDAL.getname(colorinterp)`](@ref): name (string) corresponding to color interpretation (`"Red"`)
* [`ArchGDAL.width(band)`](@ref): width (pixels) of the band (`2048`)
* [`ArchGDAL.height(band)`](@ref): height (pixels) of the band (`1024`)
* [`ArchGDAL.indexof(band)`](@ref): the index of the band (1+) within its dataset, or 0 if unknown. (`1`)
* [`ArchGDAL.pixeltype(band)`](@ref): pixel data type for this band. (`UInt8`)

You can get additional attribute information using
* [`ArchGDAL.getscale(band)`](@ref): the scale in `units = (px * scale) + offset` (`1.0`)
* [`ArchGDAL.getoffset(band)`](@ref): the offset in `units = (px * scale) + offset` (`0.0`)
* [`ArchGDAL.getunittype(band)`](@ref): name for the units, e.g. "m" (meters) or "ft" (feet). (`""`)
* [`ArchGDAL.getnodatavalue(band)`](@ref): a special marker value used to mark pixels that are not valid data. (`-1.0e10`)
* `(x,y) = `[`ArchGDAL.blocksize(band)`](@ref): the "natural" block size of this band (`(256,256)`)

!!! note

    GDAL contains a concept of the natural block size of rasters so that applications can organized data access efficiently for some file formats. The natural block size is the block size that is most efficient for accessing the format. For many formats this is simple a whole scanline. However, for tiled images this will typically be the tile size.

Finally, you can obtain overviews:
* [`ArchGDAL.noverview(band)`](@ref): the number of overview layers available, zero if none. (`7`)
* [`ArchGDAL.getoverview(band, i)`](@ref): returns the `i`-th overview in the raster band. Each overview is itself a raster band, e.g.

```@example rasters
ArchGDAL.getoverview(band, 2)
```

## Raster I/O

### Reading Raster Values
The general operative method for reading in raster values from a `dataset` or `band` is to use `ArchGDAL.read()`.

* `ArchGDAL.read(dataset)`: reads the entire dataset as a single multidimensional array.
* `ArchGDAL.read(dataset, indices)`: reads the raster bands at the `indices` (in that order) into a multidimensional array.
* `ArchGDAL.read(dataset, i)`: reads the `i`-th raster band into an array.
* `ArchGDAL.read(band)`: reads the raster band into an array.

!!! note

    The array returned by `read` has `(cols, rows, bands)` dimensions. 
    
    To convert to a format used by the Images.jl ecosystem, you can either create a view using `PermutedDimsArray(A, (3,2,1))` or create a permuted copy using `permutedims(A, (3,2,1))`. The resulting arrays will have `(bands, rows, cols)` dimensions.

You can also specify the subset of rows and columns (provided as `UnitRange`s like `2:9`) to read:

* `ArchGDAL.read(dataset, indices, rows, cols)`
* `ArchGDAL.read(dataset, i, rows, cols)`
* `ArchGDAL.read(band, rows, cols)`

On other occasions, it might be easier to first specify a position `(xoffset,yoffset)` to read from, and the size `(xsize, ysize)` of the window to read:

* `ArchGDAL.read(dataset, indices, xoffset, yoffset, xsize, ysize)`
* `ArchGDAL.read(dataset, i, xoffset, yoffset, xsize, ysize)`
* `ArchGDAL.read(band, xoffset, yoffset, xsize, ysize)`

You might have an existing buffer that you wish to read the values into. In such cases, the general API for doing so is to write `ArchGDAL.read!(source, buffer, args...)` instead of `ArchGDAL.read(source, args...)`.

### Writing Raster Values
For writing values from a `buffer` to a raster `dataset` or `band`, the following methods are available:

* `ArchGDAL.write!(band, buffer)`
* `ArchGDAL.write!(band, buffer, rows, cols)`
* `ArchGDAL.write!(band, buffer, xoffset, yoffset, xsize, ysize)`
* `ArchGDAL.write!(dataset, buffer, i)`
* `ArchGDAL.write!(dataset, buffer, i, rows, cols)`
* `ArchGDAL.write!(dataset, buffer, i, xoffset, yoffset, xsize, ysize)`
* `ArchGDAL.write!(dataset, buffer, indices)`
* `ArchGDAL.write!(dataset, buffer, indices, rows, cols)`
* `ArchGDAL.write!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)`

!!! note

    ArchGDAL expects the dimensions of the buffer to be `(cols, rows, bands)` or `(cols, rows)`.

## Windowed Reads and Writes

Following the description in [mapbox/rasterio's documentation](https://rasterio.readthedocs.io/en/latest/topics/windowed-rw.html), a window is a view onto a rectangular subset of a raster dataset. This is useful when you want to work on rasters that are larger than your computers RAM or process chunks of large rasters in parallel.

For that purpose, we have a method called `ArchGDAL.windows(band)` which iterates over the windows of a raster band, returning the indices corresponding to the rasterblocks within that raster band for efficiency:

```@example rasters
using Base.Iterators: take  # to prevent showing all blocks
windows = ArchGDAL.windows(band)

for (cols, rows) in take(windows, 5)
    @info "Window" cols rows
end
```

Alternatively, we have another method called `ArchGDAL.blocks(band)` which iterates over the windows of a raster band, returning the `offset` and `size` corresponding to the rasterblocks within that raster band for efficiency:
```@example rasters
blocks = ArchGDAL.blocks(band)
for (xyoffset, xysize) in take(blocks, 5)
    @info "Window offset" xyoffset xysize
end
```

!!! note

    These methods are often used for reading/writing a block of image data efficiently, as it accesses "natural" blocks from the raster band without resampling, or data type conversion.

# Using the DiskArray interface

## Raster bands as 2D Disk Arrays

As of ArchGDAL version 1.4.2 and higher a `RasterBand` is a subtype of `AbstractDiskArray` from the [DiskArrays.jl package](https://github.com/meggart/DiskArrays.jl). This means that a `RasterBand` is also an `AbstractArray` and can therefore be treated like any Julia array. This means that square bracket indexing works in addition to the `read` methods described above.  

````@example rasters
band[1000:1010,300:310]
````

Also, windowed reading of the data can alternatively be done through the DiskArrays interface:

````@example rasters
using DiskArrays: eachchunk
for (rows, cols) in take(eachchunk(band), 5)
    @info "Window" rows, cols
end
````

This code is equivalent to the window function mentioned in [Windowed Reads and Writes](@ref) but more portable because the raster band can be exchanged with any other type implementing the DiskArrays interface. Also, for many operations it will not be necessary anymore to implement the window loop, since the `DiskArrays` package provides efficient implementations for reductions and lazy broadcasting, so that for example operations like: 

````@example rasters
sum(sqrt.(band), dims=1)
````

will read the data block by block allocating only the amount of memory in the order of the size of a single raster block. See https://github.com/meggart/DiskArrays.jl/blob/master/README.md for more information on DiskArrays.jl

## The RasterDataset type

Many raster datasets that contain multiple bands of the same size and data type can also be abstracted as a 3D array where the last dimension represents the band index. In order to open a raster dataset in a way that it is represented as a 3D `AbstractArray` there is the `readraster` funtion. It returns a `RasterDataset` which is a thin wrapper around a `Dataset` but it is a subtype of `AbstractDiskArray{T,3}` and therefore part of the array hierarchy. 

This means that data can be accessed with the square-bracket syntax

````@example rasters
dataset = AG.readraster("gdalworkshop/world.tif")
dataset[1000,300,:]
````

and broadcasting, views and reductions are provided by the DiskArrays package. In addition, many ArchGDAL functions like (`getband`, `nraster`, `getgeotransform`, etc) are delegated to the wrapped Dataset and work for RasterDatasets as well. 
