
"Return the layer name."
getname(layer::FeatureLayer) = GDAL.getname(layer)

"Return the layer geometry type."
getgeomtype(layer::FeatureLayer) = GDAL.getgeomtype(layer)

"Returns the current spatial filter for this layer."
getspatialfilter(layer::FeatureLayer) = GDAL.getspatialfilter(layer)

"""
Fetch the spatial reference system for this layer.

The returned object is owned by the OGRLayer and should not be modified or
freed by the application.
"""
borrow_getspatialref(layer::FeatureLayer) = GDAL.getspatialref(layer)

"""
Set a new spatial filter for the layer, using the geom.

This method set the geometry to be used as a spatial filter when fetching
features via the GetNextFeature() method. Only features that geometrically
intersect the filter geometry will be returned.

Currently this test may be inaccurately implemented, but it is guaranteed
that all features who's envelope (as returned by OGRGeometry::getEnvelope())
overlaps the envelope of the spatial filter will be returned. This can result
in more shapes being returned that should strictly be the case.

This method makes an internal copy of the passed geometry. The passed geometry
remains the responsibility of the caller, and may be safely destroyed.

### Parameters
* `layer`  handle to the layer on which to set the spatial filter.
* `i`      (optional) index of the geometry field for the spatial filter.
* `geom`   handle to the geometry to use as a filtering region. NULL may be
           passed indicating that the current spatial filter should be cleared,
           but no new one instituted.

### Additional Remarks
For the time being the passed filter geometry should be in the same SRS as the
geometry field definition it corresponds to (as returned by
`GetLayerDefn()->OGRFeatureDefn::GetGeomFieldDefn(i)->GetSpatialRef()`).
In the future this may be generalized.

Note that only the last spatial filter set is applied, even if several
successive calls are done with different iGeomField values.
"""
setspatialfilter!(layer::FeatureLayer, geom::Geometry) =
    GDAL.setspatialfilter(layer, geom)

setspatialfilter!(layer::FeatureLayer, i::Integer, geom::Geometry) =
    GDAL.setspatialfilterex(layer, geom)

"""
Set a new rectangular spatial filter for the layer.

This method set rectangle to be used as a spatial filter when fetching features
via the GetNextFeature() method. Only features that geometrically intersect the
given rectangle will be returned.

The x/y values should be in the same coordinate system as the layer as a whole
(as returned by OGRLayer::GetSpatialRef()). Internally this method is normally
implemented as creating a 5 vertex closed rectangular polygon and passing it to
OGRLayer::SetSpatialFilter(). It exists as a convenience.

The only way to clear a spatial filter set with this method is to call
`OGRLayer::SetSpatialFilter(NULL)`.
"""
setspatialfilter!(layer::FeatureLayer, xmin::Real, ymin::Real,
                  xmax::Real, ymax::Real) = 
    GDAL.setspatialfilterrect(layer, xmin, ymin, xmax, ymax)

setspatialfilter!(layer::FeatureLayer, i::Integer, xmin::Real, ymin::Real,
                  xmax::Real, ymax::Real) = 
    GDAL.setspatialfilterrectex(layer, i, xmin, ymin, xmax, ymax)

"""
Set a new spatial filter.

This method set the geometry to be used as a spatial filter when fetching
features via the GetNextFeature() method. Only features that geometrically
intersect the filter geometry will be returned.

Currently this test is may be inaccurately implemented, but it is guaranteed
that all features who's envelope (as returned by OGRGeometry::getEnvelope())
overlaps the envelope of the spatial filter will be returned. This can result
in more shapes being returned that should strictly be the case.

This method makes an internal copy of the passed geometry. The passed geometry
remains the responsibility of the caller, and may be safely destroyed.

For the time being the passed filter geometry should be in the same SRS as the
layer (as returned by OGRLayer::GetSpatialRef()). In the future this may be
generalized.

### Parameters
* `layer`: the layer on which to set the spatial filter.
* `i`: index of the geometry field on which the spatial filter operates.
* `geom`: the geometry to use as a filtering region. NULL may be passed
    indicating that the current spatial filter should be cleared, but
    no new one instituted.
"""
setspatialfilter!(layer::FeatureLayer, i::Integer, geom::Geometry) = 
    GDAL.setspatialfilterex(layer, i, geom)

clearspatialfilter!(layer::FeatureLayer, i::Integer) = 
    GDAL.setspatialfilterex(layer, i, C_NULL)

"""
Set a new rectangular spatial filter.
### Parameters
* `layer`: handle to the layer on which to set the spatial filter.
* `i`: index of the geometry field on which the spatial filter operates.
* `xmin`: the minimum X coordinate for the rectangular region.
* `ymin`: the minimum Y coordinate for the rectangular region.
* `xmax`: the maximum X coordinate for the rectangular region.
* `ymax`: the maximum Y coordinate for the rectangular region.
"""
setspatialfilter!(layer::FeatureLayer, i::Integer, xmin::Real, ymin::Real,
               xmax::Real, ymax::Real) = 
    GDAL.setspatialfilterrectex(layer, i, xmin, ymin, xmax, ymax)

"""
Set a new attribute query.

This method sets the attribute query string to be used when fetching features
via the GetNextFeature() method. Only features for which the query evaluates as
true will be returned.

The query string should be in the format of an SQL WHERE clause. For instance
`"population > 1000000 and population < 5000000"` where population is an
attribute in the layer. The query format is normally a restricted form of
SQL WHERE clause as described in the "WHERE" section of the OGR SQL tutorial.
In some cases (RDBMS backed drivers) the native capabilities of the database may
be used to interpret the WHERE clause in which case the capabilities will be
broader than those of OGR SQL.

Note that installing a query string will generally result in resetting the
current reading position (ala ResetReading()).

### Parameters
* `layer`: handle to the layer on which attribute query will be executed.
* `query`: query in restricted SQL WHERE format, or NULL to clear the
    current query.
"""
function setattributefilter!(layer::FeatureLayer, query::AbstractString)
    result = GDAL.setattributefilter(layer, query)
    @ogrerr result """Failed to set a new attribute query. The query expression
    might be in error."""
end

function clearattributefilter!(layer::FeatureLayer)
    result = GDAL.setattributefilter(layer, Ptr{UInt8}(C_NULL))
    @ogrerr result """OGRErr $result: Failed to clear attribute query."""
end

"""
Reset feature reading to start on the first feature.

This affects `GetNextFeature()`.
"""
resetreading!(layer::FeatureLayer) = GDAL.resetreading(layer)

