"""
    unsafe_createfeaturedefn(name::AbstractString)

Create a new feature definition object to hold field definitions.

The `FeatureDefn` maintains a reference count, but this starts at zero, and
should normally be incremented by the owner.
"""
unsafe_createfeaturedefn(name::AbstractString)::FeatureDefn =
    FeatureDefn(GDAL.ogr_fd_create(name))

"""
    reference(featuredefn::FeatureDefn)

Increments the reference count in the FeatureDefn by one.

The count is used to track the number of `Feature`s referencing this definition.

### Returns
The updated reference count.
"""
reference(featuredefn::FeatureDefn)::Integer =
    GDAL.ogr_fd_reference(featuredefn.ptr)

"""
    dereference(featuredefn::FeatureDefn)

Decrements the reference count by one, and returns the updated count.
"""
dereference(featuredefn::FeatureDefn)::Integer =
    GDAL.ogr_fd_dereference(featuredefn.ptr)

"""
    nreference(featuredefn::AbstractFeatureDefn)

Fetch the current reference count.
"""
nreference(featuredefn::AbstractFeatureDefn)::Integer =
    GDAL.ogr_fd_getreferencecount(featuredefn.ptr)

"Destroy a feature definition object and release all memory associated with it"
function destroy(featuredefn::FeatureDefn)::Nothing
    GDAL.ogr_fd_destroy(featuredefn.ptr)
    featuredefn.ptr = C_NULL
    return nothing
end

"Destroy a feature definition view"
function destroy(featuredefn::IFeatureDefnView)::Nothing
    featuredefn.ptr = C_NULL
    return nothing
end

"""
    release(featuredefn::FeatureDefn)

Drop a reference, and destroy if unreferenced.
"""
function release(featuredefn::FeatureDefn)::Nothing
    GDAL.ogr_fd_release(featuredefn.ptr)
    return nothing
end

"""
    getname(featuredefn::AbstractFeatureDefn)

Get name of the OGRFeatureDefn passed as an argument.
"""
getname(featuredefn::AbstractFeatureDefn)::String =
    GDAL.ogr_fd_getname(featuredefn.ptr)

"""
    nfield(featuredefn::AbstractFeatureDefn)

Fetch number of fields on the passed feature definition.
"""
nfield(featuredefn::AbstractFeatureDefn)::Integer =
    GDAL.ogr_fd_getfieldcount(featuredefn.ptr)

"""
    getfielddefn(featuredefn::FeatureDefn, i::Integer)

Fetch field definition of the passed feature definition.

### Parameters
* `featuredefn`: the feature definition to get the field definition from.
* `i`:  index of the field to fetch, between `0` and `nfield(featuredefn)-1`.

### Returns
an handle to an internal field definition object or NULL if invalid index. This
object should not be modified or freed by the application.
"""
getfielddefn(featuredefn::FeatureDefn, i::Integer)::FieldDefn =
    FieldDefn(GDAL.ogr_fd_getfielddefn(featuredefn.ptr, i))

getfielddefn(featuredefn::IFeatureDefnView, i::Integer)::IFieldDefnView =
    IFieldDefnView(GDAL.ogr_fd_getfielddefn(featuredefn.ptr, i))

"""
    findfieldindex(featuredefn::AbstractFeatureDefn,
        name::Union{AbstractString, Symbol})

Find field by name.

### Returns
the field index, or -1 if no match found.

### Remarks
This uses the OGRFeatureDefn::GetFieldIndex() method.
"""
function findfieldindex(
    featuredefn::AbstractFeatureDefn,
    name::Union{AbstractString,Symbol},
)::Integer
    return GDAL.ogr_fd_getfieldindex(featuredefn.ptr, name)
end

"""
    addfielddefn!(featuredefn::FeatureDefn, fielddefn::FieldDefn)

Add a new field definition to the passed feature definition.

To add a new field definition to a layer definition, do not use this function
directly, but use OGR_L_CreateField() instead.

This function should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn. The OGRFieldDefn passed in is copied,
and remains the responsibility of the caller.
"""
function addfielddefn!(
    featuredefn::FeatureDefn,
    fielddefn::FieldDefn,
)::FeatureDefn
    GDAL.ogr_fd_addfielddefn(featuredefn.ptr, fielddefn.ptr)
    return featuredefn
