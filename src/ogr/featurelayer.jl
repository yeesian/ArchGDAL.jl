
function destroy(layer::AbstractFeatureLayer)
    layer.ptr = GDALFeatureLayer(C_NULL)
    return layer
end

function destroy(layer::IFeatureLayer)
    layer.ptr = GDALFeatureLayer(C_NULL)
    layer.ownedby = Dataset()
    layer.spatialref = SpatialRef()
    return layer
end

"""
This function attempts to create a new layer on the dataset with the indicated
`name`, `spatialref`, and geometry type.

### Parameters
* `name`: the name for the new layer. This should ideally not match any
    existing layer on the datasource. Defaults to an empty string.

### Keyword Arguments
* `dataset`: the dataset
* `geom`: the geometry type for the layer. Use wkbUnknown (default) if
    there are no constraints on the types geometry to be written.
* `spatialref`: the coordinate system to use for the new layer.
* `options`: a StringList of name=value (driver-specific) options.
"""
function createlayer(;
        name::AbstractString            = "",
        dataset::AbstractDataset        = create(getdriver("Memory")),
        geom::OGRwkbGeometryType        = GDAL.wkbUnknown,
        spatialref::AbstractSpatialRef  = SpatialRef(),
        options                         = StringList(C_NULL)
    )
    return IFeatureLayer(
        GDAL.datasetcreatelayer(dataset.ptr, name, spatialref.ptr, geom,
            options),
        ownedby = dataset,
        spatialref = spatialref
    )
end

function unsafe_createlayer(;
        name::AbstractString            = "",
        dataset::AbstractDataset        = create(getdriver("Memory")),
        geom::OGRwkbGeometryType        = GDAL.wkbUnknown,
        spatialref::AbstractSpatialRef  = SpatialRef(),
        options                         = StringList(C_NULL)
    )
    return FeatureLayer(
        GDAL.datasetcreatelayer(dataset.ptr, name, spatialref.ptr, geom,
            options)
    )
end

"""
Copy an existing layer.

This method creates a new layer, duplicate the field definitions of the source
layer, and then duplicates each feature of the source layer.

### Parameters
* `layer`: source layer to be copied.

### Keyword Arguments
* `dataset`: the dataset handle. (Creates a new dataset in memory by default.)
* `name`: the name of the layer to create on the dataset.
* `options`: a StringList of name=value (driver-specific) options.
"""
function copy(
        layer::AbstractFeatureLayer;
        dataset::AbstractDataset = create(getdriver("Memory")),
        name::AbstractString = "copy($(getname(layer)))",
        options = StringList(C_NULL)
    )
    return IFeatureLayer(
        GDAL.datasetcopylayer(dataset.ptr, layer.ptr, name, options),
        ownedby = dataset
    )
end

function unsafe_copy(
        layer::AbstractFeatureLayer;
        dataset::AbstractDataset = create(getdriver("Memory")),
        name::AbstractString = "copy($(getname(layer)))",
        options = StringList(C_NULL)
    )
    FeatureLayer(GDAL.datasetcopylayer(dataset.ptr, layer.ptr, name, options))
end

"Return the layer name."
getname(layer::AbstractFeatureLayer) = GDAL.getname(layer.ptr)

"Return the layer geometry type."
getgeomtype(layer::AbstractFeatureLayer) = GDAL.getgeomtype(layer.ptr)

"Returns the current spatial filter for this layer."
function getspatialfilter(layer::AbstractFeatureLayer)
    result = GDALGeometry(GDAL.C.OGR_L_GetSpatialFilter(Ptr{Cvoid}(layer.ptr)))
    if result == C_NULL
        return IGeometry(result)
    else
        # NOTE(yeesian): we make a clone here so that the geometry does not
        # depend on the FeatureLayer.
        return IGeometry(GDALGeometry(GDAL.clone(result)))
    end
end

"Returns a clone of the spatial reference system for this layer."
function getspatialref(layer::AbstractFeatureLayer)
    result = GDAL.getspatialref(layer.ptr)
    if result == C_NULL
        return ISpatialRef()
    else
        # NOTE(yeesian): we make a clone here so that the spatialref does not
        # depend on the FeatureLayer/Dataset.
        return ISpatialRef(GDAL.clone(result))
    end
end

function unsafe_getspatialref(layer::AbstractFeatureLayer)
    result = GDAL.getspatialref(layer.ptr)
    if result == C_NULL
        return SpatialRef()
    else
        # NOTE(yeesian): we make a clone here so that the spatialref does not
        # depend on the FeatureLayer/Dataset.
        return SpatialRef(GDAL.clone(result))
    end
end

