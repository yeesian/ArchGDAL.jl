const AllowedXY = Union{Integer,Colon,AbstractRange}
const AllowedBand = Union{Integer,Colon,AbstractArray}


# RasterBand indexing

Base.size(band::RasterBand) = width(band), height(band)
Base.firstindex(band::RasterBand, d) = 1
Base.lastindex(band::RasterBand, d) = size(band)[d]

Base.getindex(band::RasterBand, x::AllowedXY, y::AllowedXY) = begin
    I = Base.to_indices(band, (x, y))
    buffer = Array{getdatatype(band),2}(undef, length.(I)...)
    # Calculate `read!` args and read
    xoffset, yoffset = first.(I) .- 1
    xsize, ysize = length.(I)
    read!(band, buffer, xoffset, yoffset, xsize, ysize)
    # Drop dimensions of integer indices
    dimsize = map(length, _dropint(I...))
    if dimsize == ()
        return buffer[1]
    else
        return reshape(buffer, dimsize...)
    end
end

Base.setindex!(band::RasterBand, value, x::AllowedXY, y::AllowedXY) = begin
    I = Base.to_indices(band, (x, y))
    if value isa AbstractArray
        Base.setindex_shape_check(value, length.(I)...)
        value = reshape(value, length.(I))
    else
        value = reshape([value], 1, 1)
    end
    # Calculate `write!` args and write
    xoffset, yoffset = first.(I) .- 1
    xsize, ysize = length.(I)
    write!(band, value, xoffset, yoffset, xsize, ysize)
end


# Dataset indexing

Base.size(dataset::Dataset) = (size(getband(dataset, 1))..., nraster(dataset))
Base.firstindex(dataset::Dataset, d) = 1
Base.lastindex(dataset::Dataset, d) = size(dataset)[d]

Base.getindex(dataset::Dataset, x::AllowedXY, y::AllowedXY, bands::AllowedBand=1) = begin
    I = x, y, bands = Base.to_indices(dataset, (x, y, bands))
    buffer = Array{getdatatype(getband(dataset, 1)),3}(undef, length.(I)...)
    # Calculate `read!` args and read
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize = length.((x, y))
    indices = _bandindices(bands)
    read!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
    # Drop dimensions of integer indices
    dimsize = map(length, _dropint(I...))
    if dimsize == ()
        return buffer[1]
    else
        return reshape(buffer, dimsize...)
    end
end

Base.setindex!(dataset::Dataset, value, x::AllowedXY, y::AllowedXY, bands::AllowedBand=1) = begin
    I = x, y, bands = Base.to_indices(dataset, (x, y, bands))
    if value isa AbstractArray
        Base.setindex_shape_check(value, length.((x, y, bands))...)
        value = reshape(value, length.(I))
    else
        value = reshape([value], 1, 1, 1)
    end
    # Calculate `write!` args and write
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize = length.((x, y))
    indices = _bandindices(bands)
    write!(dataset, value, indices, xoffset, yoffset, xsize, ysize)
end

# Index conversion utilities

_dropint(x::Integer, args...) = _dropint(args...)
_dropint(x::AbstractRange, args...) = (x, _dropint(args...)...)
_dropint() = ()

_bandindices(band::Integer) = Cint[band]
_bandindices(bands::AbstractArray) = Cint[b for b in bands]

