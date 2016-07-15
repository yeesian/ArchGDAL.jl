"""
Create a new feature definition object to hold field definitions.

The OGRFeatureDefn maintains a reference count, but this starts at zero, and
should normally be incremented by the owner.
"""
unsafe_createfeaturedefn(name::AbstractString) = GDAL.fd_create(name)

"""
Increments the reference count by one.

The reference count is used keep track of the number of OGRFeature objects
referencing this definition.

### Returns
the updated reference count.
"""
reference(featuredefn::FeatureDefn) = GDAL.reference(featuredefn)

"Decrements the reference count by one, and returns the updated count."
dereference(featuredefn::FeatureDefn) = GDAL.dereference(featuredefn)

"Fetch the current reference count."
nreference(featuredefn::FeatureDefn) = GDAL.getreferencecount(featuredefn)

"Destroy a feature definition object and release all memory associated with it"
destroy(featuredefn::FeatureDefn) = GDAL.destroy(featuredefn)

"Drop a reference, and destroy if unreferenced."
release(featuredefn::FeatureDefn) = GDAL.release(featuredefn)

"Get name of the OGRFeatureDefn passed as an argument."
getname(featuredefn::FeatureDefn) = GDAL.getname(featuredefn)

"Fetch number of fields on the passed feature definition."
nfield(featuredefn::FeatureDefn) = GDAL.getfieldcount(featuredefn)

"""
Fetch field definition of the passed feature definition.

### Parameters
* `featuredefn` the feature definition to get the field definition from.
* `i`           the field to fetch, between `0` and `nfield(featuredefn)-1`.

### Returns
an handle to an internal field definition object or NULL if invalid index. This
object should not be modified or freed by the application.
"""
borrow_getfielddefn(featuredefn::FeatureDefn, i::Integer) =
    GDAL.getfielddefn(featuredefn, i)

"""
Find field by name.

### Returns
the field index, or -1 if no match found.
"""
getfieldindex(featuredefn::FeatureDefn, name::AbstractString) =
    GDAL.getfieldindex(featuredefn, name)

"""
Add a new field definition to the passed feature definition.

To add a new field definition to a layer definition, do not use this function
directly, but use OGR_L_CreateField() instead.

This function should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn. The OGRFieldDefn passed in is copied,
and remains the responsibility of the caller.
"""
addfielddefn(featuredefn::FeatureDefn, fielddefn::FieldDefn) =
    GDAL.addfielddefn(featuredefn, fielddefn)

"""
Delete an existing field definition.

To delete an existing field definition from a layer definition, do not use this
function directly, but use `OGR_L_DeleteField()` instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function deletefielddefn!(featuredefn::FeatureDefn, i::Integer)
    result = GDAL.deletefielddefn(featuredefn, i)
    @ogrerr result "Failed to delete field $i in the feature definition"
end

"""
Reorder the field definitions in the array of the feature definition.

To reorder the field definitions in a layer definition, do not use this function
directly, but use `OGR_L_ReorderFields()` instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.

### Parameters
* **featuredefn**: handle to the feature definition.
* **indices**: an array of `GetFieldCount()` elements which is a permutation of
    `[0, GetFieldCount()-1]`. `indices` is such that, for each field definition
    at position `i` after reordering, its position before reordering was 
    `indices[i]`.
"""
function reorderfielddefns!(featuredefn::FeatureDefn, indices::Vector{Cint})
    result = GDAL.reorderfielddefns(featuredefn, indices)
    @ogrerr result "Failed to delete field $i in the feature definition"
end
    

"""
Fetch the geometry base type of the passed feature definition.

For layers without any geometry field, this method returns `wkbNone`.

This returns the same result as `OGR_FD_GetGeomType(OGR_L_GetLayerDefn(hLayer))`
but for a few drivers, calling `OGR_L_GetGeomType()` directly can avoid lengthy
layer definition initialization.

For layers with multiple geometry fields, this method only returns the geometry
type of the first geometry column. For other columns, use
    `OGR_GFld_GetType(OGR_FD_GetGeomFieldDefn(OGR_L_GetLayerDefn(hLayer), i))`.
