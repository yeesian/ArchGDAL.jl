mutable struct Source <: Data.Source
    schema::Data.Schema
    featurelayer::FeatureLayer
    feature::ArchGDAL.Feature
    ngeom::Int
end

function Source(layer::FeatureLayer)
    layerdefn = getlayerdefn(layer)
    ngeom = ngeomfield(layerdefn)
    nfld = nfield(layerdefn)
    header = [
        ["geometry$(i-1)" for i in 1:ngeom];
        [getname(getfielddefn(layerdefn,i-1)) for i in 1:nfld]
    ]
    types = [
        [IGeometry for i in 1:ngeom];
        [_FIELDTYPE[gettype(getfielddefn(layerdefn,i-1))] for i in 1:nfld]
    ]
    ArchGDAL.Source(
        Data.Schema(header, types, nfeature(layer)),
        layer,
        unsafe_nextfeature(layer),
        ngeom
    )
end
Data.isdone(s::ArchGDAL.Source, row, col) = s.feature.ptr == C_NULL
Data.schema(source::ArchGDAL.Source, ::Type{Data.Field}) = source.schema
Data.streamtype(::Type{ArchGDAL.Source}, ::Type{Data.Field}) = true

function Data.streamfrom{T}(
        source::ArchGDAL.Source,
        ::Type{Data.Field},
        ::Type{Nullable{T}},
        row,
        col
    )
    val = if col <= source.ngeom
        Nullable{T}(getgeomfield(source.feature, col-1))
    else
        Nullable{T}(getfield(source.feature, col-source.ngeom-1))
    end
    if col == source.schema.cols
        destroy(source.feature)
        source.feature.ptr = @gdal(
            OGR_L_GetNextFeature::GDALFeature,
            source.featurelayer.ptr::GDALFeatureLayer
        )
        if row == source.schema.rows
            @assert source.feature.ptr == C_NULL
            resetreading!(source.featurelayer)
        end
    end
    val
end

function Data.streamfrom{T}(
        source::ArchGDAL.Source,
        ::Type{Data.Field},
        ::Type{T},
        row,
        col
    )
    val = if col <= source.ngeom
        T(getgeomfield(source.feature, col-1).ptr)
    else
        T(getfield(source.feature, col-source.ngeom-1))
    end
    if col == source.schema.cols
        destroy(source.feature)
        source.feature.ptr = @gdal(
            OGR_L_GetNextFeature::GDALFeature,
            source.featurelayer.ptr::GDALFeatureLayer
        )
        if row == source.schema.rows
            @assert source.feature.ptr == C_NULL
            resetreading!(source.featurelayer)
        end
    end
    val
end