"""
Set a new spatial filter for the layer, using the geom.

This method set the geometry to be used as a spatial filter when fetching
features via the `nextfeature()` method. Only features that geometrically
intersect the filter geometry will be returned.

### Parameters
* `layer`  handle to the layer on which to set the spatial filter.
* `geom`   handle to the geometry to use as a filtering region. NULL may be
           passed indicating that the current spatial filter should be cleared,
           but no new one instituted.

### Remarks
Currently this test may be inaccurately implemented, but it is guaranteed
that all features whose envelope (as returned by OGRGeometry::getEnvelope())
overlaps the envelope of the spatial filter will be returned. This can result
in more shapes being returned that should strictly be the case.

For the time being the passed filter geometry should be in the same SRS as the
geometry field definition it corresponds to (as returned by
`GetLayerDefn()->OGRFeatureDefn::GetGeomFieldDefn(i)->GetSpatialRef()`).
In the future this may be generalized.

Note that only the last spatial filter set is applied, even if several
successive calls are done with different iGeomField values.
"""
function setspatialfilter!(layer::AbstractFeatureLayer, geom::Geometry)
    # This method makes an internal copy of `geom`. The input `geom` remains
    # the responsibility of the caller, and may be safely destroyed.
    GDAL.setspatialfilter(layer.ptr, geom.ptr)
    return layer
end

function clearspatialfilter!(layer::AbstractFeatureLayer)
    GDAL.setspatialfilter(layer.ptr, GDALGeometry(C_NULL))
    return layer
end

"""
Set a new rectangular spatial filter for the layer.

This method set rectangle to be used as a spatial filter when fetching features
via the `nextfeature()` method. Only features that geometrically intersect the
given rectangle will be returned.

The x/y values should be in the same coordinate system as the layer as a whole
(as returned by OGRLayer::GetSpatialRef()). Internally this method is normally
implemented as creating a 5 vertex closed rectangular polygon and passing it to
OGRLayer::SetSpatialFilter(). It exists as a convenience.

The only way to clear a spatial filter set with this method is to call
`OGRLayer::SetSpatialFilter(NULL)`.
"""
function setspatialfilter!(
        layer::AbstractFeatureLayer,
        xmin::Real,
        ymin::Real,
        xmax::Real,
        ymax::Real
    )
    GDAL.setspatialfilterrect(layer.ptr, xmin, ymin, xmax, ymax)
    return layer
end

"""
Set a new spatial filter.

This method set the geometry to be used as a spatial filter when fetching
features via the `nextfeature()` method. Only features that geometrically
intersect the filter geometry will be returned.

### Parameters
* `layer`: the layer on which to set the spatial filter.
* `i`: index of the geometry field on which the spatial filter operates.
* `geom`: the geometry to use as a filtering region. NULL may be passed
    indicating that the current spatial filter should be cleared, but
    no new one instituted.

### Remarks
Currently this test is may be inaccurately implemented, but it is guaranteed
that all features who's envelope (as returned by OGRGeometry::getEnvelope())
overlaps the envelope of the spatial filter will be returned. This can result
in more shapes being returned that should strictly be the case.

For the time being the passed filter geometry should be in the same SRS as the
layer (as returned by OGRLayer::GetSpatialRef()). In the future this may be
generalized.
"""
function setspatialfilter!(
        layer::AbstractFeatureLayer,
        i::Integer,
        geom::AbstractGeometry
    )
    # This method makes an internal copy of `geom`. The input `geom` remains
    # the responsibility of the caller, and may be safely destroyed.
    GDAL.setspatialfilterex(layer.ptr, i, geom.ptr)
    return layer
end

function clearspatialfilter!(layer::AbstractFeatureLayer, i::Integer)
    GDAL.setspatialfilterex(layer.ptr, i, GDALGeometry(C_NULL))
    return layer
end

"""
Set a new rectangular spatial filter.

### Parameters
* `layer`: the feature layer on which to set the spatial filter.
* `i`: index of the geometry field on which the spatial filter operates.
* `xmin`: the minimum X coordinate for the rectangular region.
* `ymin`: the minimum Y coordinate for the rectangular region.
* `xmax`: the maximum X coordinate for the rectangular region.
* `ymax`: the maximum Y coordinate for the rectangular region.
"""
function setspatialfilter!(
        layer::AbstractFeatureLayer,
        i::Integer,
        xmin::Real,
        ymin::Real,
        xmax::Real,
        ymax::Real
    )
    GDAL.setspatialfilterrectex(layer.ptr, i, xmin, ymin, xmax, ymax)
    return layer
end

"""
Set a new attribute query.

This method sets the attribute query string to be used when fetching features
via the `nextfeature()` method. Only features for which the query evaluates as
`true` will be returned.

### Parameters
* `layer`: handle to the layer on which attribute query will be executed.
* `query`: query in restricted SQL WHERE format.

### Remarks
The query string should be in the format of an SQL WHERE clause. For instance
`"population > 1000000 and population < 5000000"` where population is an
attribute in the layer. The query format is normally a restricted form of
SQL WHERE clause as described in the "WHERE" section of the OGR SQL tutorial.
In some cases (RDBMS backed drivers) the native capabilities of the database may
be used to interpret the WHERE clause in which case the capabilities will be
broader than those of OGR SQL.

Note that installing a query string will generally result in resetting the
current reading position (ala `resetreading!()`).
"""
function setattributefilter!(layer::AbstractFeatureLayer, query::AbstractString)
    result = GDAL.setattributefilter(layer.ptr, query)
    @ogrerr result """Failed to set a new attribute query. The query expression
    might be in error."""
    return layer
end

function clearattributefilter!(layer::AbstractFeatureLayer)
    result = GDAL.setattributefilter(layer.ptr, C_NULL)
    @ogrerr result "OGRErr $result: Failed to clear attribute query."
    return layer
