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
    colnames::NTuple{N,String},
    AGtypes::Vector{
        Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}},
    },
    name::String,
) where {N}
    # Split names and types: between geometry type columns and field type columns
    geomindices = isa.(AGtypes, OGRwkbGeometryType)
    !any(geomindices) && error("No column convertible to geometry")
    geomtypes = AGtypes[geomindices] # TODO consider to use a view
    geomnames = colnames[geomindices]

    fieldindices = isa.(AGtypes, Tuple{OGRFieldType,OGRFieldSubType})
    fieldtypes = AGtypes[fieldindices] # TODO consider to use a view
    fieldnames = colnames[fieldindices]

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

"""
    _infergeometryorfieldtypes(sch, rows, spgeomcols, spfieldtypes)

Infer ArchGDAL field and geometry types from schema, `rows`' values (for WKT/WKB cases) and `geomcols` and `fieldtypes` kwargs 

"""
function _infergeometryorfieldtypes(
    sch::Tables.Schema{names,types},
    rows,
    spgeomcols::Union{Nothing,Vector{String},Vector{Int}},
    spfieldtypes::Union{
        Nothing,
        Dict{Int,Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}},
    },
) where {names,types}
    colnames = string.(sch.names)

    # Convert column types to either geometry types or field types and subtypes
    AGtypes =
        Vector{Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}}(
            undef,
            length(Tables.columnnames(rows)),
        )
    for (j, (coltype, colname)) in enumerate(zip(sch.types, colnames))
        if spfieldtypes !== nothing && j ∈ keys(spfieldtypes)
            AGtypes[j] = spfieldtypes[j]
        else
            # we wrap the following in a try-catch block to surface the original column type (rather than clean/converted type) in the error message
            AGtypes[j] = try
                (_convert_cleantype_to_AGtype ∘ _convert_coltype_to_cleantype)(
                    coltype,
                )
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
    end

    #* CANNOT FIND A TESTCASE WHERE `state === nothing` COULD HAPPEN => COMMENTED FOR NOW
    # # Return layer with FeatureDefn without any feature if table is empty, even
    # # if it has a full featured schema
    state = iterate(rows)
    # if state === nothing
    #     (layer, _, _) =
    #         _create_empty_layer_from_AGtypes(colnames, AGtypes, name)
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
    if spgeomcols !== nothing
        maybeWKTcolinds = maybeWKTcolinds ∩ spgeomcols
        maybeWKBcolinds = maybeWKBcolinds ∩ spgeomcols
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

    # Verify after parsing that:
    # - there is no column, not specified in `geomcols` kwarg, and found to be 
    #   of a geometry eltype which is not a compatible GDAL field type 
    #   (e.g. `IGeometry` or `GeoInterface.AbstractGeometry`) 
    # - there is no column specified in `geomcols` kwarg that could not be
    #   parsed as a geometry column
    if spgeomcols !== nothing
        foundgeomcols = findall(T -> T isa OGRwkbGeometryType, AGtypes)
        if Set(spgeomcols) != Set(foundgeomcols)
            diff = setdiff(spgeomcols, foundgeomcols)
            if !Base.isempty(diff)
                error(
                    "Column(s) $(join(string.(diff), ", ", " and ")) could not be parsed as geometry column(s)",
                )
            end
            diff = setdiff(foundgeomcols, spgeomcols)
            if !Base.isempty(diff)
                error(
                    "Column(s) $(join(string.(diff), ", ", " and ")) is(are) composed of geometry objects that cannot be converted to a GDAL field type.\nConsider adding this(these) column(s) to `geomcols` kwarg or convert their values to WKT/WKB",
                )
            end
        end
    end

    return AGtypes
end

