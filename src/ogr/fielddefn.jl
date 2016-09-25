"""
Create a new field definition.

By default, fields have no width, precision, are nullable and not ignored.
"""
unsafe_createfielddefn(name::AbstractString, etype::OGRFieldType) =
    FieldDefn(GDAL.fld_create(name, GDAL.OGRFieldType(etype)))

"Destroy a field definition."
destroy(fd::FieldDefn) = (GDAL.destroy(fd.ptr); fd.ptr = C_NULL)

"Set the name of this field."
setname!(fielddefn::FieldDefn, name::AbstractString) =
    (GDAL.setname(fielddefn.ptr, name); fielddefn)

"Fetch the name of this field."
getname(fielddefn::FieldDefn) = GDAL.getnameref(fielddefn.ptr)

"Fetch the type of this field."
gettype(fielddefn::FieldDefn) = OGRFieldType(GDAL.gettype(fielddefn.ptr))

"Set the type of this field."
settype!(fielddefn::FieldDefn, etype::OGRFieldType) =
    (GDAL.settype(fielddefn.ptr, GDAL.OGRFieldType(etype)); fielddefn)

"""
Fetch subtype of this field.

### Parameters
* `fielddefn`: handle to the field definition to get subtype from.

### Returns
field subtype.
"""
getsubtype(fielddefn::FieldDefn) =
    OGRFieldSubType(GDAL.getsubtype(fielddefn.ptr))

"""
Set the subtype of this field.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.

### Parameters
* `fielddefn`: handle to the field definition to set type to.
* `subtype`: the new field subtype.
"""
setsubtype!(fielddefn::FieldDefn, subtype::OGRFieldSubType) =
    (GDAL.setsubtype(fielddefn.ptr, GDAL.OGRFieldSubType(subtype)); fielddefn)

"""
Get the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
getjustify(fielddefn::FieldDefn) =
    OGRJustification(GDAL.getjustify(fielddefn.ptr))

"""
Set the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
setjustify!(fielddefn::FieldDefn, ejustify::OGRJustification) =
    (GDAL.setjustify(fielddefn.ptr, GDAL.OGRJustification(ejustify)); fielddefn)

"""Get the formatting width for this field.

### Returns
the width, zero means no specified width.
"""
getwidth(fielddefn::FieldDefn) = GDAL.getwidth(fielddefn.ptr)

"""
Set the formatting width for this field in characters.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.
"""
setwidth!(fielddefn::FieldDefn, width::Integer) =
    (GDAL.setwidth(fielddefn.ptr, width); fielddefn)

"""
Get the formatting precision for this field.

This should normally be zero for fields of types other than OFTReal.
"""
getprecision(fielddefn::FieldDefn) = GDAL.getprecision(fielddefn.ptr)

"""
Set the formatting precision for this field in characters.

This should normally be zero for fields of types other than OFTReal.
"""
setprecision!(fielddefn::FieldDefn, precision::Integer) =
    (GDAL.setprecision(fielddefn.ptr, precision); fielddefn)

"""
Set defining parameters for a field in one call.

### Parameters
* `fielddefn`:  the field definition to set to.
* `name`:       the new name to assign.
* `etype`:      the new type (one of the OFT values like OFTInteger).
* `nwidth`:     the preferred formatting width. 0 (default) indicates undefined.
* `nprecision`: number of decimals for formatting. 0 (default) for undefined.
                indicating undefined.
* `justify`:    the formatting justification ([OJUndefined], OJLeft or OJRight)
"""
function setparams!(
        fielddefn::FieldDefn,
        name::AbstractString,
        etype::OGRFieldType;
        nwidth::Integer             = 0,
        nprecision::Integer         = 0,
        justify::OGRJustification   = OJUndefined
    )
    GDAL.set(fielddefn.ptr,
        name,
        GDAL.OGRFieldType(etype),
        nwidth,
        nprecision,
        GDAL.OGRJustification(justify)
    )
    fielddefn
end

"Return whether this field should be omitted when fetching features."
isignored(fielddefn::FieldDefn) = Bool(GDAL.isignored(fielddefn.ptr))

"Set whether this field should be omitted when fetching features."
setignored!(fielddefn::FieldDefn, ignore::Bool) =
    (GDAL.setignored(fielddefn.ptr, ignore); fielddefn)