end

"""
Reset feature reading to start on the first feature.

This affects `nextfeature()`.
"""
function resetreading!(layer::AbstractFeatureLayer)
    GDAL.resetreading(layer.ptr)
    return layer
end

"""
Fetch the next available feature from this layer.

### Parameters
* `layer`: the feature layer to be read from.

### Remarks
This method implements sequential access to the features of a layer. The
`resetreading!()` method can be used to start at the beginning again. Only
features matching the current spatial filter (set with `setspatialfilter!()`)
will be returned.

The returned feature becomes the responsibility of the caller to delete with
`destroy()`. It is critical that all features associated with a `FeatureLayer`
(more specifically a `FeatureDefn`) be destroyed before that layer is destroyed.

Features returned by `nextfeature()` may or may not be affected by concurrent
modifications depending on drivers. A guaranteed way of seeing modifications in
effect is to call `resetreading!()` on layers where `nextfeature()` has been
called, before reading again. Structural changes in layers (field addition,
deletion, ...) when a read is in progress may or may not be possible depending
on drivers. If a transaction is committed/aborted, the current sequential
reading may or may not be valid after that operation and a call to
`resetreading!()` might be needed.
"""
function unsafe_nextfeature(layer::AbstractFeatureLayer)
    return Feature(GDALFeature(GDAL.getnextfeature(layer.ptr)))
end

"""
Move read cursor to the `i`-th feature in the current resultset.

This method allows positioning of a layer such that the `nextfeature()` call
will read the requested feature, where `i` is an absolute index into the
current result set. So, setting it to `3` would mean the next feature read with
`nextfeature()` would have been the fourth feature to have been read if
sequential reading took place from the beginning of the layer, including
accounting for spatial and attribute filters.

### Parameters
* `layer`: handle to the layer
* `i`: the index indicating how many steps into the result set to seek.

### Remarks
Only in rare circumstances is `setnextbyindex!()` efficiently implemented. In
all other cases the default implementation which calls `resetreading!()` and
then calls `nextfeature()` `i` times is used. To determine if fast seeking is
available on the layer, use the `testcapability()` method with a value of
`OLCFastSetNextByIndex`.
"""
function setnextbyindex!(layer::AbstractFeatureLayer, i::Integer)
    result = GDAL.setnextbyindex(layer.ptr, i)
    @ogrerr result "Failed to move the cursor to index $i"
    return layer
end

"""
Return a feature (now owned by the caller) by its identifier or NULL on failure.

### Parameters
* `layer`: the feature layer to be read from.
* `i`: the index of the feature to be returned.

### Remarks
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

The returned feature is now owned by the caller, and should be freed with `destroy()`.
"""
unsafe_getfeature(layer::AbstractFeatureLayer, i::Integer) =
    Feature(GDALFeature(GDAL.getfeature(layer.ptr, i)))

"""
Rewrite an existing feature.

This function will write a feature to the layer, based on the feature id within
the OGRFeature.

### Remarks
Use OGR_L_TestCapability(OLCRandomWrite) to establish if this layer supports
random access writing via OGR_L_SetFeature().
"""
function write!(layer::AbstractFeatureLayer, feature::Feature)
    result = GDAL.setfeature(layer.ptr, feature.ptr)
    # OGRERR_NONE if the operation works, otherwise an appropriate error code
    # (e.g OGRERR_NON_EXISTING_FEATURE if the feature does not exist).
    @ogrerr result "Failed to set feature."
    return layer
end

"""
Write a new feature within a layer.

### Remarks
The passed feature is written to the layer as a new feature, rather than
overwriting an existing one. If the feature has a feature id other than
OGRNullFID, then the native implementation may use that as the feature id of
the new feature, but not necessarily. Upon successful return the passed feature
will have been updated with the new feature id.
"""
function push!(layer::AbstractFeatureLayer, feature::Feature)
    result = GDAL.createfeature(layer.ptr, feature.ptr)
    @ogrerr result "Failed to create and write feature in layer."
    return layer
end

"""
Create and returns a new feature based on the layer definition.

The newly feature is owned by the layer (it will increase the number of features
the layer by one), but the feature has not been written to the layer yet.
"""
unsafe_createfeature(layer::AbstractFeatureLayer) =
    unsafe_createfeature(getlayerdefn(layer))

"""
Delete feature with fid `i` from layer.

### Remarks
The feature with the indicated feature id is deleted from the layer if supported
by the driver. Most drivers do not support feature deletion, and will return
OGRERR_UNSUPPORTED_OPERATION. The OGR_L_TestCapability() function may be called
with OLCDeleteFeature to check if the driver supports feature deletion.
"""
function deletefeature!(layer::AbstractFeatureLayer, i::Integer)
    result = GDAL.deletefeature(layer.ptr, i)
    # OGRERR_NONE if the operation works, otherwise an appropriate error code
    # (e.g OGRERR_NON_EXISTING_FEATURE if the feature does not exist).
    @ogrerr result "OGRErr $result: Failed to delete feature $i"
    return layer
end

