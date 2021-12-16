###################################
# Trial with GeneralizedGenerated #
###################################
# - Runtime generated functions for:
#   - geom columns: _get_getgeom_funcs_gg
#   - field columns: _get_getfield_funcs_gg
# - Feature to columns line function: FDPf2c_gg
# - (Tables.)columns function: FDPcolumns_gg

function _get_getgeom_funcs_gg(::Type{FD}) where {FD<:FDType}
    NG = _ngt(FD)
    f0 = mk_function(
        ArchGDAL,
        :(
            function (row)
                return (geomptr = GDAL.ogr_f_stealgeometry(row.ptr)) == C_NULL ? missing : IGeometry(geomptr)
            end
        ),
    )
    return NG == 1 ? (f0,) :
           (
        f0,
        (
            mk_function(
                ArchGDAL,
                :(
                    function (row)
                        return (
                            geomptr =
                                GDAL.ogr_f_getgeomfieldref(feature.ptr, $k)
                        ) == C_NULL ? missing : IGeometry(geomptr)
                    end
                ),
            ) for k in 2:NG
        )...,
    )
end

function _get_getfield_funcs_gg(::Type{FD}) where {FD<:FDType}
    NF = _nft(FD)
    fafs = _get_fields_asfuncs(FD)
    return (
        (
            mk_function(
                ArchGDAL,
                :(
                    function (row)
                        return !(isfieldset(row, $(k - 1))) ? nothing :
                               isfieldnull(row, $(k - 1)) ? missing :
                               $(fafs[k])(row, $(k - 1))
                    end
                ),
            ) for k in 1:NF
        )...,
    )
end