end

"""
    deletefielddefn!(featuredefn::FeatureDefn, i::Integer)

Delete an existing field definition.

To delete an existing field definition from a layer definition, do not use this
function directly, but use `OGR_L_DeleteField()` instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function deletefielddefn!(featuredefn::FeatureDefn, i::Integer)::FeatureDefn
    result = GDAL.ogr_fd_deletefielddefn(featuredefn.ptr, i)
    @ogrerr result "Failed to delete field $i in the feature definition"
    return featuredefn
end

"""
    reorderfielddefns!(featuredefn::FeatureDefn, indices::Vector{Cint})

Reorder the field definitions in the array of the feature definition.

To reorder the field definitions in a layer definition, do not use this function
directly, but use `OGR_L_ReorderFields()` instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.

### Parameters
* **fd**: handle to the feature definition.
* **indices**: an array of `GetFieldCount()` elements which is a permutation of
    `[0, GetFieldCount()-1]`. `indices` is such that, for each field definition
    at position `i` after reordering, its position before reordering was
    `indices[i]`.
"""
function reorderfielddefns!(
    featuredefn::FeatureDefn,
    indices::Vector{Cint},
)::FeatureDefn
    result = GDAL.ogr_fd_reorderfielddefns(featuredefn.ptr, indices)
    @ogrerr result "Failed to reorder $indices in the feature definition"
    return featuredefn
end

"""
    getgeomtype(featuredefn::AbstractFeatureDefn)

Fetch the geometry base type of the passed feature definition.

For layers without any geometry field, this method returns `wkbNone`.

This returns the same result as `OGR_FD_GetGeomType(OGR_L_GetLayerDefn(hLayer))`
but for a few drivers, calling `OGR_L_GetGeomType()` directly can avoid lengthy
layer definition initialization.

For layers with multiple geometry fields, this method only returns the geometry
type of the first geometry column. For other columns, use
    `OGR_GFld_GetType(OGR_FD_GetGeomFieldDefn(OGR_L_GetLayerDefn(hLayer), i))`.
"""
getgeomtype(featuredefn::AbstractFeatureDefn)::OGRwkbGeometryType =
    GDAL.ogr_fd_getgeomtype(featuredefn.ptr)

"""
    setgeomtype!(featuredefn::FeatureDefn, etype::OGRwkbGeometryType)

Assign the base geometry type for the passed layer (same as the fd).

All geometry objects using this type must be of the defined type or a derived
type. The default upon creation is `wkbUnknown` which allows for any geometry
type. The geometry type should generally not be changed after any OGRFeatures
have been created against this definition.
"""
function setgeomtype!(
    featuredefn::FeatureDefn,
    etype::OGRwkbGeometryType,
)::FeatureDefn
    GDAL.ogr_fd_setgeomtype(featuredefn.ptr, etype)
    return featuredefn
end

"""
    isgeomignored(featuredefn::AbstractFeatureDefn)

Determine whether the geometry can be omitted when fetching features.
"""
isgeomignored(featuredefn::AbstractFeatureDefn)::Bool =
    Bool(GDAL.ogr_fd_isgeometryignored(featuredefn.ptr))

"""
    setgeomignored!(featuredefn::FeatureDefn, ignore::Bool)

Set whether the geometry can be omitted when fetching features.
"""
function setgeomignored!(featuredefn::FeatureDefn, ignore::Bool)::FeatureDefn
    GDAL.ogr_fd_setgeometryignored(featuredefn.ptr, ignore)
    return featuredefn
end

"""
    isstyleignored(featuredefn::AbstractFeatureDefn)

Determine whether the style can be omitted when fetching features.
"""
isstyleignored(featuredefn::AbstractFeatureDefn)::Bool =
    Bool(GDAL.ogr_fd_isstyleignored(featuredefn.ptr))

"""
    setstyleignored!(featuredefn::FeatureDefn, ignore::Bool)

Set whether the style can be omitted when fetching features.
"""
function setstyleignored!(featuredefn::FeatureDefn, ignore::Bool)::FeatureDefn
    GDAL.ogr_fd_setstyleignored(featuredefn.ptr, ignore)
    return featuredefn
end

"""
    ngeom(featuredefn::AbstractFeatureDefn)