"""
Fetch the next available feature from this layer.

The returned feature becomes the responsibility of the caller to delete with
`DestroyFeature()`. It is critical that all features associated with an OGRLayer
(more specifically an OGRFeatureDefn) be deleted before that layer/datasource is
deleted.

Only features matching the current spatial filter (set with SetSpatialFilter())
will be returned.

This method implements sequential access to the features of a layer. The
`ResetReading()` method can be used to start at the beginning again.

Features returned by `GetNextFeature()` may or may not be affected by concurrent
modifications depending on drivers. A guaranteed way of seeing modifications in
effect is to call ResetReading() on layers where `GetNextFeature()` has been
called, before reading again. Structural changes in layers (field addition,
deletion, ...) when a read is in progress may or may not be possible depending
on drivers. If a transaction is committed/aborted, the current sequential
reading may or may not be valid after that operation and a call to
`ResetReading()` might be needed.
"""
unsafe_nextfeature(layer::FeatureLayer) = GDAL.getnextfeature(layer)

"""
Move read cursor to the `i`-th feature in the current resultset.

This method allows positioning of a layer such that the GetNextFeature() call
will read the requested feature, where `i` is an absolute index into the
current result set. So, setting it to 3 would mean the next feature read with
`GetNextFeature()` would have been the 4th feature to have been read if
sequential reading took place from the beginning of the layer, including
accounting for spatial and attribute filters.

Only in rare circumstances is `SetNextByIndex()` efficiently implemented. In all
other cases the default implementation which calls `ResetReading()` and then
calls `GetNextFeature()` `i` times is used. To determine if fast seeking is
available on the current layer use the `TestCapability()` method with a value of
`OLCFastSetNextByIndex`.

### Parameters
* `layer`: handle to the layer
* `i`: the index indicating how many steps into the result set to seek.
"""
function setnextbyindex!(layer::FeatureLayer, i::Integer)
    result = GDAL.setnextbyindex(layer, i)
    @ogrerr result "Failed to move the cursor to index $i"
end

"""
Return a feature (now owned by the caller) by its identifier or NULL on failure.

This function will attempt to read the identified feature. The nFID value cannot
be OGRNullFID. Success or failure of this operation is unaffected by the spatial
or attribute filters (and specialized implementations in drivers should make
sure that they do not take into account spatial or attribute filters).

If this function returns a non-NULL feature, it is guaranteed that its feature
id (OGR_F_GetFID()) will be the same as nFID.

Use OGR_L_TestCapability(OLCRandomRead) to establish if this layer supports
efficient random access reading via OGR_L_GetFeature(); however, the call should
always work if the feature exists as a fallback implementation just scans all
the features in the layer looking for the desired feature.

Sequential reads (with OGR_L_GetNextFeature()) are generally considered
interrupted by a OGR_L_GetFeature() call.

The returned feature should be free with OGR_F_Destroy().
"""
unsafe_getfeature(layer::FeatureLayer, i::Integer) = GDAL.getfeature(layer, i)

"""
Rewrite an existing feature.

This function will write a feature to the layer, based on the feature id within
the OGRFeature.

Use OGR_L_TestCapability(OLCRandomWrite) to establish if this layer supports
random access writing via OGR_L_SetFeature().

### Returns
OGRERR_NONE if the operation works, otherwise an appropriate error code
(e.g OGRERR_NON_EXISTING_FEATURE if the feature does not exist).
"""
function setfeature!(layer::FeatureLayer, feature::Feature)
    result = GDAL.setfeature(layer, feature)
    @ogrerr result "Failed to set feature."
end

"""
Create and write a new feature within a layer.

The passed feature is written to the layer as a new feature, rather than
overwriting an existing one. If the feature has a feature id other than
OGRNullFID, then the native implementation may use that as the feature id of
the new feature, but not necessarily. Upon successful return the passed feature
will have been updated with the new feature id.
"""
function createfeature(layer::FeatureLayer, feature::Feature)
    result = GDAL.createfeature(layer, feature)
    @ogrerr result "Failed to create and write feature in layer."
end

unsafe_createfeature(layer::FeatureLayer) =
    unsafe_createfeature(borrow_getlayerdefn(layer))

"""
Delete feature with fid `i` from layer.

The feature with the indicated feature id is deleted from the layer if supported
by the driver. Most drivers do not support feature deletion, and will return
OGRERR_UNSUPPORTED_OPERATION. The OGR_L_TestCapability() function may be called
with OLCDeleteFeature to check if the driver supports feature deletion.

### Returns
OGRERR_NONE if the operation works, otherwise an appropriate error code
(e.g OGRERR_NON_EXISTING_FEATURE if the feature does not exist).
"""
function deletefeature!(layer::FeatureLayer, i::Integer)
    result = GDAL.deletefeature(layer, i)
    @ogrerr result "OGRErr $result: Failed to delete feature $i."
end

"""
Destroy the feature passed in.

The feature is deleted, but within the context of the GDAL/OGR heap. This is
necessary when higher level applications use GDAL/OGR from a DLL and they want
to delete a feature created within the DLL. If the delete is done in the calling
application the memory will be freed onto the application heap which is
inappropriate.
"""
destroy(feature::Feature) = GDAL.destroy(feature)

"""
Set feature geometry.

This method updates the features geometry, and operate exactly as SetGeometry(),
except that this method assumes ownership of the passed geometry (even in case
of failure of that function).

### Returns
OGRERR_NONE if successful, or OGR_UNSUPPORTED_GEOMETRY_TYPE if the geometry
type is illegal for the OGRFeatureDefn (checking not yet implemented).
"""
function setgeomdirectly!(feature::Feature, geom::Geometry)
    result = GDAL.setgeometrydirectly(feature, geom)
    @ogrerr result "OGRErr $result: Failed to set feature geometry."
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
OGRERR_NONE if successful, or OGR_UNSUPPORTED_GEOMETRY_TYPE if the geometry
type is illegal for the OGRFeatureDefn (checking not yet implemented).
"""
function setgeom!(feature::Feature, geom::Geometry)
    result = GDAL.setgeometry(feature, geom)
    @ogrerr result "OGRErr $result: Failed to set feature geometry."
end

"Fetch an handle to internal feature geometry. It should not be modified."
borrow_getgeom(feature::Feature) = GDAL.getgeometryref(feature)

"Test if two features are the same."
equals(feat1::Feature, feat2::Feature) = Bool(GDAL.equals(feat1, feat2))

"""
Fetch number of fields on this feature.

This will always be the same as the field count for the OGRFeatureDefn.
"""
nfield(feature::Feature) = GDAL.getfieldcount(feature)

"""
Fetch definition for this field.

### Parameters
* `feature`: the feature on which the field is found.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.

