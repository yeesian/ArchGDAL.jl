const AllowedXY = Union{Integer,Colon,AbstractRange}
const AllowedBand = Union{Integer,Colon,AbstractArray}


# RasterBand indexing

Base.size(band::RasterBand) = width(band), height(band)

Base.getindex(band::RasterBand, x::AllowedXY, y::AllowedXY) = begin
    I = map(colon2range, (x, y), size(band))
    buffer = Array{getdatatype(band),2}(undef, length.(I)...)
    # Calculate `read!` args and read
    xoffset, yoffset = first.(I) .- 1
    xsize, ysize = length.(I)
    read!(band, buffer, xoffset, yoffset, xsize, ysize)
    # Drop dimensions of integer indices
    dimsize = map(length, dropint(I...))
    if dimsize == ()
        return buffer[1]
    else
        return reshape(buffer, dimsize...)
    end
end

Base.setindex!(band::RasterBand, value, x::AllowedXY, y::AllowedXY) = begin
    I = map(colon2range, (x, y), size(band))
    if value isa AbstractArray
        if size(value) != length.(I)
            throw(ArgumentError("size of value $(size(value)) does not match indices $I"))
        end
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

Base.getindex(dataset::Dataset, x::AllowedXY, y::AllowedXY, bands::AllowedBand=1) = begin
    I = x, y, bands = map(colon2range, (x, y, bands), size(dataset))
    buffer = Array{getdatatype(getband(dataset, 1)),3}(undef, length.(I)...)
    # Calculate `read!` args and read
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize = length.((x, y))
    indices = bandindices(bands)
    read!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
    # Drop dimensions of integer indices
    dimsize = map(length, dropint(I...))
    if dimsize == ()
        return buffer[1]
    else
        return reshape(buffer, dimsize...)
    end
end

Base.setindex!(dataset::Dataset, value, x::AllowedXY, y::AllowedXY, bands::AllowedBand=1) = begin
    # Convert colons to ranges
    I = x, y, bands = map(colon2range, (x, y, bands), size(dataset))
    if value isa AbstractArray
        if size(value) != length.(I)
            throw(ArgumentError("size of value $(size(value)) does not match indices $I"))
        end
    else
        value = reshape([value], 1, 1, 1)
    end
    # Calculate `write!` args and write
    xoffset, yoffset = first.((x, y)) .- 1
    xsize, ysize = length.((x, y))
    indices = bandindices(bands)
    write!(dataset, value, indices, xoffset, yoffset, xsize, ysize)
end


# Index conversion utilities

dropint(x::Integer, args...) = dropint(args...)
dropint(x::AbstractRange, args...) = (x, dropint(args...)...)
dropint() = ()

colon2range(i::Colon, sze) = 1:sze
colon2range(i, sze) = i

bandindices(band::Integer) = Cint[band]
bandindices(bands::AbstractArray) = Cint[b for b in bands]
