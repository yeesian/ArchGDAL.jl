struct GeoTable{T <: NamedTuple} <:AbstractVector{T}
        parsed_shapefile::T
end

function geotable(layer::Union{IFeatureLayer, FeatureLayer}, i::Int) 
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
    
    #Using the tables interface
    RowTable = rowtable(NamedTuple{keys_tup}(vals_tup))
    return GeoTable(reshape(RowTable, (1,length(RowTable))))
end

# "Struct representing a singe record in a shapefile"
# struct Row{T}
#      ######
# end

Tables.istable(::Type{<:GeoTable}) = true
Tables.rowaccess(::Type{<:GeoTable}) = true
Tables.rows(g::GeoTable) = g  

# Base.IteratorSize(::Type{<:GeoTable}) = Base.HasLength()
# Base.length(fc::GeoTable) = length(geotable(g))
# Base.IteratorEltype(::Type{<:GeoTable}) = Base.HasEltype()


# "Iterate over the rows of a Shapefile.Table, yielding a Shapefile.Row for each row"
# Base.iterate(g::GeoTable, st=1) = st > length(g) ? nothing : (Row(st, g), st + 1




# Tables.schema(g::geotable) = Tables.Schema()
    