### Returns
an handle to the field definition (from the OGRFeatureDefn). This is an
internal reference, and should not be deleted or modified.
"""
borrow_getfielddefn(feature::Feature, i::Integer) =
    GDAL.getfielddefnref(feature, i)

# fetchfields(feature::Feature) =
#     Dict([getname(borrowfieldefn(feature, i-1)) => fetchfield(feature, i-1)
#          for i in 1:nfield(feature)])

# fetchfields{T <: Integer}(feature::Feature, indices::UnitRange{T}) =
#     Dict([getname(borrowfieldefn(feature, i)) => fetchfield(feature, i)
#          for i in indices])

# fetchfields{T <: Integer}(feature::Feature, indices::Vector{T}) =
#     Dict([getname(borrowfieldefn(feature, i)) => fetchfield(feature, i)
#          for i in indices])

# fetchfields(feature::Feature, names::Vector{ASCIIString}) =
#     Dict([name => fetchfield(feature, getfieldindex(feature, name))
#          for name in names])

# borrowgeomfields(feature::Feature) =
#     Dict([getname(borrowgeomfieldefn(feature, i)) =>
#           toWKT(borrowgeomfield(feature, i))
#           for i in 1:ngeomfield(feature)])

"""
Fetch the field index given field name.

This is a cover for the OGRFeatureDefn::GetFieldIndex() method.

### Parameters
* `feature`: the feature on which the field is found.
* `name`: the name of the field to search for.

### Returns
the field index, or -1 if no matching field is found.
"""
getfieldindex(feature::Feature, name::AbstractString) =
    GDAL.getfieldindex(feature, name)

"""Test if a field has ever been assigned a value or not.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
isfieldset(feature::Feature, i::Integer) = Bool(GDAL.isfieldset(feature, i))

"""
Clear a field, marking it as unset.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
unsetfield(feature::Feature, i::Integer) = GDAL.unsetfield(feature, i)

# """
#     OGR_F_GetRawFieldRef(OGRFeatureH hFeat,
#                          int iField) -> OGRField *
# Fetch an handle to the internal field value given the index.
# ### Parameters
# * `hFeat`: handle to the feature on which field is found.
# * `iField`: the field to fetch, from 0 to GetFieldCount()-1.
# ### Returns
# the returned handle is to an internal data structure, and should not be freed, or modified.
# """
# function getrawfieldref(arg1::Ptr{OGRFeatureH},arg2::Integer)
#     ccall((:OGR_F_GetRawFieldRef,libgdal),Ptr{OGRField},(Ptr{OGRFeatureH},Cint),arg1,arg2)
# end

"""Fetch field value as integer.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint(feature::Feature, i::Integer) = GDAL.getfieldasinteger(feature, i)

"""Fetch field value as integer 64 bit.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asint64(feature::Feature, i::Integer) = GDAL.getfieldasinteger64(feature, i)

"""Fetch field value as a double.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asdouble(feature::Feature, i::Integer) = GDAL.getfieldasdouble(feature, i)

"""
Fetch field value as a string.

### Parameters
* `feature`: the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
"""
asstring(feature::Feature, i::Integer) = GDAL.getfieldasstring(feature, i)

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
the field value. This list is internal, and should not be modified, or freed. Its lifetime may be very brief. If *pnCount is zero on return the returned pointer may be NULL or non-NULL.
"""
function asintlist(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasintegerlist(feature, i, n)
    GDAL.checknull(ptr)
    pointer_to_array(ptr, n[], false)
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
the field value. This list is internal, and should not be modified, or freed. Its lifetime may be very brief. If *pnCount is zero on return the returned pointer may be NULL or non-NULL.
"""
function asint64list(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasinteger64list(feature, i, n)
    GDAL.checknull(ptr)
    pointer_to_array(ptr, n[], false)
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
the field value. This list is internal, and should not be modified, or freed. Its lifetime may be very brief. If *pnCount is zero on return the returned pointer may be NULL or non-NULL.
"""
function asdoublelist(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasdoublelist(feature, i, n)
    GDAL.checknull(ptr)
    pointer_to_array(ptr, n[], false)
end

"""
    OGR_F_GetFieldAsStringList(OGRFeatureH hFeat,
                               int iField) -> char **
Fetch field value as a list of strings.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to fetch, from 0 to GetFieldCount()-1.
### Returns
the field value. This list is internal, and should not be modified, or freed. Its lifetime may be very brief.
"""
asstringlist(feature::Feature, i::Integer) =
    unsafe_loadstringlist(GDAL.C.OGR_F_GetFieldAsStringList(feature, i))

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
the field value. This list is internal, and should not be modified, or freed. Its lifetime may be very brief.
"""
function asbinary(feature::Feature, i::Integer)
    n = Ref{Cint}()
    ptr = GDAL.getfieldasbinary(feature, i, n)
    GDAL.checknull(ptr)
    pointer_to_array(ptr, n[], false)
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
    pyr=Ref{Cint}(); pmth=Ref{Cint}(); pday=Ref{Cint}(); phr=Ref{Cint}()
    pmin=Ref{Cint}(); psec=Ref{Cint}(); ptz=Ref{Cint}()
    result = GDAL.getfieldasdatetime(feature,i,pyr,pmth,pday,phr,pmin,psec,ptz)
    (Bool(result) == false) && error("Failed to fetch datetime at index $i")
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
# function getfieldasdatetimeex(hFeat::Ptr{OGRFeatureH},iField::Integer,pnYear,pnMonth,pnDay,pnHour,pnMinute,pfSecond,pnTZFlag)
#     ccall((:OGR_F_GetFieldAsDateTimeEx,libgdal),Cint,(Ptr{OGRFeatureH},Cint,Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cfloat},Ptr{Cint}),hFeat,iField,pnYear,pnMonth,pnDay,pnHour,pnMinute,pfSecond,pnTZFlag)
# end

asnothing(feature::Feature, i::Integer) = nothing

const _FETCHFIELD = Dict{GDAL.OGRFieldType, Function}(
                         GDAL.OFTInteger => asint,              #0
                         GDAL.OFTIntegerList => asintlist,      #1
                         GDAL.OFTReal => asdouble,              #2
                         GDAL.OFTRealList => asdoublelist,      #3
                         GDAL.OFTString => asstring,            #4
                         GDAL.OFTStringList => asstringlist,    #5
                                # const OFTWideString = (UInt32)(6)
                            # const OFTWideStringList = (UInt32)(7)
                         GDAL.OFTBinary => asbinary,            #8
                                      # const OFTDate = (UInt32)(9)
                                      # const OFTTime = (UInt32)(10)
                         GDAL.OFTDateTime => asdatetime,        #11
                         GDAL.OFTInteger64 => asint64,          #12
                         GDAL.OFTInteger64List => asint64list  #,13
                    # const OFTMaxType = (UInt32)(13)
                        )

# function fetchfield(feature::Feature, i::Integer)
#     const FETCHFIELD = Dict{GDAL.OGRFieldType, Function}(
#                         GDAL.OFTInteger => asint,
#                         GDAL.OFTInteger64 => asint64,
#                         GDAL.OFTReal => asdouble,
#                         GDAL.OFTString => asstring)
#     asnothing(feature::Feature, i::Integer) = nothing
#     if isfieldset(feature, i)
#         _fieldtype = fieldtype(borrowfieldefn(feature, i))
#         _fetchfield = get(FETCHFIELD, _fieldtype, asnothing)
#         return _fetchfield(feature, i)
#     end
# end

# fetchfield(feature::Feature, name::AbstractString) =
#     fetchfield(feature, fieldindex(feature, name))

function getfield(feature::Feature, i::Integer)
    if isfieldset(feature, i)
        _fieldtype = gettype(borrow_getfielddefn(feature, i))
        _fetchfield = get(_FETCHFIELD, _fieldtype, asnothing)
        return _fetchfield(feature, i)
    end
end

fetchfield(feature::Feature, name::AbstractString) =
    fetchfield(feature, getfieldindex(feature, name))

"""
Set field to integer value.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::Integer) =
    GDAL.setfieldinteger(feature, i, value)

"""
Set field to 64 bit integer value.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::Int64) =
    GDAL.setfieldinteger64(feature, i, value)

"""
Set field to double value.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::Cdouble) =
    GDAL.setfielddouble(feature, i, value)

