
"""
Read/write a region of image data from multiple bands.

This method allows reading a region of one or more `GDALRasterBands` from this
dataset into a buffer, or writing data from a buffer into a region of the
`GDALRasterBands`. It automatically takes care of data type translation if the
data type (`eBufType`) of the buffer is different than that of the
`GDALRasterBand`. The method also takes care of image decimation / replication
if the buffer size (`nBufXSize x nBufYSize`) is different than the size of the
region being accessed (`nXSize x nYSize`).

The `pxspace`, `linespace` and `bandspace` parameters allow reading into
or writing from various organization of buffers.

For highest performance full resolution data access, read and write on \"block
boundaries\" as returned by `GetBlockSize()`, or use the `ReadBlock()` and
`WriteBlock()` methods.

### Parameters
* `access`      Either `GF_Read` to read a region of data, or `GF_Write` to
                write a region of data.
* `xoffset`     The pixel offset to the top left corner of the band to be
                accessed. This would be 0 to start from the left side.
* `yoffset`     The line offset to the top left corner of the region of the
                band to be accessed. This would be zero to start from the top.
* `xsize`       The width of the region of the band to be accessed in pixels.
* `ysize`       The height of the region of the band to be accessed in lines.
* `buffer`      The buffer into which the data should be read, or from which it
                should be written. It must contain
                    ≥`nBufXSize * nBufYSize * nBandCount`
                words of type `eBufType`. It is organized in left to right,
                top to bottom pixel order. Spacing is controlled by the
                `nPixelSpace`, and `nLineSpace` parameters
* `xsz`         The width of the buffer image into which the desired region is
                to be read, or from which it is to be written.
* `ysz`         The height of the buffer image into which the desired region is
                to be read, or from which it is to be written.
* `bands`       The list of bands (1 based) to be read/written.
* `pxspace`     The byte offset from the start of one pixel value in `pBuffer`
                to the start of the next pixel value within a scanline.
                If defaulted (0) the size of the datatype `eBufType` is used.
* `linespace`   The byte offset from the start of one scanline in pBuffer to
                the start of the next. If defaulted (0) the size of the datatype
                `eBufType * nBufXSize` is used.
* `bandspace`   The byte offset from the start of one bands data to the start
                of the next. If defaulted (0) the value will be
                    `nlinespace * nBufYSize`
                implying band sequential organization of the data buffer.
* `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg structure
with additional arguments to specify resampling and progress callback, or
`NULL` for default behaviour. The `GDAL_RASTERIO_RESAMPLING` configuration
option can also be defined to override the default resampling to one of
`BILINEAR`, `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.
"""
function rasterio!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        bands::Vector{Cint},
        access::GDALRWFlag  = GDAL.GF_Read,
        pxspace::Integer    = 0,
        linespace::Integer  = 0,
        bandspace::Integer  = 0
    )
    rasterio!(dataset, buffer, bands, 0, 0, width(dataset), height(dataset),
        access, pxspace, linespace, bandspace
    )
end

function rasterio!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        bands::Vector{Cint},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer},
        access::GDALRWFlag  = GDAL.GF_Read,
        pxspace::Integer    = 0,
        linespace::Integer  = 0,
        bandspace::Integer  = 0
    )
    xsize = cols[end] - cols[1] + 1; xsize < 0 && error("invalid window width")
    ysize = rows[end] - rows[1] + 1; ysize < 0 && error("invalid window height")
    rasterio!(dataset, buffer, bands, cols[1], rows[1], xsize, ysize, access,
        pxspace, linespace, bandspace
    )
end

