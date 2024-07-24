# GDALAttribute

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

function readasstring(attribute::AbstractAttribute)::String
    @assert !isnull(attribute)
    stringptr = GDAL.gdalattributereadasstring(attribute)
    string = unsafe_string(stringptr)
    # do not free
    return string
end

function readasint(attribute::AbstractAttribute)::Int32
    @assert !isnull(attribute)
    return GDAL.gdalattributereadasint(attribute)
end

function readasint64(attribute::AbstractAttribute)::Int64
    @assert !isnull(attribute)
    return GDAL.gdalattributereadasint64(attribute)
end

function readasdouble(attribute::AbstractAttribute)::Float64
    @assert !isnull(attribute)
    return GDAL.gdalattributereadasdouble(attribute)
end

function readasstringarray(attribute::AbstractAttribute)::Vector{String}
    @assert !isnull(attribute)
    return GDAL.gdalattributereadasstringarray(attribute)
end

function readasintarray(attribute::AbstractAttribute)::Vector{Int32}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalattributereadasintarray(attribute, count)
    ptr == C_NULL && return Int32[]
    values = Int32[unsafe_load(ptr, n) for n in 1:count[]]
    GDAL.vsifree(ptr)
    return values
end

function readasint64array(attribute::AbstractAttribute)::Vector{Int64}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalattributereadasint64array(attribute, count)
    ptr == C_NULL && return Int64[]
    values = Int64[unsafe_load(ptr, n) for n in 1:count[]]
    GDAL.vsifree(ptr)
    return values
end

function readasdoublearray(attribute::AbstractAttribute)::Vector{Float64}
    @assert !isnull(attribute)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalattributereadasdoublearray(attribute, count)
    ptr == C_NULL && return Float64[]
    values = Float64[unsafe_load(ptr, n) for n in 1:count[]]
    GDAL.vsifree(ptr)
    return values
end

read(::Type{String}, attribute)::String = readasstring(attribute)
read(::Type{Int32}, attribute)::Int32 = readasint(attribute)
read(::Type{Int64}, attribute)::Int64 = readasint64(attribute)
read(::Type{Float64}, attribute)::Float64 = readasdouble(attribute)
read(::Type{Vector{String}}, attribute)::Vector{String} =
    readasstringarray(attribute)
read(::Type{Vector{Int32}}, attribute)::Vector{Int32} =
    readasintarray(attribute)
read(::Type{Vector{Int64}}, attribute)::Vector{Int64} =
    readasint64array(attribute)
read(::Type{Vector{Float64}}, attribute)::Vector{Float64} =
    readasdoublearray(attribute)

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

function write(attribute::AbstractAttribute, value::Int32)::Bool
    @assert !isnull(attribute)
    return Bool(GDAL.gdalattributewriteint(attribute, value))
end

function write(attribute::AbstractAttribute, value::Int64)::Bool
    @assert !isnull(attribute)
    return Bool(GDAL.gdalattributewriteint64(attribute, value))
end

function write(attribute::AbstractAttribute, value::Float64)::Bool
    @assert !isnull(attribute)
    return Bool(GDAL.gdalattributewritedouble(attribute, value))
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
    values::AbstractVector{Int32},
)::Bool
    @assert !isnull(attribute)
    return Bool(
        GDAL.gdalattributewriteintarray(attribute, values, length(values)),
    )
end

function write(
    attribute::AbstractAttribute,
    values::AbstractVector{Int64},
)::Bool
    @assert !isnull(attribute)
    return Bool(
        GDAL.gdalattributewriteint64array(attribute, values, length(values)),
    )
end

function write(
    attribute::AbstractAttribute,
    values::AbstractVector{Float64},
)::Bool
    @assert !isnull(attribute)
    return Bool(
        GDAL.gdalattributewritedoublearray(attribute, values, length(values)),
    )
end

################################################################################

# For GDALGroup

function unsafe_getattribute(
    group::AbstractGroup,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(group)
    return Attribute(
        GDAL.gdalgroupgetattribute(group, name),
        group.dataset.value,
    )
end

function getattribute(
    group::AbstractGroup,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(group)
    return IAttribute(
        GDAL.gdalgroupgetattribute(group, name),
        group.dataset.value,
    )
end

function unsafe_getattributes(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(group)
    count = Ref{Csize_t}()
    ptr =
        GDAL.gdalgroupgetattributes(group, count, CSLConstListWrapper(options))
    dataset = group.dataset.value
    attributes = AbstractAttribute[
        Attribute(unsafe_load(ptr, n), dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

function getattributes(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(group)
    count = Ref{Csize_t}()
    ptr =
        GDAL.gdalgroupgetattributes(group, count, CSLConstListWrapper(options))
    dataset = group.dataset.value
    attributes = AbstractAttribute[
        IAttribute(unsafe_load(ptr, n), dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

function unsafe_createattribute(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(group)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    return Attribute(
        GDAL.gdalgroupcreateattribute(
            group,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function createattribute(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(group)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    return IAttribute(
        GDAL.gdalgroupcreateattribute(
            group,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function deleteattribute(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(group)
    return GDAL.gdalgroupdeleteattribute(
        group,
        name,
        CSLConstListWrapper(options),
    )
end

################################################################################

# For GDALMDArray

function unsafe_getattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(mdarray)
    return Attribute(
        GDAL.gdalmdarraygetattribute(mdarray, name),
        mdarray.dataset.value,
    )
end

function getattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(mdarray)
    return IAttribute(
        GDAL.gdalmdarraygetattribute(mdarray, name),
        mdarray.dataset.value,
    )
end

function unsafe_getattributes(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalmdarraygetattributes(
        mdarray,
        count,
        CSLConstListWrapper(options),
    )
    dataset = mdarray.dataset.value
    attributes = AbstractAttribute[
        Attribute(unsafe_load(ptr, n), dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

function getattributes(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalmdarraygetattributes(
        mdarray,
        count,
        CSLConstListWrapper(options),
    )
    dataset = mdarray.dataset.value
    attributes = AbstractAttribute[
        IAttribute(unsafe_load(ptr, n), dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

function unsafe_createattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(mdarray)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    return Attribute(
        GDAL.gdalmdarraycreateattribute(
            mdarray,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            CSLConstListWrapper(options),
        ),
        mdarray.dataset.value,
    )
end

function createattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(mdarray)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    return IAttribute(
        GDAL.gdalmdarraycreateattribute(
            mdarray,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            CSLConstListWrapper(options),
        ),
        mdarray.dataset.value,
    )
end

function deleteattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraydeleteattribute(
        mdarray,
        name,
        CSLConstListWrapper(options),
    )
end
