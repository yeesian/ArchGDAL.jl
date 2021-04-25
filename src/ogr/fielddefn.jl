"""
    unsafe_createfielddefn(name::AbstractString, etype::OGRFieldType)

Create a new field definition.

By default, fields have no width, precision, are nullable and not ignored.
"""
unsafe_createfielddefn(name::AbstractString, etype::OGRFieldType)::FieldDefn =
    FieldDefn(GDAL.ogr_fld_create(name, etype))

"Destroy a field definition."
function destroy(fielddefn::FieldDefn)::Nothing
    GDAL.ogr_fld_destroy(fielddefn.ptr)
    fielddefn.ptr = C_NULL
    return nothing
end

function destroy(fielddefn::IFieldDefnView)::Nothing
    fielddefn.ptr = C_NULL
    return nothing
end

"Set the name of this field."
function setname!(fielddefn::FieldDefn, name::AbstractString)::FieldDefn
    GDAL.ogr_fld_setname(fielddefn.ptr, name)
    return fielddefn
end

"Fetch the name of this field."
getname(fielddefn::AbstractFieldDefn)::String =
    GDAL.ogr_fld_getnameref(fielddefn.ptr)

"Fetch the type of this field."
gettype(fielddefn::AbstractFieldDefn)::OGRFieldType =
    GDAL.ogr_fld_gettype(fielddefn.ptr)

"Set the type of this field."
function settype!(fielddefn::FieldDefn, etype::OGRFieldType)::FieldDefn
    GDAL.ogr_fld_settype(fielddefn.ptr, etype)
    return fielddefn
end

"""
    getsubtype(fielddefn::AbstractFieldDefn)

Fetch subtype of this field.

### Parameters
* `fielddefn`: handle to the field definition to get subtype from.

### Returns
field subtype.
"""
getsubtype(fielddefn::AbstractFieldDefn)::OGRFieldSubType =
    GDAL.ogr_fld_getsubtype(fielddefn.ptr)

"""
    setsubtype!(fielddefn::FieldDefn, subtype::OGRFieldSubType)

Set the subtype of this field.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.

### Parameters
* `fielddefn`: handle to the field definition to set type to.
* `subtype`: the new field subtype.
"""
function setsubtype!(
        fielddefn::FieldDefn,
        subtype::OGRFieldSubType
    )::FieldDefn
    GDAL.ogr_fld_setsubtype(fielddefn.ptr, subtype)
    return fielddefn
end

"""
    getjustify(fielddefn::AbstractFieldDefn)

Get the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
getjustify(fielddefn::AbstractFieldDefn)::OGRJustification =
    GDAL.ogr_fld_getjustify(fielddefn.ptr)

"""
    setjustify!(fielddefn::FieldDefn, ejustify::OGRJustification)

Set the justification for this field.

Note: no driver is know to use the concept of field justification.
"""
function setjustify!(
        fielddefn::FieldDefn,
        ejustify::OGRJustification
    )::FieldDefn
    GDAL.ogr_fld_setjustify(fielddefn.ptr, ejustify)
    return fielddefn
end

"""
    getwidth(fielddefn::AbstractFieldDefn)

Get the formatting width for this field.

### Returns
the width, zero means no specified width.
"""
getwidth(fielddefn::AbstractFieldDefn)::Integer =
    GDAL.ogr_fld_getwidth(fielddefn.ptr)

"""
    setwidth!(fielddefn::FieldDefn, width::Integer)

Set the formatting width for this field in characters.

This should never be done to an OGRFieldDefn that is already part of an
OGRFeatureDefn.
"""
function setwidth!(fielddefn::FieldDefn, width::Integer)::FieldDefn
    GDAL.ogr_fld_setwidth(fielddefn.ptr, width)
    return fielddefn
end

"""
    getprecision(fielddefn::AbstractFieldDefn)

Get the formatting precision for this field.

This should normally be zero for fields of types other than OFTReal.
"""
getprecision(fielddefn::AbstractFieldDefn)::Integer =
    GDAL.ogr_fld_getprecision(fielddefn.ptr)

"""
    setprecision!(fielddefn::FieldDefn, precision::Integer)