"""
Set field to string value.

### Parameters
* `feature`: handle to the feature that owned the field.
* `i`: the field to fetch, from 0 to GetFieldCount()-1.
* `value`: the value to assign.
"""
setfield!(feature::Feature, i::Integer, value::AbstractString) =
    GDAL.setfieldstring(feature, i, value)

"""
    OGR_F_SetFieldIntegerList(OGRFeatureH hFeat,
                              int iField,
                              int nCount,
                              int * panValues) -> void
Set field to list of integers value.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nCount`: the number of values in the list being assigned.
* `panValues`: the values to assign.
"""
setfield!(feature::Feature, i::Integer, value::Vector{Cint}) =
    GDAL.setfieldintegerlist(feature, i, length(value), value)

"""
    OGR_F_SetFieldInteger64List(OGRFeatureH hFeat,
                                int iField,
                                int nCount,
                                const GIntBig * panValues) -> void
Set field to list of 64 bit integers value.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nCount`: the number of values in the list being assigned.
* `panValues`: the values to assign.
"""
setfield!(feature::Feature, i::Integer, value::Vector{GDAL.GIntBig}) =
    GDAL.setfieldintegerlist(feature, i, length(value), value)

"""
    OGR_F_SetFieldDoubleList(OGRFeatureH hFeat,
                             int iField,
                             int nCount,
                             double * padfValues) -> void
Set field to list of doubles value.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nCount`: the number of values in the list being assigned.
* `padfValues`: the values to assign.
"""
setfield!(feature::Feature, i::Integer, value::Vector{Cdouble}) =
    GDAL.setfielddoublelist(feature, i, length(value), value)

"""
    OGR_F_SetFieldStringList(OGRFeatureH hFeat,
                             int iField,
                             char ** papszValues) -> void
Set field to list of strings value.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `papszValues`: the values to assign.
"""
setfield!{T <: AbstractString}(feature::Feature, i::Integer, value::Vector{T}) =
    ccall((:OGR_F_SetFieldStringList,GDAL.libgdal),Void,
          (Feature,Cint,StringList),feature,i,value)

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
#     ccall((:OGR_F_SetFieldRaw,libgdal),Void,(Ptr{OGRFeatureH},Cint,Ptr{OGRField}),arg1,arg2,arg3)
# end

"""
    OGR_F_SetFieldBinary(OGRFeatureH hFeat,
                         int iField,
                         int nBytes,
                         GByte * pabyData) -> void
Set field to binary data.
### Parameters
* `hFeat`: handle to the feature that owned the field.
* `iField`: the field to set, from 0 to GetFieldCount()-1.
* `nBytes`: the number of bytes in pabyData array.
* `pabyData`: the data to apply.
"""
setfield!(feature::Feature, i::Integer, value::Vector{GDAL.GByte}) =
    GDAL.setfieldbinary(feature, i, sizeof(value), value)

"""
    OGR_F_SetFieldDateTime(OGRFeatureH hFeat,
                           int iField,
                           int nYear,
                           int nMonth,
                           int nDay,
                           int nHour,
                           int nMinute,
                           int nSecond,
                           int nTZFlag) -> void
Set field to datetime.
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
setfield!(feature::Feature, i::Integer, dt::DateTime) =
    GDAL.setfielddatetime(feature,i,Dates.year(dt),Dates.month(dt),Dates.day(dt),
                          Dates.hour(dt),Dates.minute(dt),Dates.second(dt),0)

# """
#     OGR_F_SetFieldDateTimeEx(OGRFeatureH hFeat,
#                              int iField,
#                              int nYear,
#                              int nMonth,
#                              int nDay,
#                              int nHour,
#                              int nMinute,
#                              float fSecond,
#                              int nTZFlag) -> void
# Set field to datetime.
# ### Parameters
# * `hFeat`: handle to the feature that owned the field.
# * `iField`: the field to set, from 0 to GetFieldCount()-1.
# * `nYear`: (including century)
# * `nMonth`: (1-12)
# * `nDay`: (1-31)
# * `nHour`: (0-23)
# * `nMinute`: (0-59)
# * `fSecond`: (0-59, with millisecond accuracy)
# * `nTZFlag`: (0=unknown, 1=localtime, 100=GMT, see data model for details)
# """
# function setfielddatetimeex(arg1::Ptr{OGRFeatureH},arg2::Integer,arg3::Integer,arg4::Integer,arg5::Integer,arg6::Integer,arg7::Integer,arg8::Cfloat,arg9::Integer)
#     ccall((:OGR_F_SetFieldDateTimeEx,libgdal),Void,(Ptr{OGRFeatureH},Cint,Cint,Cint,Cint,Cint,Cint,Cfloat,Cint),arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)
# end


"""
Fetch number of geometry fields on this feature.

This will always be the same as the geometry field count for OGRFeatureDefn.
"""
ngeomfield(feature::Feature) = GDAL.getgeomfieldcount(feature)

"""
Fetch definition for this geometry field.

### Parameters
* `feature`: the feature on which the field is found.
* `i`: the field to fetch, from 0 to GetGeomFieldCount()-1.

### Returns
The field definition (from the OGRFeatureDefn). This is an
internal reference, and should not be deleted or modified.
"""
borrow_getgeomfieldefn(feature::Feature, i::Integer) =
    GDAL.getgeomfielddefnref(feature, i)

"""
Fetch the geometry field index given geometry field name.

This is a cover for the OGRFeatureDefn::GetGeomFieldIndex() method.

### Parameters
* `feature`: the feature on which the geometry field is found.
* `name`: the name of the geometry field to search for.

### Returns
the geometry field index, or -1 if no matching geometry field is found.
"""
getgeomfieldindex(feature::Feature, name::AbstractString) =
    GDAL.getgeomfieldindex(feature, i)

"""
Fetch pointer to the feature geometry.

### Parameters
* `feature`: handle to the feature to get geometry from.
* `i`: geometry field to get.

### Returns
an internal feature geometry. This object should not be modified.
"""
borrow_getgeomfield(feature::Feature, i::Integer) =
    GDAL.getgeomfieldref(feature, i)

