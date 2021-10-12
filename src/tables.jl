function Tables.schema(layer::AbstractFeatureLayer)::Nothing
    return nothing
end

Tables.istable(::Type{<:AbstractFeatureLayer})::Bool = true
Tables.rowaccess(::Type{<:AbstractFeatureLayer})::Bool = true

function Tables.rows(layer::T)::T where {T<:AbstractFeatureLayer}
    return layer
end

function Tables.getcolumn(row::Feature, i::Int)
    if i > nfield(row)
        return getgeom(row, i - nfield(row) - 1)
    elseif i > 0
        return getfield(row, i - 1)
    else
        return missing
    end
end

function Tables.getcolumn(row::Feature, name::Symbol)
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
    row::Feature,
)::NTuple{Int64(nfield(row) + ngeom(row)),Symbol}
    geom_names, field_names = schema_names(getfeaturedefn(row))
    return (geom_names..., field_names...)
end

function schema_names(featuredefn::IFeatureDefnView)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(featuredefn)-1)
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = collect(
        Symbol(getname(getgeomdefn(featuredefn, i - 1))) for
        i in 1:ngeom(featuredefn)
    )
    return (geom_names, field_names, featuredefn, fielddefns)
end

"""
    convert_coltype_to_AGtype(T, colidx)

Convert a table column type to ArchGDAL IGeometry or OGRFieldType/OGRFieldSubType
Conforms GDAL version 3.3 except for OFTSJSON and OFTSUUID
"""
function _convert_coltype_to_AGtype(
    T::Type,
    colname::String,
)::Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}
    flattened_T = Base.uniontypes(T)
    clean_flattened_T = filter(t -> t ∉ [Missing, Nothing], flattened_T)
    promoted_clean_flattened_T = promote_type(clean_flattened_T...)
    if promoted_clean_flattened_T <: IGeometry
        # IGeometry
        return if promoted_clean_flattened_T == IGeometry
            wkbUnknown
        else
            convert(OGRwkbGeometryType, promoted_clean_flattened_T)
        end
    elseif (promoted_clean_flattened_T isa DataType) &&
           (promoted_clean_flattened_T != Any)
        # OGRFieldType and OGRFieldSubType or error
        # TODO move from try-catch with convert to if-else with collections (to be defined)
        oft::OGRFieldType = try
            convert(OGRFieldType, promoted_clean_flattened_T)
        catch e
            if e isa MethodError
                error(
                    "Cannot convert column \"$colname\" (type $T) to OGRFieldType and OGRFieldSubType",
                )
            else
                rethrow()
            end
        end
        if oft ∉ [OFTInteger, OFTIntegerList, OFTReal, OFTRealList] # TODO consider extension to OFTSJSON and OFTSUUID
            ofst = OFSTNone
        else
            ofst::OGRFieldSubType = try
                convert(OGRFieldSubType, promoted_clean_flattened_T)
            catch e
                e isa MethodError ? OFSTNone : rethrow()
            end
        end

        return oft, ofst
    else
        error(
            "Cannot convert column \"$colname\" (type $T) to neither IGeometry{::OGRwkbGeometryType} or OGRFieldType and OGRFieldSubType",
        )
    end
end

