"""
Create a new field definition.

By default, fields have no width, precision, are nullable and not ignored.
"""
unsafe_createfielddefn(name::AbstractString, etype::OGRFieldType) =
    FieldDefn(GDAL.ogr_fld_create(name, etype))

"Destroy a field definition."
function destroy(fielddefn::FieldDefn)
    GDAL.ogr_fld_destroy(fielddefn.ptr)
    fielddefn.ptr = C_NULL
    return fielddefn
end

function destroy(fielddefn::IFieldDefnView)
    fielddefn.ptr = C_NULL
    return fielddefn
end

"Set the name of this field."
function setname!(fielddefn::FieldDefn, name::AbstractString)
    GDAL.ogr_fld_setname(fielddefn.ptr, name)
    return fielddefn
end

"Fetch the name of this field."
getname(fielddefn::AbstractFieldDefn) = GDAL.ogr_fld_getnameref(fielddefn.ptr)

"Fetch the type of this field."
gettype(fielddefn::AbstractFieldDefn) = GDAL.ogr_fld_gettype(fielddefn.ptr)

"Set the type of this field."
function settype!(fielddefn::FieldDefn, etype::OGRFieldType)
    GDAL.ogr_fld_settype(fielddefn.ptr, etype)
    return fielddefn
end

"""
Fetch subtype of this field.

### Parameters
* `fielddefn`: handle to the field definition to get subtype from.

### Returns
field subtype.
"""
getsubtype(fielddefn::AbstractFieldDefn) =
    GDAL.ogr_fld_getsubtype(fielddefn.ptr)

"""
Set the subtype of this field.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.

### Parameters
* `fielddefn`: handle to the field definition to set type to.
* `subtype`: the new field subtype.
"""
function setsubtype!(fielddefn::FieldDefn, subtype::OGRFieldSubType)
    GDAL.ogr_fld_setsubtype(fielddefn.ptr, subtype)
    return fielddefn
end

"""
Get the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
getjustify(fielddefn::AbstractFieldDefn) =
    GDAL.ogr_fld_getjustify(fielddefn.ptr)

"""
Set the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
function setjustify!(fielddefn::FieldDefn, ejustify::OGRJustification)
    GDAL.ogr_fld_setjustify(fielddefn.ptr, ejustify)
    return fielddefn
end

"""Get the formatting width for this field.

### Returns
the width, zero means no specified width.
"""
getwidth(fielddefn::AbstractFieldDefn) = GDAL.ogr_fld_getwidth(fielddefn.ptr)

"""
Set the formatting width for this field in characters.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.
"""
function setwidth!(fielddefn::FieldDefn, width::Integer)
    GDAL.ogr_fld_setwidth(fielddefn.ptr, width)
    return fielddefn
end

"""
Get the formatting precision for this field.

This should normally be zero for fields of types other than OFTReal.
"""
getprecision(fielddefn::AbstractFieldDefn) =
    GDAL.ogr_fld_getprecision(fielddefn.ptr)

"""
Set the formatting precision for this field in characters.

This should normally be zero for fields of types other than OFTReal.
"""
function setprecision!(fielddefn::FieldDefn, precision::Integer)
    GDAL.ogr_fld_setprecision(fielddefn.ptr, precision)
    return fielddefn
end

"""
Set defining parameters for a field in one call.

### Parameters
* `fielddefn`:  the field definition to set to.
* `name`:       the new name to assign.
* `etype`:      the new type (one of the OFT values like OFTInteger).
* `nwidth`:     the preferred formatting width. 0 (default) indicates undefined.
* `nprecision`: number of decimals for formatting. 0 (default) for undefined.
* `justify`:    the formatting justification ([OJUndefined], OJLeft or OJRight)
"""
function setparams!(
        fielddefn::FieldDefn,
        name::AbstractString,
        etype::OGRFieldType;
        nwidth::Integer             = 0,
        nprecision::Integer         = 0,
        justify::OGRJustification   = GDAL.OJUndefined
    )
    GDAL.ogr_fld_set(fielddefn.ptr, name, etype, nwidth, nprecision, justify)
    return fielddefn
end

"Return whether this field should be omitted when fetching features."
isignored(fielddefn::AbstractFieldDefn) =
    Bool(GDAL.ogr_fld_isignored(fielddefn.ptr))

"Set whether this field should be omitted when fetching features."
function setignored!(fielddefn::FieldDefn, ignore::Bool)
    GDAL.ogr_fld_setignored(fielddefn.ptr, ignore)
    return fielddefn
end

"""
Return whether this field can receive null values.

By default, fields are nullable.

Even if this method returns `false` (i.e not-nullable field), it doesn't mean that
OGRFeature::IsFieldSet() will necessary return `true`, as fields can be temporary
unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.
"""
isnullable(fielddefn::AbstractFieldDefn) =
    Bool(GDAL.ogr_fld_isnullable(fielddefn.ptr))

"""
Set whether this field can receive null values.

By default, fields are nullable, so this method is generally called with `false`
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_FIELDS driver metadata item.
"""
function setnullable!(fielddefn::FieldDefn, nullable::Bool)
    GDAL.ogr_fld_setnullable(fielddefn.ptr, nullable)
    return fielddefn
end

"Get default field value"
function getdefault(fielddefn::AbstractFieldDefn)
    result = @gdal(OGR_Fld_GetDefault::Cstring, fielddefn.ptr::GDALFieldDefn)
    if result == C_NULL
        return ""
    else
        return unsafe_string(result)
    end
end

