"""
    unsafe_clone(feature::AbstractFeature)

Duplicate feature.

The newly created feature is owned by the caller, and will have its own
reference to the OGRFeatureDefn.
"""
unsafe_clone(feature::AbstractFeature)::AbstractFeature =
    Feature(GDAL.ogr_f_clone(feature))

"""
    destroy(feature::AbstractFeature)

Destroy the feature passed in.

The feature is deleted, but within the context of the GDAL/OGR heap. This is
necessary when higher level applications use GDAL/OGR from a DLL and they want
to delete a feature created within the DLL. If the delete is done in the calling
application the memory will be freed onto the application heap which is
inappropriate.
"""
function destroy(feature::AbstractFeature)::Nothing
    GDAL.ogr_f_destroy(feature)
    feature.ptr = C_NULL
    return nothing
end

"""
    setgeom!(feature::AbstractFeature, geom::AbstractGeometry)

Set feature geometry.

This method updates the features geometry, and operate exactly as
SetGeometryDirectly(), except that this method does not assume ownership of the
passed geometry, but instead makes a copy of it.

### Parameters
* `feature`: the feature on which new geometry is applied to.
* `geom`: the new geometry to apply to feature.

### Returns
`OGRERR_NONE` if successful, or `OGR_UNSUPPORTED_GEOMETRY_TYPE` if the geometry
type is illegal for the `OGRFeatureDefn` (checking not yet implemented).
"""
function setgeom!(
    feature::AbstractFeature,
    geom::AbstractGeometry,
)::AbstractFeature
    result = GDAL.ogr_f_setgeometry(feature, geom)
    @ogrerr result "OGRErr $result: Failed to set feature geometry."
    return feature
end

"""
    getgeom(feature::AbstractFeature)

Returns a clone of the geometry corresponding to the feature.
"""
function getgeom(feature::AbstractFeature)::IGeometry
    result = GDAL.ogr_f_getgeometryref(feature)
    return if result == C_NULL
        IGeometry()
    else
        IGeometry(GDAL.ogr_g_clone(result))
    end
end

function unsafe_getgeom(feature::AbstractFeature)::Geometry
    result = GDAL.ogr_f_getgeometryref(feature)
    return if result == C_NULL
        Geometry()
    else
        Geometry(GDAL.ogr_g_clone(result))
    end
end

"""
    nfield(feature::AbstractFeature)

Fetch number of fields on this feature.

This will always be the same as the field count for the OGRFeatureDefn.
"""
nfield(feature::AbstractFeature)::Integer = GDAL.ogr_f_getfieldcount(feature)

"""
    keys(feature::AbstractFeature)

Fetch the keys or names on this feature.
"""
function Base.keys(feature::AbstractFeature)
    return (getname(getfielddefn(feature, i)) for i in 0:(nfield(feature)-1))
end

"""
    values(feature::AbstractFeature)

Fetch the values this feature.
"""
function Base.values(feature::AbstractFeature)
    return (getfield(feature, i) for i in 0:(nfield(feature)-1))
end

"""
    getfielddefn(feature::AbstractFeature, i::Integer)

Fetch definition for this field.

### Parameters
* `feature`: the feature on which the field is found.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.

### Returns
an handle to the field definition (from the `FeatureDefn`). This is an
internal reference, and should not be deleted or modified.
"""
getfielddefn(feature::AbstractFeature, i::Integer)::IFieldDefnView =
    IFieldDefnView(GDAL.ogr_f_getfielddefnref(feature, i))

"""
    findfieldindex(feature::AbstractFeature, name::Union{AbstractString, Symbol})

Fetch the field index given field name.

### Parameters
* `feature`: the feature on which the field is found.
* `name`: the name of the field to search for.

### Returns
the field index, or `nothing` if no matching field is found.

### Remarks
This is a cover for the `OGRFeatureDefn::GetFieldIndex()` method.
"""
function findfieldindex(
    feature::AbstractFeature,
    name::Union{AbstractString,Symbol},
)::Union{Integer,Nothing}
    i = GDAL.ogr_f_getfieldindex(feature, name)
    return if i == -1
        nothing
    else
        i
    end
end

