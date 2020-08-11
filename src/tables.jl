const AG = ArchGDAL

struct GeoTable{T<:Union{IFeatureLayer, FeatureLayer}} 
    layer::T
end

function GeoTable(layer)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)

    if(ngeometries == 0 )
        error("Layer is not a valid ArchGDAL layer")
    end
    GeoTable(layer)
end

struct FeatureRow
    Geometry::Array
    feature_number::Int
end

function Tables.schema(layer::AG.AbstractFeatureLayer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeom = ArchGDAL.ngeom(featuredefn)

    fielddefns = (AG.getfielddefn(featuredefn, i) for i in 0:nfield-1)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)

    names_fields = Tuple(AG.getname(fielddefn) for fielddefn in fielddefns)
    geom_names = Tuple(ArchGDAL.getname(geomdefn) for geomdefn in geomdefns)
    names = (names_fields..., geom_names...)
    
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

    d = Dict{String, Vector}()

    for field_no in 0:nfield-1
        field = getfielddefn(featuredefn, field_no)
        name = getname(field)
        typ = _FIELDTYPE[gettype(field)]
        d[name] = typ[]
    end
    d["geometry"] = IGeometry[]
    
    st >= nfeat && return nothing
    AG.nextfeature(layer) do feature
        for (k, v) in pairs(d)
            if k == "geometry"
                val = getgeom(feature, 0)
            else
                val = getfield(feature, k)
            end
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
    return FeatureRow(Row, st), st + 1
end


Tables.istable(::Type{<:GeoTable}) = true
Tables.rowaccess(::Type{<:GeoTable}) = true
Tables.rows(gt::GeoTable) = gt

Base.IteratorSize(::Type{<:GeoTable}) = Base.HasLength()
Base.size(gt::GeoTable) = nfeature(gt.layer)
Base.length(gt::GeoTable) = (Base.size(gt::GeoTable)) * (nfield(gt.layer) + ngeom(gt.layer))
Base.IteratorEltype(::Type{<:GeoTable}) = Base.HasEltype()

Base.propertynames(fr::FeatureRow, gt::GeoTable) = (Tables.schema(gt.layer)).names
geometry(fr::FeatureRow) = (fr.Row)

function Base.show(io::IO, gt::GeoTable)
    println(io, "GeoTable with $(ArchGDAL.nfeature(gt.layer)) Features")
end
Base.show(io::IO, ::MIME"text/plain", gt::GeoTable) = show(io, gt)



