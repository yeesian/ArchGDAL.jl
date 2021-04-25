"""
A tabular representation of a `FeatureLayer`

Every row is a `Feature` consisting of Geometry and attributes.
"""
struct Table{T <: AbstractFeatureLayer}
    layer::T
end

function Tables.schema(layer::AbstractFeatureLayer)::Tables.Schema
    field_names, geom_names, featuredefn, fielddefns = schema_names(layer)
    ngeom = ArchGDAL.ngeom(featuredefn)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)
    field_types = (
        convert(DataType, gettype(fielddefn)) for fielddefn in fielddefns
    )
    geom_types = (IGeometry for i in 1:ngeom)
    Tables.Schema(
        (field_names..., geom_names...),
        (field_types..., geom_types...)
    )
end

Tables.istable(::Type{<:Table})::Bool = true
Tables.rowaccess(::Type{<:Table})::Bool = true

function Tables.rows(t::Table{T})::T where {T <: AbstractFeatureLayer}
    return t.layer
end

function Tables.getcolumn(row::Feature, i::Int)
    if i > nfield(row)
        return getgeom(row, i - nfield(row) - 1)
    elseif i > 0
        return getfield(row, i - 1)
    else
        return nothing
    end
end

function Tables.getcolumn(row::Feature, name::Symbol)
    field = getfield(row, name)
    if !isnothing(field)
        return field
    end
    geom = getgeom(row, name)
    if geom.ptr != C_NULL
        return geom
    end
    return nothing
end

function Tables.columnnames(
        row::Feature
    )::NTuple{nfield(row) + ngeom(row), String}
    field_names, geom_names = schema_names(layer)
    return (field_names..., geom_names...)
end

"""
Returns the feature row of a layer as a `NamedTuple`

Calling it iteratively will work similar to `nextfeature` i.e. give the
consecutive feature as `NamedTuple`.
"""
function nextnamedtuple(layer::IFeatureLayer)::NamedTuple
    field_names, geom_names = schema_names(layer)
    return nextfeature(layer) do feature
        prop = (getfield(feature, name) for name in field_names)
        geom = (getgeom(feature, i - 1) for i in 1:length(geom_names))
        NamedTuple{(field_names..., geom_names...)}((prop..., geom...))
    end
end

function schema_names(layer::AbstractFeatureLayer)
    featuredefn = layerdefn(layer)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(layer)-1)
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = (
        Symbol(getname(getgeomdefn(featuredefn, i - 1))) for i in 1:ngeom(layer)
    )
    return (field_names, geom_names, featuredefn, fielddefns)
end

function Base.show(io::IO, t::Table)
    println(io, "Table with $(nfeature(t.layer)) features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)
