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
    nfields = nfield(row)
    if i > nfields
        return _cell(getgeom(row, i - nfields - 1))
    elseif i > 0
        return _cell(getfield(row, i - 1))
    else
        return missing
    end
end

function Tables.getcolumn(row::AbstractFeature, name::Symbol)
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
# a null one both arrive as `missing`; `getfield` and `getgeom` keep them apart.
_cell(value) = value
_cell(::Nothing)::Missing = missing
_cell(geom::AbstractGeometry) = geom.ptr == C_NULL ? missing : geom

function Tables.columnnames(row::AbstractFeature)::Tuple{Vararg{Symbol}}
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