"""
Read/write a region of image data for this band.

This method allows reading a region of a `GDALRasterBand` into a buffer, or
writing data from a buffer into a region of a `GDALRasterBand`. It
automatically takes care of data type translation if the data type (`eBufType`)
of the buffer is different than that of the `GDALRasterBand`. The method also
takes care of image decimation / replication if the buffer size
`(nBufXSize x nBufYSize)` is different than the size of the region being
accessed `(nXSize x nYSize)`.

The `nPixelSpace` and `nLineSpace` parameters allow reading into or writing
from unusually organized buffers. This is primarily used for buffers containing
more than one bands raster data in interleaved format.

Some formats may efficiently implement decimation into a buffer by reading from
lower resolution overview images.

For highest performance full resolution data access, read and write on "block
boundaries" returned by `GetBlockSize()`, or use the `ReadBlock()` and 
`WriteBlock()` methods.

### Parameters
* `eRWFlag`     Either GF_Read to read a region of data, or GF_Write to write a
region of data.
* `nXOff`       The pixel offset to the top left corner of the region of the
band to be accessed. This would be zero to start from the left side.
* `nYOff`       The line offset to the top left corner of the region of the
band to be accessed. This would be zero to start from the top.
* `nXSize`      The width of the region of the band to be accessed in pixels.
* `nYSize`      The height of the region of the band to be accessed in lines.
* `pData`       The buffer into which the data should be read, or from which it
should be written. This buffer must contain at least `(nBufXSize * nBufYSize)`
words of type `eBufType`. It is organized in left to right, top to bottom pixel
order. Spacing is controlled by the `nPixelSpace`, and `nLineSpace` parameters.
* `nBXSize`     The width of the buffer image into which the desired region is
to be read, or from which it is to be written.
* `nBYSize`     The height of the buffer image into which the desired region is
to be read, or from which it is to be written.
* `eBufType`    The type of the pixel values in the `buffer`. The pixel values
will be auto-translated to/from the `GDALRasterBand` data type as needed.
* `nPixelSpace` The byte offset from the start of one pixel value in `buffer`
to the start of the next pixel value within a scanline. If defaulted (0) the
size of the datatype `eBufType` is used.
* `nLineSpace`  The byte offset from the start of one scanline in `buffer` to
the start of the next. If defaulted (0) the size of the datatype
`(eBufType * nBufXSize)` is used.
* `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg structure
with additional arguments to specify resampling and progress callback, or
`NULL` for default behaviour. The `GDAL_RASTERIO_RESAMPLING` configuration
option can also be defined to override the default resampling to one of
`BILINEAR`, `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.

### Returns
`CE_Failure` if the access fails, otherwise `CE_None`.
"""
function rasterio!(
        rasterband::AbstractRasterBand,
        buffer::Matrix{<:Real},
        access::GDALRWFlag  = GDAL.GF_Read,
        pxspace::Integer    = 0,
        linespace::Integer  = 0
    )
    rasterio!(rasterband, buffer, 0, 0, width(rasterband), height(rasterband),
        access, pxspace, linespace
    )
end

function rasterio!(
        rasterband::AbstractRasterBand,
        buffer::Matrix{<:Real},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer},
        access::GDALRWFlag  = GDAL.GF_Read,
        pxspace::Integer    = 0,
        linespace::Integer  = 0
    )
    xsize = length(cols); xsize < 1 && error("invalid window width")
    ysize = length(rows); ysize < 1 && error("invalid window height")
    rasterio!(rasterband, buffer, cols[1]-1, rows[1]-1, xsize, ysize,
        access, pxspace, linespace
    )
end

function read!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real}
    )
    rasterio!(rb, buffer, GDAL.GF_Read)
end

function read!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
end

function read!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(rb, buffer, rows, cols)
end

function read(rb::AbstractRasterBand)
    rasterio!(rb, Array{getdatatype(rb)}(undef, width(rb), height(rb)))
end

function read(
        rb::AbstractRasterBand,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    buffer = Array{getdatatype(rb)}(undef, width(rb), height(rb))
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
end

function read(
        rb::AbstractRasterBand,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(rb,
        Array{getdatatype(rb)}(undef, length(cols), length(rows)),
        rows, cols
    )
end

function write!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real}
    )
    rasterio!(rb, buffer, GDAL.GF_Write)
end

function write!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize, GDAL.GF_Write)
end

function write!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(rb, buffer, rows, cols, GDAL.GF_Write)
end

function read!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer
    )
    read!(getband(dataset, i), buffer)
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices::Vector{Cint}
    )
    rasterio!(dataset, buffer, indices, GDAL.GF_Read)
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3}
    )
    nband = nraster(dataset); @assert size(buffer, 3) == nband
    rasterio!(dataset, buffer, collect(Cint, 1:nband), GDAL.GF_Read)
end

function read!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    read!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices::Vector{Cint},
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
end

function read!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    read!(getband(dataset, i), buffer, rows, cols)
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices::Vector{Cint},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(dataset, buffer, indices, rows, cols)
end

read(dataset::AbstractDataset, i::Integer) = read(getband(dataset, i))

function read(
        dataset::AbstractDataset,
        indices::Vector{Cint}
    )
    buffer = Array{getdatatype(getband(dataset, indices[1]))}(
        undef, width(dataset), height(dataset), length(indices)
    )
    rasterio!(dataset, buffer, indices)
end

function read(dataset::AbstractDataset)
    read!(dataset, Array{getdatatype(getband(dataset, 1))}(
        undef, width(dataset), height(dataset), nraster(dataset)
    ))
end

