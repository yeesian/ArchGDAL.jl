function geotable(dataset::ArchGDAL.IDataset)
    layer = getlayer(dataset, 0)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)
    nfield = ArchGDAL.nfield(featuredefn)
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
    
    return NamedTuple{keys_tup}(vals_tup)
end

    
    # Tables.istable(::Type{<:GeoTable}) = true
    # # getter methods to avoid getproperty clash
    # names(g::GeoTable) = getfield(g, :names)
    
    # geometry(g::GeoTable) = getfield(g, :geometry)
    # # schema is column names and types
    # Tables.schema(g::GeoTable{T}) where {T} = Tables.Schema(names(g), )