"""
Returns a view of the schema information for this layer.

### Remarks
The `featuredefn` is owned by the `layer` and should not be modified.
"""
getlayerdefn(layer::AbstractFeatureLayer) =
    IFeatureDefnView(GDAL.getlayerdefn(layer.ptr))

"""
Find the index of the field in a layer, or -1 if the field doesn't exist.

If `exactmatch` is set to `false` and the field doesn't exists in the given form
the driver might apply some changes to make it match, like those it might do if
the layer was created (eg. like `LAUNDER` in the OCI driver).
"""
function findfieldindex(
        layer::AbstractFeatureLayer,
        field::AbstractString,
        exactmatch::Bool
    )
    GDAL.findfieldindex(layer.ptr, field, exactmatch)
end

"""
Fetch the feature count in this layer, or `-1` if the count is not known.

### Parameters
* `layer`: handle to the layer that owned the features.
* `force`: flag indicating whether the count should be computed even if it is
    expensive. (`false` by default.)
"""
nfeature(layer::AbstractFeatureLayer, force::Bool = false) =
    GDAL.getfeaturecount(layer.ptr, force)

"Fetch number of geometry fields on the feature layer."
ngeom(layer::AbstractFeatureLayer) = ngeom(getlayerdefn(layer))

"Fetch number of fields on the feature layer."
nfield(layer::AbstractFeatureLayer) = nfield(getlayerdefn(layer))

"""
Fetch the extent of this layer.

Returns the extent (MBR) of the data in the layer. If `force` is `false`, and it
would be expensive to establish the extent then OGRERR_FAILURE will be returned
indicating that the extent isn't know. If `force` is `true` then some
implementations will actually scan the entire layer once to compute the MBR of
all the features in the layer.

### Parameters
* `layer`: handle to the layer from which to get extent.
* `i`:     (optional) the index of the geometry field to compute the extent.
* `force`: Flag indicating whether the extent should be computed even if it is
            expensive.

### Additional Remarks
Depending on the drivers, the returned extent may or may not take the spatial
filter into account. So it is safer to call GetExtent() without setting a
spatial filter.

Layers without any geometry may return OGRERR_FAILURE just indicating that no
meaningful extents could be collected.

Note that some implementations of this method may alter the read cursor of the
layer.
"""
function envelope(layer::AbstractFeatureLayer, i::Integer, force::Bool = false)
    envelope = Ref{GDAL.OGREnvelope}(GDAL.OGREnvelope(0, 0, 0, 0))
    result = GDAL.getextentex(layer.ptr, i, envelope, force)
    @ogrerr result "Extent not known"
    envelope[]
end

function envelope(layer::AbstractFeatureLayer, force::Bool = false)
    envelope = Ref{GDAL.OGREnvelope}(GDAL.OGREnvelope(0, 0, 0, 0))
    result = GDAL.getextent(layer.ptr, envelope, force)
    @ogrerr result "Extent not known"
    envelope[]
end

"""
Test if this layer supported the named capability.

### Parameters
* `capability`  the name of the capability to test.

### Returns
`true` if the layer has the requested capability, `false` otherwise. It will
return `false` for any unrecognized capabilities.

### Additional Remarks
The capability codes that can be tested are represented as strings, but
`#defined` constants exists to ensure correct spelling. Specific layer types may
implement class specific capabilities, but this can't generally be discovered by
the caller.

* `OLCRandomRead` / \"RandomRead\": TRUE if the GetFeature() method is
    implemented in an optimized way for this layer, as opposed to the default
    implementation using `resetreading!()` and `nextfeature()` to find the
    requested feature id.

* `OLCSequentialWrite` / \"SequentialWrite\": TRUE if the CreateFeature() method
    works for this layer. Note this means that this particular layer is
    writable. The same OGRLayer class may returned FALSE for other layer
    instances that are effectively read-only.

* `OLCRandomWrite` / \"RandomWrite\": TRUE if the SetFeature() method is
    operational on this layer. Note this means that this particular layer is
    writable. The same OGRLayer class may returned FALSE for other layer
    instances that are effectively read-only.

* `OLCFastSpatialFilter` / \"FastSpatialFilter\": TRUE if this layer implements
    spatial filtering efficiently. Layers that effectively read all features,
    and test them with the OGRFeature intersection methods should return FALSE.
    This can be used as a clue by the application whether it should build and
    maintain its own spatial index for features in this layer.

* `OLCFastFeatureCount` / \"FastFeatureCount\": TRUE if this layer can return a
    feature count (via GetFeatureCount()) efficiently. i.e. without counting the
    features. In some cases this will return TRUE until a spatial filter is
    installed after which it will return FALSE.

* `OLCFastGetExtent` / \"FastGetExtent\": TRUE if this layer can return its data
    extent (via GetExtent()) efficiently, i.e. without scanning all the
    features. In some cases this will return TRUE until a spatial filter is
    installed after which it will return FALSE.

* `OLCFastSetNextByIndex` / \"FastSetNextByIndex\": TRUE if this layer can
    perform the SetNextByIndex() call efficiently, otherwise FALSE.

* `OLCCreateField` / \"CreateField\": TRUE if this layer can create new fields
    on the current layer using CreateField(), otherwise FALSE.

* `OLCCreateGeomField` / \"CreateGeomField\": (GDAL >= 1.11) TRUE if this layer
    can create new geometry fields on the current layer using CreateGeomField(),
    otherwise FALSE.

* `OLCDeleteField` / \"DeleteField\": TRUE if this layer can delete existing
    fields on the current layer using DeleteField(), otherwise FALSE.

* `OLCReorderFields` / \"ReorderFields\": TRUE if this layer can reorder
    existing fields on the current layer using ReorderField() or
    ReorderFields(), otherwise FALSE.

* `OLCAlterFieldDefn` / \"AlterFieldDefn\": TRUE if this layer can alter the
    definition of an existing field on the current layer using AlterFieldDefn(),
    otherwise FALSE.

* `OLCDeleteFeature` / \"DeleteFeature\": TRUE if the DeleteFeature() method is
    supported on this layer, otherwise FALSE.

* `OLCStringsAsUTF8` / \"StringsAsUTF8\": TRUE if values of OFTString fields are
    assured to be in UTF-8 format. If FALSE the encoding of fields is uncertain,
    though it might still be UTF-8.

* `OLCTransactions` / \"Transactions\": TRUE if the StartTransaction(),
    CommitTransaction() and RollbackTransaction() methods work in a meaningful
    way, otherwise FALSE.

* `OLCIgnoreFields` / \"IgnoreFields\": TRUE if fields, geometry and style will
    be omitted when fetching features as set by SetIgnoredFields() method.

* `OLCCurveGeometries` / \"CurveGeometries\": TRUE if this layer supports
    writing curve geometries or may return such geometries. (GDAL 2.0).
"""
testcapability(layer::AbstractFeatureLayer, capability::AbstractString) =
    Bool(GDAL.testcapability(layer.ptr, capability))

