function geotable(layer::Union{IFeatureLayer, FeatureLayer}, i::Int)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)
    nfield = nfield(featuredefn)
    featuredefn = layerdefn(layer)
    nfeat = nfeature(layer)


    d = Dict{String, Vector}()

    for field_no in 0:nfield-1
        field = getfielddefn(featuredefn, field_no)
        name = getname(field)
        typ = _FIELDTYPE[gettype(field)]
        d[name] = typ[]
    end
    
    d["geometry"] = IGeometry[]
    
    for fid in 0:nfeat-1
        getfeature(layer, fid) do feature
            for (k, v) in pairs(d)
                if k == "geometry"
                    val = getgeom(feature, 0)
                else
                    val = getfield(feature, k)
                end
                push!(v, val)
            end
        end
    end
    keys_tup = ()
    for _key in keys(d)
        keys_tup = (keys_tup..., Symbol(_key))
    end
    vals_tup = Tuple(values(d))
    
    #Using the tables interface
    RowTable = rowtable(NamedTuple{keys_tup}(vals_tup))
    return reshape(RowTable, (1,length(RowTable)))
end

# Base.eltype(#type) where {T} = GeoTableRow{T}
# Base.iterate(#type, st=1) = st > length(m) ? nothing : (#logic)
# Base.length(#type) = length(geotable(#type))



# Base.IteratorSize(::Type{<:#type}) = Base.HasLength()
# Base.IteratorEltype(::Type{<:#type}) = Base.HasEltype()

# function Base.iterate(t::Table, st = 1)
#     st > length(t) && return nothing
#     geom = @inbounds getshp(t).shapes[st]
#     record = DBFTables.Row(getdbf(t), st)
#     return Row(geom, record), st + 1
# end

# #Implementing the tables interface

# Tables.istable(::Type{<:geotable}) = true
# Tables.rowaccess(::Type{<:geotable}) = true
# Tables.rows(g::geotable) = g

# Tables.schema(g::geotable) = Tables.Schema()
    

