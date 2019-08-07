# Raster Data

In this section, we revisit the [`gdalworkshop/world.tif`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif) dataset.
```julia
julia> dataset = AG.read("gdalworkshop/world.tif")
GDAL Dataset (Driver: GTiff/GeoTIFF)
File(s):
  gdalworkshop/world.tif

Dataset (width x height): 2048 x 1024 (pixels)
Number of raster bands: 3
  [GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
  [GA_ReadOnly] Band 2 (Green): 2048 x 1024 (UInt8)
  [GA_ReadOnly] Band 3 (Blue): 2048 x 1024 (UInt8)
```
A description of the display is available in [Raster Datasets](@ref).

## Raster Bands
We can examine an individual raster band
```julia
julia> band = ArchGDAL.getband(dataset, 1)
[GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
    blocksize: 256×256, nodata: -1.0e10, units: 1.0px + 0.0
    overviews: (0) 1024x512 (1) 512x256 (2) 256x128
               (3) 128x64 (4) 64x32 (5) 32x16
               (6) 16x8
```
You can programmatically retrieve the information in the header using
* `ArchGDAL.accessflag(band)`: the access flag for this band. (`GA_ReadOnly`)
* `colorinterp = ArchGDAL.getcolorinterp(band)`: color interpretation of the values in the band (`GCI_RedBand`)
* `ArchGDAL.getname(colorinterp)`: name (string) corresponding to color interpretation (`"Red"`)
* `ArchGDAL.width(band)`: width (pixels) of the band (`2048`)
* `ArchGDAL.height(band)`: height (pixels) of the band (`1024`)
* `ArchGDAL.indexof(band)`: the index of the band (1+) within its dataset, or 0 if unknown. (`1`)
* `ArchGDAL.pixeltype(band)`: pixel data type for this band. (`UInt8`)

You can get additional attribute information using
* `ArchGDAL.getscale(band)`: the scale in `units = (px * scale) + offset` (`1.0`)
* `ArchGDAL.getoffset(band)`: the offset in `units = (px * scale) + offset` (`0.0`)
* `ArchGDAL.getunittype(band)`: name for the units, e.g. "m" (meters) or "ft" (feet). (`""`)
* `ArchGDAL.getnodatavalue(band)`: a special marker value used to mark pixels that are not valid data. (`-1.0e10`)
* `(x,y) = ArchGDAL.blocksize(band)`: the "natural" block size of this band (`(256,256)`)

!!! note

    GDAL contains a concept of the natural block size of rasters so that applications can organized data access efficiently for some file formats. The natural block size is the block size that is most efficient for accessing the format. For many formats this is simple a whole scanline. However, for tiled images this will typically be the tile size.

Finally, you can obtain overviews:
* `ArchGDAL.noverview(band)`: the number of overview layers available, zero if none. (`7`)
* `ArchGDAL.getoverview(band, i)`: returns the `i`-th overview in the raster band. Each overview is itself a raster band, e.g.

```julia
julia> ArchGDAL.getoverview(band, 2)
[GA_ReadOnly] Band 1 (Red): 256 x 128 (UInt8)
    blocksize: 128×128, nodata: -1.0e10, units: 1.0px + 0.0
    overviews:
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

You can also specify the subset of rows and columns (provided as `UnitRange`s) to read:

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

```julia
julia> for (cols,rows) in ArchGDAL.windows(band)
           println((cols,rows))
       end
(1:256, 1:256)
(1:256, 257:512)
(1:256, 513:768)
(1:256, 769:1024)
(257:512, 1:256)
(257:512, 257:512)
(257:512, 513:768)
(257:512, 769:1024)
(513:768, 1:256)
...
```

Alternatively, we have another method called `ArchGDAL.blocks(band)` which iterates over the windows of a raster band, returning the `offset` and `size` corresponding to the rasterblocks within that raster band for efficiency:
```julia
julia> for (xyoffset,xysize) in ArchGDAL.blocks(band)
           println((xyoffset,xysize))
       end
((0, 0), (256, 256))
((1, 0), (256, 256))
((2, 0), (256, 256))
((3, 0), (256, 256))
((0, 1), (256, 256))
((1, 1), (256, 256))
...
```

!!! note

    These methods are often used for reading/writing a block of image data efficiently, as it accesses "natural" blocks from the raster band without resampling, or data type conversion.