function listcapability(
        layer::AbstractFeatureLayer,
        capabilities = (GDAL.OLCRandomRead,
                        GDAL.OLCSequentialWrite,
                        GDAL.OLCRandomWrite,
                        GDAL.OLCFastSpatialFilter,
                        GDAL.OLCFastFeatureCount,
                        GDAL.OLCFastGetExtent,
                        GDAL.OLCCreateField,
                        GDAL.OLCDeleteField,
                        GDAL.OLCReorderFields,
                        GDAL.OLCAlterFieldDefn,
                        GDAL.OLCTransactions,
                        GDAL.OLCDeleteFeature,
                        GDAL.OLCFastSetNextByIndex,
                        GDAL.OLCStringsAsUTF8,
                        GDAL.OLCIgnoreFields,
                        GDAL.OLCCreateGeomField,
                        GDAL.OLCCurveGeometries,
                        GDAL.OLCMeasuredGeometries)
    )
    Dict{String, Bool}([
        c => testcapability(layer,c) for c in capabilities
    ])
end

# TODO use syntax below once v0.4 support is dropped (not in Compat.jl)
# listcapability(layer::AbstractFeatureLayer) = Dict(
#     c => testcapability(layer,c) for c in
#     (GDAL.OLCRandomRead,        GDAL.OLCSequentialWrite, GDAL.OLCRandomWrite,
#      GDAL.OLCFastSpatialFilter, GDAL.OLCFastFeatureCount,GDAL.OLCFastGetExtent,
#      GDAL.OLCCreateField,       GDAL.OLCDeleteField,     GDAL.OLCReorderFields,
#      GDAL.OLCAlterFieldDefn,    GDAL.OLCTransactions,    GDAL.OLCDeleteFeature,
#      GDAL.OLCFastSetNextByIndex,GDAL.OLCStringsAsUTF8,   GDAL.OLCIgnoreFields,
#      GDAL.OLCCreateGeomField,   GDAL.OLCCurveGeometries,
#      GDAL.OLCMeasuredGeometries)
# )

"""
Create a new field on a layer.

### Parameters
* `layer`:  the layer to write the field definition.
* `field`:  the field definition to write to disk.
* `approx`: If `true`, the field may be created in a slightly different form
            depending on the limitations of the format driver.

### Remarks
You must use this to create new fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the new field.
Applications should never modify the OGRFeatureDefn used by a layer directly.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the `GDAL.OLCCreateField` capability. Some drivers may only
support this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

Drivers may or may not support not-null constraints. If they support creating
fields with not-null constraints, this is generally before creating any feature
to the layer.
"""
function addfielddefn!(
        layer::AbstractFeatureLayer,
        field::AbstractFieldDefn,
        approx::Bool = false
    )
    result = GDAL.createfield(layer.ptr, field.ptr, approx)
    @ogrerr result "Failed to create new field"
    return layer
end

"""
Create a new geometry field on a layer.

### Parameters
* `layer`:  the layer to write the field definition.
* `field`:  the geometry field definition to write to disk.
* `approx`: If TRUE, the field may be created in a slightly different form
            depending on the limitations of the format driver.

### Remarks
You must use this to create new geometry fields on a real layer. Internally the
OGRFeatureDefn for the layer will be updated to reflect the new field.
Applications should never modify the OGRFeatureDefn used by a layer directly.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the `GDAL.OLCCreateGeomField` capability. Some drivers may only
support this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

Drivers may or may not support not-null constraints. If they support creating
fields with not-null constraints, this is generally before creating any feature
to the layer.
"""
function addgeomdefn!(
        layer::AbstractFeatureLayer,
        field::AbstractGeomFieldDefn,
        approx::Bool = false
    )
    result = GDAL.creategeomfield(layer.ptr, field.ptr, approx)
    # OGRERR_NONE on success.
    @ogrerr result "Failed to create new geometry field"
    return layer
