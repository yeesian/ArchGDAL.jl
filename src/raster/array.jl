import DiskArrays: eachchunk, GridChunks
import DiskArrays
const AllowedXY = Union{Integer,Colon,AbstractRange}
const AllowedBand = Union{Integer,Colon,AbstractArray}


# Define a RasterDataset type
struct RasterDataset{T,DS} <: AbstractDiskArray{T,3}
    ds::DS
    size::Tuple{Int,Int,Int}
end
function RasterDataset(ds::AbstractDataset)
    iszero(nraster(ds)) && throw(ArgumentError("The Dataset does not contain any raster bands"))
    s = _common_size(ds)
    RasterDataset{_dataset_type(ds), typeof(ds)}(ds,s)
end
function _dataset_type(ds::AbstractDataset)
  alldatatypes = map(1:nraster(ds)) do i
    b = getband(ds,i)
    pixeltype(b)
  end
  reduce(promote_type,alldatatypes)
end
function _common_size(ds::AbstractDataset)
  nr = nraster(ds)
  allsizes = map(1:nr) do i
    b = getband(ds,i)
    size(b)
  end
  s = unique(allsizes)
  length(s) == 1 || throw(DimensionMismatch("Can not coerce bands to single dataset, different sizes found"))
  Int64.((s[1]...,nr))
end
getband(ds::RasterDataset,i) = getband(ds.ds,i)
unsafe_readraster(args...;kwargs...)  = RasterDataset(unsafe_read(args...;kwargs...))
destroy(ds::RasterDataset) = destroy(ds.ds)
height(ds::RasterDataset) = height(ds.ds)
width(ds::RasterDataset) = width(ds.ds)
function eachchunk(ds::RasterDataset)
  subchunks = eachchunk(getband(ds,1))
  GridChunks(ds,(subchunks.chunksize...,1))
end
DiskArrays.haschunks(::RasterDataset) = DiskArrays.Chunked()
DiskArrays.haschunks(::AbstractRasterBand) = DiskArrays.Chunked()
# AbstractRasterBand indexing

Base.size(band::AbstractRasterBand) = width(band), height(band)
# Don't know if we need these, commenting out for the moment
#Base.firstindex(band::AbstractRasterBand, d) = 1
#Base.lastindex(band::AbstractRasterBand, d) = size(band)[d]

function eachchunk(band::AbstractRasterBand)
  wI = windows(band)
  cs = wI.blockiter.xbsize,wI.blockiter.ybsize
  GridChunks(band,cs)
end

DiskArrays.readblock!(band::AbstractRasterBand, buffer, x, y) = begin
    # Calculate `read!` args and read
    xoffset, yoffset = first(x)-1, first(y)-1
    xsize, ysize = length(x), length(y)
    read!(band, buffer, xoffset, yoffset, xsize, ysize)
end

DiskArrays.writeblock!(band::AbstractRasterBand, value, x, y) = begin
    # Calculate `read!` args and read
    xoffset, yoffset = first(x)-1, first(y)-1
    xsize, ysize = length(x), length(y)
    write!(band, value, xoffset, yoffset, xsize, ysize)
end


# AbstractDataset indexing

Base.size(dataset::RasterDataset) = dataset.size
# Base.firstindex(dataset::AbstractDataset, d) = 1
# Base.lastindex(dataset::AbstractDataset, d) = size(dataset)[d]

DiskArrays.readblock!(dataset::RasterDataset, buffer, x, y, z) = begin
    # Calculate `read!` args and read
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize= length.((x, y))
    indices  = [Cint(i) for i in z]
    read!(dataset.ds, buffer, indices, xoffset, yoffset, xsize, ysize)
end

DiskArrays.writeblock!(dataset::RasterDataset, value, x, y, bands) = begin
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize= length.((x, y))
    indices  = [Cint(i) for i in bands]
    write!(dataset.ds, value, indices, xoffset, yoffset, xsize, ysize)
end

# Index conversion utilities

Array(dataset::RasterDataset) = dataset[:,:,:]
