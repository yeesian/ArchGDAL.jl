# function Tables.schema(::AbstractFeatureLayer)::Nothing
#     return nothing
# end

function Tables.schema(layer::AbstractFeatureLayer)
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

@generated function Tables.schema(
    ::FDP_AbstractFeatureLayer{FD},
) where {FD<:FDType}
    gnames = _gtnames(FD)
    fnames = _ftnames(FD)
    gtypes = (convert(IGeometry, gt) for gt in _gttypes(FD))
    ftypes = (get(FType2DataType, ft, missing) for ft in _fttypes(FD))
    return Tables.Schema((gnames..., fnames...), (gtypes..., ftypes...))
end

Tables.istable(::Type{<:DUAL_AbstractFeatureLayer})::Bool = true
Tables.rowaccess(::Type{<:DUAL_AbstractFeatureLayer})::Bool = true

function Tables.rows(layer::T)::T where {T<:DUAL_AbstractFeatureLayer}
    return layer
end

function Tables.getcolumn(row::AbstractFeature, i::Int)
    ng = ngeom(row)
    return if i <= ng
        geom = stealgeom(row, i - 1)
        geom.ptr != C_NULL ? geom : missing
    else
        getfield(row, i - ng - 1)
    end
end

function Tables.getcolumn(
    row::FDP_AbstractFeature{FD},
    i::Int,
) where {FD<:FDType}
    ng = ngeom(row)
    return if i <= ng
        geom = stealgeom(row, i - 1)
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
    geom = stealgeom(row, name)
    if geom.ptr != C_NULL
        return geom
    end
    return missing
end

function Tables.getcolumn(
    row::FDP_AbstractFeature{FD},
    name::Symbol,
) where {FD<:FDType}
    field = getfield(row, name)
    if !ismissing(field)
        return field
    end
    geom = stealgeom(row, name)
    if geom.ptr != C_NULL
        return geom
    end
    return missing
end

function Tables.columnnames(
    row::DUAL_AbstractFeature,
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

#TODO: check wether some functions used in schema_names could be optimized
function schema_names(
    fdp_featuredefn::FDP_IFeatureDefnView{FD},
) where {FD<:FDType}
    fielddefns =
        (getfielddefn(fdp_featuredefn, i) for i in 0:nfield(fdp_featuredefn)-1)
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = collect(
        Symbol(getname(getgeomdefn(fdp_featuredefn, i - 1))) for
        i in 1:ngeom(fdp_featuredefn)
    )
    return (geom_names, field_names, fdp_featuredefn, fielddefns)
end