"""
getgeomtype(featuredefn::FeatureDefn) = GDAL.getgeomtype(featuredefn)

"""
Assign the base geometry type for the passed layer (same as the featuredefn).

All geometry objects using this type must be of the defined type or a derived
type. The default upon creation is `wkbUnknown` which allows for any geometry
type. The geometry type should generally not be changed after any OGRFeatures
have been created against this definition.
"""
setgeomtype!(featuredefn::FeatureDefn, etype::GDAL.OGRwkbGeometryType) =
    GDAL.setgeomtype(featuredefn, etype)

"Determine whether the geometry can be omitted when fetching features."
isgeomignored(featuredefn::FeatureDefn) = GDAL.isgeometryignored(featuredefn)

"Set whether the geometry can be omitted when fetching features."
setgeomignored!(featuredefn::FeatureDefn, ignore::Bool) =
    GDAL.setgeometryignored(featuredefn, ignore)

"Determine whether the style can be omitted when fetching features."
isstyleignored(featuredefn::FeatureDefn) =Bool(GDAL.isstyleignored(featuredefn))

"Set whether the style can be omitted when fetching features."
setstyleignored!(featuredefn, ignore::Bool) =
    GDAL.setstyleignored(featuredefn, ignore)

"Fetch number of geometry fields on the passed feature definition."
ngeomfield(featuredefn::FeatureDefn) = GDAL.getgeomfieldcount(featuredefn)

"""
Fetch geometry field definition of the passed feature definition.

### Parameters
* `i`  the geometry field to fetch, between `0` and `ngeomfield(featuredefn)-1`.

### Returns
an internal field definition object or `NULL` if invalid index. This object
should not be modified or freed by the application.
"""
borrow_getgeomfielddefn(featuredefn::FeatureDefn, i::Integer) =
    GDAL.getgeomfielddefn(featuredefn, i)

"""
Find geometry field by name.

The geometry field index of the first geometry field matching the passed field
name (case insensitively) is returned.

### Returns
the geometry field index, or -1 if no match found.
"""
getgeomfieldindex(featuredefn::FeatureDefn, name::AbstractString) =
    GDAL.getgeomfieldindex(featuredefn, name)

"""
Add a new field definition to the passed feature definition.

To add a new geometry field definition to a layer definition, do not use this
function directly, but use OGRLayer::CreateGeomField() instead.

This method does an internal copy of the passed geometry field definition,
unless bCopy is set to FALSE (in which case it takes ownership of the field
definition.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn. The OGRGeomFieldDefn passed in is
copied, and remains the responsibility of the caller.
"""
addgeomfielddefn!(featuredefn::FeatureDefn, geomfielddefn::GeomFieldDefn) =
    GDAL.addgeomfielddefn(featuredefn, geomfielddefn)

"""
Delete an existing geometry field definition.

To delete an existing field definition from a layer definition, do not use this
function directly, but use OGRLayer::DeleteGeomField() instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function deletegeomfielddefn!(featuredefn::FeatureDefn, i::Integer)
    result = GDAL.deletegeomfielddefn(featuredefn, i)
    if result != GDAL.OGRERR_NONE
        error("Failed to delete geometry field $i in the feature definition")
    end
end

"Test if the feature definition is identical to the other one."
issame(featuredefn1::FeatureDefn, featuredefn2::FeatureDefn) =
    Bool(GDAL.issame(featuredefn1, featuredefn2))

"""Returns the new feature object with null fields and no geometry

Note that the OGRFeature will increment the reference count of it's defining
OGRFeatureDefn. Destruction of the OGRFeatureDefn before destruction of all
OGRFeatures that depend on it is likely to result in a crash.

Starting with GDAL 2.1, returns NULL in case out of memory situation.
"""
function unsafe_createfeature(featuredefn::FeatureDefn)
    result = GDAL.f_create(featuredefn)
    (result == C_NULL) && error("out of memory when creating feature")
    result
end

"Fetch feature definition."
borrow_getfeaturedefn(feature::Feature) = GDAL.getdefnref(feature)
