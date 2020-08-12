const AG = ArchGDAL

struct GeoTable{T<:Union{IFeatureLayer, FeatureLayer}} 
    layer::T
end

function geotable(layer)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)
    if(ngeometries == 0 )
        println("NULL Geometry found")
    end
    GeoTable(layer)
end

function Tables.schema(layer::AG.AbstractFeatureLayer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeom = ArchGDAL.ngeom(featuredefn)

    fielddefns = (AG.getfielddefn(featuredefn, i) for i in 0:nfield-1)
    names_fields = Tuple(AG.getname(fielddefn) for fielddefn in fielddefns)
    types_fields = Tuple(AG._FIELDTYPE[AG.gettype(fielddefn)] for fielddefn in fielddefns)
    
    Tables.Schema(names_fields, types_fields)
end

function Base.iterate(gt::GeoTable, st = 0)
    layer = gt.layer
    AG.resetreading!(layer)
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    featuredefn = layerdefn(layer)

    d = Dict{String, Vector}()

    for field_no in 0:nfield-1
        field = getfielddefn(featuredefn, field_no)
        name = getname(field)
        d[name] = Vector{_FIELDTYPE[gettype(field)]}()
    end
    
    st >= nfeat && return nothing
    AG.getfeature(layer, st) do feature
        for (k, v) in pairs(d)
            val = getfield(feature, k)
            push!(v, val)
        end
    end
    
    keys_tup = ()
    for _key in keys(d)
        keys_tup = (keys_tup..., Symbol(_key))
    end
    vals_tup = Tuple(values(d))
    
    #Using the tables interface
    Row = Tables.rowtable(NamedTuple{keys_tup}(vals_tup))
    return Row..., st + 1
end


Tables.istable(::Type{<:GeoTable}) = true
Tables.rowaccess(::Type{<:GeoTable}) = true
Tables.rows(gt::GeoTable) = gt

Base.IteratorSize(::Type{<:GeoTable}) = Base.HasLength()
Base.size(gt::GeoTable) = nfeature(gt.layer)
Base.length(gt::GeoTable) = Base.size(gt)
Base.IteratorEltype(::Type{<:GeoTable}) = Base.HasEltype()
Base.propertynames(gt::GeoTable) = (Tables.schema(gt.layer)).names

"""
returns the nth geometry starting from 1 to n
"""
function geometry(gt::GeoTable, n::Int)
    if n > length(gt)
        return "NULL Geometry"
    else
        layer = gt.layer
        AG.getfeature(layer, n-1) do feature
        getgeom(feature)
        end
    end
end

function geometry(gt::GeoTable)
    layer = gt.layer
    AG.resetreading!(layer)
    arr = AG.IGeometry[]
    for i in 1:length(gt)
        AG.nextfeature(layer) do feature
        push!(arr, getgeom(feature))
        end
    end
    return arr
end

function Base.show(io::IO, gt::GeoTable)
    println(io, "GeoTable with $(ArchGDAL.nfeature(gt.layer)) Features")
end
Base.show(io::IO, ::MIME"text/plain", gt::GeoTable) = show(io, gt)



