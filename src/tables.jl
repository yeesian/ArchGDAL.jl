const AG = ArchGDAL

struct GeoTable{T<:Union{IFeatureLayer, FeatureLayer}} 
    layer::T
end

function geotable(layer)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)
    GeoTable(layer)
end

function Tables.schema(layer::AG.AbstractFeatureLayer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeom = ArchGDAL.ngeom(featuredefn)

    fielddefns = (AG.getfielddefn(featuredefn, i) for i in 0:nfield-1)
    names_fields = Tuple(AG.getname(fielddefn) for fielddefn in fielddefns)
    types_fields = Tuple(AG._FIELDTYPE[AG.gettype(fielddefn)] for fielddefn in fielddefns)
    geom_types = Tuple(ArchGDAL.gettype(geomdefn) for geomdefn in geomdefns)
    types = (types_fields..., geom_types...)
    
    Tables.Schema(names, types)
end

function Base.iterate(gt::GeoTable, st = 0)
    layer = gt.layer
    AG.resetreading!(layer)
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    ngeom = AG.ngeom(layer)
    featuredefn = layerdefn(layer)

    name = []
    v = []
    for field_no in 0:nfield-1
        field = AG.getfielddefn(featuredefn, field_no)
        push!(name, AG.getname(field))
    end
    d["geometry"] = IGeometry[]
    
    st >= nfeat && return nothing
    AG.getfeature(layer, st) do feature
        for (k, v) in pairs(d)
            if k == "geometry"
                val = getgeom(feature, 0)
            else
                val = getfield(feature, k)
            end
            push!(v, val)
        end
    end
    

    Row = NamedTuple{Tuple(Symbol.(name))}(v)
    return Row, st + 1
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



