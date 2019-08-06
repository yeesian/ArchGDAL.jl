"""
Duplicate feature.

The newly created feature is owned by the caller, and will have its own
reference to the OGRFeatureDefn.
"""
unsafe_clone(feature::Feature) = Feature(GDAL.clone(feature.ptr))

"""
Destroy the feature passed in.

The feature is deleted, but within the context of the GDAL/OGR heap. This is
necessary when higher level applications use GDAL/OGR from a DLL and they want
to delete a feature created within the DLL. If the delete is done in the calling
application the memory will be freed onto the application heap which is
inappropriate.
"""
function destroy(feature::Feature)
    GDAL.destroy(feature.ptr)
    feature.ptr = C_NULL
end

"""
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
function setgeom!(feature::Feature, geom::AbstractGeometry)
    result = GDAL.setgeometry(feature.ptr, geom.ptr)
    @ogrerr result "OGRErr $result: Failed to set feature geometry."
end

"Returns a clone of the geometry corresponding to the feature."
function getgeom(feature::Feature)
    result = GDAL.getgeometryref(feature.ptr)
    if result == C_NULL
        return IGeometry()
    else
        return IGeometry(GDAL.clone(result))
    end
end

function unsafe_getgeom(feature::Feature)
    result = GDAL.getgeometryref(feature.ptr)
    if result == C_NULL
        return Geometry()
    else
        return Geometry(GDAL.clone(result))
    end
end

"""
Fetch number of fields on this feature.

This will always be the same as the field count for the OGRFeatureDefn.
"""
nfield(feature::Feature) = GDAL.getfieldcount(feature.ptr)

"""
Fetch definition for this field.

### Parameters
* `feature`: the feature on which the field is found.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.

### Returns
an handle to the field definition (from the OGRFeatureDefn). This is an
internal reference, and should not be deleted or modified.
"""
getfielddefn(feature::Feature, i::Integer) =
    FieldDefn(GDAL.getfielddefnref(feature.ptr, i))

"""
Fetch the field index given field name.

### Parameters
* `feature`: the feature on which the field is found.
* `name`: the name of the field to search for.

### Returns
the field index, or -1 if no matching field is found.

### Remarks
This is a cover for the `OGRFeatureDefn::GetFieldIndex()` method.
"""
findfieldindex(feature::Feature, name::AbstractString) =
    GDAL.getfieldindex(feature.ptr, name)

"""Test if a field has ever been assigned a value or not.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
isfieldset(feature::Feature, i::Integer) = Bool(GDAL.isfieldset(feature.ptr, i))

"""
Clear a field, marking it as unset.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
unsetfield!(feature::Feature, i::Integer) =
    (GDAL.unsetfield(feature.ptr, i); feature)

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

"""Fetch field value as integer.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint(feature::Feature, i::Integer) = GDAL.getfieldasinteger(feature.ptr, i)

"""Fetch field value as integer 64 bit.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint64(feature::Feature, i::Integer) = GDAL.getfieldasinteger64(feature.ptr, i)

"""Fetch field value as a double.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asdouble(feature::Feature, i::Integer) = GDAL.getfieldasdouble(feature.ptr, i)

"""
Fetch field value as a string.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asstring(feature::Feature, i::Integer) = GDAL.getfieldasstring(feature.ptr, i)

"""
    OGR_F_GetFieldAsIntegerList(OGRFeatureH hFeat,
                                int iField,
                                int * pnCount) -> const int *