Set the formatting precision for this field in characters.

This should normally be zero for fields of types other than OFTReal.
"""
function setprecision!(fielddefn::FieldDefn, precision::Integer)::FieldDefn
    GDAL.ogr_fld_setprecision(fielddefn.ptr, precision)
    return fielddefn
end

"""
    setparams!(fielddefn, name, etype, [nwidth, [nprecision, [justify]]])

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
        justify::OGRJustification   = OJUndefined
    )::FieldDefn
    GDAL.ogr_fld_set(fielddefn.ptr, name, etype, nwidth, nprecision, justify)
    return fielddefn
end

"""
    isignored(fielddefn::AbstractFieldDefn)

Return whether this field should be omitted when fetching features.
"""
isignored(fielddefn::AbstractFieldDefn)::Bool =
    Bool(GDAL.ogr_fld_isignored(fielddefn.ptr))

"""
    setignored!(fielddefn::FieldDefn, ignore::Bool)

Set whether this field should be omitted when fetching features.
"""
function setignored!(fielddefn::FieldDefn, ignore::Bool)::FieldDefn
    GDAL.ogr_fld_setignored(fielddefn.ptr, ignore)
    return fielddefn
end

"""
    isnullable(fielddefn::AbstractFieldDefn)

Return whether this field can receive null values.

By default, fields are nullable.

Even if this method returns `false` (i.e not-nullable field), it doesn't mean
that OGRFeature::IsFieldSet() will necessarily return `true`, as fields can be
temporarily unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.
"""
isnullable(fielddefn::AbstractFieldDefn)::Bool =
    Bool(GDAL.ogr_fld_isnullable(fielddefn.ptr))

"""
    setnullable!(fielddefn::FieldDefn, nullable::Bool)

Set whether this field can receive null values.

By default, fields are nullable, so this method is generally called with `false`
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_FIELDS driver metadata item.
"""
function setnullable!(fielddefn::FieldDefn, nullable::Bool)::FieldDefn
    GDAL.ogr_fld_setnullable(fielddefn.ptr, nullable)
    return fielddefn
end

"""
    getdefault(fielddefn::AbstractFieldDefn)

Get default field value
"""
function getdefault(fielddefn::AbstractFieldDefn)::String
    result = @gdal(OGR_Fld_GetDefault::Cstring, fielddefn.ptr::GDAL.OGRFieldDefnH)
    return if result == C_NULL
        ""
    else
        unsafe_string(result)
    end
end

"""
    setdefault!(fielddefn::AbstractFieldDefn, default)

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
function setdefault!(fielddefn::T, default)::T where {T <: AbstractFieldDefn}
    GDAL.ogr_fld_setdefault(fielddefn.ptr, default)
    return fielddefn
end

"""
    isdefaultdriverspecific(fielddefn::AbstractFieldDefn)

Returns whether the default value is driver specific.

Driver specific default values are those that are not NULL, a numeric value, a
literal value enclosed between single quote characters, CURRENT_TIMESTAMP,
CURRENT_TIME, CURRENT_DATE or datetime literal value.
"""
isdefaultdriverspecific(fielddefn::AbstractFieldDefn)::Bool =
    Bool(GDAL.ogr_fld_isdefaultdriverspecific(fielddefn.ptr))

"""
    unsafe_creategeomdefn(name::AbstractString, etype::OGRwkbGeometryType)

