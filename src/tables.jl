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
@generated function _convert_cleantype_to_AGtype(
    T::Type{U},
) where {U<:GeoInterface.AbstractGeometry}
    return :(convert(OGRwkbGeometryType, T))
end
@generated function _convert_cleantype_to_AGtype(T::Type{U}) where {U}
    return :(convert(OGRFieldType, T), convert(OGRFieldSubType, T))
end

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

function _create_empty_layer_from_AGtypes(
    strnames::NTuple{N,String},
    AGtypes::Vector{
        Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}},
    },
    name::String,
) where {N}
    # Split names and types: between geometry type columns and field type columns
    geomindices = isa.(AGtypes, OGRwkbGeometryType)
    !any(geomindices) && error("No column convertible to geometry")
    geomtypes = AGtypes[geomindices] # TODO consider to use a view
    geomnames = strnames[geomindices]

    fieldindices = isa.(AGtypes, Tuple{OGRFieldType,OGRFieldSubType})
    fieldtypes = AGtypes[fieldindices] # TODO consider to use a view
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
    if length(geomtypes) >= 2
        for (geomtype, geomname) in zip(geomtypes[2:end], geomnames[2:end])
            creategeomdefn(geomname, geomtype) do geomfielddefn
                return addgeomdefn!(layer, geomfielddefn) # TODO check if necessary/interesting to set approx=true
            end
        end
    end
    for (fieldname, (fieldtype, fieldsubtype)) in zip(fieldnames, fieldtypes)
        createfielddefn(fieldname, fieldtype) do fielddefn
            setsubtype!(fielddefn, fieldsubtype)
            return addfielddefn!(layer, fielddefn)
        end
    end

    return layer, geomindices, fieldindices
end

const GeometryOrFieldType =
    Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}

