
"""
    rasterio!(dataset::AbstractDataset, buffer::Array{<:Any, 3},
        bands; <keyword arguments>)
    rasterio!(dataset::AbstractDataset, buffer::Array{<:Any, 3}, bands, rows,
        cols; <keyword arguments>)
    rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{<:Any};
        <keyword arguments>)
    rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{<:Any}, rows,
        cols; <keyword arguments>)


Read/write a region of image data from multiple bands.

This method allows reading a region of one or more `RasterBand`s from this
dataset into a buffer, or writing data from a buffer into a region of the
`RasterBand`s. It automatically takes care of data type translation if the
element type (`<:Any`) of the buffer is different than that of the
`RasterBand`. The method also takes care of image decimation / replication
if the buffer size (`xsz × ysz`) is different than the size of the
region being accessed (`xsize × ysize`).

The `pxspace`, `linespace` and `bandspace` parameters allow reading into
or writing from various organization of buffers.

For highest performance full resolution data access, read and write on \"block
boundaries\" as returned by `blocksize()`, or use the `readblock!()` and
`writeblock!()` methods.

### Parameters
* `rows`        A continuous range of rows expressed as a
                `UnitRange{<:Integer}`, such as 2:9.
* `cols`        A continuous range of columns expressed as a
                `UnitRange{<:Integer}`, such as 2:9.
* `access`      Either `GF_Read` to read a region of data, or
                `GF_Write` to write a region of data.
* `xoffset`     The pixel offset to the top left corner of the region to be
                accessed. It will be `0` (default) to start from the left.
* `yoffset`     The line offset to the top left corner of the region to be
                accessed. It will be `0` (default) to start from the top.
* `xsize`       The width of the region of the band to be accessed in pixels.
* `ysize`       The height of the region of the band to be accessed in lines.
* `buffer`      The buffer into which the data should be read, or from which it
                should be written. It must contain `≥ xsz * ysz * <# of bands>`
                words of type `eltype(buffer)`. It is organized in left to
                right, top to bottom pixel order. Spacing is controlled by the
                `pxspace`, and `linespace` parameters
* `xsz`         The width of the buffer into which the desired region is
                to be read, or from which it is to be written.
* `ysz`         The height of the buffer into which the desired region is
                to be read, or from which it is to be written.
* `bands`       The list of bands (`1`-based) to be read/written.
* `pxspace`     The byte offset from the start of a pixel value in the `buffer`
                to the start of the next pixel value within a scanline. By
                default (i.e., `0`) the size of `eltype(buffer)` will be used.
* `linespace`   The byte offset from the start of one scanline in pBuffer to
                the start of the next. By default (i.e., `0`) the value of
                `sizeof(eltype(buffer)) * xsz` will be used.
* `bandspace`   The byte offset from the start of one bands data to the start
                of the next. By default (`0`), it will be `linespace * ysz`
                implying band sequential organization of the buffer.

### Returns
`CE_Failure` if the access fails, otherwise `CE_None`.
"""
function rasterio! end

function rasterio!(
    dataset::AbstractDataset,
    buffer::T,
    bands,
    access::GDALRWFlag = GF_Read,
    pxspace::Integer = 0,
    linespace::Integer = 0,
    bandspace::Integer = 0,
)::T where {T<:Array{<:Any,3}}
    rasterio!(
        dataset,
        buffer,
        bands,
        0,
        0,
        size(buffer, 1),
        size(buffer, 2),
        access,
        pxspace,
        linespace,
        bandspace,
    )
    return buffer
end

function rasterio!(
    dataset::AbstractDataset,
    buffer::Array{T,3},
    bands,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
    access::GDALRWFlag = GF_Read,
    pxspace::Integer = 0,
    linespace::Integer = 0,
    bandspace::Integer = 0,
)::Array{T,3} where {T<:Any}
    xsize = cols[end] - cols[1] + 1
    xsize < 0 && error("invalid window width")
    ysize = rows[end] - rows[1] + 1
    ysize < 0 && error("invalid window height")
    rasterio!(
        dataset,
        buffer,
        bands,
        cols[1] - 1,
        rows[1] - 1,
        xsize,
        ysize,
        access,
        pxspace,
        linespace,
        bandspace,
    )
    return buffer
end

