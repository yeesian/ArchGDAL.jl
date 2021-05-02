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
struct RasterDataset{T,DS<:AbstractDataset} <: AbstractDiskArray{T,3}
    ds::DS
    size::Tuple{Int,Int,Int}
end

function RasterDataset(ds::AbstractDataset)::RasterDataset{pixeltype(ds),typeof(ds)}
    if iszero(nraster(ds))
        throw(ArgumentError("The Dataset does not contain any raster bands"))
    end
    s = _common_size(ds)
    return RasterDataset{pixeltype(ds),typeof(ds)}(ds, s)
end

# Forward a few functions
# Here we try to include all functions that are relevant
# for raster-like datasets.
for f in (
    :getgeotransform,
    :nraster,
    :getband,
    :getproj,
    :width,
    :height,
    :destroy,
    :getdriver,
    :filelist,
    :listcapability,
    :ngcp,
    :copy,
    :unsafe_copy,
    :write,
    :testcapability,
    :setproj!,
    :buildoverviews!,
    :metadata,
    :metadatadomainlist,
)
    eval(:($(f)(x::RasterDataset, args...; kwargs...) = $(f)(x.ds, args...; kwargs...)))
end

# Here we need to special-case, to avoid a method ambiguity
function metadataitem(obj::RasterDataset, name::AbstractString; kwargs...)
    return metadataitem(obj.ds, name; kwargs...)
end

# Here we need to special-case, because source and dest might be rasters
function copywholeraster!(
    source::RasterDataset,
    dest::D;
    kwargs...,
)::D where {D<:AbstractDataset}
    copywholeraster!(source.ds, dest; kwargs...)
    return dest
end

function copywholeraster!(
    source::RasterDataset,
    dest::RasterDataset;
    kwargs...,
)::RasterDataset
    copywholeraster!(source, dest.ds; kwargs...)
    return dest
end

function copywholeraster!(
    source::AbstractDataset,
    dest::RasterDataset;
    kwargs...,
)::RasterDataset
    copywholeraster!(source, dest.ds; kwargs...)
    return dest
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
        throw(
            DimensionMismatch(
                "Can not coerce bands to single dataset, different sizes found",
            ),
        )
    end
    return Int.((s[1]..., nr))
end

getband(ds::RasterDataset, i::Integer)::IRasterBand = getband(ds.ds, i)
unsafe_readraster(args...; kwargs...)::RasterDataset =
    RasterDataset(unsafe_read(args...; kwargs...))

"""
    readraster(s::String; kwargs...)

Opens a GDAL raster dataset. The difference to `ArchGDAL.read` is that this
function returns a `RasterDataset`, which is a subtype of
`AbstractDiskArray{T,3}`, so that users can operate on the array using direct
indexing.
"""
readraster(s::String; kwargs...)::RasterDataset = RasterDataset(read(s; kwargs...))

function DiskArrays.eachchunk(ds::RasterDataset)::DiskArrays.GridChunks
    subchunks = DiskArrays.eachchunk(getband(ds, 1))
    return DiskArrays.GridChunks(ds, (subchunks.chunksize..., 1))
end

DiskArrays.haschunks(::RasterDataset)::DiskArrays.Chunked = DiskArrays.Chunked()
DiskArrays.haschunks(::AbstractRasterBand)::DiskArrays.Chunked = DiskArrays.Chunked()

Base.size(band::AbstractRasterBand)::Tuple{T,T} where {T<:Integer} =
    (width(band), height(band))

function DiskArrays.eachchunk(band::AbstractRasterBand)::DiskArrays.GridChunks
    wI = windows(band)
    cs = (wI.blockiter.xbsize, wI.blockiter.ybsize)
    return DiskArrays.GridChunks(band, cs)
end

function DiskArrays.readblock!(
    band::AbstractRasterBand,
    buffer::T,
    x::AbstractUnitRange,
    y::AbstractUnitRange,
)::T where {T<:Any}
    xoffset, yoffset = first(x) - 1, first(y) - 1
    xsize, ysize = length(x), length(y)
    read!(band, buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end

function DiskArrays.writeblock!(
    band::AbstractRasterBand,
    buffer::T,
    x::AbstractUnitRange,
    y::AbstractUnitRange,
)::T where {T<:Any}
    xoffset, yoffset = first(x) - 1, first(y) - 1
    xsize, ysize = length(x), length(y)
    write!(band, buffer, xoffset, yoffset, xsize, ysize)
    return buffer
end


# AbstractDataset indexing

Base.size(dataset::RasterDataset)::Tuple{Int,Int,Int} = dataset.size

function DiskArrays.readblock!(
    dataset::RasterDataset,
    buffer::T,
    x::AbstractUnitRange,
    y::AbstractUnitRange,
    z::AbstractUnitRange,
)::T where {T<:Any}
    buffer2 = Array(buffer)
    DiskArrays.readblock!(dataset::RasterDataset, buffer2, x, y, z)
    buffer .= buffer2
    return buffer
end

function DiskArrays.readblock!(
    dataset::RasterDataset,
    buffer::T,
    x::AbstractUnitRange,
    y::AbstractUnitRange,
    z::AbstractUnitRange,
)::T where {T<:Array}
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize = length.((x, y))
    read!(dataset.ds, buffer, Cint.(z), xoffset, yoffset, xsize, ysize)
    return buffer
end

function DiskArrays.writeblock!(
    dataset::RasterDataset,
    buffer::T,
    x::AbstractUnitRange,
    y::AbstractUnitRange,
    bands::AbstractUnitRange,
)::T where {T<:Any}
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize = length.((x, y))
    indices = [Cint(i) for i in bands]
    write!(dataset.ds, buffer, indices, xoffset, yoffset, xsize, ysize)
    return buffer
end

Base.Array(dataset::RasterDataset) = dataset[:, :, :]