Create a new field geometry definition.
"""
function unsafe_creategeomdefn(
        name::AbstractString,
        etype::OGRwkbGeometryType
    )::GeomFieldDefn
    return GeomFieldDefn(GDAL.ogr_gfld_create(name, etype))
end

"Destroy a geometry field definition."
function destroy(geomdefn::GeomFieldDefn)::Nothing
    GDAL.ogr_gfld_destroy(geomdefn.ptr)
    geomdefn.ptr = C_NULL
    geomdefn.spatialref = SpatialRef()
    return nothing
end

"Destroy a geometry field definition."
function destroy(geomdefn::IGeomFieldDefnView)::Nothing
    geomdefn.ptr = C_NULL
    return nothing
end

"Set the name of this field."
function setname!(geomdefn::GeomFieldDefn, name::AbstractString)::GeomFieldDefn
    GDAL.ogr_gfld_setname(geomdefn.ptr, name)
    return geomdefn
end

"Fetch name of this field."
getname(geomdefn::AbstractGeomFieldDefn)::String =
    GDAL.ogr_gfld_getnameref(geomdefn.ptr)

"Fetch geometry type of this field."
gettype(geomdefn::AbstractGeomFieldDefn)::OGRwkbGeometryType =
    GDAL.ogr_gfld_gettype(geomdefn.ptr)

"Set the geometry type of this field."
function settype!(
        geomdefn::GeomFieldDefn,
        etype::OGRwkbGeometryType
    )::GeomFieldDefn
    GDAL.ogr_gfld_settype(geomdefn.ptr, etype)
    return geomdefn
end

"""
    getspatialref(geomdefn::AbstractGeomFieldDefn)

Returns a clone of the spatial reference system for this field. May be NULL.
"""
function getspatialref(geomdefn::AbstractGeomFieldDefn)::ISpatialRef
    result = GDAL.ogr_gfld_getspatialref(geomdefn.ptr)
    if result == C_NULL
        return ISpatialRef()
    else
        # NOTE(yeesian): we make a clone here so that the spatialref does not
        # depend on the GeomFieldDefn/Dataset.
        return ISpatialRef(GDAL.osrclone(result))
    end
end

function unsafe_getspatialref(geomdefn::AbstractGeomFieldDefn)::SpatialRef
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
    setspatialref!(geomdefn::GeomFieldDefn, spatialref::AbstractSpatialRef)

Set the spatial reference of this field.

This function drops the reference of the previously set SRS object and acquires
a new reference on the passed object (if non-NULL).
"""
function setspatialref!(
        geomdefn::GeomFieldDefn,
        spatialref::AbstractSpatialRef
    )::GeomFieldDefn
    clonespatialref = clone(spatialref)
    GDAL.ogr_gfld_setspatialref(geomdefn.ptr, clonespatialref.ptr)
    geomdefn.spatialref = clonespatialref
    return geomdefn
end

"""
    isnullable(geomdefn::AbstractGeomFieldDefn)

Return whether this geometry field can receive null values.

By default, fields are nullable.

Even if this method returns `false` (i.e not-nullable field), it doesn't mean
that OGRFeature::IsFieldSet() will necessary return `true`, as fields can be
temporarily unset and null/not-null validation is usually done when
OGRLayer::CreateFeature()/SetFeature() is called.

Note that not-nullable geometry fields might also contain 'empty' geometries.
"""
isnullable(geomdefn::AbstractGeomFieldDefn)::Bool =
    Bool(GDAL.ogr_gfld_isnullable(geomdefn.ptr))

"""
    setnullable!(geomdefn::GeomFieldDefn, nullable::Bool)

Set whether this geometry field can receive null values.

By default, fields are nullable, so this method is generally called with `false`
to set a not-null constraint.

Drivers that support writing not-null constraint will advertize the
GDAL_DCAP_NOTNULL_GEOMFIELDS driver metadata item.
"""
function setnullable!(geomdefn::GeomFieldDefn, nullable::Bool)::GeomFieldDefn
    GDAL.ogr_gfld_setnullable(geomdefn.ptr, nullable)
    return geomdefn
end

"""
    isignored(geomdefn::AbstractGeomFieldDefn)

Return whether this field should be omitted when fetching features.
"""
isignored(geomdefn::AbstractGeomFieldDefn)::Bool =
    Bool(GDAL.ogr_gfld_isignored(geomdefn.ptr))

"""
    setignored!(geomdefn::GeomFieldDefn, ignore::Bool)

Set whether this field should be omitted when fetching features.
"""
function setignored!(geomdefn::GeomFieldDefn, ignore::Bool)::GeomFieldDefn
    GDAL.ogr_gfld_setignored(geomdefn.ptr, ignore)
    return geomdefn
end