function rasterio!(
    dataset::AbstractDataset,
    buffer::Array{T,3},
    bands,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
    access::GDALRWFlag = GF_Read,
    pxspace::Integer = 0,
    linespace::Integer = 0,
    bandspace::Integer = 0,
    extraargs = Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL),
)::Array{T,3} where {T<:Any}
    # `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg
    # structure with additional arguments to specify resampling and
    # progress callback, or `NULL` for default behaviour. The
    # `GDAL_RASTERIO_RESAMPLING` configuration option can also be
    # defined to override the default resampling to one of `BILINEAR`,
    # `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.
    (dataset == C_NULL) && error("Can't read NULL dataset")
    xbsize, ybsize, zbsize = size(buffer)
    nband = length(bands)
    bands = isa(bands, Vector{Cint}) ? bands : Cint.(collect(bands))
    @assert nband == zbsize
    result = GDAL.gdaldatasetrasterioex(
        dataset,
        access,
        xoffset,
        yoffset,
        xsize,
        ysize,
        pointer(buffer),
        xbsize,
        ybsize,
        convert(GDALDataType, T),
        nband,
        pointer(bands),
        pxspace,
        linespace,
        bandspace,
        extraargs,
    )
    @cplerr result "Access in DatasetRasterIO failed."
    return buffer
end

function rasterio!(
    rasterband::AbstractRasterBand,
    buffer::T,
    access::GDALRWFlag = GF_Read,
    pxspace::Integer = 0,
    linespace::Integer = 0,
)::T where {T<:Matrix{<:Any}}
    rasterio!(
        rasterband,
        buffer,
        0,
        0,
        width(rasterband),
        height(rasterband),
        access,
        pxspace,
        linespace,
    )
    return buffer
end

function rasterio!(
    rasterband::AbstractRasterBand,
    buffer::T,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
    access::GDALRWFlag = GF_Read,
    pxspace::Integer = 0,
    linespace::Integer = 0,
)::T where {T<:Matrix{<:Any}}
    xsize = length(cols)
    xsize < 1 && error("invalid window width")
    ysize = length(rows)
    ysize < 1 && error("invalid window height")
    rasterio!(
        rasterband,
        buffer,
        cols[1] - 1,
        rows[1] - 1,
        xsize,
        ysize,
        access,
        pxspace,
        linespace,
    )
    return buffer
end

function rasterio!(
    rasterband::AbstractRasterBand,
    buffer::Matrix{T},
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
    access::GDALRWFlag = GF_Read,
    pxspace::Integer = 0,
    linespace::Integer = 0,
    extraargs = Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL),
)::Matrix{T} where {T<:Any}
    # `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg
    # structure with additional arguments to specify resampling and
    # progress callback, or `NULL` for default behaviour. The
    # `GDAL_RASTERIO_RESAMPLING` configuration option can also be
    # defined to override the default resampling to one of `BILINEAR`,
    # `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.
    (rasterband == C_NULL) && error("Can't read NULL rasterband")
    xbsize, ybsize = size(buffer)
    result = GDAL.gdalrasterioex(
        rasterband,
        access,
        xoffset,
        yoffset,
        xsize,
        ysize,
        pointer(buffer),
        xbsize,
        ybsize,
        convert(GDALDataType, T),
        pxspace,
        linespace,
        extraargs,
    )
    @cplerr result "Access in RasterIO failed."
    return buffer
end

function read!(rb::AbstractRasterBand, buffer::T)::T where {T<:Matrix{<:Any}}
    rasterio!(rb, buffer, GF_Read)
    return buffer
end