Fetch number of geometry fields on the passed feature definition.
"""
ngeom(featuredefn::AbstractFeatureDefn)::Integer =
    GDAL.ogr_fd_getgeomfieldcount(featuredefn.ptr)

"""
    getgeomdefn(featuredefn::FeatureDefn, i::Integer = 0)

Fetch geometry field definition of the passed feature definition.

### Parameters
* `i`  geometry field to fetch, between `0` (default) and `ngeomfield(fd)-1`.

### Returns
an internal field definition object or `NULL` if invalid index. This object
should not be modified or freed by the application.
"""
getgeomdefn(featuredefn::FeatureDefn, i::Integer = 0)::GeomFieldDefn =
    GeomFieldDefn(GDAL.ogr_fd_getgeomfielddefn(featuredefn.ptr, i))

getgeomdefn(featuredefn::IFeatureDefnView, i::Integer = 0)::IGeomFieldDefnView =
    IGeomFieldDefnView(GDAL.ogr_fd_getgeomfielddefn(featuredefn.ptr, i))

"""
    findgeomindex(featuredefn::AbstractFeatureDefn, name::AbstractString = "")

Find geometry field by name.

The geometry field index of the first geometry field matching the passed field
name (case insensitively) is returned.

### Returns
the geometry field index, or -1 if no match found.
"""
function findgeomindex(
    featuredefn::AbstractFeatureDefn,
    name::AbstractString = "",
)::Integer
    return GDAL.ogr_fd_getgeomfieldindex(featuredefn.ptr, name)
end

"""
    addgeomdefn!(featuredefn::FeatureDefn, geomfielddefn::AbstractGeomFieldDefn)

Add a new field definition to the passed feature definition.

To add a new geometry field definition to a layer definition, do not use this
function directly, but use OGRLayer::CreateGeomField() instead.

This method does an internal copy of the passed geometry field definition,
unless bCopy is set to `false` (in which case it takes ownership of the field
definition.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function addgeomdefn!(
    featuredefn::FeatureDefn,
    geomfielddefn::AbstractGeomFieldDefn,
)::FeatureDefn
    # `geomfielddefn` is copied, and remains the responsibility of the caller.
    GDAL.ogr_fd_addgeomfielddefn(featuredefn.ptr, geomfielddefn.ptr)
    return featuredefn
end

"""
    deletegeomdefn!(featuredefn::FeatureDefn, i::Integer)

Delete an existing geometry field definition.

To delete an existing field definition from a layer definition, do not use this
function directly, but use OGRLayer::DeleteGeomField() instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function deletegeomdefn!(featuredefn::FeatureDefn, i::Integer)::FeatureDefn
    result = GDAL.ogr_fd_deletegeomfielddefn(featuredefn.ptr, i)
    @ogrerr result "Failed to delete geom field $i in the feature definition"
    return featuredefn
end

"""
    issame(featuredefn1::AbstractFeatureDefn, featuredefn2::AbstractFeatureDefn)

Test if the feature definition is identical to the other one.
"""
function issame(
    featuredefn1::AbstractFeatureDefn,
    featuredefn2::AbstractFeatureDefn,
)::Bool
    return Bool(GDAL.ogr_fd_issame(featuredefn1.ptr, featuredefn2.ptr))
end

"""
    unsafe_createfeature(featuredefn::AbstractFeatureDefn)

Returns the new feature object with null fields and no geometry

Note that the OGRFeature will increment the reference count of it's defining
OGRFeatureDefn. Destruction of the OGRFeatureDefn before destruction of all
OGRFeatures that depend on it is likely to result in a crash.

Starting with GDAL 2.1, returns NULL in case out of memory situation.
"""
function unsafe_createfeature(featuredefn::AbstractFeatureDefn)::Feature
    return Feature(GDAL.ogr_f_create(featuredefn.ptr))
end

"""
    getfeaturedefn(feature::AbstractFeature)

Fetch feature definition.
"""
getfeaturedefn(feature::AbstractFeature)::IFeatureDefnView =
    IFeatureDefnView(GDAL.ogr_f_getdefnref(feature.ptr))
