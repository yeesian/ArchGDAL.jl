"Construct a Spatial Reference System from its WKT."
newspatialref(wkt::AbstractString = "") =
    ISpatialRef(GDAL.newspatialreference(wkt))

unsafe_newspatialref(wkt::AbstractString = "") =
    SpatialRef(GDAL.newspatialreference(wkt))

function destroy(spref::AbstractSpatialRef)
    GDAL.destroyspatialreference(spref.ptr)
    spref.ptr = C_NULL
end

"Makes a clone of the Spatial Reference System. May return NULL."
function clone(spref::AbstractSpatialRef)
    if spref.ptr == C_NULL
        return ISpatialRef()
    else
        return ISpatialRef(GDAL.clone(spref.ptr))
    end
end

function unsafe_clone(spref::AbstractSpatialRef)
    if spref.ptr == C_NULL
        return SpatialRef()
    else
        return SpatialRef(GDAL.clone(spref.ptr))
    end
end

"""
Initialize SRS based on EPSG GCS or PCS code.

This method will initialize the spatial reference based on the passed in
EPSG GCS or PCS code. It is relatively expensive, and generally involves quite a
bit of text file scanning. Reasonable efforts should be made to avoid calling it
many times for the same coordinate system.

### Additional Remarks
This method is similar to importFromEPSGA() except that EPSG preferred axis
ordering will not be applied for geographic coordinate systems. EPSG normally
defines geographic coordinate systems to use lat/long contrary to typical GIS
use). Since OGR 1.10.0, EPSG preferred axis ordering will also not be applied
for projected coordinate systems that use northing/easting order.

The coordinate system definitions are normally read from the EPSG derived
support files such as pcs.csv, gcs.csv, pcs.override.csv, gcs.override.csv and
falling back to search for a PROJ.4 epsg init file or a definition in epsg.wkt.

These support files are normally searched for in /usr/local/share/gdal or in the
directory identified by the GDAL_DATA configuration option. See CPLFindFile()
for details.
"""
function importEPSG!(spref::AbstractSpatialRef, code::Integer)
    result = GDAL.importfromepsg(spref.ptr, code)
    @ogrerr result "Failed to initialize SRS based on EPSG"
    spref
end

"Construct a Spatial Reference System from its EPSG GCS or PCS code."
importEPSG(code::Integer) = importEPSG!(newspatialref(), code)

unsafe_importEPSG(code::Integer) = importEPSG!(unsafe_newspatialref(), code)

"""
Initialize SRS based on EPSG CRS code.

This method is similar to `importFromEPSG()` except that EPSG preferred axis
ordering will be applied for geographic and projected coordinate systems. EPSG
normally defines geographic coordinate systems to use lat/long, and also there
are also a few projected coordinate systems that use northing/easting order
contrary to typical GIS use). See `importFromEPSG()` for more
details on operation of this method.
"""
function importEPSGA!(spref::AbstractSpatialRef, code::Integer)
    result = GDAL.importfromepsga(spref.ptr, code)
    @ogrerr result "Failed to initializ SRS based on EPSGA"
    spref
end

"""
Construct a Spatial Reference System from its EPSG CRS code.

This method is similar to `importFromEPSG()` except that EPSG preferred axis
ordering will be applied for geographic and projected coordinate systems. EPSG
normally defines geographic coordinate systems to use lat/long, and also there
are also a few projected coordinate systems that use northing/easting order
contrary to typical GIS use). See `importFromEPSG()` for more
details on operation of this method.
"""
importEPSGA(code::Integer) = importEPSGA!(newspatialref(), code)

unsafe_importEPSGA(code::Integer) = importEPSGA!(unsafe_newspatialref(), code)

"""
Import from WKT string.

This method will wipe the existing SRS definition, and reassign it based on the
contents of the passed WKT string. Only as much of the input string as needed to
construct this SRS is consumed from the input string, and the input string
pointer is then updated to point to the remaining (unused) input.
"""
function importWKT!(spref::AbstractSpatialRef, wktstr::AbstractString)
    result = GDAL.importfromwkt(spref.ptr, [wktstr])
    @ogrerr result "Failed to initialize SRS based on WKT string"
    spref
