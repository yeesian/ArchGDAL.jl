
"""
    rasterio!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, bands; <keyword arguments>)
    rasterio!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, bands, rows, cols; <keyword arguments>)
    rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{<:Real}; <keyword arguments>)
    rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{<:Real}, rows, cols; <keyword arguments>)


Read/write a region of image data from multiple bands.

This method allows reading a region of one or more `RasterBand`s from this
dataset into a buffer, or writing data from a buffer into a region of the
`RasterBand`s. It automatically takes care of data type translation if the
element type (`<:Real`) of the buffer is different than that of the
`GDALRasterBand`. The method also takes care of image decimation / replication
if the buffer size (`xsz × ysz`) is different than the size of the
region being accessed (`xsize × ysize`).

The `pxspace`, `linespace` and `bandspace` parameters allow reading into
or writing from various organization of buffers.

For highest performance full resolution data access, read and write on \"block
boundaries\" as returned by `blocksize()`, or use the `readblock!()` and
`writeblock!()` methods.

### Parameters
* `rows`        A continuous range of rows expressed as a `UnitRange{<:Integer}`,
                such as 2:9.
* `cols`        A continuous range of columns expressed as a `UnitRange{<:Integer}`,
                such as 2:9.
* `access`      Either `GDAL.GF_Read` to read a region of data, or
                `GDAL.GF_Write` to write a region of data.
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
        buffer::Array{<:Real, 3},
        bands,
        access::GDALRWFlag  = GDAL.GF_Read,
        pxspace::Integer    = 0,
        linespace::Integer  = 0,
        bandspace::Integer  = 0
    )
    rasterio!(dataset, buffer, bands, 0, 0, width(dataset), height(dataset),
        access, pxspace, linespace, bandspace)
    return buffer
end

function rasterio!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        bands,
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
        pxspace, linespace, bandspace)
    return buffer
end

function rasterio!(
        rasterband::AbstractRasterBand,
        buffer::Matrix{<:Real},
        access::GDALRWFlag  = GDAL.GF_Read,
        pxspace::Integer    = 0,
        linespace::Integer  = 0
    )
    rasterio!(rasterband, buffer, 0, 0, width(rasterband), height(rasterband),
        access, pxspace, linespace)
    return buffer
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
    rasterio!(rasterband, buffer, cols[1]-1, rows[1]-1, xsize, ysize, access,
        pxspace, linespace)
    return buffer
end

read!(rb::AbstractRasterBand, buffer::Matrix{<:Real}) =
    rasterio!(rb, buffer, GDAL.GF_Read)

function read!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(rb, buffer, rows, cols)
    return buffer
end

read(rb::AbstractRasterBand) =
    rasterio!(rb, Array{pixeltype(rb)}(undef, width(rb), height(rb)))

function read(
        rb::AbstractRasterBand,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    buffer = Array{pixeltype(rb)}(undef, width(rb), height(rb))
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read(
        rb::AbstractRasterBand,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    buffer = Array{pixeltype(rb)}(undef, length(cols), length(rows))
    rasterio!(rb, buffer, rows, cols)
    return buffer
end

function write!(rb::AbstractRasterBand, buffer::Matrix{<:Real})
    rasterio!(rb, buffer, GDAL.GF_Write)
    return buffer
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
    return buffer
end

function write!(
        rb::AbstractRasterBand,
        buffer::Matrix{<:Real},
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(rb, buffer, rows, cols, GDAL.GF_Write)
    return buffer
end

function read!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer)
    read!(getband(dataset, i), buffer)
    return buffer
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices
    )
    rasterio!(dataset, buffer, indices, GDAL.GF_Read)
    return buffer
end

function read!(dataset::AbstractDataset, buffer::Array{<:Real, 3})
    nband = nraster(dataset)
    @assert size(buffer, 3) == nband
    rasterio!(dataset, buffer, collect(Cint, 1:nband), GDAL.GF_Read)
    return buffer
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
    return buffer
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
    return buffer
end

function read!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    read!(getband(dataset, i), buffer, rows, cols)
    return buffer
end

function read!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(dataset, buffer, indices, rows, cols)
    return buffer
end

read(dataset::AbstractDataset, i::Integer) = read(getband(dataset, i))

function read(
        dataset::AbstractDataset,
        indices
    )
    buffer = Array{pixeltype(getband(dataset, indices[1]))}(undef,
        width(dataset), height(dataset), length(indices))
    rasterio!(dataset, buffer, indices)
    return buffer
end

function read(dataset::AbstractDataset)
    buffer = Array{pixeltype(getband(dataset, 1))}(undef, width(dataset),
        height(dataset), nraster(dataset))
    read!(dataset, buffer)
    return buffer
end

function read(
        dataset::AbstractDataset,
        i::Integer,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    buffer = read(getband(dataset, i), xoffset, yoffset, xsize, ysize)
    return buffer
end

function read(
        dataset::AbstractDataset,
        indices,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    buffer = Array{pixeltype(getband(dataset, indices[1]))}(undef,
        width(dataset), height(dataset), length(indices))
    rasterio!(dataset, buffer, indices, xsize, ysize, xoffset, yoffset)
    return buffer
end

function read(
        dataset::AbstractDataset,
        i::Integer,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    buffer = read(getband(dataset, i), rows, cols)
    return buffer
end

function read(
        dataset::AbstractDataset,
        indices,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    buffer = Array{pixeltype(getband(dataset, indices[1]))}(undef,
        width(dataset), height(dataset), length(indices))
    rasterio!(dataset, buffer, indices, rows, cols)
    return buffer
end

function write!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer)
    write!(getband(dataset, i), buffer)
    return dataset
end

function write!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices
    )
    rasterio!(dataset, buffer, indices, GDAL.GF_Write)
    return dataset
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
    return dataset
end

function write!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices,
        xoffset::Integer,
        yoffset::Integer,
        xsize::Integer,
        ysize::Integer
    )
    rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize,
        GDAL.GF_Write)
    return dataset
end

function write!(
        dataset::AbstractDataset,
        buffer::Matrix{<:Real},
        i::Integer,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    write!(getband(dataset, i), buffer, rows, cols)
    return dataset
end

function write!(
        dataset::AbstractDataset,
        buffer::Array{<:Real, 3},
        indices,
        rows::UnitRange{<:Integer},
        cols::UnitRange{<:Integer}
    )
    rasterio!(dataset, buffer, indices, rows, cols, GDAL.GF_Write)
    return dataset
end

for (T,GT) in _GDALTYPE
    eval(quote
        function rasterio!(
                dataset::AbstractDataset,
                buffer::Array{$T, 3},
                bands,
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
            # `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg
            # structure with additional arguments to specify resampling and
            # progress callback, or `NULL` for default behaviour. The
            # `GDAL_RASTERIO_RESAMPLING` configuration option can also be
            # defined to override the default resampling to one of `BILINEAR`,
            # `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.
            (dataset == C_NULL) && error("Can't read invalid rasterband")
            xbsize, ybsize, zbsize = size(buffer)
            nband = length(bands)
            bands = isa(bands, Vector{Cint}) ? bands : Cint.(collect(bands))
            @assert nband == zbsize
            result = ccall((:GDALDatasetRasterIOEx,GDAL.libgdal),
                           GDAL.CPLErr,  # return type
                           (GDALDataset,
                           GDAL.GDALRWFlag,  # access
                           Cint,  # xoffset
                           Cint,  # yoffset
                           Cint,  # xsize
                           Cint,  # ysize
                           Ptr{Cvoid},  # poiter to buffer
                           Cint,  # xbsize
                           Cint,  # ybsize
                           GDAL.GDALDataType,
                           Cint,  # number of bands
                           Ptr{Cint},  # bands
                           GDAL.GSpacing,  # pxspace
                           GDAL.GSpacing,  # linespace
                           GDAL.GSpacing,  # bandspace
                           Ptr{GDAL.GDALRasterIOExtraArg}  # extra args
                           ),
                           dataset.ptr,
                           access,
                           xoffset,
                           yoffset,
                           xsize,
                           ysize,
                           pointer(buffer),
                           xbsize,
                           ybsize,
                           $GT,
                           nband,
                           pointer(bands),
                           pxspace,
                           linespace,
                           bandspace,
                           extraargs)
            @cplerr result "Access in DatasetRasterIO failed."
            return buffer
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
            # `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg
            # structure with additional arguments to specify resampling and
            # progress callback, or `NULL` for default behaviour. The
            # `GDAL_RASTERIO_RESAMPLING` configuration option can also be
            # defined to override the default resampling to one of `BILINEAR`,
            # `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.
            (rasterband == C_NULL) && error("Can't read invalid rasterband")
            xbsize, ybsize = size(buffer)
            result = ccall((:GDALRasterIOEx,GDAL.libgdal),GDAL.CPLErr,
                (GDALRasterBand,GDAL.GDALRWFlag,Cint,Cint,Cint,Cint,Ptr{Cvoid},
                Cint,Cint,GDAL.GDALDataType,GDAL.GSpacing, GDAL.GSpacing,
                Ptr{GDAL.GDALRasterIOExtraArg}),rasterband.ptr,access,xoffset,
                yoffset,xsize,ysize,pointer(buffer),xbsize,ybsize,$GT,pxspace,
                linespace,extraargs)
            @cplerr result "Access in RasterIO failed."
            return buffer
        end
    end)
end

"""
    readblock!(rb::AbstractRasterBand, xoffset::Integer, yoffset::Integer, buffer)

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
    result = GDAL.gdalreadblock(rb.ptr, xoffset, yoffset, buffer)
    @cplerr result "Failed to read block at ($xoffset,$yoffset)"
    return buffer
end

"""
    writeblock!(rb::AbstractRasterBand, xoffset::Integer, yoffset::Integer, buffer)

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
    result = GDAL.gdalwriteblock(rb.ptr, xoffset, yoffset, buffer)
    @cplerr result "Failed to write block at ($xoffset,$yoffset)"
    return rb
end