Fetch field value as a list of integers.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
* `pnCount`: an integer to put the list count (number of integers) into.
### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief. If *pnCount is zero on return the returned
pointer may be NULL or non-NULL.
"""
function asintlist(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasintegerlist(feature.ptr, i, n)
    return (n.x == 0) ? Int32[] : unsafe_wrap(Array{Int32}, ptr, n.x)
end

"""
    OGR_F_GetFieldAsInteger64List(OGRFeatureH hFeat,
                                  int iField,
                                  int * pnCount) -> const GIntBig *
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
function asint64list(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasinteger64list(feature.ptr, i, n)
    return (n.x == 0) ? Int64[] : unsafe_wrap(Array{Int64}, ptr, n.x)
end

"""
    OGR_F_GetFieldAsDoubleList(OGRFeatureH hFeat,
                               int iField,
                               int * pnCount) -> const double *
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
function asdoublelist(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasdoublelist(feature.ptr, i, n)
    return (n.x == 0) ? Float64[] : unsafe_wrap(Array{Float64}, ptr, n.x)
end

"""
    OGR_F_GetFieldAsStringList(OGRFeatureH hFeat,
                               int iField) -> char **
Fetch field value as a list of strings.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief.
"""
asstringlist(feature::Feature, i::Integer) =
    GDAL.getfieldasstringlist(feature.ptr, i)

"""
    OGR_F_GetFieldAsBinary(OGRFeatureH hFeat,
                           int iField,
                           int * pnBytes) -> GByte *
Fetch field value as binary.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
* `pnBytes`: location to place count of bytes returned.
### Returns
the field value. This list is internal, and should not be modified, or freed.
Its lifetime may be very brief.
"""
function asbinary(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasbinary(feature.ptr, i, n)
    return (n.x == 0) ? UInt8[] : unsafe_wrap(Array{UInt8}, ptr, n.x)
end

"""
    OGR_F_GetFieldAsDateTime(OGRFeatureH hFeat,
                             int iField,
                             int * pnYear,
                             int * pnMonth,
                             int * pnDay,
                             int * pnHour,
                             int * pnMinute,
                             int * pnSecond,
                             int * pnTZFlag) -> int
Fetch field value as date and time.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
* `pnYear`: (including century)
* `pnMonth`: (1-12)
* `pnDay`: (1-31)
* `pnHour`: (0-23)
* `pnMinute`: (0-59)
* `pnSecond`: (0-59)
* `pnTZFlag`: (0=unknown, 1=localtime, 100=GMT, see data model for details)
### Returns
TRUE on success or FALSE on failure.
"""
function asdatetime(feature::Feature, i::Integer)
    pyr = Ref{Cint}(); pmth = Ref{Cint}(); pday = Ref{Cint}()
    phr = Ref{Cint}(); pmin = Ref{Cint}(); psec = Ref{Cint}(); ptz=Ref{Cint}()
    result = Bool(GDAL.getfieldasdatetime(
        feature.ptr, i, pyr, pmth, pday, phr, pmin, psec, ptz
    ))
    (result == false) && error("Failed to fetch datetime at index $i")
    DateTime(pyr[], pmth[], pday[], phr[], pmin[], psec[])
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
# TRUE on success or FALSE on failure.
# """
# function getfieldasdatetimeex(hFeat::Ptr{OGRFeatureH},iField::Integer,pnYear,
#                               pnMonth,pnDay,pnHour,pnMinute,pfSecond,pnTZFlag)
#     ccall((:OGR_F_GetFieldAsDateTimeEx,libgdal),Cint,(Ptr{OGRFeatureH},Cint,
#           Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cfloat},
#           Ptr{Cint}),hFeat,iField,pnYear,pnMonth,pnDay,pnHour,pnMinute,
#           pfSecond,pnTZFlag)
# end

asnothing(feature::Feature, i::Integer) = nothing

const _FETCHFIELD = Dict{GDAL.OGRFieldType, Function}(
    GDAL.OFTInteger         => asint,           #0
    GDAL.OFTIntegerList     => asintlist,       #1
    GDAL.OFTReal            => asdouble,        #2
    GDAL.OFTRealList        => asdoublelist,    #3
    GDAL.OFTString          => asstring,        #4
    GDAL.OFTStringList      => asstringlist,    #5
 # const OFTWideString =                (UInt32)(6)
 # const OFTWideStringList =            (UInt32)(7)
    GDAL.OFTBinary          => asbinary,        #8
 # const OFTDate =                      (UInt32)(9)
 # const OFTTime =                      (UInt32)(10)
    GDAL.OFTDateTime        => asdatetime,      #11
    GDAL.OFTInteger64       => asint64,         #12
    GDAL.OFTInteger64List   => asint64list      #13
 # const OFTMaxType =                   (UInt32)(13)
 )

function getfield(feature::Feature, i::Integer)
    if isfieldset(feature, i)
        _fieldtype = gettype(getfielddefn(feature, i))
        _fetchfield = get(_FETCHFIELD, _fieldtype, asnothing)
        return _fetchfield(feature, i)
    end
end

getfield(feature::Feature, name::AbstractString) =
    getfield(feature, findfieldindex(feature, name))

"""
Set field to integer value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::Cint) =
    (GDAL.setfieldinteger(feature.ptr, i, value); feature)

"""
Set field to 64 bit integer value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::Int64) =
    (GDAL.setfieldinteger64(feature.ptr, i, value); feature)

