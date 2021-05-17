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
    field_names, geom_names, featuredefn, fielddefns = schema_names(layer)
    ngeom = ArchGDAL.ngeom(featuredefn)
    geomtypes = (IGeometry{ArchGDAL.gettype(ArchGDAL.getgeomdefn(featuredefn, i))} for i in 0:ngeom-1)
    field_types = (_FIELDTYPE[gettype(fielddefn)] for fielddefn in fielddefns)
    Tables.Schema((geom_names..., field_names...), (geomtypes..., field_types...))
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
    return nextnamedtuple(layer), st + 1
end

function Base.getindex(t::Table, idx::Integer)
    layer = getlayer(t)
    setnextbyindex!(layer, idx-1)
    return nextnamedtuple(layer)
end

Base.IteratorSize(::Type{<:Table}) = Base.HasLength()
Base.size(t::Table) = nfeature(getlayer(t))
Base.length(t::Table) = size(t)
Base.IteratorEltype(::Type{<:Table}) = Base.HasEltype()
Base.propertynames(t::Table) = Tables.schema(getlayer(t)).names
Base.getproperty(t::Table, s::Symbol) = [getproperty(row, s) for row in t]

"""
Returns the feature row of a layer as a `NamedTuple`

Calling it iteratively will work similar to `nextfeature` i.e. give the consecutive feature as `NamedTuple`
"""
function nextnamedtuple(layer::IFeatureLayer)
    field_names, geom_names = schema_names(layer)
    return nextfeature(layer) do feature
        prop = (getfield(feature, name) for name in field_names)
        geom = (getgeom(feature, idx-1) for idx in 1:length(geom_names))
        NamedTuple{(geom_names..., field_names...)}((geom..., prop...))
    end
end

function schema_names(layer::AbstractFeatureLayer)
    featuredefn = layerdefn(layer)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(layer)-1)
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = collect(Symbol(getname(getgeomdefn(featuredefn, i-1))) for i in 1:ngeom(layer))
    replace!(geom_names, Symbol("")=>Symbol("geometry"), count=1)
    return (field_names, geom_names, featuredefn, fielddefns)
end

function Base.show(io::IO, t::Table)
    println(io, "Table with $(nfeature(getlayer(t))) features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)