"""
    _coherencecheckandnormalizationofkwargs(geomcols, fieldtypes)

Test coherence: 
   - of `geomcols` and `fieldtypes` kwargs with table schema
   - between `geomcols` and `fieldtypes` kwargs
   - of `ORGFieldTypes` and `OGRFieldSubType` types in `fieldtypes`kwarg

And normalize `geomcols` and `fieldtypes` kwargs with indices of table schema names.

"""
function _coherencecheckandnormalizationofkwargs(
    geomcols::Union{Nothing,Vector{String},Vector{Int}},
    fieldtypes::Union{
        Nothing,
        Dict{Int,Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}},
        Dict{
            String,
            Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}},
        },
    },
    colnames = Vector{String},
)::Tuple{
    Union{Nothing,Vector{Int}},
    Union{
        Nothing,
        Dict{Int,Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}},
    },
}
    # Test coherence of `geomcols` and normalize it with indices of schema names
    if geomcols === nothing
        spgeomcols = nothing
    elseif geomcols isa Vector{String}
        if geomcols ⊈ colnames
            errored_geomcols = setdiff(geomcols, geomcols ∩ colnames)
            error(
                "Column(s) $(join(string.(errored_geomcols), ", ", " and ")) in `geomcols` kwarg is(are) not in table's columns names",
            )
        else
            spgeomcols = findall(s -> s ∈ geomcols, colnames)
        end
    else
        @assert geomcols isa Vector{Int}
        if geomcols ⊈ Vector(1:length(colnames))
            errored_geomcols =
                setdiff(geomcols, geomcols ∩ Vector(1:length(colnames)))
            error(
                "Column(s) $(join(string.(errored_geomcols), ", ", " and ")) in `geomcols` kwarg is(are) not in table's columns indices ranging from 1 to $(length(colnames))",
            )
        else
            spgeomcols = geomcols
        end
    end

    # Test coherence `fieldtypes` with schema names, and normalize it to a `Dict{Int, ...}` with indices of schema names
    if fieldtypes === nothing
        spfieldtypes = nothing
    elseif collect(keys(fieldtypes)) isa Vector{String}
        if keys(fieldtypes) ⊈ colnames
            errored_fieldtypes_keys =
                setdiff(keys(fieldtypes), keys(fieldtypes) ∩ colnames)
            error(
                "Column(s) $(join(string.(errored_fieldtypes_keys), ", ", " and ")) specified in `fieldtypes` kwarg keys is(are) not in table's colums' names",
            )
        end
        spfieldtypes = Dict((
            i => fieldtypes[colnames[i]] for
            i in findall(s -> s ∈ keys(fieldtypes), colnames)
        ))
    else
        @assert collect(keys(fieldtypes)) isa Vector{Int}
        if keys(fieldtypes) ⊈ Vector(1:length(colnames))
            errored_fieldtypes_keys = setdiff(
                keys(fieldtypes),
                keys(fieldtypes) ∩ Vector(1:length(colnames)),
            )
            error(
                "Column(s) $(join(string.(errored_fieldtypes_keys), ", ", " and ")) specified in `fieldtypes` kwarg keys is(are) not in table's colums' indices ranging from 1 to $(length(colnames))",
            )
        else
            spfieldtypes = fieldtypes
        end
    end

    # Test coherence of `spfieldtypes` and `spgeomcols`
    if spgeomcols !== nothing && spfieldtypes !== nothing
        if keys(filter(kv -> last(kv) isa OGRwkbGeometryType, spfieldtypes)) ⊈
           spgeomcols
            geomfieldtypedcols = keys(
                filter(kv -> last(kv) isa OGRwkbGeometryType, spfieldtypes),
            )
            incoherent_geomfieldtypedcols =
                setdiff(geomfieldtypedcols, geomfieldtypedcols ∩ spgeomcols)
            error(
                "Column(s) $(join(string.(incoherent_geomfieldtypedcols), ", ", " and ")) specified with an `OGRwkbGeometryType` type in `fieldtypes` kwarg, is(are) not specified in `geomcols` kwarg",
            )
        end
        if !Base.isempty(
            keys(
                filter(
                    kv -> last(kv) isa Tuple{OGRFieldType,OGRFieldSubType},
                    spfieldtypes,
                ),
            ) ∩ spgeomcols,
        )
            fieldtypedcols = keys(
                filter(
                    kv -> last(kv) isa Tuple{OGRFieldType,OGRFieldSubType},
                    spfieldtypes,
                ),
            )
            incoherent_fieldtypedcols = fieldtypedcols ∩ spgeomcols
            error(
                "Column(s) $(join(string.(incoherent_fieldtypedcols), ", ", " and ")) specified with a `Tuple{OGRFieldType,OGRFieldSubType}` in `fieldtypes` kwarg, is(are) also specified as geometry column(s) in `geomcols` kwarg",
            )
        end
    end

    # Test coherence of `OGRFieldType` and `OGRFieldSubType` in `fieldtypes` kwarg
    if spfieldtypes !== nothing
        incoherent_OGRFT_OGRFST = filter(
            kv ->
                last(kv) isa Tuple{OGRFieldType,OGRFieldSubType} &&
                    last(kv) ∉ values(OGRFieldcompatibleDataTypes),
            spfieldtypes,
        )
        if !Base.isempty(incoherent_OGRFT_OGRFST)
            incoherent_OGRFT_OGRFST_cols =
                collect(keys(incoherent_OGRFT_OGRFST))
            error(
                "`OGRFieldtype` and `ORGFieldSubType` specified for column(s) $(join(string.(incoherent_OGRFT_OGRFST_cols), ", ", " and "))  in `fieldtypes` kwarg, are not compatible",
            )
        end
    end

    return spgeomcols, spfieldtypes
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
1. test coherence:
   - of `geomcols` and `fieldtypes` kwargs with table schema
   - between `geomcols` and `fieldtypes` kwargs
   - of `ORGFieldTypes` and `OGRFieldSubType` types in `fieldtypes`kwarg