"""
    isfieldset(feature::AbstractFeature, i::Integer)

Test if a field has ever been assigned a value or not.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
isfieldset(feature::AbstractFeature, i::Integer)::Bool =
    Bool(GDAL.ogr_f_isfieldset(feature, i))

"""
    unsetfield!(feature::AbstractFeature, i::Integer)

Clear a field, marking it as unset.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
function unsetfield!(feature::AbstractFeature, i::Integer)::AbstractFeature
    GDAL.ogr_f_unsetfield(feature, i)
    return feature
end

"""
    isfieldnull(feature::AbstractFeature, i::Integer)

Test if a field is null.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to test, from 0 to GetFieldCount()-1.

### Returns
`true` if the field is null, otherwise `false`.

### References
* https://gdal.org/development/rfc/rfc67_nullfieldvalues.html
"""
isfieldnull(feature::AbstractFeature, i::Integer)::Bool =
    Bool(GDAL.ogr_f_isfieldnull(feature, i))

"""
    isfieldsetandnotnull(feature::AbstractFeature, i::Integer)

Test if a field is set and not null.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to test, from 0 to GetFieldCount()-1.

### Returns
`true` if the field is set and not null, otherwise `false`.

### References
* https://gdal.org/development/rfc/rfc67_nullfieldvalues.html
"""
isfieldsetandnotnull(feature::AbstractFeature, i::Integer)::Bool =
    Bool(GDAL.ogr_f_isfieldsetandnotnull(feature, i))

"""
    setfieldnull!(feature::AbstractFeature, i::Integer)

Clear a field, marking it as null.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to set to null, from 0 to GetFieldCount()-1.

### References
* https://gdal.org/development/rfc/rfc67_nullfieldvalues.html
"""
function setfieldnull!(feature::AbstractFeature, i::Integer)::AbstractFeature
    GDAL.ogr_f_setfieldnull(feature, i)
    return feature
end

# """
#     OGR_F_GetRawFieldRef(OGRFeatureH hFeat,
#                          int iField) -> OGRField *
# Fetch an handle to the internal field value given the index.
# ### Parameters
# * `hFeat`: handle to the feature on which field is found.
# * `iField`: the field to fetch, from 0 to GetFieldCount()-1.
# ### Returns
# the returned handle is to an internal data structure, and should not be freed,
# or modified.
# """
# function getrawfieldref(arg1::Ptr{OGRFeatureH},arg2::Integer)
#     ccall((:OGR_F_GetRawFieldRef,libgdal),Ptr{OGRField},(Ptr{OGRFeatureH},
#           Cint),arg1,arg2)
# end

"""
    asbool(feature::AbstractFeature, i::Integer)

Fetch field value as a boolean

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asbool(feature::AbstractFeature, i::Integer)::Bool =
    convert(Bool, GDAL.ogr_f_getfieldasinteger(feature, i))

"""
    asint16(feature::AbstractFeature, i::Integer)

Fetch field value as integer 16 bit.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint16(feature::AbstractFeature, i::Integer)::Int16 =
    convert(Int16, GDAL.ogr_f_getfieldasinteger(feature, i))

"""
    asint(feature::AbstractFeature, i::Integer)

Fetch field value as integer.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint(feature::AbstractFeature, i::Integer)::Int32 =
    GDAL.ogr_f_getfieldasinteger(feature, i)

"""
    asint64(feature::AbstractFeature, i::Integer)

Fetch field value as integer 64 bit.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint64(feature::AbstractFeature, i::Integer)::Int64 =
    GDAL.ogr_f_getfieldasinteger64(feature, i)

"""
assingle(feature::AbstractFeature, i::Integer)

Fetch field value as a single.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
assingle(feature::AbstractFeature, i::Integer)::Float32 =
    convert(Float32, GDAL.ogr_f_getfieldasdouble(feature, i))

"""
    asdouble(feature::AbstractFeature, i::Integer)

Fetch field value as a double.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asdouble(feature::AbstractFeature, i::Integer)::Float64 =
    GDAL.ogr_f_getfieldasdouble(feature, i)

"""
    asstring(feature::AbstractFeature, i::Integer)

Fetch field value as a string.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asstring(feature::AbstractFeature, i::Integer)::String =
    GDAL.ogr_f_getfieldasstring(feature, i)

"""
    asintlist(feature::AbstractFeature, i::Integer)

Fetch field value as a list of integers.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
* `pnCount`: an integer to put the list count (number of integers) into.