function _fromtable(
    sch::Tables.Schema{names,types},
    rows;
    name::String = "",
)::IFeatureLayer where {names,types}
    # TODO maybe constrain `names` and `types` types
    strnames = string.(sch.names)

    # Convert types and split types/names between geometries and fields
    AG_types = collect(_convert_coltype_to_AGtype.(sch.types, strnames))

    # Split names and types: between geometry type columns and field type columns
    geomindices = isa.(AG_types, OGRwkbGeometryType)
    !any(geomindices) && error("No column convertible to geometry")
    geomtypes = AG_types[geomindices] # TODO consider to use a view
    geomnames = strnames[geomindices]

    fieldindices = isa.(AG_types, Tuple{OGRFieldType,OGRFieldSubType})
    fieldtypes = AG_types[fieldindices] # TODO consider to use a view
    fieldnames = strnames[fieldindices]

    # Create layer
    layer = createlayer(name = name, geom = first(geomtypes))
    # TODO: create setname! for IGeomFieldDefnView. Probably needs first to fix issue #215
    # TODO: "Model and handle relationships between GDAL objects systematically"
    GDAL.ogr_gfld_setname(
        getgeomdefn(layerdefn(layer), 0).ptr,
        first(geomnames),
    )

    # Create FeatureDefn
    if length(geomtypes) ≥ 2
        for (j, geomtype) in enumerate(geomtypes[2:end])
            creategeomdefn(geomnames[j+1], geomtype) do geomfielddefn
                return addgeomdefn!(layer, geomfielddefn) # TODO check if necessary/interesting to set approx=true
            end
        end
    end
    for (j, (ft, fst)) in enumerate(fieldtypes)
        createfielddefn(fieldnames[j], ft) do fielddefn
            setsubtype!(fielddefn, fst)
            return addfielddefn!(layer, fielddefn)
        end
    end

    # Populate layer
    for (i, row) in enumerate(rows)
        rowvalues =
            [Tables.getcolumn(row, col) for col in Tables.columnnames(row)]
        rowgeoms = view(rowvalues, geomindices)
        rowfields = view(rowvalues, fieldindices)
        addfeature(layer) do feature
            # TODO: optimize once PR #238 is merged define in casse of `missing` 
            # TODO: or `nothing` value, geom or field as to leave unset or set to null
            for (j, val) in enumerate(rowgeoms)
                val !== missing &&
                    val !== nothing &&
                    setgeom!(feature, j - 1, val)
            end
            for (j, val) in enumerate(rowfields)
                val !== missing &&
                    val !== nothing &&
                    setfield!(feature, j - 1, val)
            end
        end
    end

    return layer
end

function _fromtable(
    ::Tables.Schema{names,nothing},
    rows;
    name::String = "",
)::IFeatureLayer where {names}
    cols = Tables.columns(rows)
    types = (eltype(collect(col)) for col in cols)
    return _fromtable(Tables.Schema(names, types), rows; name)
end

function _fromtable(::Nothing, rows, name::String = "")::IFeatureLayer
    state = iterate(rows)
    state === nothing && return IFeatureLayer()
    row, _ = state
    names = Tables.columnnames(row)
    return _fromtable(Tables.Schema(names, nothing), rows; name)
end

"""
    IFeatureLayer(table; name="")

Construct an IFeatureLayer from a source implementing Tables.jl interface

## Restrictions
- Source must contains at least one geometry column
- Geometry columns are recognized by their element type being a subtype of `Union{IGeometry, Nothing,  Missing}`
- Non geometry columns must contain types handled by GDAL/OGR (e.g. not `Int128` nor composite type)

## Returns
An IFeatureLayer within a **MEMORY** driver dataset

## Examples
```jldoctest
julia> using ArchGDAL; AG = ArchGDAL
ArchGDAL

julia> nt = NamedTuple([
           :point => [AG.createpoint(30, 10), missing],
           :mixedgeom => [AG.createpoint(5, 10), AG.createlinestring([(30.0, 10.0), (10.0, 30.0)])],
           :id => ["5.1", "5.2"],
           :zoom => [1.0, 2],
           :location => [missing, "New Delhi"],
       ])
(point = Union{Missing, ArchGDAL.IGeometry{ArchGDAL.wkbPoint}}[Geometry: POINT (30 10), missing], mixedgeom = ArchGDAL.IGeometry[Geometry: POINT (5 10), Geometry: LINESTRING (30 10,10 30)], id = ["5.1", "5.2"], zoom = [1.0, 2.0], location = Union{Missing, String}[missing, "New Delhi"])

julia> layer = AG.IFeatureLayer(nt; name="towns")
Layer: towns
  Geometry 0 (point): [wkbPoint]
  Geometry 1 (mixedgeom): [wkbUnknown]
     Field 0 (id): [OFTString], 5.1, 5.2
     Field 1 (zoom): [OFTReal], 1.0, 2.0
     Field 2 (location): [OFTString], missing, New Delhi
```
"""
function IFeatureLayer(table; name::String = "")::IFeatureLayer
    # Check tables interface's conformance
    !Tables.istable(table) &&
        throw(DomainError(table, "$table has not a Table interface"))
    # Extract table data
    rows = Tables.rows(table)
    schema = Tables.schema(table)
    return _fromtable(schema, rows; name)
end
