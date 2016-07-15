"""
Create a new field definition.

By default, fields have no width, precision, are nullable and not ignored.
"""
unsafe_createfielddefn(name::AbstractString, etype::GDAL.OGRFieldType) =
    GDAL.fld_create(name, etype)

"Destroy a field definition."
destroy(fielddefn::FieldDefn) = GDAL.destroy(fielddefn)

"Set the name of this field."
setname!(fielddefn::FieldDefn, name::AbstractString) =
    GDAL.setname(fielddefn, name)

"Fetch the name of this field."
getname(fielddefn::FieldDefn) = GDAL.getnameref(fielddefn)

"Fetch the type of this field."
gettype(fielddefn::FieldDefn) = GDAL.gettype(fielddefn)

"Set the type of this field."
settype!(fielddefn::FieldDefn, etype::GDAL.OGRFieldType) =
    GDAL.settype(fielddefn, etype)

"""
Fetch subtype of this field.

### Parameters
* `fielddefn`: handle to the field definition to get subtype from.

### Returns
field subtype.
"""
getsubtype(fielddefn::FieldDefn) = GDAL.getsubtype(fielddefn)

"""
Set the subtype of this field.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.

### Parameters
* `fielddefn`: handle to the field definition to set type to.
* `subtype`: the new field subtype.
"""
setsubtype!(fielddefn::FieldDefn, subtype::GDAL.OGRFieldSubType) =
    GDAL.setsubtype(fielddefn, subtype)

"""
Get the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
getjustify(fielddefn::FieldDefn) = GDAL.getjustify(fielddefn)

"""
Set the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
setjustify!(fielddefn::FieldDefn, ejustify::GDAL.OGRJustification) =
    GDAL.setjustify(fielddefn, ejustify)

"""Get the formatting width for this field.

### Returns
the width, zero means no specified width.
"""
getwidth(fielddefn::FieldDefn) = GDAL.getwidth(fielddefn)

"""
Set the formatting width for this field in characters.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.
"""
setwidth!(fielddefn::FieldDefn, width::Integer) =
    GDAL.setwidth(fielddefn, width)

"""
Get the formatting precision for this field.

This should normally be zero for fields of types other than OFTReal.
"""
getprecision(fielddefn::FieldDefn) = GDAL.getprecision(fielddefn)

"""
Set the formatting precision for this field in characters.

This should normally be zero for fields of types other than OFTReal.
"""
setprecision!(fielddefn::FieldDefn, precision::Integer) =
    GDAL.setprecision(fielddefn, precision)

"""
Set defining parameters for a field in one call.

### Parameters
* `fielddefn`:  handle to the field definition to set to.
* `name`:       the new name to assign.
* `etype`:      the new type (one of the OFT values like OFTInteger).
* `nwidth`:     the preferred formatting width. 0 (default) indicates undefined.
* `nprecision`: number of decimals places for formatting, defaults to 0
                indicating undefined.
* `justify`:    the formatting justification (OJLeft or OJRight), defaults to
                OJUndefined.
"""
setparams!(fielddefn::FieldDefn, name::AbstractString, etype::GDAL.OGRFieldType;
           nwidth::Integer=0, nprecision::Integer=0,
           justify::GDAL.OGRJustification=GDAL.OJUndefined) =
    GDAL.set(fielddefn, name, etype, nwidth, nprecision, justify)

"Return whether this field should be omitted when fetching features."
isignored(fielddefn::FieldDefn) = Bool(GDAL.isignored(fielddefn))

"Set whether this field should be omitted when fetching features."
setignored!(fielddefn::FieldDefn, ignore::Bool) =
    GDAL.setignored(fielddefn, ignore)

"""
Return whether this field can receive null values.

By default, fields are nullable.

Even if this method returns FALSE (i.e not-nullable field), it doesn't mean that
OGRFeature::IsFieldSet() will necessary return TRUE, as fields can be temporary
unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.
"""
isnullable(fielddefn::FieldDefn) = Bool(GDAL.isnullable(fielddefn))

"""
Set whether this field can receive null values.

By default, fields are nullable, so this method is generally called with FALSE
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_FIELDS driver metadata item.
"""
setnullable!(fielddefn::FieldDefn, nullable::Bool) =
    GDAL.setnullable(fielddefn, nullable)

"Get default field value"
getdefault(fielddefn::FieldDefn) = GDAL.getdefault(fielddefn)

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
    GDAL.setdefault(fielddefn, default)

"""
Returns whether the default value is driver specific.

Driver specific default values are those that are not NULL, a numeric value, a
literal value enclosed between single quote characters, CURRENT_TIMESTAMP,
CURRENT_TIME, CURRENT_DATE or datetime literal value.
"""
isdefaultdriverspecific(fielddefn::FieldDefn) =
    Bool(GDAL.isdefaultdriverspecific(fielddefn))

"Create a new field geometry definition."
unsafe_creategeomfielddefn(name::AbstractString,etype::GDAL.OGRwkbGeometryType)=
    GDAL.gfld_create(name, etype)

"Destroy a geometry field definition."
destroy(gfd::GeomFieldDefn) = GDAL.destroy(gfd)

"Set the name of this field."
setname!(gfd::GeomFieldDefn, name::AbstractString) =
    GDAL.setname(gfd, name)

"Fetch name of this field."
getname(gfd::GeomFieldDefn) = GDAL.getnameref(gfd)

"Fetch geometry type of this field."
gettype(gfd::GeomFieldDefn) = GDAL.gettype(gfd)

"Set the geometry type of this field."
settype!(gfd::GeomFieldDefn, etype::GDAL.OGRwkbGeometryType) =
    GDAL.settype(gfd, etype)

"Fetch spatial reference system of this field."
getspatialref(gfd::GeomFieldDefn) = GDAL.getspatialref(gfd)

"""
Set the spatial reference of this field.

This function drops the reference of the previously set SRS object and acquires
a new reference on the passed object (if non-NULL).
"""
# should reference be increased by 1?
setspatialref!(gfd::GeomFieldDefn, spatialref::SpatialRef) =
    GDAL.setspatialref(gfd, spatialref)

"""
Return whether this geometry field can receive null values.

By default, fields are nullable.

Even if this method returns FALSE (i.e not-nullable field), it doesn't mean that
OGRFeature::IsFieldSet() will necessary return TRUE, as fields can be temporary
unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.

Note that not-nullable geometry fields might also contain 'empty' geometries.
"""
isnullable(gfd::GeomFieldDefn) = Bool(GDAL.isnullable(gfd))

"""
Set whether this geometry field can receive null values.

By default, fields are nullable, so this method is generally called with FALSE
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_GEOMFIELDS driver metadata item.
"""
setnullable!(gfd::GeomFieldDefn, nullable::Bool)=GDAL.setnullable(gfd, nullable)

"Return whether this field should be omitted when fetching features."
isignored(gfd::GeomFieldDefn) = Bool(GDAL.isignored(gfd))

"Set whether this field should be omitted when fetching features."
setignored(gfd::GeomFieldDefn, ignore::Bool) = GDAL.setignored(gfd, ignore)