### Returns
the field value, copied from GDAL to Julia.
"""
function asintlist(feature::AbstractFeature, i::Integer)::Vector{Int32}
    n = Ref{Cint}()
    ptr = GDAL.ogr_f_getfieldasintegerlist(feature, i, n)
    return (n.x == 0) ? Int32[] : copy(unsafe_wrap(Vector{Int32}, ptr, n.x))
end

"""
    asint64list(feature::AbstractFeature, i::Integer)

Fetch field value as a list of 64 bit integers.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
* `pnCount`: an integer to put the list count (number of integers) into.

### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief. If *pnCount is zero on return the returned
pointer may be NULL or non-NULL.
"""
function asint64list(feature::AbstractFeature, i::Integer)::Vector{Int64}
    n = Ref{Cint}()
    ptr = GDAL.ogr_f_getfieldasinteger64list(feature, i, n)
    return (n.x == 0) ? Int64[] : copy(unsafe_wrap(Vector{Int64}, ptr, n.x))
end

"""
    asdoublelist(feature::AbstractFeature, i::Integer)

Fetch field value as a list of doubles.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
* `pnCount`: an integer to put the list count (number of doubles) into.

### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief. If *pnCount is zero on return the returned
pointer may be NULL or non-NULL.
"""
function asdoublelist(feature::AbstractFeature, i::Integer)::Vector{Float64}
    n = Ref{Cint}()
    ptr = GDAL.ogr_f_getfieldasdoublelist(feature, i, n)
    return (n.x == 0) ? Float64[] : copy(unsafe_wrap(Vector{Float64}, ptr, n.x))
end

"""
    asstringlist(feature::AbstractFeature, i::Integer)

Fetch field value as a list of strings.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.

### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief.
"""
asstringlist(feature::AbstractFeature, i::Integer)::Vector{String} =
    copy(GDAL.ogr_f_getfieldasstringlist(feature, i))

"""
    asbinary(feature::AbstractFeature, i::Integer)

Fetch field value as binary.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.

### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief.
"""
function asbinary(feature::AbstractFeature, i::Integer)::Vector{UInt8}
    n = Ref{Cint}()
    ptr = GDAL.ogr_f_getfieldasbinary(feature, i, n)
    return (n.x == 0) ? UInt8[] : copy(unsafe_wrap(Vector{UInt8}, ptr, n.x))
end

"""
    asdatetime(feature::AbstractFeature, i::Integer)

Fetch field value as date and time. Currently this method only works for
OFTDate, OFTTime and OFTDateTime fields.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.

### Returns
`true` on success or `false` on failure.
"""
function asdatetime(feature::AbstractFeature, i::Integer)::DateTime
    pyr = Ref{Cint}()
    pmth = Ref{Cint}()
    pday = Ref{Cint}()
    phr = Ref{Cint}()
    pmin = Ref{Cint}()
    psec = Ref{Cint}()
    ptz = Ref{Cint}()
    result = Bool(
        GDAL.ogr_f_getfieldasdatetime(
            feature,
            i,
            pyr,
            pmth,
            pday,
            phr,
            pmin,
            psec,
            ptz,
        ),
    )
    (result == false) && error("Failed to fetch datetime at index $i")
    return DateTime(pyr[], pmth[], pday[], phr[], pmin[], psec[])
end

# """
#     OGR_F_GetFieldAsDateTimeEx(OGRFeatureH hFeat,
#                                int iField,
#                                int * pnYear,
#                                int * pnMonth,
#                                int * pnDay,
#                                int * pnHour,
#                                int * pnMinute,
#                                float * pfSecond,
#                                int * pnTZFlag) -> int
# Fetch field value as date and time.
# ### Parameters
# * `hFeat`: handle to the feature that owned the field.
# * `iField`: the field to fetch, from 0 to GetFieldCount()-1.
# * `pnYear`: (including century)
# * `pnMonth`: (1-12)
# * `pnDay`: (1-31)
# * `pnHour`: (0-23)
# * `pnMinute`: (0-59)
# * `pfSecond`: (0-59 with millisecond accuracy)
# * `pnTZFlag`: (0=unknown, 1=localtime, 100=GMT, see data model for details)
# ### Returns
# `true` on success or `false` on failure.
# """
# function getfieldasdatetimeex(hFeat::Ptr{OGRFeatureH},iField::Integer,pnYear,
#                               pnMonth,pnDay,pnHour,pnMinute,pfSecond,pnTZFlag)
#     ccall((:OGR_F_GetFieldAsDateTimeEx,libgdal),Cint,(Ptr{OGRFeatureH},Cint,
#           Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cfloat},
#           Ptr{Cint}),hFeat,iField,pnYear,pnMonth,pnDay,pnHour,pnMinute,
#           pfSecond,pnTZFlag)
# end

