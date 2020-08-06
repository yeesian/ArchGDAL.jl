import DiskArrays
const AllowedXY = Union{Integer,Colon,AbstractRange}
const AllowedBand = Union{Integer,Colon,AbstractArray}


"""
struct RasterDataset{T} <: AbstractDiskArray{T,3}

This data structure is returned by the `readraster` function and
is a wrapper for a GDAL dataset. This wrapper is to signal the
user that the dataset should be treated as a 3D AbstractArray
where the first two dimensions correspond to latitude and longitude
and the third dimension corresponds to different raster bands.

As it is a wrapper around a GDAL Dataset, it supports the usual
raster methods for a GDAL Dataset such as `getgeotransform`,
`nraster`, `getband`, `getproj`, `width`, and `height`. As it
is also a subtype of `AbstractDiskArray{T,3}`, it supports the
following additional methods: `readblock!`, `writeblock!`,
`eachchunk`, `haschunks`, etc.
This satisfies the DiskArray interface, allowing us to
be able to index into it like we would an array.

Constructing a RasterDataset will error if the raster bands do not
have all the same size and a common element data type.
"""
struct RasterDataset{T,DS} <: AbstractDiskArray{T,3}
    ds::DS
    size::Tuple{Int,Int,Int}
end
#Forward a few functions
#Here we try to include all functions that are relevant
#for raster-like datasets.
for f in (:getgeotransform, :nraster, :getband, :getproj,
    :width, :height, :destroy, :getdriver, :filelist, :listcapability, 
    :ngcp, :copy, :write, :testcapability, :setproj!, :buildoverviews!)
    eval(:($(f)(x::RasterDataset, args...; kwargs...) = $(f)(x.ds, args...;kwargs...)))
end
#Here we need to special-case, because source and dest might be rasters
copywholeraster(x::RasterDataset,y::AbstractDataset;kwargs...) = copywholeraster(x.ds,y;kwargs...)
copywholeraster(x::RasterDataset,y::RasterDataset;kwargs...) = copywholeraster(x.ds,y.ds;kwargs...)
copywholeraster(x::AbstractDataset,y::RasterDataset;kwargs...) = copywholeraster(x.ds,y.ds;kwargs...)


function RasterDataset(ds::AbstractDataset)
    iszero(nraster(ds)) && throw(ArgumentError("The Dataset does not contain any raster bands"))
    s = _common_size(ds)
    RasterDataset{_dataset_type(ds), typeof(ds)}(ds,s)
end
"""
  _dataset_type(ds::AbstractDataset)

Tries to determine a common dataset type for all the bands
in a raster dataset.
"""
function _dataset_type(ds::AbstractDataset)
    alldatatypes = map(1:nraster(ds)) do i
        b = getband(ds,i)
        pixeltype(b)
    end
    reduce(promote_type,alldatatypes)
end
"""
    _common_size(ds::AbstractDataset)

Determines the size of the raster bands in a dataset and errors
if the sizes are not unique.
"""
function _common_size(ds::AbstractDataset)
    nr = nraster(ds)
    allsizes = map(1:nr) do i
        b = getband(ds,i)
        size(b)
    end
    s = unique(allsizes)
    length(s) == 1 || throw(DimensionMismatch("Can not coerce bands to single dataset, different sizes found"))
    Int.((s[1]...,nr))
end
getband(ds::RasterDataset,i) = getband(ds.ds,i)
unsafe_readraster(args...;kwargs...)  = RasterDataset(unsafe_read(args...;kwargs...))
"""
    ArchGDAL.readraster(s::String;kwargs...)

Opens a GDAL raster dataset. The difference to `ArchGDAL.read` is that
this function returns a `RasterDataset`, which is a subtype of `AbstractDiskArray{T,3}`,
so that users can operate on the array using direct indexing.
"""
readraster(s::String;kwargs...) = RasterDataset(read(s;kwargs...))

function DiskArrays.eachchunk(ds::RasterDataset)
  subchunks = DiskArrays.eachchunk(getband(ds,1))
  DiskArrays.GridChunks(ds,(subchunks.chunksize...,1))
end
DiskArrays.haschunks(::RasterDataset) = DiskArrays.Chunked()
DiskArrays.haschunks(::AbstractRasterBand) = DiskArrays.Chunked()

Base.size(band::AbstractRasterBand) = width(band), height(band)
# Don't know if we need these, commenting out for the moment
#Base.firstindex(band::AbstractRasterBand, d) = 1
#Base.lastindex(band::AbstractRasterBand, d) = size(band)[d]

function DiskArrays.eachchunk(band::AbstractRasterBand)
  wI = windows(band)
  cs = wI.blockiter.xbsize,wI.blockiter.ybsize
  DiskArrays.GridChunks(band,cs)
end

DiskArrays.readblock!(band::AbstractRasterBand, buffer, x::AbstractUnitRange, y::AbstractUnitRange) = begin
    xoffset, yoffset = first(x)-1, first(y)-1
    xsize, ysize = length(x), length(y)
    read!(band, buffer, xoffset, yoffset, xsize, ysize)
end

DiskArrays.writeblock!(band::AbstractRasterBand, value, x::AbstractUnitRange, y::AbstractUnitRange) = begin
    xoffset, yoffset = first(x)-1, first(y)-1
    xsize, ysize = length(x), length(y)
    write!(band, value, xoffset, yoffset, xsize, ysize)
end


# AbstractDataset indexing

Base.size(dataset::RasterDataset) = dataset.size
# Base.firstindex(dataset::AbstractDataset, d) = 1
# Base.lastindex(dataset::AbstractDataset, d) = size(dataset)[d]
function DiskArrays.readblock!(dataset::RasterDataset, buffer, x::AbstractUnitRange, y::AbstractUnitRange, z::AbstractUnitRange)
  buffer2 = Array(buffer)
  DiskArrays.readblock!(dataset::RasterDataset, buffer2, x, y, z)
  buffer .= buffer2
end


DiskArrays.readblock!(dataset::RasterDataset, buffer::Array, x::AbstractUnitRange, y::AbstractUnitRange, z::AbstractUnitRange) = begin
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize= length.((x, y))
    indices  = [Cint(i) for i in z]
    read!(dataset.ds, buffer, indices, xoffset, yoffset, xsize, ysize)
end

DiskArrays.writeblock!(dataset::RasterDataset, value, x::AbstractUnitRange, y::AbstractUnitRange, bands::AbstractUnitRange) = begin
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize= length.((x, y))
    indices  = [Cint(i) for i in bands]
    write!(dataset.ds, value, indices, xoffset, yoffset, xsize, ysize)
end

Array(dataset::RasterDataset) = dataset[:,:,:]
