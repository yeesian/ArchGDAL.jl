"""
A tabular representation of a `FeatureLayer`

Every row is a `Feature` consisting of Geometry and attributes.
"""
struct Table{T<:AbstractFeatureLayer}
    layer::T
end

function Tables.schema(layer::AbstractFeatureLayer)::Tables.Schema
    field_names, geom_names, featuredefn, fielddefns =
        schema_names(layerdefn(layer))
    ngeom = ArchGDAL.ngeom(featuredefn)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)
    field_types =
        (convert(DataType, gettype(fielddefn)) for fielddefn in fielddefns)
    geom_types = (IGeometry{gettype(geomdefn)} for geomdefn in geomdefns)
    return Tables.Schema(
        (geom_names..., field_names...),
        (geom_types..., field_types...),
    )
end

Tables.istable(::Type{<:Table})::Bool = true
Tables.rowaccess(::Type{<:Table})::Bool = true

function Tables.rows(t::Table{T})::T where {T<:AbstractFeatureLayer}
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
    row::Feature,
)::NTuple{Int64(nfield(row) + ngeom(row)),Symbol}
    field_names, geom_names = schema_names(getfeaturedefn(row))
    return (field_names..., geom_names...)
end

function schema_names(featuredefn::IFeatureDefnView)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(featuredefn)-1)
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = collect(
        Symbol(getname(getgeomdefn(featuredefn, i - 1))) for
        i in 1:ngeom(featuredefn)
    )
    replace!(geom_names, Symbol("") => Symbol("geometry"), count = 1)
    return (field_names, geom_names, featuredefn, fielddefns)
end

function Base.show(io::IO, t::Table)
    return println(io, "Table with $(nfeature(t.layer)) features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)