1. convert `rows`'s column types given in `sch` and a normalized version of `geomcols` and `fieldtypes` kwargs, to either geometry types or field types and subtypes
2. split `rows`'s columns into geometry typed columns and field typed columns
3. create layer named `name` in a MEMORY dataset geomfields and fields types inferred from `rows`'s column types
4. populate layer with `rows` values

"""
function _fromtable(
    sch::Tables.Schema{names,types},
    rows;
    layer_name::String,
    geomcols::Union{Nothing,Vector{String},Vector{Int}} = nothing, # Default value set as a convinience for tests
    fieldtypes::Union{
        Nothing,
        Dict{Int,Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}},
        Dict{
            String,
            Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}},
        },
    } = nothing, # Default value set as a convinience for tests
)::IFeatureLayer where {names,types}
    # Test coherence of `geomcols` and `fieldtypes` and normalize them with indices for schema names
    (spgeomcols, spfieldtypes) = _coherencecheckandnormalizationofkwargs(
        geomcols,
        fieldtypes,
        string.(sch.names),
    )

    # Infer geometry and field types
    AGtypes = _infergeometryorfieldtypes(sch, rows, spgeomcols, spfieldtypes)

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
- `geomcols::Union{Nothing, Vector{String}, Vector{Int}} = nothing`: if `geomcols` is different from nothing, only the specified columns (by names or number) will be converted to geomfields
- `fieldtypes`: has a default value of `nothing`. If it is different from `nothing`, the specified types will be used for column parsing. `Fieldtypes` can be of either types:
  - `Dict{Int,Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}}`
  - `Dict{String,Union{OGRwkbGeometryType,Tuple{OGRFieldType,OGRFieldSubType}}}` 

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
(point = Union{Missing, ArchGDAL.IGeometry{ArchGDAL.wkbPoint}}[IGeometry: POINT (30 10), missing], mixedgeom = ArchGDAL.IGeometry[IGeometry: POINT (5 10), IGeometry: LINESTRING (30 10,10 30)], id = ["5.1", "5.2"], zoom = [1.0, 2.0], location = Union{Missing, String}[missing, "New Delhi"])

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
    geomcols::Union{Nothing,Vector{String},Vector{Int}} = nothing,
    fieldtypes::T = nothing,
) where {T<:Union{Nothing,Dict{U,V}}} where {U<:Union{String,Int},V}
    # Check tables interface's conformance
    !Tables.istable(table) &&
        throw(DomainError(table, "$table has not a Table interface"))
    # Extract table data
    rows = Tables.rows(table)
    schema = Tables.schema(table)
    # Necessary since the default type will be Any when building the Dictionary
    if T != Nothing
        norm_fieldtypes = try
            convert(
                Dict{
                    U,
                    Union{
                        OGRwkbGeometryType,
                        Tuple{OGRFieldType,OGRFieldSubType},
                    },
                },
                fieldtypes,
            )
        catch
            error(
                "`fieldtypes` keys should be of type `String` or `Int` and values should be either of type `OGRwkbGeometryType` or `Tuple{OGRFieldType,OGRFieldSubType}`",
            )
        end
    else
        norm_fieldtypes = nothing
    end
    return _fromtable(
        schema,
        rows;
        layer_name = layer_name,
        geomcols = geomcols,
        fieldtypes = norm_fieldtypes,
    )
end
