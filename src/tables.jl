function Tables.schema(
    layer::AbstractFeatureLayer,
)::Union{Nothing,Tables.Schema}
    # If the layer has no features, calculate the schema from the layer
    # otherwise let the features build the schema on the fly
    # If we always build the schema, all isnullable (by default true) fields
    # will result in columns with Union{Missing}.
    nfeature(layer) == 0 || return nothing
    ld = layerdefn(layer)
    geom_names, field_names, _, fielddefns = schema_names(ld)
    names = (geom_names..., field_names...)
    types = Type[_datatype(getgeomdefn(ld, i - 1)) for i in 1:ngeom(ld)]
    append!(types, map(_datatype, fielddefns))
    return Tables.Schema(names, types)
end

function _datatype(fielddefn::IFieldDefnView)
    return T = convert(DataType, getfieldtype(fielddefn))
end

function _datatype(fielddefn::IGeomFieldDefnView)
    return IGeometry{gettype(fielddefn)}
end

Tables.istable(::Type{<:AbstractFeatureLayer})::Bool = true
Tables.rowaccess(::Type{<:AbstractFeatureLayer})::Bool = true

function Tables.rows(layer::T)::T where {T<:AbstractFeatureLayer}
    return layer
end

function Tables.getcolumn(row::AbstractFeature, i::Int)
    if i > nfield(row)
        return getgeom(row, i - nfield(row) - 1)
    elseif i > 0
        return getfield(row, i - 1)
    else
        return missing
    end
end

function Tables.getcolumn(row::AbstractFeature, name::Symbol)
    field = getfield(row, name)
    if !ismissing(field)
        return field
    end
    geom = getgeom(row, name)
    if geom.ptr != C_NULL
        return geom
    end
    return missing
end

function Tables.columnnames(
    row::AbstractFeature,
)::NTuple{Int64(nfield(row) + ngeom(row)),Symbol}
    geom_names, field_names = schema_names(getfeaturedefn(row))
    return (geom_names..., field_names...)
end

function schema_names(featuredefn::IFeatureDefnView)
    fielddefns =
        (getfielddefn(featuredefn, i) for i in 0:(nfield(featuredefn)-1))
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = collect(
        Symbol(getname(getgeomdefn(featuredefn, i - 1))) for
        i in 1:ngeom(featuredefn)
    )
    return (geom_names, field_names, featuredefn, fielddefns)
end