function getdefault(feature::AbstractFeature, i::Integer)::Union{String,Nothing}
    return getdefault(getfielddefn(feature, i))
end

getfield(feature::AbstractFeature, i::Nothing)::Missing = missing

const _FETCHFIELD = Dict{Union{OGRFieldType,OGRFieldSubType},Function}(
    OFTInteger => asint,
    OFTIntegerList => asintlist,
    OFTReal => asdouble,
    OFTRealList => asdoublelist,
    OFTString => asstring,
    OFTStringList => asstringlist,
    OFTBinary => asbinary,
    OFTDate => asdatetime,
    OFTTime => asdatetime,
    OFTDateTime => asdatetime,
    OFTInteger64 => asint64,
    OFTInteger64List => asint64list,
    OFSTBoolean => asbool,
    OFSTInt16 => asint16,
    OFSTFloat32 => assingle,
    OFSTJSON => asstring,
)

"""
    getfield(feature, i)

When the field is unset, it will return `nothing`. When the field is set but
null, it will return `missing`.

### References
* https://gdal.org/development/rfc/rfc53_ogr_notnull_default.html
* https://gdal.org/development/rfc/rfc67_nullfieldvalues.html
"""
function getfield(feature::AbstractFeature, i::Integer)
    return if !isfieldset(feature, i)
        nothing
    elseif isfieldnull(feature, i)
        missing
    else
        _fieldtype = getfieldtype(getfielddefn(feature, i))
        try
            _fetchfield = _FETCHFIELD[_fieldtype]
            _fetchfield(feature, i)
        catch e
            if e isa KeyError
                error(
                    "$_fieldtype not implemented in getfield, please report an issue to https://github.com/yeesian/ArchGDAL.jl/issues",
                )
            else
                rethrow(e)
            end
        end
    end
end

function getfield(feature::AbstractFeature, name::Union{AbstractString,Symbol})
    return getfield(feature, findfieldindex(feature, name))
end

"""
    setfield!(feature::AbstractFeature, i::Integer, value)
    setfield!(feature::AbstractFeature, i::Integer, value::DateTime, tzflag::Int = 0)

Set a feature's `i`-th field to `value`.

The following types for `value` are accepted: `Int32`, `Int64`, `Float64`,
`AbstractString`, or a `Vector` with those in it, as well as `Vector{UInt8}`.
For `DateTime` values, an additional keyword argument `tzflag` is accepted
(0=unknown, 1=localtime, 100=GMT, see data model for details).

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
function setfield! end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Nothing,
)::AbstractFeature
    unsetfield!(feature, i)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Missing,
)::AbstractFeature
    if isnullable(getfielddefn(feature, i))
        setfieldnull!(feature, 1)
    else
        setfield!(feature, i, getdefault(feature, i))
    end
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Union{Bool,UInt8,Int8,UInt16,Int16,Int32},
)::AbstractFeature
    GDAL.ogr_f_setfieldinteger(feature, i, value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Union{UInt32,Int64},
)::AbstractFeature
    GDAL.ogr_f_setfieldinteger64(feature, i, value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Enum,
)::AbstractFeature
    return setfield!(feature, i, Integer(value))
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Union{Float16,Float32,Float64},
)::AbstractFeature
    GDAL.ogr_f_setfielddouble(feature, i, value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::AbstractString,
)::AbstractFeature
    GDAL.ogr_f_setfieldstring(feature, i, value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Vector{Int32},
)::AbstractFeature
    GDAL.ogr_f_setfieldintegerlist(feature, i, length(value), value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Vector{Int64},
)::AbstractFeature
    GDAL.ogr_f_setfieldinteger64list(feature, i, length(value), value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Vector{Float64},
)::AbstractFeature
    GDAL.ogr_f_setfielddoublelist(feature, i, length(value), value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Vector{T},
)::AbstractFeature where {T<:AbstractString}
    GDAL.ogr_f_setfieldstringlist(feature, i, value)
    return feature
end

# """
#     OGR_F_SetFieldRaw(OGRFeatureH hFeat,
#                       int iField,
#                       OGRField * psValue) -> void
# Set field.
# ### Parameters
# * `hFeat`: handle to the feature that owned the field.
# * `iField`: the field to fetch, from 0 to GetFieldCount()-1.
# * `psValue`: handle on the value to assign.
# """
# function setfieldraw(arg1::Ptr{OGRFeatureH},arg2::Integer,arg3)
#     ccall((:OGR_F_SetFieldRaw,libgdal),Void,(Ptr{OGRFeatureH},Cint,
#           Ptr{OGRField}),arg1,arg2,arg3)
# end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    value::Vector{UInt8},
)::AbstractFeature
    GDAL.ogr_f_setfieldbinary(feature, i, sizeof(value), value)
    return feature
