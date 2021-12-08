#----- Tables.jl functions specialization for ArchGDAL FDP_AbstractLayer -----#

@generated function _get_getgeom_funcs(::Type{FD}) where {FD<:FDType}
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
@generated function _get_getfield_funcs(::Type{FD}) where {FD<:FDType}
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

const SPECIALIZATION_THRESHOLD = 100

#TODO: Investigation how to make use of types for possible speedup and if not
#TODO: merge the two versions of eachcolumns
@inline @generated function Tables.eachcolumns(
    f::F,
    sch::Tables.Schema{names,types},
    row::FDP_AbstractFeature{FD},
    columns::S,
    args...,
) where {F,names,types,FD<:FDType,S}
    ng = _ngt(FD)
    nf = _nft(FD)
    ggfs = _get_getgeom_funcs(FD)
    gffs = _get_getfield_funcs(FD)
    rex = Expr(:block)
    for i in 1:ng
        push!(
            rex.args,
            :(f($(ggfs[i])(row), $i, names[$i], columns[$i], args...)),
        )
    end
    for i in 1:nf
        push!(
            rex.args,
            :(f(
                $(gffs[i])(row),
                $(i + ng),
                names[$(i + ng)],
                columns[$(i + ng)],
                args...,
            )),
        )
    end
    return rex
end

@inline @generated function eachcolumns(
    f::F,
    sch::Tables.Schema{names,nothing},
    row::FDP_AbstractFeature{FD},
    columns::S,
    args...,
) where {F,names,FD<:FDType,S}
    ng = _ngt(FD)
    nf = _nft(FD)
    ggfs = _get_getgeom_funcs(FD)
    gffs = _get_getfield_funcs(FD)
    rex = Expr(:block)
    for i in 1:ng
        push!(
            rex.args,
            :(f($(ggfs[i])(row), $i, names[$i], columns[$i], args...)),
        )
    end
    for i in 1:nf
        push!(
            rex.args,
            :(f(
                $(gffs[i])(row),
                $(i + ng),
                names[$(i + ng)],
                columns[$(i + ng)],
                args...,
            )),
        )
    end
    return rex
end

allocatecolumn(T, len) = Array{T,1}(undef, len)

@inline function _allocatecolumns(
    ::Tables.Schema{names,types},
    len,
) where {names,types}
    if @generated
        vals = Tuple(
            :(allocatecolumn($(fieldtype(types, i)), len)) for
            i in 1:fieldcount(types)
        )
        return :(NamedTuple{$(map(Symbol, names))}(($(vals...),)))
    else
        return NamedTuple{map(Symbol, names)}(
            Tuple(
                allocatecolumn(fieldtype(types, i), len) for
                i in 1:fieldcount(types)
            ),
        )
    end
end

@inline function allocatecolumns(
    sch::Tables.Schema{names,types},
    len,
) where {names,types}
    if fieldcount(types) <= SPECIALIZATION_THRESHOLD
        return _allocatecolumns(sch, len)
    else
        return NamedTuple{map(Symbol, names)}(
            Tuple(
                allocatecolumn(fieldtype(types, i), len) for
                i in 1:fieldcount(types)
            ),
        )
    end
end

@inline function add!(
    dest::AbstractArray,
    val,
    ::Union{Base.HasLength,Base.HasShape},
    row,
)
    return setindex!(dest, val, row)
end
@inline add!(dest::AbstractArray, val, T, row) = push!(dest, val)

replacex(t, col::Int, x) = ntuple(i -> i == col ? x : t[i], length(t))

@inline function add_or_widen!(
    val,
    col::Int,
    nm,
    dest::AbstractArray{T},
    fdp_feature,
    updated,
    L,
) where {T}
    if val isa T || promote_type(typeof(val), T) <: T
        add!(dest, val, L, fdp_feature)
        return
    else
        new = allocatecolumn(promote_type(T, typeof(val)), length(dest))
        fdp_feature > 1 && copyto!(new, 1, dest, 1, fdp_feature - 1)
        add!(new, val, L, fdp_feature)
        updated[] = replacex(updated[], col, new)
        return
    end
end

function __buildcolumns(fdp_layer, st, sch, columns, rownbr, updated)
    while true
        state = iterate(fdp_layer, st)
        state === nothing && break
        row, st = state
        rownbr += 1
        eachcolumns(
            add_or_widen!,
            sch,
            row,
            columns,
            rownbr,
            updated,
            Base.IteratorSize(fdp_layer),
        )
        columns !== updated[] && return __buildcolumns(
            fdp_layer,
            st,
            sch,
            updated[],
            rownbr,
            updated,
        )
    end
    return updated
end

struct EmptyVector <: AbstractVector{Union{}}
    len::Int
end
Base.IndexStyle(::Type{EmptyVector}) = Base.IndexLinear()
Base.size(x::EmptyVector) = (x.len,)
Base.getindex(x::EmptyVector, i::Int) = throw(UndefRefError())

function _buildcolumns(fdp_layer, fdp_feature, st, sch, columns, updated)
    eachcolumns(
        add_or_widen!,
        sch,
        fdp_feature,
        columns,
        1,
        updated,
        Base.IteratorSize(fdp_layer),
    )
    return __buildcolumns(fdp_layer, st, sch, updated[], 1, updated)
end

@inline function Tables.columns(
    fdp_layer::T,
) where {FD<:FDType,T<:FDP_AbstractFeatureLayer{FD}}
    state = iterate(fdp_layer)
    fdp_feature, st = state
    names = Tuple(Tables.columnnames(fdp_feature))
    len = Base.haslength(T) ? length(rowitr) : 0
    sch = Tables.Schema(names, nothing)
    columns = Tuple(EmptyVector(len) for _ in 1:length(names))
    return NamedTuple{map(Symbol, names)}(
        _buildcolumns(
            fdp_layer,
            fdp_feature,
            st,
            sch,
            columns,
            Ref{Any}(columns),
        )[],
    )
end
