const AG = ArchGDAL

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

function Tables.schema(layer::AG.AbstractFeatureLayer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    fielddefns = (AG.getfielddefn(featuredefn, i) for i in 0:nfield-1)
    names_fields = Tuple(AG.getname(fielddefn) for fielddefn in fielddefns)
    types_fields = Tuple(AG._FIELDTYPE[AG.gettype(fielddefn)] for fielddefn in fielddefns)
    Tables.Schema(names_fields, types_fields)
end

function Base.iterate(t::Table, st = 0)
    layer = t.layer
    if iszero(st) 
        AG.resetreading!(layer) 
    end

    ngeom = AG.ngeom(layer)
    featuredefn = AG.layerdefn(layer)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)
    
    field_names = String[]
    typ = Tables.schema(layer).types
    nfield = AG.nfield(layer)
    for field_no in 0:nfield-1
        field = AG.getfielddefn(featuredefn, field_no)
        push!(field_names, AG.getname(field))
    end
    geom_names = [AG.getname(geomdefn) for geomdefn in geomdefns]
    nfeat = AG.nfeature(layer)
    st >= nfeat && return nothing
    v = Union{typ..., AG.IGeometry}[]
    AG.nextfeature(layer) do feature
        for name in field_names
            val = AG.getfield(feature, name)
            push!(v, val)
        end
        for idx in 1:length(geom_names)
            val = AG.getgeom(feature, idx-1)  
            push!(v, val)  
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
    println(io, "Table with $(ArchGDAL.nfeature(t.layer)) features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)