end

function setfield!(
    feature::AbstractFeature,
    i::Integer,
    dt::DateTime,
    tzflag::Int = 0,
)::AbstractFeature
    GDAL.ogr_f_setfielddatetime(
        feature,
        i,
        Dates.year(dt),
        Dates.month(dt),
        Dates.day(dt),
        Dates.hour(dt),
        Dates.minute(dt),
        Dates.second(dt),
        tzflag,
    )
    return feature
end

"""
    ngeom(feature::AbstractFeature)

Fetch number of geometry fields on this feature.

This will always be the same as the geometry field count for OGRFeatureDefn.
"""
ngeom(feature::AbstractFeature)::Integer = GDAL.ogr_f_getgeomfieldcount(feature)

"""
    getgeomdefn(feature::AbstractFeature, i::Integer)

Fetch definition for this geometry field.

### Parameters
* `feature`: the feature on which the field is found.
* `i`: the field to fetch, from 0 to GetGeomFieldCount()-1.

### Returns
The field definition (from the OGRFeatureDefn). This is an
internal reference, and should not be deleted or modified.
"""
function getgeomdefn(feature::AbstractFeature, i::Integer)::IGeomFieldDefnView
    return IGeomFieldDefnView(GDAL.ogr_f_getgeomfielddefnref(feature, i))
end

"""
    findgeomindex(feature::AbstractFeature, name::Union{AbstractString, Symbol} = "")

Fetch the geometry field index given geometry field name.

### Parameters
* `feature`: the feature on which the geometry field is found.
* `name`: the name of the geometry field to search for. (defaults to \"\")

### Returns
the geometry field index, or -1 if no matching geometry field is found.

### Remarks
This is a cover for the `OGRFeatureDefn::GetGeomFieldIndex()` method.
"""
function findgeomindex(
    feature::AbstractFeature,
    name::Union{AbstractString,Symbol} = "",
)::Integer
    return GDAL.ogr_f_getgeomfieldindex(feature, name)
end

"""
    getgeom(feature::AbstractFeature, i::Integer)

Returns a clone of the feature geometry at index `i`.

### Parameters
* `feature`: the feature to get geometry from.
* `i`: geometry field to get.
"""
function getgeom(feature::AbstractFeature, i::Integer)::IGeometry
    result = GDAL.ogr_f_getgeomfieldref(feature, i)
    return if result == C_NULL
        IGeometry()
    else
        IGeometry(GDAL.ogr_g_clone(result))
    end
end

function unsafe_getgeom(feature::AbstractFeature, i::Integer)::Geometry
    result = GDAL.ogr_f_getgeomfieldref(feature, i)
    return if result == C_NULL
        Geometry()
    else
        Geometry(GDAL.ogr_g_clone(result))
    end
end

function getgeom(
    feature::AbstractFeature,
    name::Union{AbstractString,Symbol},
)::IGeometry
    i = findgeomindex(feature, name)
    return if i == -1
        IGeometry()
    else
        getgeom(feature, i)
    end
end

function unsafe_getgeom(
    feature::AbstractFeature,
    name::Union{AbstractString,Symbol},
)::Geometry
    i = findgeomindex(feature, name)
    return if i == -1
        Geometry()
    else
        unsafe_getgeom(feature, i)
    end