function read(
        dataset::AbstractDataset,
        i::Integer,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    read(getband(dataset, i), xoffset, yoffset, xsize, ysize)
end

function read(
        dataset::AbstractDataset,
        indices::Vector{<:Integer},
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    buffer = Array{getdatatype(getband(dataset, indices[1]))}(
        undef, width(dataset), height(dataset), length(indices)
    )
    rasterio!(dataset, buffer, indices, xsize, ysize, xoffset, yoffset)
end

function read(
        dataset::AbstractDataset,
        i::Integer,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    read(getband(dataset, i), rows, cols)
end

function read(
        dataset::AbstractDataset,
        indices::Vector{Cint},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    buffer = Array{getdatatype(getband(dataset, indices[1]))}(
        undef, width(dataset), height(dataset), length(indices)
    )
    rasterio!(dataset, buffer, indices, rows, cols)
end

function write!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer
    )
    write!(getband(dataset, i), buffer)
end

function write!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices::Vector{Cint}
    )
    rasterio!(dataset, buffer, indices, GDAL.GF_Write)
end

function write!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    write!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)
end

function write!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices::Vector{Cint},
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(dataset, buffer, indices, xoffset, yoffset,
        xsize, ysize, GDAL.GF_Write
    )
end

function write!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    write!(getband(dataset, i), buffer, rows, cols)
end

function write!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices::Vector{Cint},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(dataset, buffer, indices, rows, cols, GDAL.GF_Write)
end

for (T,GT) in _GDALTYPE
    eval(quote
        function rasterio!(
                dataset::AbstractDataset,
                buffer::Array{$T, 3},
                bands::Vector{Cint},
                xoffset::Integer,
                yoffset::Integer,
                xsize::Integer,
                ysize::Integer,
                access::GDALRWFlag   = GDAL.GF_Read,
                pxspace::Integer     = 0,
                linespace::Integer   = 0,
                bandspace::Integer   = 0,
                extraargs            = Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL)
            )
            (dataset == C_NULL) && error("Can't read invalid rasterband")
            xbsize, ybsize, zbsize = size(buffer)
            nband = length(bands); @assert nband == zbsize
            result = ccall((:GDALDatasetRasterIOEx,GDAL.libgdal),GDAL.CPLErr,
                (GDALDataset,GDAL.GDALRWFlag,Cint,Cint,Cint,Cint,Ptr{Cvoid},
                Cint,Cint,GDAL.GDALDataType,Cint,Ptr{Cint},GDAL.GSpacing,
                GDAL.GSpacing,GDAL.GSpacing,Ptr{GDAL.GDALRasterIOExtraArg}),
                dataset.ptr,access,xoffset,yoffset,xsize,ysize,pointer(buffer),
                xbsize,ybsize,$GT,nband,pointer(bands),pxspace,linespace,
                bandspace,extraargs)
            @cplerr result "Access in DatasetRasterIO failed."
            buffer
        end

        function rasterio!(
                rasterband::AbstractRasterBand,
                buffer::Matrix{$T},
                xoffset::Integer,
                yoffset::Integer,
                xsize::Integer,
                ysize::Integer,
                access::GDALRWFlag   = GDAL.GF_Read,
                pxspace::Integer     = 0,
                linespace::Integer   = 0,
                extraargs            = Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL)
            )
            (rasterband == C_NULL) && error("Can't read invalid rasterband")
            xbsize, ybsize = size(buffer)
            result = ccall((:GDALRasterIOEx,GDAL.libgdal),GDAL.CPLErr,
                (GDALRasterBand,GDAL.GDALRWFlag,Cint,Cint,Cint,Cint,Ptr{Cvoid},
                Cint,Cint,GDAL.GDALDataType,GDAL.GSpacing, GDAL.GSpacing,
                Ptr{GDAL.GDALRasterIOExtraArg}),rasterband.ptr,access,xoffset,
                yoffset,xsize,ysize,pointer(buffer),xbsize,ybsize,$GT,pxspace,
                linespace,extraargs)
            @cplerr result "Access in RasterIO failed."
            buffer
        end
    end)
end

"""
Read a block of image data efficiently.

This method accesses a "natural" block from the raster band without resampling, 
or data type conversion. For a more generalized, but potentially less efficient 
access use RasterIO().

### Parameters
* `xoffset` the horizontal block offset, with zero indicating the left most 
            block, 1 the next block and so forth.
* `yoffset` the vertical block offset, with zero indicating the top most block,
            1 the next block and so forth.
* `buffer`  the buffer into which the data will be read. The buffer must be 
            large enough to hold GetBlockXSize()*GetBlockYSize() words of type 
            GetRasterDataType().
"""
function readblock!(
        rb::AbstractRasterBand,
        xoffset::Integer,
        yoffset::Integer,
        buffer
    )
    result = GDAL.readblock(rb.ptr, xoffset, yoffset, buffer)
    @cplerr result "Failed to read block at ($xoffset,$yoffset)"
    rb
end

"""
Write a block of image data efficiently.

This method accesses a "natural" block from the raster band without resampling,
or data type conversion. For a more generalized, but potentially less efficient 
access use RasterIO().

### Parameters
* `xoffset` the horizontal block offset, with zero indicating the left most 
            block, 1 the next block and so forth.
* `yoffset` the vertical block offset, with zero indicating the left most block,
            1 the next block and so forth.
* `buffer`  the buffer from which the data will be written. The buffer must be 
            large enough to hold GetBlockXSize()*GetBlockYSize() words of type
            GetRasterDataType().
"""
function writeblock!(
        rb::AbstractRasterBand,
        xoffset::Integer,
        yoffset::Integer,
        buffer
    )
    result = GDAL.writeblock(rb.ptr, xoffset, yoffset, buffer)
    @cplerr result "Failed to write block at ($xoffset,$yoffset)"
    rb
end
