# The FID is a `GIntBig` on the GDAL side.
const FIDTYPE = Int64

"""
    _fidcolumn(layer::AbstractFeatureLayer)

The name to expose the FID of `layer`'s features under, or `Symbol("")` if it
should not be exposed as a column at all.

Database-like drivers (GPKG, PostGIS, SQLite, ...) back the FID with a real
primary key column that OGR models separately from the fields, leaving it
absent from the field definitions and so invisible to the rest of the tables
interface. Those get a leading column named after the driver's FID column,
matching what QGIS and R's `sf` show for the same data. Drivers without such a
column (ESRI Shapefile, FlatGeobuf, ...) report `""` and gain no extra column.

Some drivers report a FID column that *is* also a field: the GeoJSON driver
promotes an `id` field to the FID while still listing `id` among the fields,
with both carrying the same value. The field wins there, so that the column is
not duplicated and the values stay reachable under the name they already had.

This resolves to a fixed answer for the whole layer, so it is queried once when
features start being read rather than per feature or per column.
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
    fidcolumn = _fidcolumn(layer)
    if fidcolumn !== Symbol("")
        names = (fidcolumn, names...)
        pushfirst!(types, FIDTYPE)
    end
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
    # The FID leads the columns, so shift the remaining indices past it.
    if row.fidcolumn !== Symbol("")
        i == 1 && return getfid(row)
        i -= 1
    end
    if i > nfield(row)
        return getgeom(row, i - nfield(row) - 1)
    elseif i > 0
        return getfield(row, i - 1)
    else
        return missing
    end
end

function Tables.getcolumn(row::AbstractFeature, name::Symbol)
    # `Symbol("")` doubles as "no FID column" and as the name of an unnamed
    # geometry column, so an empty name must never resolve to the FID.
    if name !== Symbol("") && name === row.fidcolumn
        return getfid(row)
    end
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