end

"""
    setgeom!(feature::AbstractFeature, i::Integer, geom::AbstractGeometry)

Set feature geometry of a specified geometry field.

This function updates the features geometry, and operate exactly as
SetGeometryDirectly(), except that this function does not assume ownership of
the passed geometry, but instead makes a copy of it.

### Parameters
* `feature`: the feature on which to apply the geometry.
* `i`: geometry field to set.
* `geom`: the new geometry to apply to feature.

### Returns
`OGRERR_NONE` if successful, or `OGR_UNSUPPORTED_GEOMETRY_TYPE` if the geometry
type is illegal for the `OGRFeatureDefn` (checking not yet implemented).
"""
function setgeom!(
    feature::AbstractFeature,
    i::Integer,
    geom::AbstractGeometry,
)::AbstractFeature
    result = GDAL.ogr_f_setgeomfield(feature, i, geom)
    @ogrerr result "OGRErr $result: Failed to set feature geometry"
    return feature
end

"""
    getfid(feature::AbstractFeature)

Get feature identifier.

### Returns
feature id or `OGRNullFID` (`-1`) if none has been assigned.
"""
getfid(feature::AbstractFeature) = GDAL.ogr_f_getfid(feature)::Integer

"""
    setfid!(feature::AbstractFeature, i::Integer)

Set the feature identifier.

### Parameters
* `feature`: handle to the feature to set the feature id to.
* `i`: the new feature identifier value to assign.

### Returns
On success OGRERR_NONE, or on failure some other value.
"""
function setfid!(feature::AbstractFeature, i::Integer)::AbstractFeature
    result = GDAL.ogr_f_setfid(feature, i)
    @ogrerr result "OGRErr $result: Failed to set FID $i"
    return feature
end

"""
    setfrom!(feature1::AbstractFeature, feature2::AbstractFeature, forgiving::Bool = false)
    setfrom!(feature1::AbstractFeature, feature2::AbstractFeature, indices::Vector{Cint},
        forgiving::Bool = false)

Set one feature from another.

### Parameters
* `feature1`: handle to the feature to set to.
* `feature2`: handle to the feature from which geometry, and field values
    will be copied.
* `indices`: indices of the destination feature's fields stored at the
    corresponding index of the source feature's fields. A value of `-1` should
    be used to ignore the source's field. The array should not be NULL and be
    as long as the number of fields in the source feature.
* `forgiving`: `true` if the operation should continue despite lacking output
    fields matching some of the source fields.

### Returns
OGRERR_NONE if the operation succeeds, even if some values are not transferred,
otherwise an error code.
"""
function setfrom! end

function setfrom!(
    feature1::AbstractFeature,
    feature2::AbstractFeature,
    forgiving::Bool = false,
)::AbstractFeature
    result = GDAL.ogr_f_setfrom(feature1, feature2, forgiving)
    @ogrerr result "OGRErr $result: Failed to set feature"
    return feature1
end

function setfrom!(
    feature1::AbstractFeature,
    feature2::AbstractFeature,
    indices::Vector{Cint},
    forgiving::Bool = false,
)::AbstractFeature
    result = GDAL.ogr_f_setfromwithmap(feature1, feature2, forgiving, indices)
    @ogrerr result "OGRErr $result: Failed to set feature with map"
    return feature1
end

"""
    getstylestring(feature::AbstractFeature)

Fetch style string for this feature.
"""
getstylestring(feature::AbstractFeature)::String =
    GDAL.ogr_f_getstylestring(feature)

"""
    setstylestring!(feature::AbstractFeature, style::AbstractString)

Set feature style string.

This method operate exactly as `setstylestringdirectly!()` except that
it doesn't assume ownership of the passed string, but makes a copy of it.
"""
function setstylestring!(
    feature::AbstractFeature,
    style::AbstractString,
)::AbstractFeature
    GDAL.ogr_f_setstylestring(feature, style)
    return feature
end

"""
    getstyletable(feature::AbstractFeature)

Fetch style table for this feature.
"""
getstyletable(feature::AbstractFeature)::StyleTable =
    StyleTable(GDAL.ogr_f_getstyletable(feature))