end

"Create SRS from its WKT string."
importWKT(wktstr::AbstractString) = newspatialref(wktstr)

unsafe_importWKT(wktstr::AbstractString) = unsafe_newspatialref(wktstr)

"""
Import PROJ.4 coordinate string.

The OGRSpatialReference is initialized from the passed PROJ.4 style coordinate
system string. In addition to many `+proj` formulations which have OGC
equivalents, it is also possible to import `"+init=epsg:n"` style definitions.
These are passed to `importFromEPSG()`. Other init strings (such as the state
plane zones) are not currently supported.

Example: `pszProj4 = \"+proj=utm +zone=11 +datum=WGS84\"`

Some parameters, such as grids, recognized by PROJ.4 may not be well understood
and translated into the OGRSpatialReference model. It is possible to add the
`+wktext` parameter which is a special keyword that OGR recognized as meaning
\"embed the entire PROJ.4 string in the WKT and use it literally when converting
back to PROJ.4 format\".

For example: `\"+proj=nzmg +lat_0=-41 +lon_0=173 +x_0=2510000 +y_0=6023150
+ellps=intl +units=m +nadgrids=nzgd2kgrid0005.gsb +wktext\"`
"""
function importPROJ4!(spref::AbstractSpatialRef, projstr::AbstractString)
    result = GDAL.importfromproj4(spref.ptr, projstr)
    @ogrerr result "Failed to initialize SRS based on PROJ4 string"
    spref
end

"Create SRS from its PROJ.4 string."
importPROJ4(projstr::AbstractString) =
    importPROJ4!(newspatialref(), projstr)

unsafe_importPROJ4(projstr::AbstractString) =
    importPROJ4!(unsafe_newspatialref(), projstr)

"""
Import coordinate system from ESRI .prj format(s).

This function will read the text loaded from an ESRI .prj file, and translate it
into an OGRSpatialReference definition. This should support many (but by no
means all) old style (Arc/Info 7.x) .prj files, as well as the newer pseudo-OGC
WKT .prj files. Note that new style .prj files are in OGC WKT format, but
require some manipulation to correct datum names, and units on some projection
parameters. This is addressed within `importFromESRI()` by an automatic call to
`morphFromESRI()`.

Currently only `GEOGRAPHIC`, `UTM`, `STATEPLANE`, `GREATBRITIAN_GRID`, `ALBERS`,
`EQUIDISTANT_CONIC`, `TRANSVERSE (mercator)`, `POLAR`, `MERCATOR` and
`POLYCONIC` projections are supported from old style files.

At this time there is no equivalent `exportToESRI()` method. Writing old style
.prj files is not supported by OGRSpatialReference. However the `morphToESRI()`
and `exportToWkt()` methods can be used to generate output suitable to write to
new style (Arc 8) .prj files.
"""
function importESRI!(spref::AbstractSpatialRef, esristr::AbstractString)
    result = GDAL.importfromesri(spref.ptr, [esristr])
    @ogrerr result "Failed to initialize SRS based on ESRI string"
    spref
end

"Create SRS from its ESRI .prj format(s)."
importESRI(esristr::AbstractString) =
    importESRI!(newspatialref(), esristr)

unsafe_importESRI(esristr::AbstractString) =
    importESRI!(unsafe_newspatialref(), esristr)

"Import SRS from XML format (GML only currently)."
function importXML!(spref::AbstractSpatialRef, xmlstr::AbstractString)
    result = GDAL.importfromxml(spref.ptr, xmlstr)
    @ogrerr result "Failed to initialize SRS based on XML string"
    spref
end

"Construct SRS from XML format (GML only currently)."
importXML(xmlstr::AbstractString) =
    importXML!(newspatialref(), xmlstr)