@generated function FDPf2c_gg(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Int,
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    ng = _ngt(FD)
    nf = _nft(FD)
    ggfs = _get_getgeom_funcs_gg(FD)
    gffs = _get_getfield_funcs_gg(FD)
    rex = Expr(:block)
    push!(rex.args, Expr(:inbounds, true))
    for j in 1:ng
        push!(rex.args, :(cols[$j][i] = $(ggfs[j])(fdp_feature)))
    end
    for j in ng+1:ng+nf
        push!(rex.args, :(cols[$j][i] = $(gffs[j-ng])(fdp_feature)))
    end
    push!(rex.args, Expr(:inbounds, :pop))
    push!(rex.args, :(nothing))
    return rex
end

function FDPfillcolumns_gg!(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    state = 0
    while true
        next = iterate(fdp_layer, state)
        next === nothing && break
        fdp_feature, state = next
        FDPf2c_gg(fdp_feature, state, cols)
    end
end

function FDPcolumns_gg(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
) where {FD<:FDType}
    len = length(fdp_layer)
    gdal_sch = Tables.schema(fdp_layer)
    ng = _ngt(FD)
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    FDPfillcolumns_gg!(fdp_layer, cols)
    return NamedTuple{gdal_sch.names}(
        NTuple{length(gdal_sch.names)}([
            convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c)
            for c in cols
        ]),
    )
end

#######################################
# Trial with RuntimeGeneratedFunction #
#######################################
# - Runtime generated functions for:
#   - geom columns: _get_getgeom_funcs_rgf
#   - field columns: _get_getfield_funcs_rgf
# - Feature to columns line function: FDPf2c_rgf
# - (Tables.)columns function: FDPcolumns_rgf

function _get_getgeom_funcs_rgf(::Type{FD}) where {FD<:FDType}
    NG = _ngt(FD)
    f0 = @RuntimeGeneratedFunction(
        ArchGDAL,
        :(
            function (row)
                return (geomptr = GDAL.ogr_f_stealgeometry(row.ptr)) == C_NULL ? missing : IGeometry(geomptr)
            end
        ),
    )
    return NG == 1 ? (f0,) :
           (
        f0,
        (
            @RuntimeGeneratedFunction(
                ArchGDAL,
                :(
                    function (row)
                        return (
                            geomptr =
                                GDAL.ogr_f_getgeomfieldref(feature.ptr, $k)
                        ) == C_NULL ? missing : IGeometry(geomptr)
                    end
                ),
            ) for k in 2:NG
        )...,
    )
end

function _get_getfield_funcs_rgf(::Type{FD}) where {FD<:FDType}
    NF = _nft(FD)
    fafs = _get_fields_asfuncs(FD)
    return (
        (
            @RuntimeGeneratedFunction(
                ArchGDAL,
                :(
                    function (row)
                        return !(isfieldset(row, $(k - 1))) ? nothing :
                               isfieldnull(row, $(k - 1)) ? missing :
                               $(fafs[k])(row, $(k - 1))
                    end
                ),
            ) for k in 1:NF
        )...,
    )
end

@generated function FDPf2c_rgf(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Int,
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    ng = _ngt(FD)
    nf = _nft(FD)
    ggfs = _get_getgeom_funcs_rgf(FD)
    gffs = _get_getfield_funcs_rgf(FD)
    rex = Expr(:block)
    push!(rex.args, Expr(:inbounds, true))
    for j in 1:ng
        push!(rex.args, :(cols[$j][i] = $(ggfs[j])(fdp_feature)))
    end
    for j in ng+1:ng+nf
        push!(rex.args, :(cols[$j][i] = $(gffs[j-ng])(fdp_feature)))
    end
    push!(rex.args, Expr(:inbounds, :pop))
    push!(rex.args, :(nothing))
    return rex
end

function FDPfillcolumns_rgf!(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    state = 0
    while true
        next = iterate(fdp_layer, state)
        next === nothing && break
        fdp_feature, state = next
        FDPf2c_rgf(fdp_feature, state, cols)
    end
end

function FDPcolumns_rgf(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
) where {FD<:FDType}
    len = length(fdp_layer)
    gdal_sch = Tables.schema(fdp_layer)
    ng = _ngt(FD)
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    FDPfillcolumns_rgf!(fdp_layer, cols)
    return NamedTuple{gdal_sch.names}(
        NTuple{length(gdal_sch.names)}([
            convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c)
            for c in cols
        ]),
    )
end

########################################
# Trial with plain generated functions #
########################################
# - Feature to columns line function: FDPf2c_pg
# - (Tables.)columns function: FDPfillcolumns_pg

@generated function FDPf2c_pg(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Int,
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    ng = _ngt(FD)
    nf = _nft(FD)
    return quote
        @inbounds for j in 1:($nf+$ng)
            cols[j][i] = Tables.getcolumn(fdp_feature, j)
        end
        return nothing
    end
end

function FDPfillcolumns_pg!(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    state = 0
    while true
        next = iterate(fdp_layer, state)
        next === nothing && break
        fdp_feature, state = next
        FDPf2c_pg(fdp_feature, state, cols)
    end
end

function FDPcolumns_pg(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
) where {FD<:FDType}
    len = length(fdp_layer)
    gdal_sch = Tables.schema(fdp_layer)
    ng = _ngt(FD)
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    FDPfillcolumns_pg!(fdp_layer, cols)
    return NamedTuple{gdal_sch.names}(
        NTuple{length(gdal_sch.names)}([
            convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c)
            for c in cols
        ]),
    )
end

#########################################################
# Best trials for FDP layer selected for Tables.columns #
#########################################################

# Intermediary steps performance measurement commented below
function Tables.columns(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
) where {FD<:FDType}
    len = length(fdp_layer)
    gdal_sch = Tables.schema(fdp_layer)
    ng = _ngt(FD)
    # print("\tinit columns     : ")
    # @time columns = [
    #     [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
    #     [Vector{Union{Missing,Nothing,T}}(missing, len) for T in gdal_sch.types[ng+1:end]]
    # ]
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    # print("\tfill vectors     : ")
    # @time FDPfillcolumns_pg!(fdp_layer, cols)
    FDPfillcolumns_pg!(fdp_layer, cols)
    # print("\ttrim col types   :")
    # @time trimmed_col_types = Tuple(promote_type(unique(typeof(e) for e in c)...) for c in cols)
    # print("\tconv cols types  :")
    # @time type_trimmed_columns = [
    #     convert(Vector{trimmed_col_types[i]}, c) for (i, c) in enumerate(cols)
    # ]
    # print("\ttuples to NT     : ")
    # @time nt = NamedTuple{gdal_sch.names}(
    #     NTuple{length(gdal_sch.names)}(type_trimmed_columns),
    # )
    # return nt
    return NamedTuple{gdal_sch.names}(
        NTuple{length(gdal_sch.names)}([
            convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c)
            for c in cols
        ]),
    )
end

###################################
# Tables.columns for normal layer #
###################################

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
    gdal_sch = Tables.schema(layer)
    ng = ngeom(layer)
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    fillcolumns!(layer, cols)
    return cols
    # return NamedTuple{gdal_sch.names}(
    #     NTuple{length(gdal_sch.names)}([
    #         convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c) for c in cols
    #     ]),
    # )
end