"""
Return whether this field can receive null values.

By default, fields are nullable.

Even if this method returns FALSE (i.e not-nullable field), it doesn't mean that
OGRFeature::IsFieldSet() will necessary return TRUE, as fields can be temporary
unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.
"""
isnullable(fielddefn::FieldDefn) = Bool(GDAL.isnullable(fielddefn.ptr))

"""
Set whether this field can receive null values.

By default, fields are nullable, so this method is generally called with FALSE
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_FIELDS driver metadata item.
"""
setnullable!(fielddefn::FieldDefn, nullable::Bool) =
    (GDAL.setnullable(fielddefn.ptr, nullable); fielddefn)

"Get default field value"
function getdefault(fielddefn::FieldDefn)
    result = @gdal(OGR_Fld_GetDefault::Ptr{UInt8}, fielddefn.ptr::GDALFieldDefn)
    return result == Ptr{UInt8}(C_NULL) ? "" : unsafe_string(result)
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
setdefault!(fielddefn::FieldDefn, default) =
    (GDAL.setdefault(fielddefn.ptr, default); fielddefn)

"""
Returns whether the default value is driver specific.

Driver specific default values are those that are not NULL, a numeric value, a
literal value enclosed between single quote characters, CURRENT_TIMESTAMP,
CURRENT_TIME, CURRENT_DATE or datetime literal value.
"""
isdefaultdriverspecific(fielddefn::FieldDefn) =
    Bool(GDAL.isdefaultdriverspecific(fielddefn.ptr))

"Create a new field geometry definition."
unsafe_creategeomfielddefn(name::AbstractString, etype::OGRwkbGeometryType) =
    GeomFieldDefn(GDAL.gfld_create(name, GDAL.OGRwkbGeometryType(etype)))

"Destroy a geometry field definition."
function destroy(gfd::GeomFieldDefn)
    @gdal(OGR_GFld_Destroy::Void, gfd.ptr::GDALGeomFieldDefn)
    gfd.ptr = C_NULL
end

"Set the name of this field."
setname!(gfd::GeomFieldDefn, name::AbstractString) =
    (GDAL.setname(gfd.ptr, name); gfd)

"Fetch name of this field."
getname(gfd::GeomFieldDefn) = GDAL.getnameref(gfd.ptr)

"Fetch geometry type of this field."
gettype(gfd::GeomFieldDefn) = OGRwkbGeometryType(GDAL.gettype(gfd.ptr))

"Set the geometry type of this field."
function settype!(gfd::GeomFieldDefn, etype::OGRwkbGeometryType)
    @gdal(OGR_GFld_SetType::Void,
        gfd.ptr::GDALGeomFieldDefn,
        etype::GDAL.OGRwkbGeometryType
    )
    gfd
end

"Fetch spatial reference system of this field. May return NULL"
getspatialref(gfd::GeomFieldDefn) =
    SpatialRef(@gdal(OGR_GFld_GetSpatialRef::GDALSpatialRef,
        gfd.ptr::GDALGeomFieldDefn
    ))

"""
Set the spatial reference of this field.

This function drops the reference of the previously set SRS object and acquires
a new reference on the passed object (if non-NULL).
"""
setspatialref!(gfd::GeomFieldDefn, spatialref::SpatialRef) =
    (GDAL.setspatialref(gfd.ptr, spatialref); gfd)

"""
Return whether this geometry field can receive null values.

By default, fields are nullable.

Even if this method returns FALSE (i.e not-nullable field), it doesn't mean that
OGRFeature::IsFieldSet() will necessary return TRUE, as fields can be temporary
unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.

Note that not-nullable geometry fields might also contain 'empty' geometries.
"""
isnullable(gfd::GeomFieldDefn) = Bool(GDAL.isnullable(gfd.ptr))

"""
Set whether this geometry field can receive null values.

By default, fields are nullable, so this method is generally called with FALSE
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_GEOMFIELDS driver metadata item.
"""
setnullable!(gfd::GeomFieldDefn, nullable::Bool) = 
    (GDAL.setnullable(gfd.ptr, nullable), gfd)

"Return whether this field should be omitted when fetching features."
isignored(gfd::GeomFieldDefn) = Bool(GDAL.isignored(gfd.ptr))

"Set whether this field should be omitted when fetching features."
function setignored!(gfd::GeomFieldDefn, ignore::Bool)
    @gdal(OGR_GFld_SetIgnored::Void, gfd.ptr::GDALGeomFieldDefn, ignore::Cint)
    gfd
end
