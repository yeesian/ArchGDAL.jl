function Base.iterate(
    layer::AbstractFeatureLayer,
    state::Integer = 0,
)::Union{Nothing,Tuple{Feature,Int64}}
    layer.ptr == C_NULL && return nothing
    state == 0 && resetreading!(layer)
    ptr = GDAL.ogr_l_getnextfeature(layer.ptr)
    return if ptr == C_NULL
        resetreading!(layer)
        nothing
    else
        (Feature(ptr), state + 1)
    end
end

Base.eltype(layer::AbstractFeatureLayer)::DataType = Feature

Base.IteratorSize(::Type{<:AbstractFeatureLayer}) = Base.SizeUnknown()

Base.length(layer::AbstractFeatureLayer)::Integer = nfeature(layer, true)

struct BlockIterator{T<:Integer}
    rows::T
    cols::T
    ni::T
    nj::T
    n::T
    xbsize::T
    ybsize::T
end

function blocks(
    ::Type{T},
    raster::AbstractRasterBand,
)::BlockIterator{T} where {T<:Integer}
    (xbsize, ybsize) = blocksize(raster)
    rows = T(height(raster))
    cols = T(width(raster))
    ni = ceil(T, rows / ybsize)
    nj = ceil(T, cols / xbsize)
    return BlockIterator{T}(rows, cols, ni, nj, ni * nj, xbsize, ybsize)
end

function blocks(raster::AbstractRasterBand)::BlockIterator{Int64}
    return blocks(Int64, raster)
end

function Base.iterate(
    obj::BlockIterator{T},
    iter::T = 0,
)::Union{Nothing,Tuple{Tuple{Tuple{T,T},Tuple{T,T}},T}} where {T}
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
    return (((i, j), (nrows, ncols)), iter + 1)
end

struct WindowIterator{T<:Integer}
    blockiter::BlockIterator{T}
end
Base.size(i::WindowIterator) = (i.blockiter.ni, i.blockiter.nj)
Base.length(i::WindowIterator) = i.blockiter.n

function Base.IteratorSize(::Type{WindowIterator{T}}) where {T<:Integer}
    return Base.HasShape{2}()
end

function Base.IteratorEltype(::Type{WindowIterator{T}}) where {T<:Integer}
    return Base.HasEltype()
end

function Base.eltype(::WindowIterator{T})::DataType where {T<:Integer}
    return Tuple{UnitRange{T},UnitRange{T}}
end

function windows(
    ::Type{T},
    raster::AbstractRasterBand,
)::WindowIterator{T} where {T<:Integer}
    return WindowIterator{T}(blocks(T, raster))
end

windows(raster::AbstractRasterBand)::WindowIterator{Int64} =
    windows(Int64, raster)

function Base.iterate(
    obj::WindowIterator{T},
    iter::T = 0,
)::Union{Nothing,Tuple{NTuple{2,UnitRange{T}},T}} where {T<:Integer}
    handle = obj.blockiter
    next = Base.iterate(handle, iter)
    next == nothing && return nothing
    (((i, j), (nrows, ncols)), iter) = next
    return (
        ((1:ncols) .+ j * handle.xbsize, (1:nrows) .+ i * handle.ybsize),
        iter,
    )
end

mutable struct BufferIterator{R<:Real,T<:Integer}
    raster::AbstractRasterBand
    w::WindowIterator{T}
    buffer::Matrix{R}
end

function bufferwindows(
    ::Type{T},
    raster::AbstractRasterBand,
)::BufferIterator{pixeltype(raster),T} where {T<:Integer}
    return BufferIterator{pixeltype(raster),T}(
        raster,
        windows(T, raster),
        Matrix{pixeltype(raster)}(undef, blocksize(raster)...),
    )
end

function bufferwindows(
    raster::AbstractRasterBand,
)::BufferIterator{pixeltype(raster),Int64}
    return bufferwindows(Int64, raster)
end

function Base.iterate(
    obj::BufferIterator{R,T},
    iter::T = 0,
)::Union{Nothing,Tuple{Matrix{R},T}} where {R<:Real,T<:Integer}
    next = Base.iterate(obj.w, iter)
    next == nothing && return nothing
    ((cols, rows), iter) = next
    rasterio!(obj.raster, obj.buffer, rows, cols)
    return (obj.buffer[1:length(cols), 1:length(rows)], iter)
end