function read!(
    rb::AbstractRasterBand,
    buffer::T,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::T where {T<:Matrix{<:Any}}
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read!(
    rb::AbstractRasterBand,
    buffer::T,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)::T where {T<:Matrix{<:Any}}
    rasterio!(rb, buffer, rows, cols)
    return buffer
end

function read(rb::AbstractRasterBand)
    return rasterio!(rb, Array{pixeltype(rb)}(undef, width(rb), height(rb)))
end

function read(
    rb::AbstractRasterBand,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::Matrix{pixeltype(rb)}
    buffer = Matrix{pixeltype(rb)}(undef, xsize, ysize)
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read(
    rb::AbstractRasterBand,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)::Matrix{pixeltype(rb)}
    buffer = Matrix{pixeltype(rb)}(undef, length(cols), length(rows))
    rasterio!(rb, buffer, rows, cols)
    return buffer
end

function write!(
    rb::AbstractRasterBand,
    buffer::T,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::T where {T<:Matrix{<:Any}}
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize, GF_Write)
    return buffer
end

function write!(
    rb::AbstractRasterBand,
    buffer::T,
    rows::UnitRange{<:Integer} = 1:height(rb),
    cols::UnitRange{<:Integer} = 1:width(rb),
)::T where {T<:Matrix{<:Any}}
    rasterio!(rb, buffer, rows, cols, GF_Write)
    return buffer
end

function read!(
    dataset::AbstractDataset,
    buffer::T,
    i::Integer,
)::T where {T<:Matrix{<:Any}}
    read!(getband(dataset, i), buffer)
    return buffer
end

function read!(
    dataset::AbstractDataset,
    buffer::T,
    indices,
)::T where {T<:Array{<:Any,3}}
    rasterio!(dataset, buffer, indices, GF_Read)
    return buffer
end

function read!(dataset::AbstractDataset, buffer::T)::T where {T<:Array{<:Any,3}}
    nband = nraster(dataset)
    @assert size(buffer, 3) == nband
    rasterio!(dataset, buffer, collect(Cint, 1:nband), GF_Read)
    return buffer
end

function read!(
    dataset::AbstractDataset,
    buffer::T,
    i::Integer,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::T where {T<:Matrix{<:Any}}
    read!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read!(
    dataset::AbstractDataset,
    buffer::T,
    indices,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::T where {T<:Array{<:Any,3}}
    rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read!(
    dataset::AbstractDataset,
    buffer::T,
    i::Integer,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)::T where {T<:Matrix{<:Any}}
    read!(getband(dataset, i), buffer, rows, cols)
    return buffer
end

function read!(
    dataset::AbstractDataset,
    buffer::T,
    indices,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)::T where {T<:Array{<:Any,3}}
    rasterio!(dataset, buffer, indices, rows, cols)
    return buffer
end

read(dataset::AbstractDataset, i::Integer) = read(getband(dataset, i))

function read(dataset::AbstractDataset, indices)::Array{pixeltype(dataset),3}
    buffer = Array{pixeltype(dataset)}(
        undef,
        width(dataset),
        height(dataset),
        length(indices),
    )
    rasterio!(dataset, buffer, indices)
    return buffer
end

function read(dataset::AbstractDataset)::Array{pixeltype(dataset),3}
    buffer = Array{pixeltype(dataset)}(
        undef,
        width(dataset),
        height(dataset),
        nraster(dataset),
    )
    read!(dataset, buffer)
    return buffer
end

function read(
    dataset::AbstractDataset,
    i::Integer,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::Matrix{pixeltype(dataset)}
    band = getband(dataset, i)
    buffer = Matrix{pixeltype(band)}(undef, xsize, ysize)
    read!(dataset, buffer, i, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read(
    dataset::AbstractDataset,
    indices,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::Array{pixeltype(dataset),3}
    buffer = Array{pixeltype(dataset)}(undef, xsize, ysize, length(indices))
    rasterio!(dataset, buffer, indices, xsize, ysize, xoffset, yoffset)
    return buffer
end

function read(
    dataset::AbstractDataset,
    i::Integer,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)::Matrix{pixeltype(dataset)}
    buffer = read(getband(dataset, i), rows, cols)
    return buffer
end

function read(
    dataset::AbstractDataset,
    indices,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)::Array{pixeltype(dataset),3}
    buffer = Array{pixeltype(dataset),3}(
        undef,
        length(cols),
        length(rows),
        length(indices),
    )
    rasterio!(dataset, buffer, indices, rows, cols)
    return buffer
end

function write!(
    dataset::T,
    buffer::Matrix{<:Any},
    i::Integer,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::T where {T<:AbstractDataset}
    write!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)
    return dataset
end

function write!(
    dataset::T,
    buffer::Array{<:Any,3},
    indices,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)::T where {T<:AbstractDataset}
    rasterio!(
        dataset,
        buffer,
        indices,
        xoffset,
        yoffset,
        xsize,
        ysize,
        GF_Write,
    )
    return dataset
end

function write!(
    dataset::T,
    buffer::Matrix{<:Any},
    i::Integer,
    rows::UnitRange{<:Integer} = 1:height(getband(dataset, i)),
    cols::UnitRange{<:Integer} = 1:width(getband(dataset, i)),
)::T where {T<:AbstractDataset}
    write!(getband(dataset, i), buffer, rows, cols)
    return dataset
end

function write!(
    dataset::T,
    buffer::Array{<:Any,3},
    indices,
    rows::UnitRange{<:Integer} = 1:height(dataset),
    cols::UnitRange{<:Integer} = 1:width(dataset),
)::T where {T<:AbstractDataset}
    rasterio!(dataset, buffer, indices, rows, cols, GF_Write)
    return dataset
end

"""
    readblock!(rb::AbstractRasterBand, xoffset::Integer, yoffset::Integer,
        buffer)

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
    buffer::T,
)::T where {T<:Any}
    result = GDAL.gdalreadblock(rb, xoffset, yoffset, buffer)
    @cplerr result "Failed to read block at ($xoffset,$yoffset)"
    return buffer
end

"""
    writeblock!(rb::AbstractRasterBand, xoffset::Integer, yoffset::Integer,
        buffer)

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
    rb::T,
    xoffset::Integer,
    yoffset::Integer,
    buffer,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalwriteblock(rb, xoffset, yoffset, buffer)
    @cplerr result "Failed to write block at ($xoffset, $yoffset)"
    return rb
end
