const AG = ArchGDAL

struct Table{T} 
    layer::T
end

function Table(layer::T) where {T<:Union{IFeatureLayer, FeatureLayer}}
    featuredefn = layerdefn(layer)
    ngeometries = ngeom(featuredefn)
    if ngeometries == 0
        print("NULL Geometry found")
    end
    Table{T}(layer)
end

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

    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    ngeom = AG.ngeom(layer)
    featuredefn = AG.layerdefn(layer)
    geomdefns = (ArchGDAL.getgeomdefn(featuredefn, i) for i in 0:ngeom-1)
    
    name = []
    v = []
    for field_no in 0:nfield-1
        field = AG.getfielddefn(featuredefn, field_no)
        push!(name, AG.getname(field))
    end
    geom_names = [ArchGDAL.getname(geomdefn) for geomdefn in geomdefns]
    push!(name, geom_names...)

    st >= nfeat && return nothing
    AG.nextfeature(layer) do feature
        for k in name
            if k in geom_names
                val = AG.getgeom(feature, findfirst(a->a==k, geom_names)-1)
            else
                val = AG.getfield(feature, k)
            end
            push!(v, val)
        end
    end
    
    Row = NamedTuple{Tuple(Symbol.(name))}(v)
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
    println(io, "Table with $(ArchGDAL.nfeature(t.layer)) Features")
end
Base.show(io::IO, ::MIME"text/plain", t::Table) = show(io, t)