"""
Set default field value.

The default field value is taken into account by drivers (generally those with
a SQL interface) that support it at field creation time. OGR will generally not
automatically set the default field value to null fields by itself when calling
OGRFeature::CreateFeature() / OGRFeature::SetFeature(), but will let the
low-level layers to do the job. So retrieving the feature from the layer is
recommended.

The accepted values are NULL, a numeric value, a literal value enclosed between
single quote characters (and inner single quote characters escaped by repetition
of the single quote character), CURRENT_TIMESTAMP, CURRENT_TIME, CURRENT_DATE or
a driver specific expression (that might be ignored by other drivers). For a
datetime literal value, format should be 'YYYY/MM/DD HH:MM:SS[.sss]'
(considered as UTC time).

Drivers that support writing DEFAULT clauses will advertize the
GDAL_DCAP_DEFAULT_FIELDS driver metadata item.
"""
function setdefault!(fielddefn::AbstractFieldDefn, default)
    GDAL.ogr_fld_setdefault(fielddefn.ptr, default)
    return fielddefn
end

"""
Returns whether the default value is driver specific.

Driver specific default values are those that are not NULL, a numeric value, a
literal value enclosed between single quote characters, CURRENT_TIMESTAMP,
CURRENT_TIME, CURRENT_DATE or datetime literal value.
"""
isdefaultdriverspecific(fielddefn::AbstractFieldDefn) =
    Bool(GDAL.ogr_fld_isdefaultdriverspecific(fielddefn.ptr))

"Create a new field geometry definition."
unsafe_creategeomdefn(name::AbstractString, etype::OGRwkbGeometryType) =
    GeomFieldDefn(GDAL.ogr_gfld_create(name, etype))

"Destroy a geometry field definition."
function destroy(geomdefn::GeomFieldDefn)
    GDAL.ogr_gfld_destroy(geomdefn.ptr)
    geomdefn.ptr = C_NULL
    geomdefn.spatialref = SpatialRef()
    return geomdefn
end

"Destroy a geometry field definition."
function destroy(geomdefn::IGeomFieldDefnView)
    geomdefn.ptr = C_NULL
    return geomdefn
end

"Set the name of this field."
function setname!(geomdefn::GeomFieldDefn, name::AbstractString)
    GDAL.ogr_gfld_setname(geomdefn.ptr, name)
    return geomdefn
end

"Fetch name of this field."
getname(geomdefn::AbstractGeomFieldDefn) =
    GDAL.ogr_gfld_getnameref(geomdefn.ptr)

"Fetch geometry type of this field."
gettype(geomdefn::AbstractGeomFieldDefn) = GDAL.ogr_gfld_gettype(geomdefn.ptr)

"Set the geometry type of this field."
function settype!(geomdefn::GeomFieldDefn, etype::OGRwkbGeometryType)
    GDAL.ogr_gfld_settype(geomdefn.ptr, etype)
    return geomdefn
end

"Returns a clone of the spatial reference system for this field. May be NULL."
function getspatialref(geomdefn::AbstractGeomFieldDefn)
    result = GDAL.ogr_gfld_getspatialref(geomdefn.ptr)
    if result == C_NULL
        return ISpatialRef()
    else
        # NOTE(yeesian): we make a clone here so that the spatialref does not
        # depend on the GeomFieldDefn/Dataset.
        return ISpatialRef(GDAL.osrclone(result))
    end
end

function unsafe_getspatialref(geomdefn::AbstractGeomFieldDefn)
    result = GDAL.ogr_gfld_getspatialref(geomdefn.ptr)
    if result == C_NULL
        return SpatialRef()
    else
        # NOTE(yeesian): we make a clone here so that the spatialref does not
        # depend on the GeomFieldDefn/Dataset.
        return SpatialRef(GDAL.osrclone(result))
    end
end

"""
Set the spatial reference of this field.

This function drops the reference of the previously set SRS object and acquires
a new reference on the passed object (if non-NULL).
"""
function setspatialref!(
        geomdefn::GeomFieldDefn,
        spatialref::AbstractSpatialRef
    )
    clonespatialref = clone(spatialref)
    GDAL.ogr_gfld_setspatialref(geomdefn.ptr, clonespatialref.ptr)
    geomdefn.spatialref = clonespatialref
    return geomdefn
end

"""
Return whether this geometry field can receive null values.

By default, fields are nullable.

Even if this method returns `false` (i.e not-nullable field), it doesn't mean that
OGRFeature::IsFieldSet() will necessary return `true`, as fields can be temporary
unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.

Note that not-nullable geometry fields might also contain 'empty' geometries.
"""
isnullable(geomdefn::AbstractGeomFieldDefn) =
    Bool(GDAL.ogr_gfld_isnullable(geomdefn.ptr))

"""
Set whether this geometry field can receive null values.

By default, fields are nullable, so this method is generally called with `false`
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_GEOMFIELDS driver metadata item.
"""
function setnullable!(geomdefn::GeomFieldDefn, nullable::Bool)
    GDAL.ogr_gfld_setnullable(geomdefn.ptr, nullable)
    return geomdefn
end

"Return whether this field should be omitted when fetching features."
isignored(geomdefn::AbstractGeomFieldDefn) =
    Bool(GDAL.ogr_gfld_isignored(geomdefn.ptr))

"Set whether this field should be omitted when fetching features."
function setignored!(geomdefn::GeomFieldDefn, ignore::Bool)
    GDAL.ogr_gfld_setignored(geomdefn.ptr, ignore)
    return geomdefn
end
