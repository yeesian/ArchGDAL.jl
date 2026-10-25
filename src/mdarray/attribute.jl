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

"""
    getdimensionssize(attribute::AbstractAttribute)

Return the size of the attribute along each dimension, in Julia order; an
empty tuple for a scalar attribute.
"""
function getdimensionssize(attribute::AbstractAttribute)::NTuple{<:Any,Int}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    sizeptr = GDAL.gdalattributegetdimensionssize(attribute, count)
    size = reverse(ntuple(d -> Int(unsafe_load(sizeptr, d)), count[]))
    GDAL.vsifree(sizeptr)
    return size
end

"""
    readasraw(attribute::AbstractAttribute)

Return the raw bytes of the attribute's value.
"""
function readasraw(attribute::AbstractAttribute)::AbstractVector{UInt8}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    rawptr = GDAL.gdalattributereadasraw(attribute, count)
    raw = UInt8[unsafe_load(rawptr, n) for n in 1:count[]]
    GDAL.gdalattributefreerawresult(attribute, rawptr, count[])
    return raw
end

"""
    read(attribute::AbstractAttribute)

Read the value of the attribute.

### Returns
A string or number for a scalar attribute, and a vector of strings or of
numbers for a 1-dimensional attribute. Compound data types are not
supported yet.
"""
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

"""
    writeraw(attribute::AbstractAttribute, value::AbstractVector{UInt8})

Write raw bytes as the value of the attribute. The number of bytes must
match the attribute's data type and size.

### Returns
`true` on success.
"""
function writeraw(
    attribute::AbstractAttribute,
    value::AbstractVector{UInt8},
)::Bool
    @assert !isnull(attribute)
    return Bool(GDAL.gdalattributewriteraw(attribute, value, length(value)))
end

"""
    write(attribute::AbstractAttribute, value)

Write the value of the attribute.

`value` can be a string or number (for a scalar attribute), or a vector of
strings or of numbers (for a 1-dimensional attribute). Numbers are
converted to the attribute's data type.

### Returns
`true` on success.
"""
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

"""
    getname(attribute::AbstractAttribute)

Return the name of the attribute.
"""
function getname(attribute::AbstractAttribute)::AbstractString
    @assert !isnull(attribute)
    return GDAL.gdalattributegetname(attribute)
end

"""
    getfullname(attribute::AbstractAttribute)

Return the full name of the attribute, including the path of its group or
array, e.g. `"/array/attribute"`.
"""
function getfullname(attribute::AbstractAttribute)::AbstractString
    @assert !isnull(attribute)
    return GDAL.gdalattributegetfullname(attribute)
end

"""
    gettotalelementscount(attribute::AbstractAttribute)

Return the number of elements of the attribute (1 for a scalar attribute).
"""
function gettotalelementscount(attribute::AbstractAttribute)::Int64
    @assert !isnull(attribute)
    return Int64(GDAL.gdalattributegettotalelementscount(attribute))
end

function Base.length(attribute::AbstractAttribute)::Int
    @assert !isnull(attribute)
    return Int(gettotalelementscount(attribute))
end

"""
    getdimensioncount(attribute::AbstractAttribute)

Return the number of dimensions of the attribute (0 for a scalar attribute).
"""
function getdimensioncount(attribute::AbstractAttribute)::Int
    @assert !isnull(attribute)
    return Int(GDAL.gdalattributegetdimensioncount(attribute))
end

Base.ndims(attribute::AbstractAttribute)::Int = getdimensioncount(attribute)

# getdimensions: not available in the C API

function unsafe_getdatatype(
    attribute::AbstractAttribute,
)::AbstractExtendedDataType
    @assert !isnull(attribute)
    return ExtendedDataType(GDAL.gdalattributegetdatatype(attribute))
end

"""
    getdatatype(attribute::AbstractAttribute)

Return the data type of the attribute.
"""
function getdatatype(attribute::AbstractAttribute)::AbstractExtendedDataType
    @assert !isnull(attribute)
    return IExtendedDataType(GDAL.gdalattributegetdatatype(attribute))
end

# getblocksize, getprocessingchunksize: not available in the C API

# processperchunk

"""
    rename!(attribute::AbstractAttribute, newname::AbstractString)

Rename the attribute. Not all drivers support renaming.

### Returns
`true` on success.
"""
function rename!(attribute::AbstractAttribute, newname::AbstractString)::Bool
    @assert !isnull(attribute)
    return GDAL.gdalattributerename(attribute, newname)
end