end

# """
# Delete the field at index `i` on a layer.

# You must use this to delete existing fields on a real layer. Internally the
# OGRFeatureDefn for the layer will be updated to reflect the deleted field.
# Applications should never modify the OGRFeatureDefn used by a layer directly.

# This function should not be called while there are feature objects in existence
# that were obtained or created with the previous layer definition.

# Not all drivers support this function. You can query a layer to check if it
# supports it with the OLCDeleteField capability. Some drivers may only support
# this method while there are still no features in the layer. When it is
# supported, the existing features of the backing file/database should be updated
# accordingly.

# ### Parameters
# * `layer`: handle to the layer.
# * `i`: index of the field to delete.
# """
# function deletefield!(layer::AbstractFeatureLayer, i::Integer)
#     result = GDAL.deletefield(layer.ptr, i)
#     @ogrerr result "Failed to delete field $i"
#     layer
# end

# # function deletegeomdefn!(layer::AbstractFeatureLayer, i::Integer)
# #     error("OGR_L_DeleteGeomField() is not implemented in GDAL yet.")
# # end

# """
# Reorder all the fields of a layer.

# You must use this to reorder existing fields on a real layer. Internally the
# OGRFeatureDefn for the layer will be updated to reflect the reordering of the
# fields. Applications should never modify the OGRFeatureDefn used by a layer
# directly.

# This method should not be called while there are feature objects in existence
# that were obtained or created with the previous layer definition.

# panMap is such that,for each field definition at position i after reordering,
# its position before reordering was panMap[i].

# For example, let suppose the fields were "0","1","2","3","4" initially.
# ReorderFields([0,2,3,1,4]) will reorder them as "0","2","3","1","4".

# Not all drivers support this method. You can query a layer to check if it
# supports it with the OLCReorderFields capability. Some drivers may only support
# this method while there are still no features in the layer. When it is
# supported, the existing features of the backing file/database should be updated
# accordingly.

# ### Parameters
# * `layer`: handle to the layer.
# * `indices`: an array of GetLayerDefn()->OGRFeatureDefn::GetFieldCount()
#             elements which is a permutation of
#                 `[0, GetLayerDefn()->OGRFeatureDefn::GetFieldCount()-1]`.
# """
# function reorderfields!(layer::AbstractFeatureLayer, indices::Vector{Cint})
#     result = GDAL.reorderfields(layer.ptr, indices)
#     @ogrerr result "Failed to reorder the fields of layer according to $indices"
#     layer
# end

# """
# Reorder an existing field on a layer.

# This method is a convenience wrapper of ReorderFields() dedicated to move a
# single field. It is a non-virtual method, so drivers should implement
# ReorderFields() instead.

# You must use this to reorder existing fields on a real layer. Internally the
# OGRFeatureDefn for the layer will be updated to reflect the reordering of the
# fields. Applications should never modify the OGRFeatureDefn used by a layer
# directly.

# This method should not be called while there are feature objects in existence
# that were obtained or created with the previous layer definition.

# The field definition that was at initial position iOldFieldPos will be moved at
# position iNewFieldPos, and elements between will be shuffled accordingly.

# For example, let suppose the fields were "0","1","2","3","4" initially.
# ReorderField(1, 3) will reorder them as "0","2","3","1","4".

# Not all drivers support this method. You can query a layer to check if it
# supports it with the OLCReorderFields capability. Some drivers may only support
# this method while there are still no features in the layer. When it is
# supported, the existing features of the backing file/database should be updated
# accordingly.

# ### Parameters
# * `layer`: handle to the layer.
# * `oldpos`: previous position of the field to move. Must be in the range
#             [0,GetFieldCount()-1].
# * `newpos`: new position of the field to move. Must be in the range
#             [0,GetFieldCount()-1].
# """
# function reorderfield!(
#         layer::AbstractFeatureLayer,
#         oldpos::Integer,
#         newpos::Integer
#     )
#     result = GDAL.reorderfield(layer.ptr, oldpos, newpos)
#     @ogrerr result "Failed to reorder field from $oldpos to $newpos."
#     layer
# end

# """
# Alter the definition of an existing field on a layer.

# You must use this to alter the definition of an existing field of a real layer.
# Internally the OGRFeatureDefn for the layer will be updated to reflect the
# altered field. Applications should never modify the OGRFeatureDefn used by a
# layer directly.

# This method should not be called while there are feature objects in existence
# that were obtained or created with the previous layer definition.

# Not all drivers support this method. You can query a layer to check if it
# supports it with the OLCAlterFieldDefn capability. Some drivers may only
# support this method while there are still no features in the layer. When it is
# supported, the existing features of the backing file/database should be updated
# accordingly. Some drivers might also not support all update flags.

