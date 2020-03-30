struct GeoTable{AbstractVector} <: Tables.AbstractColumns 
    names::Array
    geometry :: AG.IGeometry[]
end


function geotable(dataset::ArchGDAL.IDataset)
    layer = getlayer(dataset, 0)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)
    nfld = nfield(featuredefn)
    featuredefn = layerdefn(layer)
    
    d = Dict{String, Vector}()
    featuredefn = AG.layerdefn(layer)
    for field_no in 0:nfield-1
        field = AG.getfielddefn(featuredefn, field_no)
        name = AG.getname(field)
        typ = AG._FIELDTYPE[AG.gettype(field)]
        d[name] = typ[]
    end
    
    d["geometry"] = AG.IGeometry[]

    for fid in 0:nfeat-1
        AG.getfeature(layer, fid) do feature
            for (k, v) in pairs(d)
                if k == "geometry"
                    val = AG.getgeom(feature, 0)
                else
                    val = AG.getfield(feature, k)
                end
                push!(v, val)
            end
        end
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

    Tables.istable(::Type{<:GeoTable}) = true
    # getter methods to avoid getproperty clash
    names(g::GeoTable) = getfield(g, :names)
    
    geometry(g::GeoTable) = getfield(g, :geometry)
    # schema is column names and types
    Tables.schema(g::GeoTable{T}) where {T} = Tables.Schema(names(g), )