"""
    _infergeometryorfieldtypes(sch, rows; geom_cols)

Infer ArchGDAL field and geometry types from schema, rows' values and designated geometry columns 
"""
function _infergeometryorfieldtypes(
    sch::Tables.Schema{names,types},
    rows;
    geom_cols::Union{Nothing,Vector{String},Vector{Int}} = nothing,
) where {names,types}
    strnames = string.(sch.names)
    if geom_cols === nothing
        shouldbegeomcolinds = nothing
    elseif geom_cols isa Vector{String}
        if geom_cols ⊈ Vector(1:length(sch.names))
            error(
                "Specified geometry column names is not a subset of table column names",
            )
        else
            shouldbegeomcolinds = findall(s -> s ∈ geom_cols, strnames)
        end
    elseif geom_cols isa Vector{Int}
        if geom_cols ⊈ strnames
            error(
                "Specified geometry column indices is not a subset of table column indices",
            )
        else
            shouldbegeomcolinds = geom_cols
        end
    else
        error("Should not be here")
    end

    # Convert column types to either geometry types or field types and subtypes
    AGtypes =
        Vector{GeometryOrFieldType}(undef, length(Tables.columnnames(rows)))
    for (j, (coltype, colname)) in enumerate(zip(sch.types, strnames))
        # we wrap the following in a try-catch block to surface the original column type (rather than clean/converted type) in the error message
        AGtypes[j] = try
            (_convert_cleantype_to_AGtype ∘ _convert_coltype_to_cleantype)(coltype)
        catch e
            if e isa MethodError
                error(
                    "Cannot convert column \"$colname\" (type $coltype) to neither IGeometry{::OGRwkbGeometryType} or OGRFieldType and OGRFieldSubType",
                )
            else
                throw(e)
            end
        end
    end

    #* CANNOT FIND A TESTCASE WHERE `state === nothing` COULD HAPPEN => COMMENTED FOR NOW
    # # Return layer with FeatureDefn without any feature if table is empty, even
    # # if it has a full featured schema
    state = iterate(rows)
    # if state === nothing
    #     (layer, _, _) =
    #         _create_empty_layer_from_AGtypes(strnames, AGtypes, name)
    #     return layer
    # end

    # Search in first rows for WKT strings or WKB binary data until for each
    # columns with a compatible type (`String` or `Vector{UInt8}` tested
    # through their converted value to `OGRFieldType`, namely: `OFTString` or 
    # `OFTBinary`), a non `missing` nor `nothing` value is found
    maybeWKTcolinds = findall(
        T -> T isa Tuple{OGRFieldType,OGRFieldSubType} && T[1] == OFTString,
        AGtypes,
    )
    maybeWKBcolinds = findall(
        T -> T isa Tuple{OGRFieldType,OGRFieldSubType} && T[1] == OFTBinary,
        AGtypes,
    )
    if shouldbegeomcolinds !== nothing
        maybeWKTcolinds = maybeWKTcolinds ∩ shouldbegeomcolinds
        maybeWKBcolinds = maybeWKBcolinds ∩ shouldbegeomcolinds
    end
    maybegeomcolinds = maybeWKTcolinds ∪ maybeWKBcolinds
    if !Base.isempty(maybegeomcolinds)
        @assert Base.isempty(maybeWKTcolinds ∩ maybeWKBcolinds)
        testWKT = !Base.isempty(maybeWKTcolinds)
        testWKB = !Base.isempty(maybeWKBcolinds)
        maybegeomtypes = Dict(
            zip(
                maybegeomcolinds,
                fill!(Vector{Type}(undef, length(maybegeomcolinds)), Union{}),
            ),
        )
        row, st = state
        while testWKT || testWKB
            if testWKT
                for j in maybeWKTcolinds
                    if (val = row[j]) !== nothing && val !== missing
                        try
                            maybegeomtypes[j] = promote_type(
                                maybegeomtypes[j],
                                typeof(fromWKT(val)),
                            )
                        catch
                            pop!(maybegeomtypes, j)
                        end
                    end
                end
                maybeWKTcolinds = maybeWKTcolinds ∩ keys(maybegeomtypes)
                testWKT = !Base.isempty(maybeWKTcolinds)
            end
            if testWKB
                for j in maybeWKBcolinds
                    if (val = row[j]) !== nothing && val !== missing
                        try
                            maybegeomtypes[j] = promote_type(
                                maybegeomtypes[j],
                                typeof(fromWKB(val)),
                            )
                        catch
                            pop!(maybegeomtypes, j)
                        end
                    end
                end
                maybeWKBcolinds = maybeWKBcolinds ∩ keys(maybegeomtypes)
                testWKB = !Base.isempty(maybeWKBcolinds)
            end
            state = iterate(rows, st)
            state === nothing && break
            row, st = state
        end
        state === nothing && begin
            WKxgeomcolinds = findall(T -> T != Union{}, maybegeomtypes)
            for j in WKxgeomcolinds
                AGtypes[j] = (
                    _convert_cleantype_to_AGtype ∘
                    _convert_coltype_to_cleantype
                )(
                    maybegeomtypes[j],
                )
            end
        end
    end

    if shouldbegeomcolinds !== nothing
        foundgeomcolinds = findall(T -> T isa OGRwkbGeometryType, AGtypes)
        if Set(shouldbegeomcolinds) != Set(foundgeomcolinds)
            diff = setdiff(shouldbegeomcolinds, foundgeomcolinds)
            if !isempty(diff)
                error(
                    "The following columns could not be parsed as geometry columns: $diff",
                )
            end
            diff = setdiff(foundgeomcolinds, shouldbegeomcolinds)
            if !isempty(diff)
                error(
                    "The following columns are composed of geometry objects and have not been converted to a field type:$diff. Consider adding these columns to geometry columns or convert their values to WKT/WKB",
                )
            end
        end
    end

    return AGtypes
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
    layer_name::String,
    geom_cols::Union{Nothing,Vector{String},Vector{Int}} = nothing,
    # parseWKT::Bool,
    # parseWKB::Bool,
)::IFeatureLayer where {names,types}
    # Infer geometry and field types
    AGtypes = _infergeometryorfieldtypes(sch, rows; geom_cols = geom_cols)

    # Create layer
    (layer, geomindices, fieldindices) = _create_empty_layer_from_AGtypes(
        string.(sch.names),
        AGtypes,
        layer_name,
    )

    # Populate layer
    for row in rows
        rowvalues =
            [Tables.getcolumn(row, col) for col in Tables.columnnames(row)]
        rowgeoms = view(rowvalues, geomindices)
        rowfields = view(rowvalues, fieldindices)
        addfeature(layer) do feature
            # For geometry fields both `missing` and `nothing` map to not geometry set
            # since in GDAL <= v"3.3.2", special fields as geometry field cannot be NULL
            # cf. `OGRFeature::IsFieldNull( int iField )` implemetation
            for (j, val) in enumerate(rowgeoms)
                if val !== missing && val !== nothing
                    setgeom!(feature, j - 1, convert(IGeometry, val))
                end
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
    kwargs...,
)::IFeatureLayer where {names}
    cols = Tables.columns(rows)
    types = (eltype(collect(col)) for col in cols)
    return _fromtable(Tables.Schema(names, types), rows; kwargs...)
