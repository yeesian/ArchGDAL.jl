Base.start(layer::FeatureLayer) = [Feature(0)]
Base.next(layer::FeatureLayer, state::Vector{Feature}) = (state[1], state)
Base.eltype(layer::FeatureLayer) = Feature
Base.length(layer::FeatureLayer) = nfeature(layer, true)

function Base.done(layer::FeatureLayer, state::Vector{Feature})
    destroy(state[1])
    ptr = @gdal(OGR_L_GetNextFeature::GDALFeature, layer.ptr::GDALFeatureLayer)
    state[1] = Feature(ptr)
    
    if ptr == C_NULL
        resetreading!(layer)
        return true
    else
        return false
    end
end

struct BlockIterator
    rows::Cint
    cols::Cint
    ni::Cint
    nj::Cint
    n::Cint
    xbsize::Cint
    ybsize::Cint
end
function blocks(raster::RasterBand)
    (xbsize, ybsize) = getblocksize(raster)
    rows = height(raster)
    cols = width(raster)
    ni = ceil(Cint, rows / ybsize)
    nj = ceil(Cint, cols / xbsize)
    BlockIterator(rows, cols, ni, nj, ni * nj, xbsize, ybsize)
end
Base.start(obj::BlockIterator) = 0
function Base.next(obj::BlockIterator, iter::Int)
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
    (((i, j), (nrows, ncols)), iter + 1)
end
Base.done(obj::BlockIterator, iter::Int) = (iter == obj.n)

struct WindowIterator
    blockiter::BlockIterator
end
function windows(raster::RasterBand)
    WindowIterator(blocks(raster))
end
Base.start(obj::WindowIterator) = Base.start(obj.blockiter)
function Base.next(obj::WindowIterator, iter::Int)
    handle = obj.blockiter
    (((i, j), (nrows, ncols)), iter) = Base.next(handle, iter)
    (((1:ncols) + j * handle.xbsize, (1:nrows) + i * handle.ybsize), iter)
end
Base.done(obj::WindowIterator, iter::Int) = Base.done(obj.blockiter, iter)

mutable struct BufferIterator{T <: Real}
    raster::RasterBand
    w::WindowIterator
    buffer::Array{T, 2}
end
function bufferwindows(raster::RasterBand)
    BufferIterator(
        raster,
        windows(raster),
        Array{getdatatype(raster)}(getblocksize(raster)...)
    )
end
Base.start(obj::BufferIterator) = Base.start(obj.w)
function Base.next(obj::BufferIterator, iter::Int)
    ((cols, rows), iter) = Base.next(obj.w, iter)
    rasterio!(obj.raster, obj.buffer, rows, cols)
    (obj.buffer[1:length(cols), 1:length(rows)], iter)
end
Base.done(obj::BufferIterator, iter::Int) = Base.done(obj.w, iter)