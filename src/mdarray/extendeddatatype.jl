# GDALExtendedDataType

function Base.:(==)(
    firstedt::AbstractExtendedDataType,
    secondedt::AbstractExtendedDataType,
)::Bool
    @assert !isnull(firstedt)
    @assert !isnull(secondedt)
    return Bool(GDAL.gdalextendeddatatypeequals(firstedt, secondedt))
end

function getname(edt::AbstractExtendedDataType)::AbstractString
    @assert !isnull(edt)
    return GDAL.gdalextendeddatatypegetname(edt)
end

# TODO: Wrap GDAL.GDALExtendedDataTypeClass
function getclass(edt::AbstractExtendedDataType)::GDAL.GDALExtendedDataTypeClass
    @assert !isnull(edt)
    return GDAL.gdalextendeddatatypegetclass(edt)
end

function getnumericdatatype(edt::AbstractExtendedDataType)::GDALDataType
    @assert !isnull(edt)
    return convert(
        GDALDataType,
        GDAL.gdalextendeddatatypegetnumericdatatype(edt),
    )
end

# TODO: Wrap GDAL.GDALExtendedDataTypeSubType
function getsubtype(
    edt::AbstractExtendedDataType,
)::GDAL.GDALExtendedDataTypeSubType
    @assert !isnull(edt)
    return GDAL.gdalextendeddatatypegetsubtype(edt)
end

function unsafe_getcomponents(
    edt::AbstractExtendedDataType,
)::AbstractVector{<:AbstractEDTComponent}
    @assert !isnull(edt)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalextendeddatatypegetcomponents(edt, count)
    components = AbstractEDTComponent[
        EDTComponent(unsafe_load(ptr, n)) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return components
end

function getcomponents(
    edt::AbstractExtendedDataType,
)::AbstractVector{<:AbstractEDTComponent}
    @assert !isnull(edt)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalextendeddatatypegetcomponents(edt, count)
    components = AbstractEDTComponent[
        IEDTComponent(unsafe_load(ptr, n)) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return components
end

function getsize(edt::AbstractExtendedDataType)::Int
    @assert !isnull(edt)
    return Int(GDAL.gdalextendeddatatypegetsize(edt))
end

function getmaxstringlength(edt::AbstractExtendedDataType)::Int
    @assert !isnull(edt)
    return Int(GDAL.gdalextendeddatatypegetmaxstringlength(edt))
end

function canconvertto(
    sourceedt::AbstractExtendedDataType,
    targetedt::AbstractExtendedDataType,
)::Bool
    @assert !isnull(sourceedt)
    @assert !isnull(targetedt)
    return Bool(GDAL.gdalextendeddatatypecanconvertto(sourceedt, targetedt))
end

# TODO: automate this
function needsfreedynamicmemory(edt::AbstractExtendedDataType)::Bool
    return Bool(GDAL.gdalextendeddatatypeneedsfreedynamicmemory(edt))
end

function freedynamicmemory(
    edt::AbstractExtendedDataType,
    buffer::Ptr{Cvoid},
)::Nothing
    GDAL.gdalextendeddatatypefreedynamicmemory(edt, buffer)
    return nothing
end

################################################################################

function unsafe_extendeddatatypecreate(
    ::Type{T},
)::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return ExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end

function extendeddatatypecreate(::Type{T})::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return IExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end

# TODO: Wrap GDAL.GDALExtendedDataTypeSubType
function unsafe_extendeddatatypecreatestring(
    maxstringlength::Integer = 0,
    subtype::GDAL.GDALExtendedDataTypeSubType = GDAL.GEDTST_NONE,
)::AbstractExtendedDataType
    return ExtendedDataType(
        GDAL.gdalextendeddatatypecreatestringex(maxstringlength, subtype),
    )
end

function extendeddatatypecreatestring(
    maxstringlength::Integer = 0,
    subtype::GDAL.GDALExtendedDataTypeSubType = GDAL.GEDTST_NONE,
)::AbstractExtendedDataType
    return IExtendedDataType(
        GDAL.gdalextendeddatatypecreatestringex(maxstringlength, subtype),
    )
end

# copyvalue
# copyvalues

################################################################################

# GDLEDTComponent

function getname(comp::AbstractEDTComponent)::AbstractString
    @assert !isnull(comp)
    return GDAL.gdaledtcomponenttgetname(comp)
end

function getoffset(comp::AbstractEDTComponent)::Int
    @assert !isnull(comp)
    return Int(GDAL.gdaledtcomponenttgetoffset(comp))
end

function unsafe_gettype(comp::AbstractEDTComponent)::AbstractExtendedDataType
    @assert !isnull(comp)
    return ExtendedDatatType(GDAL.gdaledtcomponenttgettype(comp))
end

function gettype(comp::AbstractEDTComponent)::AbstractExtendedDataType
    @assert !isnull(comp)
    return IExtendedDatatType(GDAL.gdaledtcomponenttgettype(comp))
end