"""
Set field to double value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::Cdouble) =
    (GDAL.setfielddouble(feature.ptr, i, value); feature)

"""
Set field to string value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::AbstractString) =
    (GDAL.setfieldstring(feature.ptr, i, value); feature)

"""
Set field to list of integers value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nCount`: the number of values in the list being assigned.
* `panValues`: the values to assign.
"""
setfield!(feature::Feature, i::Integer, value::Vector{Cint}) =
    (GDAL.setfieldintegerlist(feature.ptr, i, length(value), value); feature)

"""
Set field to list of 64 bit integers value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nCount`: the number of values in the list being assigned.
* `panValues`: the values to assign.
"""
setfield!(feature::Feature, i::Integer, value::Vector{GDAL.GIntBig}) =
    (GDAL.setfieldinteger64list(feature.ptr, i, length(value), value); feature)

"""
Set field to list of doubles value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nCount`: the number of values in the list being assigned.
* `padfValues`: the values to assign.
"""
setfield!(feature::Feature, i::Integer, value::Vector{Cdouble}) =
    (GDAL.setfielddoublelist(feature.ptr, i, length(value), value); feature)

"""
Set field to list of strings value.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `papszValues`: the values to assign.
"""
function setfield!(
        feature::Feature,
        i::Integer,
        value::Vector{T}
    ) where T <: AbstractString
    GDAL.setfieldstringlist(feature.ptr, i, value)
    feature
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

"""
Set field to binary data.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nBytes`: the number of bytes in pabyData array.
* `pabyData`: the data to apply.
"""
setfield!(feature::Feature, i::Integer, value::Vector{GDAL.GByte}) =
    (GDAL.setfieldbinary(feature.ptr, i, sizeof(value), value); feature)

"""
Set field to datetime.

OFTInteger, OFTInteger64 and OFTReal fields will be set directly. OFTString
fields will be assigned a string representation of the value, but not
necessarily taking into account formatting constraints on this field. Other
field types may be unaffected.

### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nYear`: (including century)
* `nMonth`: (1-12)
* `nDay`: (1-31)
* `nHour`: (0-23)
* `nMinute`: (0-59)
* `nSecond`: (0-59)
* `nTZFlag`: (0=unknown, 1=localtime, 100=GMT, see data model for details)
"""
function setfield!(feature::Feature, i::Integer, dt::DateTime, tzflag::Int = 0)
    GDAL.setfielddatetime(
        feature.ptr,
        i,
        Dates.year(dt),
        Dates.month(dt),
        Dates.day(dt),
        Dates.hour(dt),
        Dates.minute(dt),
        Dates.second(dt),
        tzflag
    )
    feature
end

"""
Fetch number of geometry fields on this feature.

This will always be the same as the geometry field count for OGRFeatureDefn.
"""
ngeom(feature::Feature) = GDAL.getgeomfieldcount(feature.ptr)

"""
Fetch definition for this geometry field.

### Parameters
* `feature`: the feature on which the field is found.
* `i`: the field to fetch, from 0 to GetGeomFieldCount()-1.

### Returns
The field definition (from the OGRFeatureDefn). This is an
internal reference, and should not be deleted or modified.
"""
getgeomdefn(feature::Feature, i::Integer) =
    GeomFieldDefn(GDAL.getgeomfielddefnref(feature.ptr, i))

"""
Fetch the geometry field index given geometry field name.

### Parameters
* `feature`: the feature on which the geometry field is found.
* `name`: the name of the geometry field to search for. (defaults to \"\")

### Returns
the geometry field index, or -1 if no matching geometry field is found.

### Remarks
This is a cover for the `OGRFeatureDefn::GetGeomFieldIndex()` method.
"""
findgeomindex(feature::Feature, name::AbstractString="") =
    GDAL.getgeomfieldindex(feature.ptr, name)

"""
Returns a clone of the feature geometry at index `i`.

### Parameters
* `feature`: the feature to get geometry from.
* `i`: geometry field to get.
"""
function getgeom(feature::Feature, i::Integer)
    result = GDAL.getgeomfieldref(feature.ptr, i)
    if result == C_NULL
        return IGeometry()
    else
        return IGeometry(GDAL.clone(result))
    end
end

function unsafe_getgeom(feature::Feature, i::Integer)
    result = GDAL.getgeomfieldref(feature.ptr, i)
    if result == C_NULL
        return Geometry()
    else
        return Geometry(GDAL.clone(result))
    end
end

"""
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
function setgeom!(feature::Feature, i::Integer, geom::AbstractGeometry)
    result = GDAL.setgeomfield(feature.ptr, i, geom.ptr)
    @ogrerr result "OGRErr $result: Failed to set feature geometry"
    feature
end

"""
Get feature identifier.

