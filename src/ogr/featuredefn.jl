"""
Create a new feature definition object to hold field definitions.

The OGRFeatureDefn maintains a reference count, but this starts at zero, and
should normally be incremented by the owner.
"""
unsafe_createfeaturedefn(name::AbstractString) =
    FeatureDefn(GDAL.fd_create(name))

"""
Increments the reference count by one.

The reference count is used keep track of the number of OGRFeature objects
referencing this definition.

### Returns
the updated reference count.
"""
reference(fd::FeatureDefn) = GDAL.reference(fd.ptr)

"Decrements the reference count by one, and returns the updated count."
dereference(fd::FeatureDefn) = GDAL.dereference(fd.ptr)

"Fetch the current reference count."
nreference(fd::FeatureDefn) = GDAL.getreferencecount(fd.ptr)

"Destroy a feature definition object and release all memory associated with it"
destroy(fd::FeatureDefn) = (GDAL.destroy(fd.ptr); fd.ptr = C_NULL)

"Drop a reference, and destroy if unreferenced."
release(fd::FeatureDefn) = GDAL.release(fd.ptr)

"Get name of the OGRFeatureDefn passed as an argument."
getname(fd::FeatureDefn) = GDAL.getname(fd.ptr)

"Fetch number of fields on the passed feature definition."
nfield(fd::FeatureDefn) = GDAL.getfieldcount(fd.ptr)

"""
Fetch field definition of the passed feature definition.

### Parameters
* `fd` the feature definition to get the field definition from.
* `i`           the field to fetch, between `0` and `nfield(fd)-1`.

### Returns
an handle to an internal field definition object or NULL if invalid index. This
object should not be modified or freed by the application.
"""
getfielddefn(fd::FeatureDefn, i::Integer) =
    FieldDefn(GDAL.getfielddefn(fd.ptr, i))

"""
Find field by name.

### Returns
the field index, or -1 if no match found.
"""
getfieldindex(fd::FeatureDefn, name::AbstractString) =
    GDAL.getfieldindex(fd.ptr, name)

"""
Add a new field definition to the passed feature definition.

To add a new field definition to a layer definition, do not use this function
directly, but use OGR_L_CreateField() instead.

This function should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn. The OGRFieldDefn passed in is copied,
and remains the responsibility of the caller.
"""
addfielddefn!(fd::FeatureDefn, fielddefn::FieldDefn) =
    (GDAL.addfielddefn(fd.ptr, fielddefn.ptr); fd)

"""
Delete an existing field definition.

To delete an existing field definition from a layer definition, do not use this
function directly, but use `OGR_L_DeleteField()` instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function deletefielddefn!(fd::FeatureDefn, i::Integer)
    result = GDAL.deletefielddefn(fd.ptr, i)
    @ogrerr result "Failed to delete field $i in the feature definition"
    fd
end

"""
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
function reorderfielddefns!(fd::FeatureDefn, indices::Vector{Cint})
    result = GDAL.reorderfielddefns(fd.ptr, indices)
    @ogrerr result "Failed to reorder $indices in the feature definition"
    fd
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
getgeomtype(fd::FeatureDefn) = GDAL.getgeomtype(fd.ptr)

"""
Assign the base geometry type for the passed layer (same as the fd).

All geometry objects using this type must be of the defined type or a derived
type. The default upon creation is `wkbUnknown` which allows for any geometry
type. The geometry type should generally not be changed after any OGRFeatures
have been created against this definition.
"""
function setgeomtype!(fd::FeatureDefn, etype::OGRwkbGeometryType)
    GDAL.setgeomtype(fd.ptr, etype)
    fd
end

"Determine whether the geometry can be omitted when fetching features."
isgeomignored(fd::FeatureDefn) = Bool(GDAL.isgeometryignored(fd.ptr))

"Set whether the geometry can be omitted when fetching features."
setgeomignored!(fd::FeatureDefn, ignore::Bool) =
    (GDAL.setgeometryignored(fd.ptr, ignore); fd)

"Determine whether the style can be omitted when fetching features."
isstyleignored(fd::FeatureDefn) = Bool(GDAL.isstyleignored(fd.ptr))

"Set whether the style can be omitted when fetching features."
setstyleignored!(fd::FeatureDefn, ignore::Bool) =
    (GDAL.setstyleignored(fd.ptr, ignore); fd)

"Fetch number of geometry fields on the passed feature definition."
ngeom(fd::FeatureDefn) = GDAL.getgeomfieldcount(fd.ptr)

"""
Fetch geometry field definition of the passed feature definition.

### Parameters
* `i`  geometry field to fetch, between `0` (default) and `ngeomfield(fd)-1`.

### Returns
an internal field definition object or `NULL` if invalid index. This object
should not be modified or freed by the application.
"""
getgeomdefn(fd::FeatureDefn, i::Integer = 0) =
    GeomFieldDefn(GDAL.getgeomfielddefn(fd.ptr, i))

"""
Find geometry field by name.

The geometry field index of the first geometry field matching the passed field
name (case insensitively) is returned.

### Returns
the geometry field index, or -1 if no match found.
"""
getgeomindex(fd::FeatureDefn, name::AbstractString = "") =
    GDAL.getgeomfieldindex(fd.ptr, name)

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
addgeomdefn!(fd::FeatureDefn, geomfielddefn::GeomFieldDefn) =
    (GDAL.addgeomfielddefn(fd.ptr, geomfielddefn.ptr); fd)

"""
Delete an existing geometry field definition.

To delete an existing field definition from a layer definition, do not use this
function directly, but use OGRLayer::DeleteGeomField() instead.

This method should only be called while there are no OGRFeature objects in
existence based on this OGRFeatureDefn.
"""
function deletegeomdefn!(fd::FeatureDefn, i::Integer)
    result = GDAL.deletegeomfielddefn(fd.ptr, i)
    @ogrerr result "Failed to delete geom field $i in the feature definition"
    fd
end

"Test if the feature definition is identical to the other one."
issame(fd1::FeatureDefn, fd2::FeatureDefn) = Bool(GDAL.issame(fd1.ptr, fd2.ptr))

"""Returns the new feature object with null fields and no geometry

Note that the OGRFeature will increment the reference count of it's defining
OGRFeatureDefn. Destruction of the OGRFeatureDefn before destruction of all
OGRFeatures that depend on it is likely to result in a crash.

Starting with GDAL 2.1, returns NULL in case out of memory situation.
"""
function unsafe_createfeature(fd::FeatureDefn)
    Feature(GDALFeature(GDAL.f_create(fd.ptr)))
end

"Fetch feature definition."
getfeaturedefn(feature::Feature) = FeatureDefn(GDAL.getdefnref(feature.ptr))
