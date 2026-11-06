# GDALExtendedDataType

function Base.:(==)(
    firstedt::AbstractExtendedDataType,
    secondedt::AbstractExtendedDataType,
)::Bool
    @assert !isnull(firstedt)
    @assert !isnull(secondedt)
    return Bool(GDAL.gdalextendeddatatypeequals(firstedt, secondedt))
end

"""
    getname(edt::AbstractExtendedDataType)

Return the name of the data type (mainly meaningful for compound types).
"""
function getname(edt::AbstractExtendedDataType)::AbstractString
    @assert !isnull(edt)
    return GDAL.gdalextendeddatatypegetname(edt)
end

# TODO: Wrap GDAL.GDALExtendedDataTypeClass
"""
    getclass(edt::AbstractExtendedDataType)

Return the class of the data type: `GDAL.GEDTC_NUMERIC`,
`GDAL.GEDTC_STRING` or `GDAL.GEDTC_COMPOUND`.
"""
function getclass(edt::AbstractExtendedDataType)::GDAL.GDALExtendedDataTypeClass
    @assert !isnull(edt)
    return GDAL.gdalextendeddatatypegetclass(edt)
end

"""
    getnumericdatatype(edt::AbstractExtendedDataType)

Return the numeric data type (e.g. `GDT_Float32`) of a numeric data type,
or `GDT_Unknown` for other classes.
"""
function getnumericdatatype(edt::AbstractExtendedDataType)::GDALDataType
    @assert !isnull(edt)
    return convert(
        GDALDataType,
        GDAL.gdalextendeddatatypegetnumericdatatype(edt),
    )
end

# TODO: Wrap GDAL.GDALExtendedDataTypeSubType
"""
    getsubtype(edt::AbstractExtendedDataType)

Return the subtype of a string data type, e.g. `GDAL.GEDTST_JSON`, or
`GDAL.GEDTST_NONE`.
"""
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

"""
    getcomponents(edt::AbstractExtendedDataType)

Return the components of a compound data type; empty for other classes.
"""
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

"""
    getsize(edt::AbstractExtendedDataType)

Return the size of the data type in bytes.
"""
function getsize(edt::AbstractExtendedDataType)::Int
    @assert !isnull(edt)
    return Int(GDAL.gdalextendeddatatypegetsize(edt))
end

"""
    getmaxstringlength(edt::AbstractExtendedDataType)

Return the maximum length of a string data type, or 0 if unlimited.
"""
function getmaxstringlength(edt::AbstractExtendedDataType)::Int
    @assert !isnull(edt)
    return Int(GDAL.gdalextendeddatatypegetmaxstringlength(edt))
end

"""
    canconvertto(sourceedt::AbstractExtendedDataType,
                 targetedt::AbstractExtendedDataType)

Return whether values of type `sourceedt` can be converted to `targetedt`.
"""
function canconvertto(
    sourceedt::AbstractExtendedDataType,
    targetedt::AbstractExtendedDataType,
)::Bool
    @assert !isnull(sourceedt)
    @assert !isnull(targetedt)
    return Bool(GDAL.gdalextendeddatatypecanconvertto(sourceedt, targetedt))
end

# needsfreedynamicmemory, freedynamicmemory: not available in the C API

################################################################################

function unsafe_extendeddatatypecreate(
    ::Type{T},
)::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return ExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end

"""
    extendeddatatypecreate(T::Type)

Create a numeric data type for the Julia type `T`, e.g. `Float32` or
`Complex{Int16}`.
"""
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

"""
    extendeddatatypecreatestring(maxstringlength=0, subtype=GDAL.GEDTST_NONE)

Create a string data type.

### Parameters
* `maxstringlength`: the maximum string length, or 0 for unlimited.
* `subtype`: the string subtype, e.g. `GDAL.GEDTST_JSON`.
"""
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

"""
    getname(comp::AbstractEDTComponent)

Return the name of a component of a compound data type.
"""
function getname(comp::AbstractEDTComponent)::AbstractString
    @assert !isnull(comp)
    return GDAL.gdaledtcomponentgetname(comp)
end

"""
    getoffset(comp::AbstractEDTComponent)

Return the offset in bytes of a component within its compound data type.
"""
function getoffset(comp::AbstractEDTComponent)::Int
    @assert !isnull(comp)
    return Int(GDAL.gdaledtcomponentgetoffset(comp))
end

function unsafe_gettype(comp::AbstractEDTComponent)::AbstractExtendedDataType
    @assert !isnull(comp)
    return ExtendedDataType(GDAL.gdaledtcomponentgettype(comp))
end

"""
    gettype(comp::AbstractEDTComponent)

Return the data type of a component of a compound data type.
"""
function gettype(comp::AbstractEDTComponent)::AbstractExtendedDataType
    @assert !isnull(comp)
    return IExtendedDataType(GDAL.gdaledtcomponentgettype(comp))
end
