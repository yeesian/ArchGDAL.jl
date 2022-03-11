function Tables.schema(::AbstractFeatureLayer)::Nothing
    return nothing
end

function gdal_schema(layer::AbstractFeatureLayer)
    geom_names, field_names, featuredefn, fielddefns =
        schema_names(layerdefn(layer))
    ngeom = ArchGDAL.ngeom(featuredefn)
    geom_types =
        (IGeometry{gettype(getgeomdefn(featuredefn, i))} for i in 0:ngeom-1)
    field_types =
        (convert(DataType, gettype(fielddefn)) for fielddefn in fielddefns)
    return Tables.Schema(
        (geom_names..., field_names...),
        (geom_types..., field_types...),
    )
end

Tables.istable(::Type{<:AbstractFeatureLayer})::Bool = true
Tables.rowaccess(::Type{<:AbstractFeatureLayer})::Bool = true

function Tables.rows(layer::T)::T where {T<:AbstractFeatureLayer}
    return layer
end

function Tables.getcolumn(row::AbstractFeature, i::Int)
    ng = ngeom(row)
    return if i <= ng
        geom = getgeom(row, i - 1)
        geom.ptr != C_NULL ? geom : missing
    else
        getfield(row, i - ng - 1)
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
    row::AbstractFeature,
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

#############################################################
# Tables.columns on AbstractFeatture layer for normal layer #
#############################################################

function f2c(feature::AbstractFeature, i::Int, cols::Vector{Vector{T} where T})
    ng = ngeom(feature)
    nf = nfield(feature)
    @inbounds for j in 1:(nf+ng)
        cols[j][i] = Tables.getcolumn(feature, j)
    end
    return nothing
end

function fillcolumns!(
    layer::AbstractFeatureLayer,
    cols::Vector{Vector{T} where T},
)
    state = 0
    while true
        next = iterate(layer, state)
        next === nothing && break
        feature, state = next
        f2c(feature, state, cols)
    end
end

function Tables.columns(layer::AbstractFeatureLayer)
    len = length(layer)
    gdal_sch = gdal_schema(layer)
    ng = ngeom(layer)
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    fillcolumns!(layer, cols)
    return if VERSION < v"1.7"
        NamedTuple{gdal_sch.names}(
            NTuple{length(gdal_sch.names),Vector{T} where T}([
                convert(
                    Vector{promote_type(unique(typeof(e) for e in c)...)},
                    c,
                ) for c in cols
            ]),
        )
    else
        NamedTuple{gdal_sch.names}(
            convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c)
            for c in cols
        )
    end
end