unsafe_importXML(xmlstr::AbstractString) =
    importXML!(unsafe_newspatialref(), xmlstr)

"""
Set spatial reference from a URL.

This method will download the spatial reference at a given URL and feed it into
SetFromUserInput for you.
"""
function importURL!(spref::AbstractSpatialRef, url::AbstractString)
    result = GDAL.importfromurl(spref.ptr, url)
    @ogrerr result "Failed to initialize SRS from URL"
    spref
end

"""
Construct SRS from a URL.

This method will download the spatial reference at a given URL and feed it into
SetFromUserInput for you.
"""
importURL(url::AbstractString) = importURL!(newspatialref(), url)

unsafe_importURL(url::AbstractString) = importURL!(unsafe_newspatialref(), url)

"Convert this SRS into WKT format."
function toWKT(spref::AbstractSpatialRef)
    wktptr = Ref{Cstring}()
    result = GDAL.exporttowkt(spref.ptr, wktptr)
    @ogrerr result "Failed to convert this SRS into WKT format"
    unsafe_string(wktptr[])
end

"""
Convert this SRS into a nicely formatted WKT string for display to a person.

### Parameters
* `spref`:      the SRS to be converted
* `simplify`:   TRUE if the `AXIS`, `AUTHORITY` and `EXTENSION` nodes should be
                stripped off.
"""
function toWKT(spref::AbstractSpatialRef, simplify::Bool)
    wktptr = Ref{Cstring}()
    result = GDAL.exporttoprettywkt(spref.ptr, wktptr, simplify)
    @ogrerr result "Failed to convert this SRS into pretty WKT"
    unsafe_string(wktptr[])
end

"""
    OSRExportToProj4(OGRSpatialReferenceH,
                     char **) -> OGRErr
Export coordinate system in PROJ.4 format.
"""
function toPROJ4(spref::AbstractSpatialRef)
    projptr = Ref{Cstring}()
    result = GDAL.exporttoproj4(spref.ptr, projptr)
    @ogrerr result "Failed to export this SRS to PROJ.4 format"
    unsafe_string(projptr[])
end

"""
Export coordinate system in XML format.

Converts the loaded coordinate reference system into XML format to the extent
possible. LOCAL_CS coordinate systems are not translatable. An empty string will
be returned along with OGRERR_NONE.
"""
function toXML(spref::AbstractSpatialRef)
    xmlptr = Ref{Cstring}()
    result = GDAL.exporttoxml(spref.ptr, xmlptr, C_NULL)
    @ogrerr result "Failed to convert this SRS into XML"
    unsafe_string(xmlptr[])
end

"Export coordinate system in Mapinfo style CoordSys format."
function toMICoordSys(spref::AbstractSpatialRef)
    ptr = Ref{Cstring}()
    result = GDAL.exporttomicoordsys(spref.ptr, ptr)
    @ogrerr result "Failed to convert this SRS into XML"
    unsafe_string(ptr[])
end

"""
Convert in place to ESRI WKT format.

The value nodes of this coordinate system are modified in various manners more
closely map onto the ESRI concept of WKT format. This includes renaming a 
variety of projections and arguments, and stripping out nodes note recognised by
ESRI (like AUTHORITY and AXIS).
"""
function morphtoESRI!(spref::AbstractSpatialRef)
    result = GDAL.morphtoesri(spref.ptr)
    @ogrerr result "Failed to convert in place to ESRI WKT format"
    spref
end

