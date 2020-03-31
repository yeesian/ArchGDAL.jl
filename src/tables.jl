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
    # key = String[]
    # vals = []

    d["geometry"] = IGeometry[]
    # push!(key, "Geometry")

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

    # Named_Tuple = namedtuple(Symbol.(keys(d)), values(d))
    return namedtuple(Symbol.(keys(d)), values(d))
end

    # names = [
    #     ["geometry$(i-1)" for i in 1:ngeometries]; #in case there are more than one geometries
    #     [AG.getname(AG.getfielddefn(featuredefn,i-1)) for i in 1:nfld]
    # ]
    
    
    # types = [
    #     [AG.IGeometry for i in 1:ngeometries];
    #     [AG._FIELDTYPE[AG.gettype(AG.getfielddefn(featuredefn,i-1))] for i in 1:nfld]
    # ]
    
    #   val = if nfld <= ngeom
    #             getgeom(feature, col-1)
    #         else
    #             T(getfield(feature, col - ngeom - 1))
    #         end

    # Tables.istable(::Type{<:GeoTable}) = true
    # # getter methods to avoid getproperty clash
    # names(g::GeoTable) = getfield(g, :names)
    
    # geometry(g::GeoTable) = getfield(g, :geometry)
    # # schema is column names and types
    # Tables.schema(g::GeoTable{T}) where {T} = Tables.Schema(names(g), )