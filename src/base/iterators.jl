function Base.iterate(layer::AbstractFeatureLayer, state::Int=0)
    layer.ptr == C_NULL && return nothing
    state == 0 && resetreading!(layer)
    ptr = GDAL.getnextfeature(layer.ptr)
    if ptr == C_NULL
        resetreading!(layer)
        return nothing
    end
    (Feature(ptr), state+1)
end

Base.eltype(layer::AbstractFeatureLayer) = Feature

Base.length(layer::AbstractFeatureLayer) = nfeature(layer, true)

struct BlockIterator
    rows::Cint
    cols::Cint
    ni::Cint
    nj::Cint
    n::Cint
    xbsize::Cint
    ybsize::Cint
end

function blocks(raster::AbstractRasterBand)
    (xbsize, ybsize) = blocksize(raster)
    rows = height(raster)
    cols = width(raster)
    ni = ceil(Cint, rows / ybsize)
    nj = ceil(Cint, cols / xbsize)
    BlockIterator(rows, cols, ni, nj, ni * nj, xbsize, ybsize)
end

function Base.iterate(obj::BlockIterator, iter::Int=0)
    iter == obj.n && return nothing
    j = floor(Int, iter / obj.ni)
    i = iter % obj.ni
    nrows = if (i + 1) * obj.ybsize < obj.rows
        obj.ybsize
    else
        obj.rows - i * obj.ybsize
    end
    ncols = if (j + 1) * obj.xbsize < obj.cols
        obj.xbsize
    else
        obj.cols - j * obj.xbsize
    end
    (((i, j), (nrows, ncols)), iter+1)
end

struct WindowIterator
    blockiter::BlockIterator
end

windows(raster::AbstractRasterBand) = WindowIterator(blocks(raster))

function Base.iterate(obj::WindowIterator, iter::Int=0)
    handle = obj.blockiter
    next = Base.iterate(handle, iter)
    next == nothing && return nothing
    (((i, j), (nrows, ncols)), iter) = next
    (((1:ncols) .+ j * handle.xbsize, (1:nrows) .+ i * handle.ybsize), iter)
end

mutable struct BufferIterator{T <: Real}
    raster::AbstractRasterBand
    w::WindowIterator
    buffer::Array{T, 2}
end

function bufferwindows(raster::AbstractRasterBand)
    BufferIterator(
        raster,
        windows(raster),
        Array{getdatatype(raster)}(undef, blocksize(raster)...)
    )
end

function Base.iterate(obj::BufferIterator, iter::Int=0)
    next = Base.iterate(obj.w, iter)
    next == nothing && return nothing
    ((cols, rows), iter) = next
    rasterio!(obj.raster, obj.buffer, rows, cols)
    (obj.buffer[1:length(cols), 1:length(rows)], iter)
end
