# The FID is a `GIntBig` on the GDAL side.
const FIDTYPE = Int64

"""
    _fidcolumn(layer::AbstractFeatureLayer)

The name to expose `layer`'s FID under, or `Symbol("")` for none.

Database-like drivers (GPKG, PostGIS, SQLite, ...) back the FID with a primary
key that OGR keeps out of the field definitions; others report `""`.

Also `Symbol("")` when a field already claims the name: the GeoJSON driver
promotes an `id` field to the FID yet still lists `id` as a field, both holding
the same value. The field wins, so the column is not duplicated.
"""
function _fidcolumn(layer::AbstractFeatureLayer)::Symbol
    fidcolumn = Symbol(fidcolumnname(layer))
    fidcolumn === Symbol("") && return fidcolumn
    featuredefn = layerdefn(layer)
    for i in 0:(nfield(featuredefn)-1)
        if Symbol(getname(getfielddefn(featuredefn, i))) === fidcolumn
            return Symbol("")
        end
    end
    return fidcolumn
end

"""
    Tables.schema(layer::AbstractFeatureLayer)

The layer's columns, read from its definition: the FID column, then one column
per geometry field, then one per ordinary field, in the order
`Tables.columnnames` gives for the layer's rows.

The layer definition decides each column's type:

| Column | Type |
|:---|:---|
| FID | `Int64` |
| geometry field | `IGeometry`, or `Union{Missing,IGeometry}` when nullable |
| ordinary field | the field's Julia type, or `Union{Missing,T}` when nullable |

OGR makes fields nullable by default, so most columns carry `Missing` whether or
not the layer holds an absent value. A layer's declared geometry type binds the
layer rather than each of its features -- a shapefile `wkbPolygon` layer yields
`wkbMultiPolygon` features -- so geometry columns take the abstract `IGeometry`.
"""
function Tables.schema(layer::AbstractFeatureLayer)::Tables.Schema
    ld = layerdefn(layer)
    geom_names, field_names, _, fielddefns = schema_names(ld)
    names = (geom_names..., field_names...)
    types = Type[_datatype(getgeomdefn(ld, i - 1)) for i in 1:ngeom(ld)]
    append!(types, map(_datatype, fielddefns))
    fidcolumn = _fidcolumn(layer)
    if fidcolumn !== Symbol("")
        names = (fidcolumn, names...)
        pushfirst!(types, FIDTYPE)
    end
    return Tables.Schema(names, types)
end

# The subtypes that name a Julia type of their own. GDAL's `OFSTJSON` and
# `OFSTUUID` leave that to the base type, which `getfield` also reads them as.
const _TYPEDSUBTYPES = (OFSTBoolean, OFSTInt16, OFSTFloat32)

function _datatype(fielddefn::IFieldDefnView)::Type
    subtype = getsubtype(fielddefn)
    T = convert(
        DataType,
        subtype in _TYPEDSUBTYPES ? subtype : gettype(fielddefn),
    )
    return isnullable(fielddefn) ? Union{Missing,T} : T
end

function _datatype(geomdefn::IGeomFieldDefnView)::Type
    return isnullable(geomdefn) ? Union{Missing,IGeometry} : IGeometry
end

"""
    _featurecolumns(layer::AbstractFeatureLayer)

`layer`'s `FeatureColumns`, naming the columns in the order `Tables.schema`
gives them.
"""
function _featurecolumns(layer::AbstractFeatureLayer)::FeatureColumns
    ld = layerdefn(layer)
    fidcolumn = _fidcolumn(layer)
    ngeoms = ngeom(ld)
    nfields = nfield(ld)
    offset = fidcolumn === Symbol("") ? 0 : 1
    names = Vector{Symbol}(undef, offset + ngeoms + nfields)
    offset == 0 || (names[1] = fidcolumn)
    for i in 1:ngeoms
        names[offset+i] = Symbol(getname(getgeomdefn(ld, i - 1)))
    end
    for i in 1:nfields
        names[offset+ngeoms+i] = Symbol(getname(getfielddefn(ld, i - 1)))
    end
    # Filled in ascending precedence, so that where columns share a name a
    # field's wins over a geometry field's and the FID's wins over both.
    indices = Dict{Symbol,Int}()
    for i in (offset+1):(offset+ngeoms)
        indices[names[i]] = i
    end
    for i in (offset+ngeoms+1):(offset+ngeoms+nfields)
        indices[names[i]] = i
    end
    offset == 0 || (indices[fidcolumn] = 1)
    return FeatureColumns(fidcolumn, names, indices, ngeoms, nfields)
end

Tables.istable(::Type{<:AbstractFeatureLayer})::Bool = true
Tables.rowaccess(::Type{<:AbstractFeatureLayer})::Bool = true

function Tables.rows(layer::T)::T where {T<:AbstractFeatureLayer}
    return layer
end

function Tables.getcolumn(row::AbstractFeature, i::Int)
    # The FID leads the columns, so shift the remaining indices past it.
    if row.fidcolumn !== Symbol("")
        i == 1 && return getfid(row)
        i -= 1
    end
    i < 1 && return missing
    # A feature read one at a time carries no column layout, so OGR counts its
    # columns as it goes.
    columns = row.columns
    ngeoms = columns === nothing ? Int(ngeom(row)) : columns.ngeom
    i <= ngeoms && return _cell(getgeom(row, i - 1))
    i -= ngeoms
    nfields = columns === nothing ? Int(nfield(row)) : columns.nfield
    return i <= nfields ? _cell(getfield(row, i - 1)) : missing
end

function Tables.getcolumn(row::AbstractFeature, name::Symbol)
    columns = row.columns
    columns === nothing && return _getcolumn(row, name)
    i = get(columns.indices, name, 0)
    return i == 0 ? missing : Tables.getcolumn(row, i)
end

# `Tables` passes the column index from the schema, which orders the columns
# exactly as `Tables.columnnames` and the index path do, so the name needs no
# resolving.
function Tables.getcolumn(
    row::AbstractFeature,
    ::Type{T},
    i::Int,
    name::Symbol,
) where {T}
    return Tables.getcolumn(row, i)
end

# A feature read one at a time carries no column layout, so OGR resolves the
# name.
function _getcolumn(row::AbstractFeature, name::Symbol)
    # `Symbol("")` is both "no FID column" and the name of an unnamed geometry
    # column, so it must never resolve to the FID.
    if name !== Symbol("") && name === row.fidcolumn
        return getfid(row)
    end
    i = findfieldindex(row, name)
    i === nothing || return _cell(getfield(row, i))
    j = findgeomindex(row, name)
    return j == -1 ? missing : _cell(getgeom(row, j))
end

# A column has the one `missing` to say a value is absent, so an unset field and
# a null geometry both arrive as `missing`; `getfield` and `getgeom` keep them
# apart. A single method covers every cell type, so the call stays static where
# a field read infers to `Any`.
@inline function _cell(value)
    value === nothing && return missing
    value isa AbstractGeometry && value.ptr == C_NULL && return missing
    return value
end

function Tables.columnnames(row::AbstractFeature)::Tuple{Vararg{Symbol}}
    columns = row.columns
    columns === nothing || return Tuple(columns.names)
    geom_names, field_names = schema_names(getfeaturedefn(row))
    fidcolumn = row.fidcolumn
    return if fidcolumn === Symbol("")
        (geom_names..., field_names...)
    else
        (fidcolumn, geom_names..., field_names...)
    end
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
