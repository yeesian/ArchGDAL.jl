"""
Create a new field definition.

By default, fields have no width, precision, are nullable and not ignored.
"""
unsafe_createfielddefn(name::AbstractString, etype::OGRFieldType) =
    FieldDefn(GDAL.fld_create(name, etype))

"Destroy a field definition."
function destroy(fd::FieldDefn)
    GDAL.destroy(fd.ptr)
    fd.ptr = C_NULL
end

"Set the name of this field."
function setname!(fielddefn::FieldDefn, name::AbstractString)
    GDAL.setname(fielddefn.ptr, name)
    fielddefn
end

"Fetch the name of this field."
getname(fielddefn::FieldDefn) = GDAL.getnameref(fielddefn.ptr)

"Fetch the type of this field."
gettype(fielddefn::FieldDefn) = GDAL.gettype(fielddefn.ptr)

"Set the type of this field."
function settype!(fielddefn::FieldDefn, etype::OGRFieldType)
    GDAL.settype(fielddefn.ptr, etype)
    fielddefn
end

"""
Fetch subtype of this field.

### Parameters
* `fielddefn`: handle to the field definition to get subtype from.

### Returns
field subtype.
"""
getsubtype(fielddefn::FieldDefn) = GDAL.getsubtype(fielddefn.ptr)

"""
Set the subtype of this field.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.

### Parameters
* `fielddefn`: handle to the field definition to set type to.
* `subtype`: the new field subtype.
"""
function setsubtype!(fielddefn::FieldDefn, subtype::OGRFieldSubType)
    GDAL.setsubtype(fielddefn.ptr, subtype)
    fielddefn
end

"""
Get the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
getjustify(fielddefn::FieldDefn) = GDAL.getjustify(fielddefn.ptr)

"""
Set the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
function setjustify!(fielddefn::FieldDefn, ejustify::OGRJustification)
    GDAL.setjustify(fielddefn.ptr, ejustify)
    fielddefn
end

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
function setwidth!(fielddefn::FieldDefn, width::Integer)
    GDAL.setwidth(fielddefn.ptr, width)
    fielddefn
end

"""
Get the formatting precision for this field.

This should normally be zero for fields of types other than OFTReal.
"""
getprecision(fielddefn::FieldDefn) = GDAL.getprecision(fielddefn.ptr)

"""
Set the formatting precision for this field in characters.

This should normally be zero for fields of types other than OFTReal.
"""
function setprecision!(fielddefn::FieldDefn, precision::Integer)
    GDAL.setprecision(fielddefn.ptr, precision)
    fielddefn
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
    GDAL.set(fielddefn.ptr,
        name,
        etype,
        nwidth,
        nprecision,
        justify
    )
    fielddefn
end

"Return whether this field should be omitted when fetching features."
isignored(fielddefn::FieldDefn) = Bool(GDAL.isignored(fielddefn.ptr))

"Set whether this field should be omitted when fetching features."
function setignored!(fielddefn::FieldDefn, ignore::Bool)
    GDAL.setignored(fielddefn.ptr, ignore)
    fielddefn
end

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
function setnullable!(fielddefn::FieldDefn, nullable::Bool)
    GDAL.setnullable(fielddefn.ptr, nullable)
    fielddefn
end

"Get default field value"
function getdefault(fielddefn::FieldDefn)
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
function setdefault!(fielddefn::FieldDefn, default)
    GDAL.setdefault(fielddefn.ptr, default)
    fielddefn
end

"""
Returns whether the default value is driver specific.

Driver specific default values are those that are not NULL, a numeric value, a
literal value enclosed between single quote characters, CURRENT_TIMESTAMP,
CURRENT_TIME, CURRENT_DATE or datetime literal value.
"""
isdefaultdriverspecific(fielddefn::FieldDefn) =
    Bool(GDAL.isdefaultdriverspecific(fielddefn.ptr))

"Create a new field geometry definition."
unsafe_creategeomdefn(name::AbstractString, etype::OGRwkbGeometryType) =
    GeomFieldDefn(GDAL.gfld_create(name, etype))

"Destroy a geometry field definition."
function destroy(gfd::GeomFieldDefn)
    GDAL.destroy(gfd.ptr)
    gfd.ptr = C_NULL
end

"Set the name of this field."
function setname!(gfd::GeomFieldDefn, name::AbstractString)
    GDAL.setname(gfd.ptr, name)
    gfd
end

"Fetch name of this field."
getname(gfd::GeomFieldDefn) = GDAL.getnameref(gfd.ptr)

"Fetch geometry type of this field."
gettype(gfd::GeomFieldDefn) = GDAL.gettype(gfd.ptr)

"Set the geometry type of this field."
function settype!(gfd::GeomFieldDefn, etype::OGRwkbGeometryType)
    GDAL.settype(gfd.ptr, etype)
    gfd
end

"Returns a clone of the spatial reference system for this field. May be NULL."
function getspatialref(gfd::GeomFieldDefn)
    result = GDAL.getspatialref(gfd.ptr)
    if result == C_NULL
        return ISpatialRef()
    else
        return ISpatialRef(GDAL.clone(result))
    end
end

function unsafe_getspatialref(gfd::GeomFieldDefn)
    result = GDAL.getspatialref(gfd.ptr)
    if result == C_NULL
        return SpatialRef()
    else
        return SpatialRef(GDAL.clone(result))
    end
end

"""
Set the spatial reference of this field.

This function drops the reference of the previously set SRS object and acquires
a new reference on the passed object (if non-NULL).
"""
function setspatialref!(gfd::GeomFieldDefn, spatialref::AbstractSpatialRef)
    GDAL.setspatialref(gfd.ptr, spatialref.ptr)
    gfd
end

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
function setnullable!(gfd::GeomFieldDefn, nullable::Bool)
    GDAL.setnullable(gfd.ptr, nullable)
    gfd
end

"Return whether this field should be omitted when fetching features."
isignored(gfd::GeomFieldDefn) = Bool(GDAL.isignored(gfd.ptr))

"Set whether this field should be omitted when fetching features."
function setignored!(gfd::GeomFieldDefn, ignore::Bool)
    GDAL.setignored(gfd.ptr, ignore)
    gfd
end