"""
    setstyletable!(feature::AbstractFeature, styletable::StyleTable)

Set the style table for this feature.
"""
function setstyletable!(
    feature::AbstractFeature,
    styletable::StyleTable,
)::AbstractFeature
    GDAL.ogr_f_setstyletable(feature, styletable)
    return feature
end

"""
    getnativedata(feature::AbstractFeature)

Returns the native data for the feature.

The native data is the representation in a "natural" form that comes from the
driver that created this feature, or that is aimed at an output driver. The
native data may be in different format, which is indicated by
GetNativeMediaType().

Note that most drivers do not support storing the native data in the feature
object, and if they do, generally the NATIVE_DATA open option must be passed at
dataset opening.

The "native data" does not imply it is something more performant or powerful
than what can be obtained with the rest of the API, but it may be useful in
round-tripping scenarios where some characteristics of the underlying format
are not captured otherwise by the OGR abstraction.
"""
getnativedata(feature::AbstractFeature)::String =
    GDAL.ogr_f_getnativedata(feature)

"""
    setnativedata!(feature::AbstractFeature, data::AbstractString)

Sets the native data for the feature.

The native data is the representation in a "natural" form that comes from the
driver that created this feature, or that is aimed at an output driver. The
native data may be in different format, which is indicated by
GetNativeMediaType().
"""
function setnativedata!(
    feature::AbstractFeature,
    data::AbstractString,
)::AbstractFeature
    GDAL.ogr_f_setnativedata(feature, data)
    return feature
end

"""
    getmediatype(feature::AbstractFeature)

Returns the native media type for the feature.

The native media type is the identifier for the format of the native data. It
follows the IANA RFC 2045 (see https://en.wikipedia.org/wiki/Media_type),
e.g. \"application/vnd.geo+json\" for JSON.
"""
getmediatype(feature::AbstractFeature)::String =
    GDAL.ogr_f_getnativemediatype(feature)

"""
    setmediatype!(feature::AbstractFeature, mediatype::AbstractString)

Sets the native media type for the feature.

The native media type is the identifier for the format of the native data. It
follows the IANA RFC 2045 (see https://en.wikipedia.org/wiki/Media_type),
e.g. \"application/vnd.geo+json\" for JSON.
"""
function setmediatype!(
    feature::AbstractFeature,
    mediatype::AbstractString,
)::AbstractFeature
    GDAL.ogr_f_setnativemediatype(feature, mediatype)
    return feature
end

"""
    fillunsetwithdefault!(feature::AbstractFeature; notnull = true,
        options = StringList(C_NULL))

Fill unset fields with default values that might be defined.

### Parameters
* `feature`: handle to the feature.
* `notnull`: if we should fill only unset fields with a not-null constraint.
* `papszOptions`: unused currently. Must be set to `NULL`.

### References
* https://gdal.org/development/rfc/rfc53_ogr_notnull_default.html
"""
function fillunsetwithdefault!(
    feature::AbstractFeature;
    notnull::Bool = true,
    options = StringList(C_NULL),
)::AbstractFeature
    GDAL.ogr_f_fillunsetwithdefault(feature, notnull, options)
    return feature
end

"""
    validate(feature::AbstractFeature, flags::Integer, emiterror::Bool)

Validate that a feature meets constraints of its schema.

The scope of test is specified with the nValidateFlags parameter.

Regarding `OGR_F_VAL_WIDTH`, the test is done assuming the string width must be
interpreted as the number of UTF-8 characters. Some drivers might interpret the
width as the number of bytes instead. So this test is rather conservative (if it
fails, then it will fail for all interpretations).

### Parameters
* `feature`: handle to the feature to validate.
* `flags`: `OGR_F_VAL_ALL` or combination of `OGR_F_VAL_NULL`,
    `OGR_F_VAL_GEOM_TYPE`, `OGR_F_VAL_WIDTH` and
    `OGR_F_VAL_ALLOW_NULL_WHEN_DEFAULT` with `|` operator
* `emiterror`: `true` if a `CPLError()` must be emitted when a check fails

### Returns
`true` if all enabled validation tests pass.

### References
* https://gdal.org/development/rfc/rfc53_ogr_notnull_default.html
"""
validate(
    feature::AbstractFeature,
    flags::FieldValidation,
    emiterror::Bool,
)::Bool = Bool(GDAL.ogr_f_validate(feature, flags, emiterror))
