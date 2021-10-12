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
    _convert_cleantype_to_AGtype(T)

Converts type `T` into either:
- a `OGRwkbGeometryType` or
- a tuple of `OGRFieldType` and `OGRFieldSubType`

"""
function _convert_cleantype_to_AGtype end
_convert_cleantype_to_AGtype(::Type{IGeometry}) = wkbUnknown
@generated _convert_cleantype_to_AGtype(::Type{IGeometry{U}}) where U = :($U)
@generated _convert_cleantype_to_AGtype(T::Type{U}) where U = :(convert(OGRFieldType, T), convert(OGRFieldSubType, T))


"""
    _convert_coltype_to_cleantype(T)

Convert a table column type to a "clean" type:
- Unions are flattened
- Missing and Nothing are dropped
- Resulting mixed types are approximated by their tightest common supertype

"""
function _convert_coltype_to_cleantype(T::Type)
    flattened_T = Base.uniontypes(T)
    clean_flattened_T = filter(t -> t ∉ [Missing, Nothing], flattened_T)
    return promote_type(clean_flattened_T...)
end

"""
    _fromtable(sch, rows; name)

Converts a row table `rows` with schema `sch` to a layer (optionally named `name`) within a MEMORY dataset

"""
function _fromtable end

"""
    _fromtable(sch::Tables.Schema{names,types}, rows; name::String = "")

Handles the case where names and types in `sch` are different from `nothing`

# Implementation
1. convert `rows`'s column types given in `sch` to either geometry types or field types and subtypes
2. split `rows`'s columns into geometry typed columns and field typed columns
3. create layer named `name` in a MEMORY dataset geomfields and fields types inferred from `rows`'s column types
4. populate layer with `rows` values

"""
function _fromtable(
    sch::Tables.Schema{names,types},
    rows;
    name::String = "",
)::IFeatureLayer where {names,types}
    # TODO maybe constrain `names`
    strnames = string.(sch.names)

    # Convert column types to either geometry types or field types and subtypes
    AG_types = Vector{Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}}(undef, length(Tables.columnnames(rows)))
    for (i, (coltype, colname)) in enumerate(zip(sch.types, strnames))
        AG_types[i] = try
            (_convert_cleantype_to_AGtype ∘ _convert_coltype_to_cleantype)(coltype)
        catch e
            if e isa MethodError
                error("Cannot convert column \"$colname\" (type $coltype) to neither IGeometry{::OGRwkbGeometryType} or OGRFieldType and OGRFieldSubType",)
            else
                rethrow()
            end
        end
    end

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
            # For geometry fields both `missing` and `nothing` map to not geometry set
            # since in GDAL <= v"3.3.2", special fields as geometry field cannot be NULL
            # cf. `OGRFeature::IsFieldNull( int iField )` implemetation
            for (j, val) in enumerate(rowgeoms)
                val !== missing &&
                    val !== nothing &&
                    setgeom!(feature, j - 1, val)
            end
            for (j, val) in enumerate(rowfields)
                if val === missing
                    setfieldnull!(feature, j - 1)
                elseif val !== nothing
                    setfield!(feature, j - 1, val)
                end
            end
        end
    end

    return layer
end

"""
    _fromtable(::Tables.Schema{names,nothing}, rows; name::String = "")

Handles the case where types in schema is `nothing`

# Implementation
Tables.Schema types are extracted from `rows`'s columns element types before calling `_fromtable(Tables.Schema(names, types), rows; name = name)`

"""
function _fromtable(
    ::Tables.Schema{names,nothing},
    rows;
    name::String = "",
)::IFeatureLayer where {names}
    cols = Tables.columns(rows)
    types = (eltype(collect(col)) for col in cols)
    return _fromtable(Tables.Schema(names, types), rows; name = name)
end

"""
    _fromtable(::Tables.Schema{names,nothing}, rows; name::String = "")

Handles the case where schema is `nothing`

# Implementation
Tables.Schema names are extracted from `rows`'s columns names before calling `_fromtable(Tables.Schema(names, types), rows; name = name)`

"""
function _fromtable(::Nothing, rows; name::String = "")::IFeatureLayer
    state = iterate(rows)
    state === nothing && return IFeatureLayer()
    row, _ = state
    names = Tables.columnnames(row)
    return _fromtable(Tables.Schema(names, nothing), rows; name = name)
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
    return _fromtable(schema, rows; name = name)
end
