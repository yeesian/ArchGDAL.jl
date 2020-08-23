"""
Constructs `Table` out of `FeatureLayer`, where every row is a `Feature` consisting of Geometry and attributes.
```
ArchGDAL.Table(T::Union{IFeatureLayer, FeatureLayer})
```
"""
struct Table{T} 
    layer::T
end

Table(layer::T) where {T<:Union{IFeatureLayer, FeatureLayer}} = Table{T}(layer)

function Tables.schema(layer::AbstractFeatureLayer)
    featuredefn = layerdefn(layer)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(layer)-1)
    names_fields = Tuple(getname(fielddefn) for fielddefn in fielddefns)
    types_fields = Tuple(_FIELDTYPE[gettype(fielddefn)] for fielddefn in fielddefns)
    Tables.Schema(names_fields, types_fields)
end

function Base.iterate(t::Table, st = 0)
    layer = t.layer
    if iszero(st) 
        resetreading!(layer) 
    end

    featuredefn = layerdefn(layer)    
    field_names = [getname(getfielddefn(featuredefn, i-1)) for i in 1:nfield(layer)]
    geom_names = [getname(getgeomdefn(featuredefn, i-1)) for i in 1:ngeom(layer)]

    st >= nfeature(layer) && return nothing
    v = Union{Tables.schema(layer).types..., IGeometry}[]
    nextfeature(layer) do feature
        for name in field_names
            push!(v, getfield(feature, name))
        end
        for idx in 1:length(geom_names)
            push!(v, getgeom(feature, idx-1))  
        end
    end
    Row = NamedTuple{(Symbol.(field_names)..., Symbol.(geom_names)...)}(v)
    return Row, st + 1
end

Tables.istable(::Type{<:Table}) = true
Tables.rowaccess(::Type{<:Table}) = true
Tables.rows(t::Table) = t

Base.IteratorSize(::Type{<:Table}) = Base.HasLength()
Base.size(t::Table) = nfeature(t.layer)
Base.length(t::Table) = Base.size(t)
Base.IteratorEltype(::Type{<:Table}) = Base.HasEltype()
Base.propertynames(t::Table) = Tables.schema(t.layer).names

function Base.show(io::IO, t::Table)
    println(io, "Table with $(nfeature(t.layer)) features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)
