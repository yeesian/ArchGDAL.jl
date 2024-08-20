# GDALAttribute

const NumericAttributeType = Union{
    Int8,
    Int16,
    Int32,
    Int64,
    UInt8,
    UInt16,
    UInt32,
    UInt64,
    Float32,
    Float64,
    Complex{Int16},
    Complex{Int32},
    Complex{Float32},
    Complex{Float64},
}
const ScalarAttributeType = Union{AbstractString,NumericAttributeType}
const AttributeType =
    Union{ScalarAttributeType,AbstractVector{<:ScalarAttributeType}}

function getdimensionssize(attribute::AbstractAttribute)::NTuple{<:Any,Int}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    sizeptr = GDAL.gdalattributegetdimensionssize(attribute, count)
    size = ntuple(n -> unsafe_load(sizeptr, n), count[])
    GDAL.vsifree(sizeptr)
    return Int.(size)
end

function readasraw(attribute::AbstractAttribute)::AbstractVector{UInt8}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    rawptr = GDAL.gdalattributereadasraw(attribute, count)
    raw = UInt8[unsafe_load(rawptr, n) for n in 1:count[]]
    GDAL.gdalattributefreerawresult(rawptr, count[])
    return raw
end

function read(attribute::AbstractAttribute)::AttributeType
    @assert !isnull(attribute)
    rank = getdimensioncount(attribute)
    length = gettotalelementscount(attribute)
    rank == 0 && @assert length == 1
    datatype = getdatatype(attribute)
    class = getclass(datatype)

    if class == GDAL.GEDTC_NUMERIC
        # Read a numeric attribute
        T = convert(DataType, getnumericdatatype(datatype))
        @assert T <: NumericAttributeType
        count = Ref{Csize_t}()
        ptr = GDAL.gdalattributereadasraw(attribute, count)
        @assert count[] == length * sizeof(T)
        if rank == 0
            # Read a scalar
            value = unsafe_load(convert(Ptr{T}, ptr))
            GDAL.gdalattributefreerawresult(attribute, ptr, count[])
            return value
        else
            # Read a vector
            values = T[unsafe_load(convert(Ptr{T}, ptr), n) for n in 1:length]
            GDAL.gdalattributefreerawresult(attribute, ptr, count[])
            return values
        end

    elseif class == GDAL.GEDTC_STRING
        # Read a string attribute
        if rank == 0
            return GDAL.gdalattributereadasstring(attribute)
        else
            return GDAL.gdalattributereadasstringarray(attribute)
        end

    elseif class == GDAL.GEDTC_COMPOUND
        # Read a compound attribute
        error("unimplemented")
    else
        error("internal error")
    end
end

function writerraw(
    attribute::AbstractAttribute,
    value::AbstractVector{UInt8},
)::Bool
    @assert !isnull(attribute)
    return Bool(GDAL.gdalattributewriteraw(attribute, value, length(value)))
end

function write(attribute::AbstractAttribute, value::AbstractString)::Bool
    @assert !isnull(attribute)
    return Bool(GDAL.gdalattributewritestring(attribute, value))
end

function write(attribute::AbstractAttribute, value::NumericAttributeType)::Bool
    @assert !isnull(attribute)
    rank = getdimensioncount(attribute)
    @assert rank == 0
    length = gettotalelementscount(attribute)
    @assert length == 1
    datatype = getdatatype(attribute)
    class = getclass(datatype)
    @assert class == GDAL.GEDTC_NUMERIC
    T = convert(DataType, getnumericdatatype(datatype))

    valueT = convert(T, value)::T
    return Bool(
        GDAL.gdalattributewriteraw(attribute, Ref(valueT), sizeof(valueT)),
    )
end

function write(
    attribute::AbstractAttribute,
    values::AbstractVector{<:AbstractString},
)::Bool
    @assert !isnull(attribute)
    return Bool(
        GDAL.gdalattributewritestringarray(
            attribute,
            CSLConstListWrapper(values),
        ),
    )
end

function write(
    attribute::AbstractAttribute,
    values::AbstractVector{<:NumericAttributeType},
)::Bool
    @assert !isnull(attribute)
    rank = getdimensioncount(attribute)
    @assert rank == 1
    length = gettotalelementscount(attribute)
    datatype = getdatatype(attribute)
    class = getclass(datatype)
    @assert class == GDAL.GEDTC_NUMERIC
    T = convert(DataType, getnumericdatatype(datatype))

    valuesT = convert(Vector{T}, values)::Vector{T}
    return Bool(GDAL.gdalattributewriteraw(attribute, valuesT, sizeof(valuesT)))
end

################################################################################

function getname(attribute::AbstractAttribute)::AbstractString
    @assert !isnull(attribute)
    return GDAL.gdalattributegetname(attribute)
end

function getfullname(attribute::AbstractAttribute)::AbstractString
    @assert !isnull(attribute)
    return GDAL.gdalattributegetfullname(attribute)
end

function gettotalelementscount(attribute::AbstractAttribute)::Int64
    @assert !isnull(attribute)
    return Int64(GDAL.gdalattributegettotalelementscount(attribute))
end

function Base.length(attribute::AbstractAttribute)
    @assert !isnull(attribute)
    return Int(gettotalelementscount(attribute))
end

function getdimensioncount(attribute::AbstractAttribute)::Int
    @assert !isnull(attribute)
    return Int(GDAL.gdalattributegetdimensioncount(attribute))
end

Base.ndims(attribute::AbstractAttribute)::Int = getdimensioncount(attribute)

function getdimensions(
    attribute::AbstractAttribute,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(attribute)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr =
        GDAL.gdalattributegetdimensions(attribute, dimensionscountref)
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionshptr, n), attribute.dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_getdimensions(
    attribute::AbstractAttribute,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(attribute)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr =
        GDAL.gdalattributegetdimensions(attribute, dimensionscountref)
    dimensions = AbstractDimension[
        Dimension(unsafe_load(dimensionshptr, n), attribute.dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_getdatatype(
    attribute::AbstractAttribute,
)::AbstractExtendedDataType
    @assert !isnull(attribute)
    return ExtendedDataType(GDAL.gdalattributegetdatatype(attribute))
end

function getdatatype(attribute::AbstractAttribute)::AbstractExtendedDataType
    @assert !isnull(attribute)
    return IExtendedDataType(GDAL.gdalattributegetdatatype(attribute))
end

function getblocksize(
    attribute::AbstractAttribute,
    options::OptionList = nothing,
)::AbstractVector{Int64}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    blocksizeptr = GDAL.gdalattributegetblocksize(
        attribute,
        count,
        CSLConstListWrapper(options),
    )
    blocksize = Int64[unsafe_load(blocksizeptr, n) for n in 1:count[]]
    GDAL.vsifree(blocksizeptr)
    return blocksize
end

function getprocessingchunksize(
    attribute::AbstractAttribute,
    maxchunkmemory::Integer,
)::AbstractVector{Int64}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    chunksizeptr = GDAL.gdalattributegetprocessingchunksize(
        attribute,
        count,
        maxchunkmemory,
    )
    chunksize = Int64[unsafe_load(chunksizeptr, n) for n in 1:count[]]
    GDAL.vsifree(chunksizeptr)
    return chunksize
end

# processperchunk

function rename!(attribute::AbstractAttribute, newname::AbstractString)::Bool
    @assert !isnull(attribute)
    return GDAL.gdalattributerename(attribute, newname)
end