end

"""
    _fromtable(::Tables.Schema{names,nothing}, rows; name::String = "")

Handles the case where schema is `nothing`

# Implementation
Tables.Schema names are extracted from `rows`'s columns names before calling `_fromtable(Tables.Schema(names, types), rows; name = name)`

"""
function _fromtable(::Nothing, rows; kwargs...)::IFeatureLayer
    state = iterate(rows)
    state === nothing && return IFeatureLayer()
    row, _ = state
    names = Tables.columnnames(row)
    return _fromtable(Tables.Schema(names, nothing), rows; kwargs...)
end

"""
    IFeatureLayer(table; kwargs...)

Construct an IFeatureLayer from a source implementing Tables.jl interface

## Keyword arguments
- `layer_name::String = ""`: name of the layer
- `geom_cols::Union{Nothing, Vector{String}, Vector{Int}} = nothing`: if different from nothing, will only try to parse specified columns (by names or number) when looking for geometry columns

## Restrictions
- Source must contains at least one geometry column
- Geometry columns are recognized by their element type being a subtype of:
  - `Union{IGeometry, Nothing,  Missing}` or
  - `Union{GeoInterface.AbstractGeometry, Nothing,  Missing}` or
  - `Union{String, Nothing,  Missing}` provided that String values can be decoded as WKT or
  - `Union{Vector{UInt8}, Nothing,  Missing}` provided that Vector{UInt8} values can be decoded as WKB
- Non geometry columns must contain types handled by GDAL/OGR (e.g. not `Int128` nor composite type)

## Returns
An IFeatureLayer within a **MEMORY** driver dataset

## Example
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

julia> layer = AG.IFeatureLayer(nt; layer_name="towns")
Layer: towns
  Geometry 0 (point): [wkbPoint]
  Geometry 1 (mixedgeom): [wkbUnknown]
     Field 0 (id): [OFTString], 5.1, 5.2
     Field 1 (zoom): [OFTReal], 1.0, 2.0
     Field 2 (location): [OFTString], missing, New Delhi
```
"""
function IFeatureLayer(
    table;
    layer_name::String = "layer",
    geom_cols::Union{Nothing,Vector{String},Vector{Int}} = nothing,
    # parseWKT::Bool = false,
    # parseWKB::Bool = false,
)::IFeatureLayer
    # Check tables interface's conformance
    !Tables.istable(table) &&
        throw(DomainError(table, "$table has not a Table interface"))
    # Extract table data
    rows = Tables.rows(table)
    schema = Tables.schema(table)
    return _fromtable(
        schema,
        rows;
        layer_name = layer_name,
        geom_cols = geom_cols,
        # parseWKT = parseWKT,
        # parseWKB = parseWKB,
    )
end