### Returns
feature id or `OGRNullFID` (`-1`) if none has been assigned.
"""
getfid(feature::Feature) = GDAL.getfid(feature.ptr)

"""
Set the feature identifier.

### Parameters
* `feature`: handle to the feature to set the feature id to.
* `i`: the new feature identifier value to assign.

### Returns
On success OGRERR_NONE, or on failure some other value.
"""
function setfid!(feature::Feature, i::Integer)
    result = GDAL.setfid(feature.ptr, i)
    @ogrerr result "OGRErr $result: Failed to set FID $i"
    feature
end

"""
Set one feature from another.

### Parameters
* `feature1`: handle to the feature to set to.
* `feature2`: handle to the feature from which geometry, and field values
    will be copied.
* `forgiving`: `true` if the operation should continue despite lacking output
    fields matching some of the source fields.

### Returns
OGRERR_NONE if the operation succeeds, even if some values are not transferred,
otherwise an error code.
"""
function setfrom!(feature1::Feature, feature2::Feature, forgiving::Bool = false)
    result = GDAL.setfrom(feature1.ptr, feature2.ptr, forgiving)
    @ogrerr result "OGRErr $result: Failed to set feature"
    feature1
end

"""
Set one feature from another.

### Parameters
* `feature1`: the feature to set to.
* `feature2`: the feature from which geometry and field values will be copied
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
function setfrom!(
        feature1::Feature,
        feature2::Feature,
        indices::Vector{Cint},
        forgiving::Bool = false
    )
    result = GDAL.setfromwithmap(feature1.ptr, feature2.ptr, forgiving, indices)
    @ogrerr result "OGRErr $result: Failed to set feature with map"
    feature1
end


"Fetch style string for this feature."
getstylestring(feature::Feature) = GDAL.getstylestring(feature.ptr)

"""
Set feature style string.

This method operate exactly as `setstylestringdirectly!()` except that
it doesn't assume ownership of the passed string, but makes a copy of it.
"""
setstylestring!(feature::Feature, style::AbstractString) =
    (GDAL.setstylestring(feature.ptr, style); feature)

"OGR_F_GetStyleTable(OGRFeatureH hFeat) -> OGRStyleTableH"
getstyletable(feature::Feature) = StyleTable(GDAL.getstyletable(feature.ptr))

"""
    OGR_F_SetStyleTable(OGRFeatureH hFeat,
                        OGRStyleTableH hStyleTable) -> void
"""
setstyletable!(feature::Feature, styletable::StyleTable) =
    (GDAL.setstyletable(feature.ptr, styletable.ptr); feature)

"""
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
getnativedata(feature::Feature) = GDAL.getnativedata(feature.ptr)

"""
Sets the native data for the feature.

The native data is the representation in a "natural" form that comes from the
driver that created this feature, or that is aimed at an output driver. The
native data may be in different format, which is indicated by
GetNativeMediaType().
"""
setnativedata!(feature::Feature, data::AbstractString) =
    (GDAL.setnativedata(feature.ptr, data); feature)

"""
Returns the native media type for the feature.

The native media type is the identifier for the format of the native data. It
follows the IANA RFC 2045 (see https://en.wikipedia.org/wiki/Media_type),
e.g. \"application/vnd.geo+json\" for JSON.
"""
getmediatype(feature::Feature) = GDAL.getnativemediatype(feature.ptr)

"""
Sets the native media type for the feature.

The native media type is the identifier for the format of the native data. It
follows the IANA RFC 2045 (see https://en.wikipedia.org/wiki/Media_type),
e.g. \"application/vnd.geo+json\" for JSON.
"""
setmediatype!(feature::Feature, mediatype::AbstractString) =
    (GDAL.setnativemediatype(feature.ptr, mediatype); feature)

"""
Fill unset fields with default values that might be defined.

### Parameters
* `feature`: handle to the feature.
* `notnull`: if we should fill only unset fields with a not-null constraint.
* `papszOptions`: unused currently. Must be set to `NULL`.
"""
function fillunsetwithdefault!(
        feature::Feature;
        notnull::Bool   = true,
        options         = StringList(C_NULL)
    )
    GDAL.fillunsetwithdefault(feature.ptr, notnull, options)
end

"""
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
"""
validate(feature::Feature, flags::Integer, emiterror::Bool) =
    Bool(GDAL.validate(feature.ptr, flags, emiterror))
