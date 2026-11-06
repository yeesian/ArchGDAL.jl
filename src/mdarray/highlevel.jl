# High-level functions

"""
    writemdarray(group::AbstractGroup, name::AbstractString,
                 value::StridedArray, options=nothing)

Create the multidimensional array `name` in the group and write `value`
to it.

The array gets new dimensions named `"<name>.1"`, `"<name>.2"`, etc.
`options` are driver-specific creation options, or `nothing`.
"""
function writemdarray(
    group::AbstractGroup,
    name::AbstractString,
    value::StridedArray{T,D},
    options::OptionList = nothing,
)::Nothing where {T<:NumericAttributeType,D}
    # These dimensions are only needed while creating the array
    dimensions = AbstractDimension[]
    try
        for d in 1:D
            push!(
                dimensions,
                unsafe_createdimension(
                    group,
                    "$name.$d",
                    "",
                    "",
                    size(value, d),
                ),
            )
        end
        extendeddatatypecreate(T) do datatype
            createmdarray(group, name, dimensions, datatype, options) do mdarray
                write(mdarray, value)
                return nothing
            end
        end
    finally
        destroy(dimensions)
    end
    return nothing
end

"""
    readmdarray(group::AbstractGroup, name::AbstractString, options=nothing)

Read the whole multidimensional array `name` of the group into a Julia
array.
"""
function readmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractArray
    openmdarray(group, name, options) do mdarray
        return read(mdarray)
    end
end

"""
    writeattribute(group_or_mdarray, name::AbstractString, value)

Create the attribute `name` of a group or multidimensional array, and write
`value` to it.

`value` can be a string, a number, or a vector of strings or of numbers.
Numbers can be of any type supported by `extendeddatatypecreate`.
"""
function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    value::AbstractString,
)::Nothing
    extendeddatatypecreatestring(length(value)) do datatype
        createattribute(group, name, UInt64[], datatype) do attribute
            write(attribute, value)
            return nothing
        end
    end
end

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    value::NumericAttributeType,
)::Nothing
    extendeddatatypecreate(typeof(value)) do datatype
        createattribute(group, name, UInt64[], datatype) do attribute
            write(attribute, value)
            return nothing
        end
    end
end

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    values::AbstractVector{<:AbstractString},
)::Nothing
    extendeddatatypecreatestring(0) do datatype
        createattribute(
            group,
            name,
            UInt64[length(values)],
            datatype,
        ) do attribute
            write(attribute, values)
            return nothing
        end
    end
end

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    values::AbstractVector{<:NumericAttributeType},
)::Nothing
    extendeddatatypecreate(eltype(values)) do datatype
        createattribute(
            group,
            name,
            UInt64[length(values)],
            datatype,
        ) do attribute
            write(attribute, values)
            return nothing
        end
    end
end

"""
    readattribute(group_or_mdarray, name::AbstractString)

Read the attribute `name` of a group or multidimensional array.

### Returns
A string, a number, or a vector of strings or of numbers.
"""
function readattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
)::AttributeType
    getattribute(group, name) do attribute
        return read(attribute)
    end
end