"""
Convert in place from ESRI WKT format.

The value notes of this coordinate system are modified in various manners to
adhere more closely to the WKT standard. This mostly involves translating a
variety of ESRI names for projections, arguments and datums to "standard" names,
as defined by Adam Gawne-Cain's reference translation of EPSG to WKT for the CT
specification.

Missing parameters in `TOWGS84`, `DATUM` or `GEOGCS` nodes can be added to the
`WKT`, comparing existing `WKT` parameters to GDAL's databases. Note that this
optional procedure is very conservative and should not introduce false
information into the WKT definition (although caution should be advised when
activating it). Needs the Configuration Option `GDAL_FIX_ESRI_WKT` be set to one
of the following (`TOWGS84` recommended for proper datum shift calculations)

`GDAL_FIX_ESRI_WKT` values:

* `TOWGS84` Adds missing TOWGS84 parameters (necessary for datum
        transformations), based on named datum and spheroid values.
* `DATUM`   Adds EPSG AUTHORITY nodes and sets SPHEROID name to OGR spec.
* `GEOGCS`  Adds EPSG AUTHORITY nodes and sets `GEOGCS`, `DATUM` and `SPHEROID`
        names to OGR spec. Effectively replaces `GEOGCS` node with the result of
        `importFromEPSG(n)`, using `EPSG` code `n` corresponding to the existing
        `GEOGCS`. Does not impact `PROJCS` values.
"""
function morphfromESRI!(spref::AbstractSpatialRef)
    result = GDAL.morphfromesri(spref.ptr)
    @ogrerr result "Failed to convert in place from ESRI WKT format"
    spref
end

"""
Set attribute value in spatial reference.

Missing intermediate nodes in the path will be created if not already in
existence. If the attribute has no children one will be created and assigned
the value otherwise the zeroth child will be assigned the value.

### Parameters
* `path`: full path to attribute to be set. For instance "PROJCS|GEOGCS|UNIT".
* `value`: (optional) to be assigned to node, such as "meter". This may be left
            out if you just want to force creation of the intermediate path.
"""
function setattrvalue!(
        spref::AbstractSpatialRef,
        path::AbstractString,
        value::AbstractString
    )
    result = GDAL.setattrvalue(spref.ptr, path, value)
    @ogrerr result "Failed to set attribute path to value"
    value
end

function setattrvalue!(spref::AbstractSpatialRef, path::AbstractString)
    result = GDAL.setattrvalue(spref.ptr, path, C_NULL)
    @ogrerr result "Failed to set attribute path"
end

"""
Fetch indicated attribute of named node.

This method uses GetAttrNode() to find the named node, and then extracts the
value of the indicated child. Thus a call to `getattrvalue(spref,"UNIT",1)`
would return the second child of the UNIT node, which is normally the length of
the linear unit in meters.

Parameters
`name` the tree node to look for (case insensitive).
`i`    the child of the node to fetch (zero based).

Returns
the requested value, or NULL if it fails for any reason.
"""
getattrvalue(spref::AbstractSpatialRef, name::AbstractString, i::Integer) =
    GDAL.getattrvalue(spref.ptr, name, i)

"""
Create transformation object.

### Parameters
* `source`: source spatial reference system.
* `target`: target spatial reference system.

### Returns
NULL on failure or a ready to use transformation object.
"""
function unsafe_createcoordtrans(
        source::AbstractSpatialRef,
        target::AbstractSpatialRef
    )
    CoordTransform(GDAL.octnewcoordinatetransformation(source.ptr, target.ptr))
end

"OGRCoordinateTransformation destructor."
function destroy(obj::CoordTransform)
    GDAL.octdestroycoordinatetransformation(obj.ptr)
    obj.ptr = C_NULL
end

"""
Transform points from source to destination space.

### Parameters
* `xvertices`   array of nCount X vertices, modified in place.
* `yvertices`   array of nCount Y vertices, modified in place.
* `zvertices`   array of nCount Z vertices, modified in place.

### Returns
`true` on success, or `false` if some or all points fail to transform.
"""
function transform!(
        xvertices::Vector{Cdouble},
        yvertices::Vector{Cdouble},
        zvertices::Vector{Cdouble},
        obj::CoordTransform
    )
    # The method TransformEx() allows extended success information to be captured
    # indicating which points failed to transform.
    n = length(xvertices)
    @assert length(yvertices) == n
    @assert length(zvertices) == n
    Bool(GDAL.octtransform(obj.ptr, n,
        pointer(xvertices),
        pointer(yvertices),
        pointer(zvertices)
    ))
end
