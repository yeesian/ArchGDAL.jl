"""
Constructs `Table` out of `FeatureLayer`, where every row is a `Feature` consisting of Geometry and attributes.
```
ArchGDAL.Table(T::Union{IFeatureLayer, FeatureLayer})
```
"""
struct Table{T<:Union{IFeatureLayer, FeatureLayer}}
    layer::T
end

getlayer(t::Table) = Base.getfield(t, :layer)

function Tables.schema(layer::AbstractFeatureLayer)
    featuredefn = layerdefn(layer)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(layer)-1)
    names_fields = (getname(fielddefn) for fielddefn in fielddefns)
    types_fields = (_FIELDTYPE[gettype(fielddefn)] for fielddefn in fielddefns)
    
    ngeom = ArchGDAL.ngeom(featuredefn)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)
    geom_names = (ArchGDAL.getname(geomdefn) for geomdefn in geomdefns)
    geom_types = (IGeometry for i in 1:ngeom)
    
    Tables.Schema((names_fields..., geom_names...), (types_fields..., geom_types...))
end

Tables.istable(::Type{<:Table}) = true
Tables.rowaccess(::Type{<:Table}) = true
Tables.rows(t::Table) = t

function Base.iterate(t::Table, st = 0)
    layer = getlayer(t)
    st >= nfeature(layer) && return nothing
    if iszero(st)
        resetreading!(layer)
    end
    return get_row(layer), st + 1
end

Base.IteratorSize(::Type{<:Table}) = Base.HasLength()
Base.size(t::Table) = nfeature(getlayer(t))
Base.length(t::Table) = size(t)
Base.IteratorEltype(::Type{<:Table}) = Base.HasEltype()
Base.propertynames(t::Table) = Tables.schema(getlayer(t)).names
Base.getproperty(t::Table, s::Symbol) = [getproperty(iterate(t, i)[1], s) for i in 0:size(t)-1]

function Base.getindex(t::Table, idx::Int)
    layer = getlayer(t)
    setnextbyindex!(layer, idx) 
    return get_row(layer)
end
    
function get_row(layer::IFeatureLayer)
    featuredefn = layerdefn(layer)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(layer)-1)
    field_names = Tuple(Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = (Symbol(getname(getgeomdefn(featuredefn, i-1))) for i in 1:ngeom(layer))

    v = Union{Tables.schema(layer).types...}[]
    nextfeature(layer) do feature
        for name in field_names
            push!(v, getfield(feature, name))
        end
        for idx in 1:length(geom_names)
            push!(v, getgeom(feature, idx-1))
        end
    end
    row = NamedTuple{(field_names..., geom_names...)}(v)
end

function Base.show(io::IO, t::Table)
    println(io, "Table with $(nfeature(getlayer(t))) features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)