"""
Set feature geometry of a specified geometry field.

This function updates the features geometry, and operate exactly as
SetGeomField(), except that this function assumes ownership of the passed
geometry (even in case of failure of that function).

### Parameters
* `feature`: the feature on which to apply the geometry.
* `i`: geometry field to set.
* `geom`: the new geometry to apply to feature.

### Returns
OGRERR_NONE if successful, or OGRERR_FAILURE if the index is invalid, or
OGR_UNSUPPORTED_GEOMETRY_TYPE if the geometry type is illegal for the
OGRFeatureDefn (checking not yet implemented).
"""
function setgeomfielddirectly!(feature::Feature, i::Integer, geom::Geometry)
    result = GDAL.setgeomfielddirectly(feature, i, geom)
    @ogrerr result "OGRErr $result: Failed to set feature geometry directly"
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
OGRERR_NONE if successful, or OGR_UNSUPPORTED_GEOMETRY_TYPE if the geometry type
is illegal for the OGRFeatureDefn (checking not yet implemented).
"""
function setgeomfield!(feature::Feature, i::Integer, geom::Geometry)
    result = GDAL.setgeomfield(feature, i, geom)
    @ogrerr result "OGRErr $result: Failed to set feature geometry"
end

"""
Get feature identifier.

### Returns
feature id or OGRNullFID if none has been assigned.
"""
getfid(feature::Feature) = GDAL.getfid(feature)

"""
Set the feature identifier.

### Parameters
* `feature`: handle to the feature to set the feature id to.
* `i`: the new feature identifier value to assign.

### Returns
On success OGRERR_NONE, or on failure some other value.
"""
function setfid!(feature::Feature, i::Integer)
    result = GDAL.setfid(feature, i)
    @ogrerr result "OGRErr $result: Failed to set FID $i"
end

"""
Set one feature from another.

### Parameters
* `feature1`: handle to the feature to set to.
* `feature2`: handle to the feature from which geometry, and field values
    will be copied.
* `forgiving`: TRUE if the operation should continue despite lacking output
    fields matching some of the source fields.

### Returns
OGRERR_NONE if the operation succeeds, even if some values are not transferred,
otherwise an error code.
"""
function setfrom!(feature1::Feature, feature2::Feature, forgiving::Bool=false)
    result = GDAL.setfrom(feature1, feature2, forgiving)
    @ogrerr result "OGRErr $result: Failed to set feature"
end

"""
Set one feature from another.

### Parameters
* `feature1`: the feature to set to.
* `feature2`: the feature from which geometry and field values will be copied
* `indices`: indices of the destination feature's fields stored at the
    corresponding index of the source feature's fields. A value of -1 should be
    used to ignore the source's field. The array should not be NULL and be as
    long as the number of fields in the source feature.
* `forgiving`: TRUE if the operation should continue despite lacking output
    fields matching some of the source fields.

### Returns
OGRERR_NONE if the operation succeeds, even if some values are not transferred,
otherwise an error code.
"""
function setfrom!(feature1::Feature, feature2::Feature, indices::Vector{Cint},
                 forgiving::Bool=false)
    result = GDAL.setfromwithmap(feature1, feature2, forgiving, pointer(indices))
    @ogrerr result "OGRErr $result: Failed to set feature with map"
end


"Fetch style string for this feature."
getstylestring(feature::Feature) = GDAL.getstylestring(feature)

"""
Set feature style string.

This method operate exactly as OGRFeature::SetStyleStringDirectly() except that
it doesn't assume ownership of the passed string, but makes a copy of it.

This method operate exactly as OGR_F_SetStyleStringDirectly() except that it
does not assume ownership of the passed string, but instead makes a copy of it.
"""
setstylestring!(feature::Feature, style::AbstractString) =
    GDAL.setstylestring(feature, style)

"""
Set feature style string.

This method operate exactly as OGRFeature::SetStyleString() except that it
assumes ownership of the passed string.

This method operate exactly as OGR_F_SetStyleString() except that it assumes
ownership of the passed string.
"""
setstylestringdirectly!(feature::Feature, style::AbstractString) =
    GDAL.setstylestringdirectly(feature, style)

"OGR_F_GetStyleTable(OGRFeatureH hFeat) -> OGRStyleTableH"
getstyletable(feature::Feature) = GDAL.getstyletable(feature)

"""
    OGR_F_SetStyleTableDirectly(OGRFeatureH hFeat,
                                OGRStyleTableH hStyleTable) -> void
"""
setstyletabledirectly!(feature::Feature, styletable::StyleTable) =
    GDAL.setstyletabledirectly(feature, styletable)

"""
    OGR_F_SetStyleTable(OGRFeatureH hFeat,
                        OGRStyleTableH hStyleTable) -> void
"""
setstyletable!(feature::Feature, styletable::StyleTable) =
    GDAL.setstyletable(feature, styletable)

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
getnativedata(feature::Feature) = GDAL.getnativedata(feature)

"""
Sets the native data for the feature.

The native data is the representation in a "natural" form that comes from the
driver that created this feature, or that is aimed at an output driver. The
native data may be in different format, which is indicated by
GetNativeMediaType().
"""
setnativedata!(feature::Feature, data::AbstractString) =
    GDAL.setnativedata(feature, data)

"""
Returns the native media type for the feature.

