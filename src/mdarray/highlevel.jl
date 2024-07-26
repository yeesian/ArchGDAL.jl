# High-level functions

function writemdarray(
    group::AbstractGroup,
    name::AbstractString,
    value::StridedArray{T,D},
    options::OptionList = nothing,
)::Nothing where {T<:NumericAttributeType,D}
    dimensions = AbstractDimension[
        createdimension(group, "$name.$d", "", "", size(value, d)) for
        d in D:-1:1
    ]
    extendeddatatypecreate(T) do datatype
        createmdarray(group, name, dimensions, datatype, options) do mdarray
            write(mdarray, value)
            return nothing
        end
    end
end

function readmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractArray
    openmdarray(group, name, options) do mdarray
        return read(mdarray)
    end
end

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

function readattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
)::AttributeType
    getattribute(group, name) do attribute
        return read(attribute)
    end
end
