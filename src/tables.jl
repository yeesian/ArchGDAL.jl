const AG = ArchGDAL

struct GeoTable{T<:Union{IFeatureLayer, FeatureLayer}} 
    layer::T
end

function GeoTable(layer)
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)

    if(ngeometries == 0 )
        error("Layer in not a valid ArchGDAL layer")
    end
    GeoTable(layer)
end

struct FeatureRow
    Row
    feature_number::Int
end

function Tables.schema(layer::AG.AbstractFeatureLayer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeom = ArchGDAL.ngeom(featuredefn)

    fielddefns = (AG.getfielddefn(featuredefn, i) for i in 0:nfield-1)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)

    names = Tuple(AG.getname(fielddefn) for fielddefn in fielddefns)
    geom_names = Tuple(ArchGDAL.getname(geomdefn) for geomdefn in geomdefns)
    
    types = Tuple(AG._FIELDTYPE[AG.gettype(fielddefn)] for fielddefn in fielddefns)
    geom_types = Tuple(ArchGDAL.gettype(geomdefn) for geomdefn in geomdefns)
 
    Tables.Schema(names, types)
end

function Base.iterate(gt::GeoTable, st = 0)
    layer = gt.layer
    schema = Tables.schema(layer)
    T = NamedTuple{schema.names, Tuple{schema.types...}}
    AG.resetreading!(layer)
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    Row = T[]
    st >= nfeat && return nothing
    AG.nextfeature(layer) do feature
        # AG.getgeom(feature, 0)  # TODO
        push!(Row, T(AG.getfield(feature, j) for j in 0:nfield-1))
        end
    return FeatureRow(Row, st), st + 1
end


Tables.istable(::Type{<:GeoTable}) = true
Tables.rowaccess(::Type{<:GeoTable}) = true
Tables.rows(gt::GeoTable) = gt

Base.propertynames(f::FeatureRow) = (Tables.schema(layer)).names
#type of geometry
# geometry(fr::FeatureRow) = json(fr).geometry


function Base.show(io::IO, gt::GeoTable)
    println(io, "GeoTable with $(ArchGDAL.nfeature(gt.layer)) Features")
end
# function Base.show(io::IO, fr::FeatureRow)
#     println(io, "Feature with geometry type $(geometry(fr).type) and properties $(propertynames(fr))")
# end
# Base.show(io::IO, ::MIME"text/plain", gt::GeoTable) = show(io, gt)
# Base.show(io::IO, ::MIME"text/plain", fr::FeatureRow) = show(io, fr)



# Base.IteratorSize(::Type{<:GeoTable}) = Base.HasLength()
# Base.length(gt::GeoTable) = length(layer(gt))
# Base.IteratorEltype(::Type{<:GeoTable}) = Base.HasEltype()

# # read only AbstractVector
# Base.size(gt::GeoTable) = size(json(gt))
# Base.getindex(gt::GeoTable, i) = Feature(json(gt)[i])
# Base.IndexStyle(::Type{<:GeoTable}) = IndexLinear()

# miss(x) = ifelse(x === nothing, missing, x)


# "Access the properties JSON3.Object of a Feature"
# properties(f::Feature) = json(f).properties
# "Access the JSON3.Object that represents the Feature"
# json(f::Feature) = getfield(f, :js    on)
# "Access the JSON3.Array that represents the FeatureCollection"
# json(f::FeatureCollection) = getfield(f, :json)

# "Access the JSON3.Object that represents the Feature's geometry"

# """
# Get a specific property of the Feature
# Returns missing for null/nothing or not present, to work nicely with
# properties that are not defined for every feature. If it is a table,
# it should in some sense be defined.
# """
# function Base.getproperty(f::Feature, nm::Symbol)
#     props = properties(f)
#     val = get(props, nm, missing)
#     miss(val)
# end

# function geotable(layer::Union{IFeatureLayer, FeatureLayer}, i::Int) 
#     featuredefn = layerdefn(layer)
#     ngeometries = ngeom(featuredefn)
#     nfield = ArchGDAL.nfield(featuredefn)
#     featuredefn = layerdefn(layer)
#     nfeat = nfeature(layer)

#     d = Dict{String, Vector}()

#     for field_no in 0:nfield-1
#         field = getfielddefn(featuredefn, field_no)
#         name = getname(field)
#         typ = _FIELDTYPE[gettype(field)]
#         d[name] = typ[]
#     end
    
#     d["geometry"] = IGeometry[]
    
#     for fid in 0:nfeat-1
#         getfeature(layer, fid) do feature
#             for (k, v) in pairs(d)
#                 if k == "geometry"
#                     val = getgeom(feature, 0)
#                 else
#                     val = getfield(feature, k)
#                 end
#                 push!(v, val)
#             end
#         end
#     end
#     keys_tup = ()
#     for _key in keys(d)
#         keys_tup = (keys_tup..., Symbol(_key))
#     end
#     vals_tup = Tuple(values(d))
    
#     #Using the tables interface
#     Rows = Tables.rowtable(NamedTuple{keys_tup}(vals_tup))
#     return Rows
# end