# ### Parameters
# * `layer`:        handle to the layer.
# * `i`:            index of the field whose definition must be altered.
# * `newfielddefn`: new field definition
# * `flags`: combination of ALTER_NAME_FLAG, ALTER_TYPE_FLAG,
#             ALTER_WIDTH_PRECISION_FLAG, ALTER_NULLABLE_FLAG and
#             ALTER_DEFAULT_FLAG to indicate which of the name and/or type and/or
#             width and precision fields and/or nullability from the new field
#             definition must be taken into account.
# """
# function alterfielddefn!(
#         layer::AbstractFeatureLayer,
#         i::Integer,
#         newfielddefn::FieldDefn,
#         flags::UInt8
#     )
#     result = OGR.alterfielddefn(layer.ptr, i, newfielddefn.ptr, flags)
#     @ogrerr result "Failed to alter fielddefn of field $i."
#     layer
# end

# "For datasources which support transactions, creates a transaction."
# function starttransaction(layer::AbstractFeatureLayer)
#     result = GDAL.starttransaction(layer.ptr)
#     @ogrerr result "Failed to start transaction."
#     layer
# end

# "For datasources which support transactions, commits a transaction."
# function committransaction(layer::AbstractFeatureLayer)
#     result = GDAL.committransaction(layer.ptr)
#     @ogrerr result "Failed to commit transaction."
#     layer
# end

# """
# For datasources which support transactions, RollbackTransaction will roll back
# a datasource to its state before the start of the current transaction.
# """
# function rollbacktransaction(layer::AbstractFeatureLayer)
#     result = GDAL.rollbacktransaction(layer.ptr)
#     @ogrerr result "Failed to rollback transaction."
#     layer
# end

"""
Increment layer reference count.

### Returns
The reference count after incrementing.
"""
reference(layer::AbstractFeatureLayer) = GDAL.reference(layer.ptr)

"""
Decrement layer reference count.

### Returns
The reference count after decrementing.
"""
dereference(layer::AbstractFeatureLayer) = GDAL.dereference(layer.ptr)

"The current reference count for the layer object itself."
nreference(layer::AbstractFeatureLayer) = GDAL.getrefcount(layer.ptr)

# """
# Flush pending changes to disk.

# This call is intended to force the layer to flush any pending writes to disk,
# and leave the disk file in a consistent state. It would not normally have any
# effect on read-only datasources.

# Some layers do not implement this method, and will still return OGRERR_NONE.
# The default implementation just returns OGRERR_NONE. An error is only returned
# if an error occurs while attempting to flush to disk.

# In any event, you should always close any opened datasource with
# DestroyDataSource() that will ensure all data is correctly flushed.

# ### Returns
# OGRERR_NONE if no error occurs (even if nothing is done) or an error code.
# """
# function synctodisk!(layer::AbstractFeatureLayer)
#     result = GDAL.synctodisk(layer.ptr)
#     @ogrerr result "Failed to flush pending changes to disk"
#     layer.ptr = GDALFeatureLayer(C_NULL)
# end

# """
# Return the total number of features read.

# Warning: not all drivers seem to update this count properly.
# """
# getfeaturesread(layer::AbstractFeatureLayer) = GDAL.getfeaturesread(layer.ptr)

"The name of the FID column in the database, or \"\" if not supported."
getfidcolname(layer::AbstractFeatureLayer) = GDAL.getfidcolumn(layer.ptr)

"The name of the geometry column in the database, or \"\" if not supported."
getgeomcolname(layer::AbstractFeatureLayer) = GDAL.getgeometrycolumn(layer.ptr)

"""
Set which fields can be omitted when retrieving features from the layer.

### Parameters
* `fieldnames`: an array of field names terminated by NULL item. If NULL is
passed, the ignored list is cleared.

### Remarks
If the driver supports this functionality (testable using `OLCIgnoreFields`
capability), it will not fetch the specified fields in subsequent calls to
`GetFeature()`/`nextfeature()` and thus save some processing time and/or
bandwidth.

Besides field names of the layers, the following special fields can be passed:
`"OGR_GEOMETRY"` to ignore geometry and `"OGR_STYLE"` to ignore layer style.

By default, no fields are ignored.
"""
function setignoredfields!(layer::AbstractFeatureLayer, fieldnames)
    result = GDAL.setignoredfields(layer.ptr, fieldnames)
    # OGRERR_NONE if all field names have been resolved (even if the driver
    # does not support this method)
    @ogrerr result "Failed to set ignored fields $fieldnames."
    return layer
end


# """
# Intersection of two layers.

# The result layer contains features whose geometries represent areas that are
# common between features in the input layer and in the method layer. The features
# in the result layer have attributes from both input and method layers. The
# schema of the result layer can be set by the user or, if it is empty, is
# initialized to contain all fields in the input and method layers.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `output`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.

# ### Keyword Arguments
# * `options`: NULL terminated list of options (may be NULL).
# * `progressfunc`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `progressdata`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is:

