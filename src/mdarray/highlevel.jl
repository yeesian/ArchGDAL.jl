# High-level functions

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    value::AbstractString,
)::Bool
    extendeddatatypecreatestring(length(value)) do datatype
        createattribute(group, name, UInt64[], datatype) do attribute
            return write(attribute, value)
        end
    end
end

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    value::NumericAttributeType,
)::Bool
    extendeddatatypecreate(typeof(value)) do datatype
        createattribute(group, name, UInt64[], datatype) do attribute
            return write(attribute, value)
        end
    end
end

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    values::AbstractVector{<:AbstractString},
)::Bool
    extendeddatatypecreatestring(0) do datatype
        createattribute(
            group,
            name,
            UInt64[length(values)],
            datatype,
        ) do attribute
            return write(attribute, values)
        end
    end
end

function writeattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
    values::AbstractVector{<:NumericAttributeType},
)::Bool
    extendeddatatypecreate(eltype(values)) do datatype
        createattribute(
            group,
            name,
            UInt64[length(values)],
            datatype,
        ) do attribute
            return write(attribute, values)
        end
    end
end

function readattribute(
    group::Union{AbstractGroup,AbstractMDArray},
    name::AbstractString,
)::Union{Nothing,AttributeType}
    getattribute(group, name) do attribute
        isnull(attribute) && return nothing
        return read(attribute)
    end
end
