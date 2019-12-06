Base.size(dataset::Dataset) = begin
    band = getband(dataset, 1)
    width(band), height(band), nraster(dataset)
end

const AllowedXY = Union{Integer,Colon,AbstractRange}
const AllowedBand = Union{Integer,Colon,AbstractArray}

Base.getindex(dataset::Dataset, x::AllowedXY, y::AllowedXY, bands::AllowedBand) = begin
    # Convert colons to ranges
    x, y, bands = map(convertcolon, (x, y, bands), size(dataset))
    buffer = Array{getdatatype(getband(dataset, 1)),3}(undef, length.((x, y, bands))...)
    xoffset, yoffset = first(x) - 1, first(y) - 1
    xsize, ysize = length(x), length(y)
    indices = bandindices(bands)
    read!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
    # Drop dimensions of integer indices
    reshape(buffer, dropint(x, y, bands)...)
end

Base.getindex(dataset::Dataset, x::Int, y::Int, band::Int) = begin
    indices = bandindices(band)
    buffer = Array{getdatatype(getband(dataset, 1)),3}(undef, 1, 1, 1)
    xsize = ysize = 1
    read!(dataset, buffer, indices, x - 1, y - 1, xsize, ysize)
    # Indexing with all ints returns a scalar
    buffer[1]
end

dropint(x::Integer, args...) = dropint(args...)
dropint(x::AbstractRange, args...) = (length(x), dropint(args...)...)
dropint() = ()

convertcolon(i::Colon, sze) = 1:sze
convertcolon(i, sze) = i

bandindices(band::Int) = Cint[band]
bandindices(bands::AbstractArray) = Cint[b for b in bands]