# * `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# * `USE_PREPARED_GEOMETRIES=YES/NO`. Set to NO to not use prepared geometries to
#     pretest intersection of features of method layer with features of this layer
# * `PRETEST_CONTAINMENT=YES/NO`. Set to YES to pretest the containment of
#     features of method layer within the features of this layer. This will speed
#     up the method significantly in some cases. Requires that the prepared
#     geometries are in effect.
# * `KEEP_LOWER_DIMENSION_GEOMETRIES=YES/NO`. Set to NO to skip result features
#     with lower dimension geometry that would otherwise be added to the result
#     layer. The default is to add but only if the result layer has an unknown
#     geometry type.
# """
# function intersection(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options                 = StringList(C_NULL),
#         progressfunc::Function  = GDAL.C.GDALDummyProgress,
#         progressdata            = C_NULL
#     )
#     result = GDAL.intersection(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to compute the intersection of the two layers"
#     output
# end

# """
# Union of two layers.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `result`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is:

# * `SKIP_FAILURES=YES/NO. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# * `USE_PREPARED_GEOMETRIES=YES/NO. Set to NO to not use prepared geometries to
#     pretest intersection of features of method layer with features of this layer
# * `KEEP_LOWER_DIMENSION_GEOMETRIES=YES/NO. Set to NO to skip result features
#     with lower dimension geometry that would otherwise be added to the result
#     layer. The default is to add but only if the result layer has an unknown
#     geometry type.
# """
# function union(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options                 = StringList(C_NULL),
#         progressfunc::Function  = GDAL.C.GDALDummyProgress,
#         progressdata            = C_NULL
#     )
#     result = GDAL.union(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to compute the union of the two layers"
#     output
# end

# """
# Symmetrical difference of two layers.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `result`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is :

# * `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# """
# function symdifference(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options                 = StringList(C_NULL),
#         progressfunc::Function  = GDAL.C.GDALDummyProgress,
#         progressdata            = C_NULL
#     )
#     result = GDAL.symdifference(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to compute the sym difference of the two layers"
#     output
# end

# """
# Identify the features of this layer with the ones from the identity layer.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `result`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is :

# * `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# * `USE_PREPARED_GEOMETRIES=YES/NO`. Set to NO to not use prepared geometries to
#     pretest intersection of features of method layer with features of this layer
# * `KEEP_LOWER_DIMENSION_GEOMETRIES=YES/NO`. Set to NO to skip result features
#     with lower dimension geometry that would otherwise be added to the result
#     layer. The default is to add but only if the result layer has an unknown
#     geometry type.
# """
# function identity(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options                 = StringList(C_NULL),
#         progressfunc::Function  = GDAL.C.GDALDummyProgress,
#         progressdata            = C_NULL
#     )
#     result = GDAL.identity(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to compute the identity of the two layers"
#     output
# end

# """
# Update this layer with features from the update layer.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `result`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is :

# * `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# """
# function update(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options                 = StringList(C_NULL),
#         progressfunc::Function  = GDAL.C.GDALDummyProgress,
#         progressdata            = C_NULL
#     )
#     result = GDAL.update(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to update the layer"
#     output
# end

# """
# Clip off areas that are not covered by the method layer.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `result`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is :

# * `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# """
# function clip(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options                 = StringList(C_NULL),
#         progressfunc::Function  = GDAL.C.GDALDummyProgress,
#         progressdata            = C_NULL
#     )
#     result = GDAL.clip(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to clip the input layer"
#     output
# end

# """
# Remove areas that are covered by the method layer.

# ### Parameters
# * `input`: the input layer. Should not be NULL.
# * `method`: the method layer. Should not be NULL.
# * `result`: the layer where the features resulting from the operation
#     are inserted. Should not be NULL. See the note about the schema.
# * `papszOptions`: NULL terminated list of options (may be NULL).
# * `pfnProgress`: a GDALProgressFunc() compatible callback function for
#     reporting progress or NULL.
# * `pProgressArg`: argument to be passed to pfnProgress. May be NULL.

# ### Returns
# an error code if there was an error or the execution was interrupted,
# OGRERR_NONE otherwise.

# ### Additional Remarks
# If the schema of the result is set by user and contains fields that have the
# same name as a field in input and in method layer, then the attribute in the
# result feature will get the value from the feature of the method layer.

# For best performance use the minimum amount of features in the method layer and
# copy it into a memory layer. This method relies on GEOS support. Do not use
# unless the GEOS support is compiled in. The recognized list of options is :

# * `SKIP_FAILURES=YES/NO`. Set it to YES to go on, even when a feature could not
#     be inserted or a GEOS call failed.
# * `PROMOTE_TO_MULTI=YES/NO`. Set it to YES to convert Polygons into
#     MultiPolygons, or LineStrings to MultiLineStrings.
# * `INPUT_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the input layer.
# * `METHOD_PREFIX=string`. Set a prefix for the field names that will be created
#     from the fields of the method layer.
# """
# function erase(
#         input::AbstractFeatureLayer,
#         method::AbstractFeatureLayer,
#         output::AbstractFeatureLayer;
#         options = StringList(C_NULL),
#         progressfunc::Function = GDAL.C.GDALDummyProgress,
#         progressdata = C_NULL
#     )
#     result = GDAL.erase(
#         input.ptr,
#         method.ptr,
#         output.ptr,
#         options,
#         @cplprogress(progressfunc),
#         progressdata
#     )
#     @ogrerr result "Failed to remove areas covered by the method layer."
#     output
# end