The native media type is the identifier for the format of the native data. It
follows the IANA RFC 2045 (see https://en.wikipedia.org/wiki/Media_type),
e.g. "application/vnd.geo+json" for JSON.
"""
getmediatype(feature::Feature) = GDAL.getnativemediatype(feature)

"""
Sets the native media type for the feature.

The native media type is the identifier for the format of the native data. It
follows the IANA RFC 2045 (see https://en.wikipedia.org/wiki/Media_type),
e.g. "application/vnd.geo+json" for JSON.
"""
setmediatype!(feature::Feature, mediatype::AbstractString) =
    GDAL.setnativemediatype(feature, mediatype)

"""
Fill unset fields with default values that might be defined.

### Parameters
* `feature`: handle to the feature.
* `notnull`: if we should fill only unset fields with a not-null constraint.
* `papszOptions`: unused currently. Must be set to NULL.
"""
fillunsetwithdefault!(feature::Feature; notnull::Bool=true,
                      options=StringList(C_NULL)) =
    GDAL.fillunsetwithdefault(feature, notnull, options)

"""
Validate that a feature meets constraints of its schema.

The scope of test is specified with the nValidateFlags parameter.

Regarding OGR_F_VAL_WIDTH, the test is done assuming the string width must be
interpreted as the number of UTF-8 characters. Some drivers might interpret the
width as the number of bytes instead. So this test is rather conservative (if it
fails, then it will fail for all interpretations).

### Parameters
* `feature`: handle to the feature to validate.
* `flags`: OGR_F_VAL_ALL or combination of OGR_F_VAL_NULL,
    OGR_F_VAL_GEOM_TYPE, OGR_F_VAL_WIDTH and OGR_F_VAL_ALLOW_NULL_WHEN_DEFAULT
    with '|' operator
* `emiterror`: TRUE if a CPLError() must be emitted when a check fails

### Returns
TRUE if all enabled validation tests pass.
"""
validate(feature::Feature, flags::Integer, emiterror::Bool) =
    Bool(GDAL.validate(feature, flags, emiterror))

"""
Fetch the schema information for this layer.

The returned handle to the OGRFeatureDefn is owned by the OGRLayer, and should
not be modified or freed by the application. It encapsulates the attribute
schema of the features of the layer.
"""
borrow_getlayerdefn(layer::FeatureLayer) = GDAL.getlayerdefn(layer)

"""
Find the index of field in a layer.

If `exactMatch` is set to `false` and the field doesn't exists in the given form
the driver might apply some changes to make it match, like those it might do if
the layer was created (eg. like `LAUNDER` in the OCI driver).

### Returns
field index, or -1 if the field doesn't exist
"""
findfieldindex(layer::FeatureLayer, field::AbstractString, exactmatch::Bool) =
    GDAL.findfieldindex(layer, field, exactmatch)

"""
Fetch the feature count in this layer.

### Parameters
* `layer`: handle to the layer that owned the features.
* `force`: Flag indicating whether the count should be computed even if it
    is expensive.

### Returns
feature count, -1 if count not known.
"""
nfeature(layer::FeatureLayer, force::Bool=false) =
    GDAL.getfeaturecount(layer, force)

"""
Fetch the extent of this layer.

Returns the extent (MBR) of the data in the layer. If `force` is `false`, and it
would be expensive to establish the extent then OGRERR_FAILURE will be returned
indicating that the extent isn't know. If `force` is `true` then some
implementations will actually scan the entire layer once to compute the MBR of
all the features in the layer.

Depending on the drivers, the returned extent may or may not take the spatial
filter into account. So it is safer to call GetExtent() without setting a
spatial filter.

Layers without any geometry may return OGRERR_FAILURE just indicating that no
meaningful extents could be collected.

Note that some implementations of this method may alter the read cursor of the
layer.

### Parameters
* `layer`: handle to the layer from which to get extent.
* `force`: Flag indicating whether the extent should be computed even if it is
            expensive.
"""
function getextent(i::Integer, layer::FeatureLayer, force::Bool=false)
    envelope = Ref{Envelope}()
    result = GDAL.getextentex(i, layer, envelope, force)
    @ogrerr result "Extent not known"
    envelope[]
end

function getextent(layer::FeatureLayer, force::Bool=false)
    envelope = Ref{Envelope}()
    result = GDAL.getextent(layer, envelope, force)
    @ogrerr result "Extent not known"
    envelope[]
end

"""
Test if this layer supported the named capability.

### Parameters
* `capability`  the name of the capability to test.

### Returns
TRUE if the layer has the requested capability, or FALSE otherwise.
OGRLayers will return FALSE for any unrecognized capabilities.

### Additional Remarks
The capability codes that can be tested are represented as strings, but
`#defined` constants exists to ensure correct spelling. Specific layer types may
implement class specific capabilities, but this can't generally be discovered by
the caller.

* `OLCRandomRead` / "RandomRead": TRUE if the GetFeature() method is
    implemented in an optimized way for this layer, as opposed to the default
    implementation using ResetReading() and GetNextFeature() to find the
    requested feature id.

* `OLCSequentialWrite` / "SequentialWrite": TRUE if the CreateFeature() method
    works for this layer. Note this means that this particular layer is
    writable. The same OGRLayer class may returned FALSE for other layer
    instances that are effectively read-only.

* `OLCRandomWrite` / "RandomWrite": TRUE if the SetFeature() method is
    operational on this layer. Note this means that this particular layer is
    writable. The same OGRLayer class may returned FALSE for other layer
    instances that are effectively read-only.

* `OLCFastSpatialFilter` / "FastSpatialFilter": TRUE if this layer implements
    spatial filtering efficiently. Layers that effectively read all features,
    and test them with the OGRFeature intersection methods should return FALSE.
    This can be used as a clue by the application whether it should build and
    maintain its own spatial index for features in this layer.

* `OLCFastFeatureCount` / "FastFeatureCount": TRUE if this layer can return a
    feature count (via GetFeatureCount()) efficiently. i.e. without counting the
    features. In some cases this will return TRUE until a spatial filter is
    installed after which it will return FALSE.

* `OLCFastGetExtent` / "FastGetExtent": TRUE if this layer can return its data
    extent (via GetExtent()) efficiently, i.e. without scanning all the
    features. In some cases this will return TRUE until a spatial filter is
    installed after which it will return FALSE.

* `OLCFastSetNextByIndex` / "FastSetNextByIndex": TRUE if this layer can perform
    the SetNextByIndex() call efficiently, otherwise FALSE.

* `OLCCreateField` / "CreateField": TRUE if this layer can create new fields on
    the current layer using CreateField(), otherwise FALSE.

* `OLCCreateGeomField` / "CreateGeomField": (GDAL >= 1.11) TRUE if this layer
    can create new geometry fields on the current layer using CreateGeomField(),
    otherwise FALSE.

* `OLCDeleteField` / "DeleteField": TRUE if this layer can delete existing
    fields on the current layer using DeleteField(), otherwise FALSE.

* `OLCReorderFields` / "ReorderFields": TRUE if this layer can reorder existing
    fields on the current layer using ReorderField() or ReorderFields(),
    otherwise FALSE.

* `OLCAlterFieldDefn` / "AlterFieldDefn": TRUE if this layer can alter the
    definition of an existing field on the current layer using AlterFieldDefn(),
    otherwise FALSE.

* `OLCDeleteFeature` / "DeleteFeature": TRUE if the DeleteFeature() method is
    supported on this layer, otherwise FALSE.

* `OLCStringsAsUTF8` / "StringsAsUTF8": TRUE if values of OFTString fields are
    assured to be in UTF-8 format. If FALSE the encoding of fields is uncertain,
    though it might still be UTF-8.

* `OLCTransactions` / "Transactions": TRUE if the StartTransaction(),
    CommitTransaction() and RollbackTransaction() methods work in a meaningful
    way, otherwise FALSE.

* `OLCIgnoreFields` / "IgnoreFields": TRUE if fields, geometry and style will be
    omitted when fetching features as set by SetIgnoredFields() method.

* `OLCCurveGeometries` / "CurveGeometries": TRUE if this layer supports writing
    curve geometries or may return such geometries. (GDAL 2.0).
"""
testcapability(layer::FeatureLayer, capability::AbstractString) =
    Bool(GDAL.testcapability(layer, capability))

"""
Create a new field on a layer.

You must use this to create new fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the new field.
Applications should never modify the OGRFeatureDefn used by a layer directly.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the OLCCreateField capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

Drivers may or may not support not-null constraints. If they support creating
fields with not-null constraints, this is generally before creating any feature
to the layer.

### Parameters
* `layer`:  the layer to write the field definition.
* `field`:  the field definition to write to disk.
* `approx`: If TRUE, the field may be created in a slightly different form
            depending on the limitations of the format driver.
"""
function createfield!(layer::FeatureLayer, field::FieldDefn,
                      approx::Bool = false)
    result = GDAL.createfield(layer, field, approx)
    @ogrerr result "Failed to create new field"
end

"""
Create a new geometry field on a layer.

You must use this to create new geometry fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the new field.
Applications should never modify the OGRFeatureDefn used by a layer directly.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the OLCCreateField capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

Drivers may or may not support not-null constraints. If they support creating
fields with not-null constraints, this is generally before creating any feature
to the layer.

### Parameters
* `layer`:  the layer to write the field definition.
* `field`:  the geometry field definition to write to disk.
* `approx`: If TRUE, the field may be created in a slightly different form
            depending on the limitations of the format driver.

### Returns
OGRERR_NONE on success.
"""
function creategeomfield!(layer::FeatureLayer, field::GeomFieldDefn,
                          approx::Bool = false)
    result = GDAL.creategeomfield(layer, field, approx)
    @ogrerr result "Failed to create new field"
end

"""
Delete the field at index `i` on a layer.

You must use this to delete existing fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the deleted field.
Applications should never modify the OGRFeatureDefn used by a layer directly.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the OLCDeleteField capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

### Parameters
* `layer`: handle to the layer.
* `i`: index of the field to delete.
"""
function deletefield!(layer::FeatureLayer, i::Integer)
    result = GDAL.deletefield(layer, i)
    @ogrerr result "Failed to delete field $i"
end

"""
Reorder all the fields of a layer.

You must use this to reorder existing fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the reordering of the
fields. Applications should never modify the OGRFeatureDefn used by a layer
directly.

This method should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

panMap is such that,for each field definition at position i after reordering,
its position before reordering was panMap[i].

For example, let suppose the fields were "0","1","2","3","4" initially.
ReorderFields([0,2,3,1,4]) will reorder them as "0","2","3","1","4".

Not all drivers support this method. You can query a layer to check if it
supports it with the OLCReorderFields capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

### Parameters
* `layer`: handle to the layer.
* `indices`: an array of GetLayerDefn()->OGRFeatureDefn::GetFieldCount()
            elements which is a permutation of
                `[0, GetLayerDefn()->OGRFeatureDefn::GetFieldCount()-1]`.
"""
function recordfields!(layer::FeatureLayer, indices::Vector{Cint})
    result = GDAL.reorderfields(layer, indices)
    @ogrerr result "Failed to reorder the fields of layer according to $indices"
end

"""
Reorder an existing field on a layer.

This method is a convenience wrapper of ReorderFields() dedicated to move a
single field. It is a non-virtual method, so drivers should implement
ReorderFields() instead.

You must use this to reorder existing fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the reordering of the
fields. Applications should never modify the OGRFeatureDefn used by a layer
directly.

This method should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

The field definition that was at initial position iOldFieldPos will be moved at
position iNewFieldPos, and elements between will be shuffled accordingly.

For example, let suppose the fields were "0","1","2","3","4" initially.
ReorderField(1, 3) will reorder them as "0","2","3","1","4".

Not all drivers support this method. You can query a layer to check if it
supports it with the OLCReorderFields capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

### Parameters
* `layer`: handle to the layer.
* `oldpos`: previous position of the field to move. Must be in the range
            [0,GetFieldCount()-1].
* `newpos`: new position of the field to move. Must be in the range
            [0,GetFieldCount()-1].
"""
function reorderfield!(layer::FeatureLayer, oldpos::Integer, newpos::Integer)
    result = GDAL.reorderfield(layer, oldpos, newpos)
    @ogrerr result "Failed to reorder field from $oldpos to $newpos."
end

"""
Alter the definition of an existing field on a layer.

You must use this to alter the definition of an existing field of a real layer.
Internally the OGRFeatureDefn for the layer will be updated to reflect the
altered field. Applications should never modify the OGRFeatureDefn used by a
layer directly.

This method should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this method. You can query a layer to check if it
supports it with the OLCAlterFieldDefn capability. Some drivers may only
support this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly. Some drivers might also not support all update flags.

### Parameters
* `layer`:        handle to the layer.
* `i`:            index of the field whose definition must be altered.
* `newfielddefn`: new field definition
* `flags`: combination of ALTER_NAME_FLAG, ALTER_TYPE_FLAG,
            ALTER_WIDTH_PRECISION_FLAG, ALTER_NULLABLE_FLAG and
            ALTER_DEFAULT_FLAG to indicate which of the name and/or type and/or
            width and precision fields and/or nullability from the new field
            definition must be taken into account.
"""
function alterfielddefn!(layer::FeatureLayer, i::Integer,
                         newfielddefn::FieldDefn, flags::UInt8)
    result = OGR.alterfielddefn(layer, i, newfielddefn, flags)
    @ogrerr result "Failed to alter fielddefn of field $i."
end

"For datasources which support transactions, creates a transaction."
function starttransaction(layer::FeatureLayer)
    result = GDAL.starttransaction(layer)
    @ogrerr result "Failed to start transaction."
end

"For datasources which support transactions, commits a transaction."
function committransaction(layer::FeatureLayer)
    result = GDAL.committransaction(layer)
    @ogrerr result "Failed to commit transaction."
end

"""
For datasources which support transactions, RollbackTransaction will roll back
a datasource to its state before the start of the current transaction.
"""
function rollbacktransaction(layer::FeatureLayer)
    result = GDAL.rollbacktransaction(layer)
    @ogrerr result "Failed to rollback transaction."
end

"""
Increment layer reference count.

### Returns
the reference count after incrementing.
"""
reference(layer::FeatureLayer) = GDAL.reference(layer)

"""
Decrement layer reference count.

### Returns
the reference count after decrementing.
"""
dereference(layer::FeatureLayer) = GDAL.dereference(layer)

"the current reference count for the layer object itself."
nreference(layer::FeatureLayer) = GDAL.getrefcount(layer)

"""
Flush pending changes to disk.

This call is intended to force the layer to flush any pending writes to disk,
and leave the disk file in a consistent state. It would not normally have any
effect on read-only datasources.

Some layers do not implement this method, and will still return OGRERR_NONE.
The default implementation just returns OGRERR_NONE. An error is only returned
if an error occurs while attempting to flush to disk.

In any event, you should always close any opened datasource with
DestroyDataSource() that will ensure all data is correctly flushed.

### Returns
OGRERR_NONE if no error occurs (even if nothing is done) or an error code.
"""
function synctodisk!(layer::FeatureLayer)
    result = GDAL.synctodisk(layer)
    @ogrerr result "Failed to flush pending changes to disk"
end

"OGR_L_GetFeaturesRead(OGRLayerH hLayer) -> GIntBig"
getfeaturesread(layer::FeatureLayer) = GDAL.getfeaturesread(layer)

"""This method returns the name of the underlying database column being used as
the FID column, or "" if not supported.
"""
getfidcolname(layer::FeatureLayer) = GDAL.getfidcolumn(layer)

"""
This method returns the name of the underlying database column being used as
the geometry column, or "" if not supported.
"""
getgeomcolname(layer::FeatureLayer) = GDAL.getgeometrycolumn(layer)

"""
Set which fields can be omitted when retrieving features from the layer.

If the driver supports this functionality (testable using `OLCIgnoreFields`
capability), it will not fetch the specified fields in subsequent calls to
`GetFeature()`/`GetNextFeature()` and thus save some processing time and/or
bandwidth.

Besides field names of the layers, the following special fields can be passed:
`"OGR_GEOMETRY"` to ignore geometry and `"OGR_STYLE"` to ignore layer style.

By default, no fields are ignored.

### Parameters
* `fieldnames`: an array of field names terminated by NULL item. If NULL is
passed, the ignored list is cleared.

### Returns
OGRERR_NONE if all field names have been resolved (even if the driver does not
support this method)
"""
function setignoredfields!(layer::FeatureLayer, fieldnames)
    result = ccall((:OGR_L_SetIgnoredFields,GDAL.libgdal),GDAL.OGRErr,
                   (FeatureLayer,StringList),layer,fieldnames)
    @ogrerr result "Failed to set ignored fields $fieldnames."
end


"""
Intersection of two layers.

The result layer contains features whose geometries represent areas that are
common between features in the input layer and in the method layer. The features
in the result layer have attributes from both input and method layers. The
schema of the result layer can be set by the user or, if it is empty, is
initialized to contain all fields in the input and method layers.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is:

* `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into 
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the method layer.
* `USE_PREPARED_GEOMETRIES=YES/NO`. Set to NO to not use prepared geometries to
    pretest intersection of features of method layer with features of this layer
* `PRETEST_CONTAINMENT=YES/NO`. Set to YES to pretest the containment of
    features of method layer within the features of this layer. This will speed
    up the method significantly in some cases. Requires that the prepared
    geometries are in effect.
* `KEEP_LOWER_DIMENSION_GEOMETRIES=YES/NO`. Set to NO to skip result features
    with lower dimension geometry that would otherwise be added to the result
    layer. The default is to add but only if the result layer has an unknown
    geometry type.
"""
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.
function intersection(input::FeatureLayer, method::FeatureLayer,
                      result::FeatureLayer)
    result = GDAL.intersection(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to compute the intersection of the two layers"
end

"""
Union of two layers.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.
* `papszOptions`: NULL terminated list of options (may be NULL).
* `pfnProgress`: a GDALProgressFunc() compatible callback function for
    reporting progress or NULL.
* `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is:

* `SKIP_FAILURES=YES/NO. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO. Set it to YES to convert Polygons into
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string. Set a prefix for the field names that will be created
    from the fields of the method layer.
* `USE_PREPARED_GEOMETRIES=YES/NO. Set to NO to not use prepared geometries to
    pretest intersection of features of method layer with features of this layer
* `KEEP_LOWER_DIMENSION_GEOMETRIES=YES/NO. Set to NO to skip result features
    with lower dimension geometry that would otherwise be added to the result
    layer. The default is to add but only if the result layer has an unknown
    geometry type.
"""
function union(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer)
    result = GDAL.union(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to compute the union of the two layers"
end

"""
Symmetrical difference of two layers.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.
* `papszOptions`: NULL terminated list of options (may be NULL).
* `pfnProgress`: a GDALProgressFunc() compatible callback function for
    reporting progress or NULL.
* `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is :

* `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the method layer.
"""
function symdifference(input::FeatureLayer, method::FeatureLayer,
                       result::FeatureLayer)
    result = GDAL.symdifference(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to compute the sym difference of the two layers"
end

"""
Identify the features of this layer with the ones from the identity layer.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.
* `papszOptions`: NULL terminated list of options (may be NULL).
* `pfnProgress`: a GDALProgressFunc() compatible callback function for
    reporting progress or NULL.
* `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is :

* `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the method layer.
* `USE_PREPARED_GEOMETRIES=YES/NO`. Set to NO to not use prepared geometries to
    pretest intersection of features of method layer with features of this layer
* `KEEP_LOWER_DIMENSION_GEOMETRIES=YES/NO`. Set to NO to skip result features
    with lower dimension geometry that would otherwise be added to the result
    layer. The default is to add but only if the result layer has an unknown
    geometry type.
"""
function identity(input::FeatureLayer, method::FeatureLayer,
                  result::FeatureLayer)
    result = GDAL.identity(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to compute the identity of the two layers"
end

"""
Update this layer with features from the update layer.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.
* `papszOptions`: NULL terminated list of options (may be NULL).
* `pfnProgress`: a GDALProgressFunc() compatible callback function for
    reporting progress or NULL.
* `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is :

* `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the method layer.
"""
function update(input::FeatureLayer, method::FeatureLayer,
                result::FeatureLayer)
    result = GDAL.update(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to update the layer"
end

"""
Clip off areas that are not covered by the method layer.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.
* `papszOptions`: NULL terminated list of options (may be NULL).
* `pfnProgress`: a GDALProgressFunc() compatible callback function for
    reporting progress or NULL.
* `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is :

* `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the method layer.
"""
function clip(input::FeatureLayer, method::FeatureLayer,
              result::FeatureLayer)
    result = GDAL.clip(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to clip the input layer"
end

"""
Remove areas that are covered by the method layer.

### Parameters
* `input`: the input layer. Should not be NULL.
* `method`: the method layer. Should not be NULL.
* `result`: the layer where the features resulting from the operation
    are inserted. Should not be NULL. See the note about the schema.
* `papszOptions`: NULL terminated list of options (may be NULL).
* `pfnProgress`: a GDALProgressFunc() compatible callback function for
    reporting progress or NULL.
* `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

### Returns
an error code if there was an error or the execution was interrupted,
OGRERR_NONE otherwise.

### Additional Remarks
If the schema of the result is set by user and contains fields that have the
same name as a field in input and in method layer, then the attribute in the
result feature will get the value from the feature of the method layer.

For best performance use the minimum amount of features in the method layer and
copy it into a memory layer. This method relies on GEOS support. Do not use
unless the GEOS support is compiled in. The recognized list of options is :

* `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
    be inserted or a GEOS call failed.
* `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
    MultiPolygons, or LineStrings to MultiLineStrings.
* `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the input layer.
* `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
    from the fields of the method layer.
"""
function erase(input::FeatureLayer, method::FeatureLayer,
               result::FeatureLayer)
    result = GDAL.erase(input, method, result, C_NULL, C_NULL, C_NULL)
    @ogrerr result "Failed to remove areas covered by the method layer."
end
