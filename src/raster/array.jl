import DiskArrays
const AllowedXY = Union{Integer,Colon,AbstractRange}
const AllowedBand = Union{Integer,Colon,AbstractArray}


"""
    RasterDataset(dataset::AbstractDataset)

This data structure is returned by the [`ArchGDAL.readraster`](@ref) function
and is a wrapper for a GDAL dataset. This wrapper is to signal the user that the
dataset should be treated as a 3D AbstractArray where the first two dimensions
correspond to longitude and latitude and the third dimension corresponds to
different raster bands.

As it is a wrapper around a GDAL Dataset, it supports the usual raster methods
for a GDAL Dataset such as `getgeotransform`, `nraster`, `getband`, `getproj`,
`width`, and `height`. As it is also a subtype of `AbstractDiskArray{T,3}`, it
supports the following additional methods: `readblock!`, `writeblock!`,
`eachchunk`, `haschunks`, etc. This satisfies the DiskArray interface, allowing
us to be able to index into it like we would an array.

Constructing a RasterDataset will error if the raster bands do not have all the
same size and a common element data type.
"""
struct RasterDataset{T,DS} <: AbstractDiskArray{T,3}
    ds::DS
    size::Tuple{Int,Int,Int}
end

function RasterDataset(ds::AbstractDataset)
    if iszero(nraster(ds))
        throw(ArgumentError("The Dataset does not contain any raster bands"))
    end
    s = _common_size(ds)
    return RasterDataset{_dataset_type(ds), typeof(ds)}(ds, s)
end

# Forward a few functions
# Here we try to include all functions that are relevant
# for raster-like datasets.
for f in (:getgeotransform, :nraster, :getband, :getproj,
    :width, :height, :destroy, :getdriver, :filelist, :listcapability, 
    :ngcp, :copy, :write, :testcapability, :setproj!, :buildoverviews!)
    eval(:($(f)(x::RasterDataset, args...; kwargs...) = $(f)(x.ds, args...; kwargs...)))
end

# Here we need to special-case, because source and dest might be rasters
copywholeraster(x::RasterDataset,y::AbstractDataset;kwargs...) =
    copywholeraster(x.ds, y; kwargs...)
copywholeraster(x::RasterDataset,y::RasterDataset;kwargs...) =
    copywholeraster(x.ds, y.ds; kwargs...)
copywholeraster(x::AbstractDataset,y::RasterDataset;kwargs...) =
    copywholeraster(x.ds, y.ds; kwargs...)

"""
    _dataset_type(ds::AbstractDataset)

Tries to determine a common dataset type for all the bands
in a raster dataset.
"""
function _dataset_type(ds::AbstractDataset)
    alldatatypes = map(1:nraster(ds)) do i
        b = getband(ds, i)
        pixeltype(b)
    end
    return reduce(promote_type, alldatatypes)
end

"""
    _common_size(ds::AbstractDataset)

Determines the size of the raster bands in a dataset and errors
if the sizes are not unique.
"""
function _common_size(ds::AbstractDataset)
    nr = nraster(ds)
    allsizes = map(1:nr) do i
        b = getband(ds, i)
        size(b)
    end
    s = unique(allsizes)
    if length(s) != 1
        throw(DimensionMismatch(
            "Can not coerce bands to single dataset, different sizes found"
        ))
    end
    return Int.((s[1]..., nr))
end

getband(ds::RasterDataset, i::Integer) = getband(ds.ds, i)
unsafe_readraster(args...; kwargs...)  =
    RasterDataset(unsafe_read(args...; kwargs...))

"""
    readraster(s::String; kwargs...)

Opens a GDAL raster dataset. The difference to `ArchGDAL.read` is that this
function returns a `RasterDataset`, which is a subtype of
`AbstractDiskArray{T,3}`, so that users can operate on the array using direct
indexing.
"""
readraster(s::String; kwargs...) = RasterDataset(read(s; kwargs...))

function DiskArrays.eachchunk(ds::RasterDataset)
    subchunks = DiskArrays.eachchunk(getband(ds, 1))
    return DiskArrays.GridChunks(ds,(subchunks.chunksize..., 1))
end

DiskArrays.haschunks(::RasterDataset) = DiskArrays.Chunked()
DiskArrays.haschunks(::AbstractRasterBand) = DiskArrays.Chunked()

Base.size(band::AbstractRasterBand) = (width(band), height(band))

function DiskArrays.eachchunk(band::AbstractRasterBand)
    wI = windows(band)
    cs = (wI.blockiter.xbsize, wI.blockiter.ybsize)
    return DiskArrays.GridChunks(band, cs)
end

function DiskArrays.readblock!(
        band::AbstractRasterBand,
        buffer, x::AbstractUnitRange,
        y::AbstractUnitRange
    )
    xoffset, yoffset = first(x)-1, first(y)-1
    xsize, ysize = length(x), length(y)
    return read!(band, buffer, xoffset, yoffset, xsize, ysize)
end

function DiskArrays.writeblock!(
        band::AbstractRasterBand,
        value,
        x::AbstractUnitRange,
        y::AbstractUnitRange
    )
    xoffset, yoffset = first(x)-1, first(y)-1
    xsize, ysize = length(x), length(y)
    return write!(band, value, xoffset, yoffset, xsize, ysize)
end


# AbstractDataset indexing

Base.size(dataset::RasterDataset) = dataset.size

function DiskArrays.readblock!(
        dataset::RasterDataset,
        buffer,
        x::AbstractUnitRange,
        y::AbstractUnitRange,
        z::AbstractUnitRange
    )
    buffer2 = Array(buffer)
    DiskArrays.readblock!(dataset::RasterDataset, buffer2, x, y, z)
    return buffer .= buffer2
end

function DiskArrays.readblock!(
        dataset::RasterDataset,
        buffer::Array,
        x::AbstractUnitRange,
        y::AbstractUnitRange,
        z::AbstractUnitRange
    )
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize= length.((x, y))
    indices  = [Cint(i) for i in z]
    return read!(dataset.ds, buffer, indices, xoffset, yoffset, xsize, ysize)
end

function DiskArrays.writeblock!(
        dataset::RasterDataset,
        value,
        x::AbstractUnitRange,
        y::AbstractUnitRange,
        bands::AbstractUnitRange
    )
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize= length.((x, y))
    indices  = [Cint(i) for i in bands]
    return write!(dataset.ds, value, indices, xoffset, yoffset, xsize, ysize)
end

Base.Array(dataset::RasterDataset) = dataset[:,:,:]
