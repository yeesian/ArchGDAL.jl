
"""
    fromWKB(data)

Create a geometry object of the appropriate type from it's well known
binary (WKB) representation.

### Parameters
* `data`: pointer to the input BLOB data.
"""
function fromWKB(data)::IGeometry
    geom = Ref{GDAL.OGRGeometryH}()
    result = @gdal(
        OGR_G_CreateFromWkb::GDAL.OGRErr,
        data::Ptr{Cuchar},
        C_NULL::GDAL.OGRSpatialReferenceH,
        geom::Ptr{GDAL.OGRGeometryH},
        sizeof(data)::Cint
    )
    @ogrerr result "Failed to create geometry from WKB"
    return IGeometry(geom[])
end

function unsafe_fromWKB(data)::Geometry
    geom = Ref{GDAL.OGRGeometryH}()
    result = @gdal(
        OGR_G_CreateFromWkb::GDAL.OGRErr,
        data::Ptr{Cuchar},
        C_NULL::GDAL.OGRSpatialReferenceH,
        geom::Ptr{GDAL.OGRGeometryH},
        sizeof(data)::Cint
    )
    @ogrerr result "Failed to create geometry from WKB"
    return Geometry(geom[])
end

"""
    fromWKT(data::Vector{String})

Create a geometry object of the appropriate type from its well known text
(WKT) representation.

### Parameters
* `data`: input zero terminated string containing WKT representation of the
    geometry to be created. The pointer is updated to point just beyond that
    last character consumed.
"""
function fromWKT(data::Vector{String})::IGeometry
    geom = Ref{GDAL.OGRGeometryH}()
    result = @gdal(
        OGR_G_CreateFromWkt::GDAL.OGRErr,
        data::StringList,
        C_NULL::GDAL.OGRSpatialReferenceH,
        geom::Ptr{GDAL.OGRGeometryH}
    )
    @ogrerr result "Failed to create geometry from WKT"
    return IGeometry(geom[])
end

function unsafe_fromWKT(data::Vector{String})::Geometry
    geom = Ref{GDAL.OGRGeometryH}()
    result = @gdal(
        OGR_G_CreateFromWkt::GDAL.OGRErr,
        data::StringList,
        C_NULL::GDAL.OGRSpatialReferenceH,
        geom::Ptr{GDAL.OGRGeometryH}
    )
    @ogrerr result "Failed to create geometry from WKT"
    return Geometry(geom[])
end

fromWKT(data::String, args...)::IGeometry = fromWKT([data], args...)

unsafe_fromWKT(data::String, args...)::Geometry =
    unsafe_fromWKT([data], args...)

"""
Destroy geometry object.

Equivalent to invoking delete on a geometry, but it guaranteed to take place
within the context of the GDAL/OGR heap.
"""
function destroy(geom::AbstractGeometry)::Nothing
    GDAL.ogr_g_destroygeometry(geom.ptr)
    geom.ptr = C_NULL
    return nothing
end

"""
    clone(geom::AbstractGeometry)

Returns a copy of the geometry with the original spatial reference system.
"""
function clone(geom::AbstractGeometry)::IGeometry
    if geom.ptr == C_NULL
        return IGeometry()
    else
        return IGeometry(GDAL.ogr_g_clone(geom.ptr))
    end
end

function unsafe_clone(geom::AbstractGeometry)::Geometry
    if geom.ptr == C_NULL
        return Geometry()
    else
        return Geometry(GDAL.ogr_g_clone(geom.ptr))
    end
end

"""
    creategeom(geomtype::OGRwkbGeometryType)

Create an empty geometry of desired type.

This is equivalent to allocating the desired geometry with new, but the
allocation is guaranteed to take place in the context of the GDAL/OGR heap.
"""
creategeom(geomtype::OGRwkbGeometryType)::IGeometry =
    IGeometry(GDAL.ogr_g_creategeometry(geomtype))

unsafe_creategeom(geomtype::OGRwkbGeometryType)::Geometry =
    Geometry(GDAL.ogr_g_creategeometry(geomtype))

"""
    forceto(geom::AbstractGeometry, targettype::OGRwkbGeometryType, [options])

Tries to force the provided geometry to the specified geometry type.

### Parameters
* `geom`: the input geometry.
* `targettype`: target output geometry type.
# `options`: (optional) options as a null-terminated vector of strings

It can promote 'single' geometry type to their corresponding collection type
(see OGR_GT_GetCollection()) or the reverse. non-linear geometry type to their
corresponding linear geometry type (see OGR_GT_GetLinear()), by possibly
approximating circular arcs they may contain. Regarding conversion from linear
geometry types to curve geometry types, only "wraping" will be done. No attempt
to retrieve potential circular arcs by de-approximating stroking will be done.
For that, OGRGeometry::getCurveGeometry() can be used.

The passed in geometry is cloned and a new one returned.
"""
function forceto(
    geom::AbstractGeometry,
    targettype::OGRwkbGeometryType,
    options = StringList(C_NULL),
)::IGeometry
    return IGeometry(
        GDAL.ogr_g_forceto(unsafe_clone(geom).ptr, targettype, options),
    )
end

function unsafe_forceto(
    geom::AbstractGeometry,
    targettype::OGRwkbGeometryType,
    options = StringList(C_NULL),
)::Geometry
    return Geometry(
        GDAL.ogr_g_forceto(unsafe_clone(geom).ptr, targettype, options),
    )
end

"""
    geomdim(geom::AbstractGeometry)

Get the dimension of the geometry. 0 for points, 1 for lines and 2 for surfaces.

This function corresponds to the SFCOM IGeometry::GetDimension() method. It
indicates the dimension of the geometry, but does not indicate the dimension of
the underlying space (as indicated by OGR_G_GetCoordinateDimension() function).
"""
geomdim(geom::AbstractGeometry)::Integer = GDAL.ogr_g_getdimension(geom.ptr)

"""
    getcoorddim(geom::AbstractGeometry)

Get the dimension of the coordinates in this geometry.

### Returns
This will return 2 or 3.
"""
getcoorddim(geom::AbstractGeometry)::Integer =
    GDAL.ogr_g_getcoordinatedimension(geom.ptr)

"""
    setcoorddim!(geom::AbstractGeometry, dim::Integer)

Set the coordinate dimension.

This method sets the explicit coordinate dimension. Setting the coordinate
dimension of a geometry to 2 should zero out any existing Z values. Setting the
dimension of a geometry collection, a compound curve, a polygon, etc. will
affect the children geometries. This will also remove the M dimension if present
before this call.
"""
function setcoorddim!(geom::G, dim::Integer)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_setcoordinatedimension(geom.ptr, dim)
    return geom
end

"""
    envelope(geom::AbstractGeometry)

Computes and returns the bounding envelope for this geometry.
"""
function envelope(geom::AbstractGeometry)::GDAL.OGREnvelope
    envelope = Ref{GDAL.OGREnvelope}(GDAL.OGREnvelope(0, 0, 0, 0))
    GDAL.ogr_g_getenvelope(geom.ptr, envelope)
    return envelope[]
end

"""
    envelope3d(geom::AbstractGeometry)

Computes and returns the bounding envelope (3D) for this geometry
"""
function envelope3d(geom::AbstractGeometry)::GDAL.OGREnvelope3D
    envelope = Ref{GDAL.OGREnvelope3D}(GDAL.OGREnvelope3D(0, 0, 0, 0, 0, 0))
    GDAL.ogr_g_getenvelope3d(geom.ptr, envelope)
    return envelope[]
end

"""
    boundingbox(geom::AbstractGeometry)

Returns a bounding box polygon (CW) built from envelope coordinates
"""
function boundingbox(geom::AbstractGeometry)::IGeometry
    coordinates = envelope(geom)
    MinX, MaxX = coordinates.MinX, coordinates.MaxX
    MinY, MaxY = coordinates.MinY, coordinates.MaxY
    # creates a CW closed ring polygon
    return createpolygon([
        [MaxY, MinX],
        [MaxY, MaxX],
        [MinY, MaxX],
        [MinY, MinX],
        [MaxY, MinX],
    ])
end

"""
    toWKB(geom::AbstractGeometry, order::OGRwkbByteOrder = wkbNDR)

Convert a geometry well known binary format.

### Parameters
* `geom`: handle on the geometry to convert to a well know binary data from.
* `order`: One of wkbXDR or [wkbNDR] indicating MSB or LSB byte order resp.
"""
function toWKB(
    geom::AbstractGeometry,
    order::OGRwkbByteOrder = wkbNDR,
)::Vector{Cuchar}
    buffer = Vector{Cuchar}(undef, wkbsize(geom))
    result = GDAL.ogr_g_exporttowkb(geom.ptr, order, buffer)
    @ogrerr result "Failed to export geometry to WKB"
    return buffer
end

"""
    toISOWKB(geom::AbstractGeometry, order::OGRwkbByteOrder = wkbNDR)

Convert a geometry into SFSQL 1.2 / ISO SQL/MM Part 3 well known binary format.

### Parameters
* `geom`: handle on the geometry to convert to a well know binary data from.
* `order`: One of wkbXDR or [wkbNDR] indicating MSB or LSB byte order resp.
"""
function toISOWKB(
    geom::AbstractGeometry,
    order::OGRwkbByteOrder = wkbNDR,
)::Vector{Cuchar}
    buffer = Array{Cuchar}(undef, wkbsize(geom))
    result = GDAL.ogr_g_exporttoisowkb(geom.ptr, order, buffer)
    @ogrerr result "Failed to export geometry to ISO WKB"
    return buffer
end

"""
    wkbsize(geom::AbstractGeometry)

Returns size (in bytes) of related binary representation.
"""
wkbsize(geom::AbstractGeometry)::Integer = GDAL.ogr_g_wkbsize(geom.ptr)

"""
    toWKT(geom::AbstractGeometry)

Convert a geometry into well known text format.
"""
function toWKT(geom::AbstractGeometry)::String
    wkt_ptr = Ref(Cstring(C_NULL))
    result = GDAL.ogr_g_exporttowkt(geom.ptr, wkt_ptr)
    @ogrerr result "OGRErr $result: failed to export geometry to WKT"
    wkt = unsafe_string(wkt_ptr[])
    GDAL.vsifree(pointer(wkt_ptr[]))
    return wkt
end

"""
    toISOWKT(geom::AbstractGeometry)

Convert a geometry into SFSQL 1.2 / ISO SQL/MM Part 3 well known text format.
"""
function toISOWKT(geom::AbstractGeometry)::String
    isowkt_ptr = Ref(Cstring(C_NULL))
    result = GDAL.ogr_g_exporttoisowkt(geom.ptr, isowkt_ptr)
    @ogrerr result "OGRErr $result: failed to export geometry to ISOWKT"
    wkt = unsafe_string(isowkt_ptr[])
    GDAL.vsifree(pointer(isowkt_ptr[]))
    return wkt
end

"""
    getgeomtype(geom::AbstractGeometry)

Fetch geometry type code
"""
getgeomtype(geom::AbstractGeometry)::OGRwkbGeometryType = _geomtype(geom)

"""
    geomname(geom::AbstractGeometry)

Fetch WKT name for geometry type.
"""
function geomname(geom::AbstractGeometry)::Union{String,Missing}
    return if geom.ptr == C_NULL
        missing
    else
        GDAL.ogr_g_getgeometryname(geom.ptr)
    end
end

"""
    flattento2d!(geom::AbstractGeometry)

Convert geometry to strictly 2D.
"""
function flattento2d!(geom::G)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_flattento2d(geom.ptr)
    return geom
end

"""
    closerings!(geom::AbstractGeometry)

Force rings to be closed.

If this geometry, or any contained geometries has polygon rings that are not
closed, they will be closed by adding the starting point at the end.
"""
function closerings!(geom::G)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_closerings(geom.ptr)
    return geom
end

"""
    fromGML(data)

Create geometry from GML.

This method translates a fragment of GML containing only the geometry portion
into a corresponding OGRGeometry. There are many limitations on the forms of GML
geometries supported by this parser, but they are too numerous to list here.

The following GML2 elements are parsed : Point, LineString, Polygon, MultiPoint,
MultiLineString, MultiPolygon, MultiGeometry.
"""
fromGML(data)::IGeometry = IGeometry(GDAL.ogr_g_createfromgml(data))

unsafe_fromGML(data)::Geometry = Geometry(GDAL.ogr_g_createfromgml(data))

"""
    toGML(geom::AbstractGeometry)

Convert a geometry into GML format.
"""
toGML(geom::AbstractGeometry)::String = GDAL.ogr_g_exporttogml(geom.ptr)

"""
    toKML(geom::AbstractGeometry, altitudemode = C_NULL)

Convert a geometry into KML format.
"""
toKML(geom::AbstractGeometry, altitudemode = C_NULL)::String =
    GDAL.ogr_g_exporttokml(geom.ptr, altitudemode)
# ↑ * `altitudemode`: value to write in altitudeMode element, or NULL.

"""
    toJSON(geom::AbstractGeometry; kwargs...)

Convert a geometry into GeoJSON format.

 * The following options are supported :
 * `COORDINATE_PRECISION=number`: maximum number of figures after decimal
    separator to write in coordinates.
 * `SIGNIFICANT_FIGURES=number`: maximum number of significant figures.
 *
 * If COORDINATE_PRECISION is defined, SIGNIFICANT_FIGURES will be ignored if
 * specified.
 * When none are defined, the default is COORDINATE_PRECISION=15.

### Parameters
* `geom`: handle to the geometry.

### Returns
A GeoJSON fragment or NULL in case of error.
"""
toJSON(geom::AbstractGeometry; kwargs...)::String =
    GDAL.ogr_g_exporttojsonex(geom.ptr, String["$k=$v" for (k, v) in kwargs])

toJSON(geom::AbstractGeometry, options::Vector{String})::String =
    GDAL.ogr_g_exporttojsonex(geom.ptr, options)

"""
    fromJSON(data::String)

Create a geometry object from its GeoJSON representation.
"""
fromJSON(data::String)::IGeometry =
    IGeometry(GDAL.ogr_g_creategeometryfromjson(data))

unsafe_fromJSON(data::String)::Geometry =
    Geometry(GDAL.ogr_g_creategeometryfromjson(data))

# """
# Assign spatial reference to this object.

# Any existing spatial reference is replaced, but under no circumstances
# does this result in the object being reprojected. It is just changing
# the interpretation of the existing geometry. Note that assigning a
# spatial reference increments the reference count on the
# OGRSpatialReference, but does not copy it.

# Starting with GDAL 2.3, this will also assign the spatial reference to
# potential sub-geometries of the geometry (OGRGeometryCollection,
# OGRCurvePolygon/OGRPolygon, OGRCompoundCurve, OGRPolyhedralSurface and
# their derived classes).
# """
# function setspatialref!(geom::Geometry, spatialref::AbstractSpatialRef)
#     GDAL.assignspatialreference(geom.ptr, spatialref.ptr)
#     return geom
# end

"""
    getspatialref(geom::AbstractGeometry)

Returns a clone of the spatial reference system for the geometry.

(The original SRS may be shared with many objects, and should not be modified.)
"""
function getspatialref(geom::AbstractGeometry)::ISpatialRef
    if geom.ptr == C_NULL
        return ISpatialRef()
    end
    result = GDAL.ogr_g_getspatialreference(geom.ptr)
    return if result == C_NULL
        ISpatialRef()
    else
        ISpatialRef(GDAL.osrclone(result))
    end
end

function unsafe_getspatialref(geom::AbstractGeometry)::SpatialRef
    if geom.ptr == C_NULL
        return SpatialRef()
    end
    result = GDAL.ogr_g_getspatialreference(geom.ptr)
    return if result == C_NULL
        SpatialRef()
    else
        SpatialRef(GDAL.osrclone(result))
    end
end

"""
    transform!(geom::AbstractGeometry, coordtransform::CoordTransform)

Apply arbitrary coordinate transformation to geometry.

### Parameters
* `geom`: handle on the geometry to apply the transform to.
* `coordtransform`: handle on the transformation to apply.
"""
function transform!(
    geom::G,
    coordtransform::CoordTransform,
)::G where {G<:AbstractGeometry}
    result = GDAL.ogr_g_transform(geom.ptr, coordtransform.ptr)
    @ogrerr result "Failed to transform geometry"
    return geom
end

# """
# Transform geometry to new spatial reference system.

# This function will transform the coordinates of a geometry from their
# current spatial reference system to a new target spatial reference
# system. Normally this means reprojecting the vectors, but it could
# include datum shifts, and changes of units.

# This function will only work if the geometry already has an assigned
# spatial reference system, and if it is transformable to the target
# coordinate system.

# Because this function requires internal creation and initialization of
# an OGRCoordinateTransformation object it is significantly more
# expensive to use this function to transform many geometries than it is
# to create the OGRCoordinateTransformation in advance, and call
# transform() with that transformation. This function exists primarily
# for convenience when only transforming a single geometry.

# ### Parameters
# * `geom`: handle on the geometry to apply the transformation.
# * `spatialref`: Target spatial reference system.
# """
# function transform!(geom::AbstractGeometry, spatialref::AbstractSpatialRef)
#     result = GDAL.ogr_g_transformto(geom.ptr, spatialref.ptr)
#     @ogrerr result "Failed to transform geometry to the new SRS"
#     return geom
# end

"""
    simplify(geom::AbstractGeometry, tol::Real)

Compute a simplified geometry.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.
"""
simplify(geom::AbstractGeometry, tol::Real)::IGeometry =
    IGeometry(GDAL.ogr_g_simplify(geom.ptr, tol))

unsafe_simplify(geom::AbstractGeometry, tol::Real)::Geometry =
    Geometry(GDAL.ogr_g_simplify(geom.ptr, tol))

"""
    simplifypreservetopology(geom::AbstractGeometry, tol::Real)

Simplify the geometry while preserving topology.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.
"""
simplifypreservetopology(geom::AbstractGeometry, tol::Real)::IGeometry =
    IGeometry(GDAL.ogr_g_simplifypreservetopology(geom.ptr, tol))

unsafe_simplifypreservetopology(geom::AbstractGeometry, tol::Real)::Geometry =
    Geometry(GDAL.ogr_g_simplifypreservetopology(geom.ptr, tol))

"""
    delaunaytriangulation(geom::AbstractGeometry, tol::Real, onlyedges::Bool)

Return a Delaunay triangulation of the vertices of the geometry.

### Parameters
* `geom`: the geometry.
* `tol`: optional snapping tolerance to use for improved robustness
* `onlyedges`: if `true`, will return a MULTILINESTRING, otherwise it
    will return a GEOMETRYCOLLECTION containing triangular POLYGONs.
"""
function delaunaytriangulation(
    geom::AbstractGeometry,
    tol::Real,
    onlyedges::Bool,
)::IGeometry
    return IGeometry(GDAL.ogr_g_delaunaytriangulation(geom.ptr, tol, onlyedges))
end

function unsafe_delaunaytriangulation(
    geom::AbstractGeometry,
    tol::Real,
    onlyedges::Bool,
)::Geometry
    return Geometry(GDAL.ogr_g_delaunaytriangulation(geom.ptr, tol, onlyedges))
end

"""
    segmentize!(geom::AbstractGeometry, maxlength::Real)

Modify the geometry such it has no segment longer than the given distance.

Interpolated points will have Z and M values (if needed) set to 0. Distance
computation is performed in 2d only

### Parameters
* `geom`: the geometry to segmentize
* `maxlength`: the maximum distance between 2 points after segmentization
"""
function segmentize!(geom::G, maxlength::Real)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_segmentize(geom.ptr, maxlength)
    return geom
end

"""
    intersects(g1::AbstractGeometry, g2::AbstractGeometry)

Returns whether the geometries intersect

Determines whether two geometries intersect. If GEOS is enabled, then this is
done in rigorous fashion otherwise `true` is returned if the envelopes (bounding
boxes) of the two geometries overlap.
"""
intersects(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_intersects(g1.ptr, g2.ptr))

"""
    equals(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if the geometries are equivalent.
"""
equals(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_equals(g1.ptr, g2.ptr))

"""
    disjoint(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if the geometries are disjoint.
"""
disjoint(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_disjoint(g1.ptr, g2.ptr))

"""
    touches(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if the geometries are touching.
"""
touches(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_touches(g1.ptr, g2.ptr))

"""
    crosses(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if the geometries are crossing.
"""
crosses(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_crosses(g1.ptr, g2.ptr))

"""
    within(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if g1 is contained within g2.
"""
within(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_within(g1.ptr, g2.ptr))

"""
    contains(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if g1 contains g2.
"""
contains(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_contains(g1.ptr, g2.ptr))

"""
    overlaps(g1::AbstractGeometry, g2::AbstractGeometry)

Returns `true` if the geometries overlap.
"""
overlaps(g1::AbstractGeometry, g2::AbstractGeometry)::Bool =
    Bool(GDAL.ogr_g_overlaps(g1.ptr, g2.ptr))

"""
    boundary(geom::AbstractGeometry)

Returns the boundary of the geometry.

A new geometry object is created and returned containing the boundary of the
geometry on which the method is invoked.
"""
boundary(geom::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_boundary(geom.ptr))

unsafe_boundary(geom::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_boundary(geom.ptr))

"""
    convexhull(geom::AbstractGeometry)

Returns the convex hull of the geometry.

A new geometry object is created and returned containing the convex hull of the
geometry on which the method is invoked.
"""
convexhull(geom::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_convexhull(geom.ptr))

unsafe_convexhull(geom::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_convexhull(geom.ptr))

"""
    buffer(geom::AbstractGeometry, dist::Real, quadsegs::Integer = 30)

Compute buffer of geometry.

Builds a new geometry containing the buffer region around the geometry on which
it is invoked. The buffer is a polygon containing the region within the buffer
distance of the original geometry.

Some buffer sections are properly described as curves, but are converted to
approximate polygons. The nQuadSegs parameter can be used to control how many
segments should be used to define a 90 degree curve - a quadrant of a circle.
A value of 30 is a reasonable default. Large values result in large numbers of
vertices in the resulting buffer geometry while small numbers reduce the
accuracy of the result.

### Parameters
* `geom`: the geometry.
* `dist`: the buffer distance to be applied. Should be expressed into the
    same unit as the coordinates of the geometry.
* `quadsegs`: the number of segments used to approximate a 90 degree
    (quadrant) of curvature.
"""
buffer(geom::AbstractGeometry, dist::Real, quadsegs::Integer = 30)::IGeometry =
    IGeometry(GDAL.ogr_g_buffer(geom.ptr, dist, quadsegs))

function unsafe_buffer(
    geom::AbstractGeometry,
    dist::Real,
    quadsegs::Integer = 30,
)::Geometry
    return Geometry(GDAL.ogr_g_buffer(geom.ptr, dist, quadsegs))
end

"""
    intersection(g1::AbstractGeometry, g2::AbstractGeometry)

Returns a new geometry representing the intersection of the geometries, or NULL
if there is no intersection or an error occurs.

Generates a new geometry which is the region of intersection of the two
geometries operated on. The OGR_G_Intersects() function can be used to test if
two geometries intersect.
"""
intersection(g1::AbstractGeometry, g2::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_intersection(g1.ptr, g2.ptr))

unsafe_intersection(g1::AbstractGeometry, g2::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_intersection(g1.ptr, g2.ptr))

"""
    union(g1::AbstractGeometry, g2::AbstractGeometry)

Returns a new geometry representing the union of the geometries.
"""
union(g1::AbstractGeometry, g2::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_union(g1.ptr, g2.ptr))

unsafe_union(g1::AbstractGeometry, g2::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_union(g1.ptr, g2.ptr))

"""
    pointonsurface(geom::AbstractGeometry)

Returns a point guaranteed to lie on the surface.

This method relates to the SFCOM ISurface::get_PointOnSurface() method however
the current implementation based on GEOS can operate on other geometry types
than the types that are supported by SQL/MM-Part 3 : surfaces (polygons) and
multisurfaces (multipolygons).
"""
pointonsurface(geom::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_pointonsurface(geom.ptr))

unsafe_pointonsurface(geom::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_pointonsurface(geom.ptr))

"""
    difference(g1::AbstractGeometry, g2::AbstractGeometry)

Generates a new geometry which is the region of this geometry with the region of
the other geometry removed.

### Returns
A new geometry representing the difference of the geometries, or NULL
if the difference is empty.
"""
difference(g1::AbstractGeometry, g2::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_difference(g1.ptr, g2.ptr))

unsafe_difference(g1::AbstractGeometry, g2::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_difference(g1.ptr, g2.ptr))

"""
    symdifference(g1::AbstractGeometry, g2::AbstractGeometry)

Returns a new geometry representing the symmetric difference of the geometries
or NULL if the difference is empty or an error occurs.
"""
symdifference(g1::AbstractGeometry, g2::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_symdifference(g1.ptr, g2.ptr))

unsafe_symdifference(g1::AbstractGeometry, g2::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_symdifference(g1.ptr, g2.ptr))

"""
    distance(g1::AbstractGeometry, g2::AbstractGeometry)

Returns the distance between the geometries or -1 if an error occurs.
"""
distance(g1::AbstractGeometry, g2::AbstractGeometry)::Float64 =
    GDAL.ogr_g_distance(g1.ptr, g2.ptr)

"""
    geomlength(geom::AbstractGeometry)

Returns the length of the geometry, or 0.0 for unsupported geometry types.
"""
geomlength(geom::AbstractGeometry)::Float64 = GDAL.ogr_g_length(geom.ptr)

"""
    geomarea(geom::AbstractGeometry)

Returns the area of the geometry or 0.0 for unsupported geometry types.
"""
geomarea(geom::AbstractGeometry)::Float64 = GDAL.ogr_g_area(geom.ptr)

"""
    centroid!(geom::AbstractGeometry, centroid::AbstractGeometry)

Compute the geometry centroid.

The centroid location is applied to the passed in OGRPoint object. The centroid
is not necessarily within the geometry.

This method relates to the SFCOM ISurface::get_Centroid() method however the
current implementation based on GEOS can operate on other geometry types such as
multipoint, linestring, geometrycollection such as multipolygons. OGC SF SQL 1.1
defines the operation for surfaces (polygons). SQL/MM-Part 3 defines the
operation for surfaces and multisurfaces (multipolygons).
"""
function centroid!(
    geom::AbstractGeometry,
    centroid::G,
)::G where {G<:AbstractGeometry}
    result = GDAL.ogr_g_centroid(geom.ptr, centroid.ptr)
    @ogrerr result "Failed to compute the geometry centroid"
    return centroid
end

"""
    centroid(geom::AbstractGeometry)

Compute the geometry centroid.

The centroid is not necessarily within the geometry.

(This method relates to the SFCOM ISurface::get_Centroid() method however the
current implementation based on GEOS can operate on other geometry types such as
multipoint, linestring, geometrycollection such as multipolygons. OGC SF SQL 1.1
defines the operation for surfaces (polygons). SQL/MM-Part 3 defines the
operation for surfaces and multisurfaces (multipolygons).)
"""
function centroid(geom::AbstractGeometry)::IGeometry
    point = createpoint()
    centroid!(geom, point)
    return point
end

function unsafe_centroid(geom::AbstractGeometry)::Geometry
    point = unsafe_createpoint()
    centroid!(geom, point)
    return point
end

"""
    pointalongline(geom::AbstractGeometry, distance::Real)

Fetch point at given distance along curve.

### Parameters
* `geom`: curve geometry.
* `distance`: distance along the curve at which to sample position. This
    distance should be between zero and geomlength() for this curve.

### Returns
a point or NULL.
"""
pointalongline(geom::AbstractGeometry, distance::Real)::IGeometry =
    IGeometry(GDAL.ogr_g_value(geom.ptr, distance))

unsafe_pointalongline(geom::AbstractGeometry, distance::Real)::Geometry =
    Geometry(GDAL.ogr_g_value(geom.ptr, distance))

"""
    empty!(geom::AbstractGeometry)

Clear geometry information.

This restores the geometry to its initial state after construction, and before
assignment of actual geometry.
"""
function empty!(geom::G)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_empty(geom.ptr)
    return geom
end

"""
    isempty(geom::AbstractGeometry)

Returns `true` if the geometry has no points, otherwise `false`.
"""
isempty(geom::AbstractGeometry)::Bool = Bool(GDAL.ogr_g_isempty(geom.ptr))

"""
    isvalid(geom::AbstractGeometry)

Returns `true` if the geometry is valid, otherwise `false`.
"""
isvalid(geom::AbstractGeometry)::Bool = Bool(GDAL.ogr_g_isvalid(geom.ptr))

"""
    issimple(geom::AbstractGeometry)

Returns `true` if the geometry is simple, otherwise `false`.
"""
issimple(geom::AbstractGeometry)::Bool = Bool(GDAL.ogr_g_issimple(geom.ptr))

"""
    isring(geom::AbstractGeometry)

Returns `true` if the geometry is a ring, otherwise `false`.
"""
isring(geom::AbstractGeometry)::Bool = Bool(GDAL.ogr_g_isring(geom.ptr))

"""
    polygonize(geom::AbstractGeometry)

Polygonizes a set of sparse edges.

A new geometry object is created and returned containing a collection of
reassembled Polygons: NULL will be returned if the input collection doesn't
correspond to a MultiLinestring, or when reassembling Edges into Polygons is
impossible due to topological inconsistencies.
"""
polygonize(geom::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_polygonize(geom.ptr))

unsafe_polygonize(geom::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_polygonize(geom.ptr))

# """
#     OGR_G_GetPoints(OGRGeometryH hGeom,
#                     void * pabyX,
#                     int nXStride,
#                     void * pabyY,
#                     int nYStride,
#                     void * pabyZ,
#                     int nZStride) -> int
# Returns all points of line string.
# ### Parameters
# * `hGeom`: handle to the geometry from which to get the coordinates.
# * `pabyX`: a buffer of at least (sizeof(double) * nXStride * nPointCount)
# bytes, may be NULL.
# * `nXStride`: the number of bytes between 2 elements of pabyX.
# * `pabyY`: a buffer of at least (sizeof(double) * nYStride * nPointCount)
# bytes, may be NULL.
# * `nYStride`: the number of bytes between 2 elements of pabyY.
# * `pabyZ`: a buffer of at last size (sizeof(double) * nZStride * nPointCount)
# bytes, may be NULL.
# * `nZStride`: the number of bytes between 2 elements of pabyZ.
# ### Returns
# the number of points
# """
# function getpoints(hGeom::Ptr{OGRGeometryH},pabyX,nXStride::Integer,pabyY,
# nYStride::Integer,pabyZ,nZStride::Integer)
#     ccall((:OGR_G_GetPoints,libgdal),Cint,(Ptr{OGRGeometryH},Ptr{Cvoid},Cint,
# Ptr{Cvoid},Cint,Ptr{Cvoid},Cint),hGeom,pabyX,nXStride,pabyY,nYStride,pabyZ,
# nZStride)
# end

"""
    getx(geom::AbstractGeometry, i::Integer)

Fetch the x coordinate of a point from a geometry, at index i.
"""
getx(geom::AbstractGeometry, i::Integer)::Float64 = GDAL.ogr_g_getx(geom.ptr, i)

"""
    gety(geom::AbstractGeometry, i::Integer)

Fetch the y coordinate of a point from a geometry, at index i.
"""
gety(geom::AbstractGeometry, i::Integer)::Float64 = GDAL.ogr_g_gety(geom.ptr, i)

"""
    getz(geom::AbstractGeometry, i::Integer)

Fetch the z coordinate of a point from a geometry, at index i.
"""
getz(geom::AbstractGeometry, i::Integer)::Float64 = GDAL.ogr_g_getz(geom.ptr, i)

"""
    getpoint(geom::AbstractGeometry, i::Integer)

Fetch a point in line string or a point geometry, at index i.

### Parameters
* `i`: the vertex to fetch, from 0 to getNumPoints()-1, zero for a point.
"""
getpoint(geom::AbstractGeometry, i::Integer)::Tuple{Float64,Float64,Float64} =
    getpoint!(geom, i, Ref{Float64}(), Ref{Float64}(), Ref{Float64}())

function getpoint!(geom::AbstractGeometry, i::Integer, x, y, z)
    GDAL.ogr_g_getpoint(geom.ptr, i, x, y, z)
    return (x[], y[], z[])
end

"""
    setpointcount!(geom::AbstractGeometry, n::Integer)

Set number of points in a geometry.

### Parameters
* `geom`: the geometry.
* `n`: the new number of points for geometry.
"""
function setpointcount!(geom::G, n::Integer)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_setpointcount(geom.ptr, n)
    return geom
end

"""
    setpoint!(geom::AbstractGeometry, i::Integer, x, y)
    setpoint!(geom::AbstractGeometry, i::Integer, x, y, z)

Set the location of a vertex in a point or linestring geometry.

### Parameters
* `geom`: handle to the geometry to add a vertex to.
* `i`: the index of the vertex to assign (zero based) or zero for a point.
* `x`: input X coordinate to assign.
* `y`: input Y coordinate to assign.
* `z`: input Z coordinate to assign (defaults to zero).
"""
function setpoint! end

function setpoint!(
    geom::G,
    i::Integer,
    x::Real,
    y::Real,
    z::Real,
)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_setpoint(geom.ptr, i, x, y, z)
    return geom
end

function setpoint!(
    geom::G,
    i::Integer,
    x::Real,
    y::Real,
)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_setpoint_2d(geom.ptr, i, x, y)
    return geom
end

"""
    addpoint!(geom::AbstractGeometry, x, y)
    addpoint!(geom::AbstractGeometry, x, y, z)

Add a point to a geometry (line string or point).

### Parameters
* `geom`: the geometry to add a point to.
* `x`: x coordinate of point to add.
* `y`: y coordinate of point to add.
* `z`: z coordinate of point to add.
"""
function addpoint! end

function addpoint!(
    geom::G,
    x::Real,
    y::Real,
    z::Real,
)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_addpoint(geom.ptr, x, y, z)
    return geom
end

function addpoint!(geom::G, x::Real, y::Real)::G where {G<:AbstractGeometry}
    GDAL.ogr_g_addpoint_2d(geom.ptr, x, y)
    return geom
end

# """
#     OGR_G_SetPoints(OGRGeometryH hGeom,
#                     int nPointsIn,
#                     void * pabyX,
#                     int nXStride,
#                     void * pabyY,
#                     int nYStride,
#                     void * pabyZ,
#                     int nZStride) -> void
# Assign all points in a point or a line string geometry.
# ### Parameters
# * `hGeom`: handle to the geometry to set the coordinates.
# * `nPointsIn`: number of points being passed in padfX and padfY.
# * `pabyX`: list of X coordinates (double values) of points being assigned.
# * `nXStride`: the number of bytes between 2 elements of pabyX.
# * `pabyY`: list of Y coordinates (double values) of points being assigned.
# * `nYStride`: the number of bytes between 2 elements of pabyY.
# * `pabyZ`: list of Z coordinates (double values) of points being assigned
# (defaults to NULL for 2D objects).
# * `nZStride`: the number of bytes between 2 elements of pabyZ.
# """
# function setpoints(hGeom::Ptr{OGRGeometryH},nPointsIn::Integer,pabyX,
# nXStride::Integer,pabyY,nYStride::Integer,pabyZ,nZStride::Integer)
#     ccall((:OGR_G_SetPoints,libgdal),Void,(Ptr{OGRGeometryH},Cint,Ptr{Cvoid},
# Cint,Ptr{Cvoid},Cint,Ptr{Cvoid},Cint),hGeom,nPointsIn,pabyX,nXStride,pabyY,
# nYStride,pabyZ,nZStride)
# end

"""
    ngeom(geom::AbstractGeometry)

The number of elements in a geometry or number of geometries in container.

This corresponds to

* `OGR_G_GetPointCount` for wkbPoint[25D] or wkbLineString[25D],
* `OGR_G_GetGeometryCount` for geometries of type wkbPolygon[25D],
    wkbMultiPoint[25D], wkbMultiLineString[25D], wkbMultiPolygon[25D] or
    wkbGeometryCollection[25D], and
* `0` for other geometry types.
"""
function ngeom(geom::AbstractGeometry)::Integer
    n = GDAL.ogr_g_getpointcount(geom.ptr)
    return n == 0 ? GDAL.ogr_g_getgeometrycount(geom.ptr) : n
end

"""
    getgeom(geom::AbstractGeometry, i::Integer)

Fetch geometry from a geometry container.

For a polygon, `getgeom(polygon,i)` returns the exterior ring if
`i == 0`, and the interior rings for `i > 0`.

### Parameters
* `geom`: the geometry container from which to get a geometry from.
* `i`: index of the geometry to fetch, between 0 and getNumGeometries() - 1.
"""
function getgeom(geom::AbstractGeometry, i::Integer)::IGeometry
    # NOTE(yeesian): GDAL.ogr_g_getgeometryref(geom, i) returns an handle to a
    # geometry within the container. The returned geometry remains owned by the
    # container, and should not be modified. The handle is only valid until the
    # next change to the geometry container. Use OGR_G_Clone() to make a copy.
    if geom.ptr == C_NULL
        return IGeometry()
    end
    result = GDAL.ogr_g_getgeometryref(geom.ptr, i)
    if result == C_NULL
        return IGeometry()
    else
        return IGeometry(GDAL.ogr_g_clone(result))
    end
end

function unsafe_getgeom(geom::AbstractGeometry, i::Integer)::Geometry
    # NOTE(yeesian): GDAL.ogr_g_getgeometryref(geom, i) returns an handle to a
    # geometry within the container. The returned geometry remains owned by the
    # container, and should not be modified. The handle is only valid until the
    # next change to the geometry container. Use OGR_G_Clone() to make a copy.
    if geom.ptr == C_NULL
        return Geometry()
    end
    result = GDAL.ogr_g_getgeometryref(geom.ptr, i)
    if result == C_NULL
        return Geometry()
    else
        return Geometry(GDAL.ogr_g_clone(result))
    end
end

"""
    addgeom!(geomcontainer::AbstractGeometry, subgeom::AbstractGeometry)

Add a geometry to a geometry container.

Some subclasses of OGRGeometryCollection restrict the types of geometry that can
be added, and may return an error. The passed geometry is cloned to make an
internal copy.

For a polygon, `subgeom` must be a linearring. If the polygon is empty, the
first added subgeometry will be the exterior ring. The next ones will be the
interior rings.

### Parameters
* `geomcontainer`: existing geometry.
* `subgeom`: geometry to add to the existing geometry.
"""
function addgeom!(
    geomcontainer::G,
    subgeom::AbstractGeometry,
)::G where {G<:AbstractGeometry}
    result = GDAL.ogr_g_addgeometry(geomcontainer.ptr, subgeom.ptr)
    @ogrerr result "Failed to add geometry. The geometry type could be illegal"
    return geomcontainer
end

# """
# Add a geometry directly to an existing geometry container.

# Some subclasses of OGRGeometryCollection restrict the types of geometry that can
# be added, and may return an error. Ownership of the passed geometry is taken by
# the container rather than cloning as addGeometry() does.

# For a polygon, hNewSubGeom must be a linearring. If the polygon is empty, the
# first added subgeometry will be the exterior ring. The next ones will be the
# interior rings.

# ### Parameters
# * `geomcontainer`: existing geometry.
# * `subgeom`: geometry to add to the existing geometry.
# """
# function addgeomdirectly!(
#         geomcontainer::AbstractGeometry,
#         subgeom::AbstractGeometry
#     )
#     result = GDAL.ogr_g_addgeometrydirectly(geomcontainer.ptr, subgeom.ptr)
#     @ogrerr result "Failed to add geometry. The geometry type could be illegal"
#     return geomcontainer
# end

"""
    removegeom!(geom::AbstractGeometry, i::Integer, todelete::Bool = true)

Remove a geometry from an exiting geometry container.

### Parameters
* `geom`: the existing geometry to delete from.
* `i`: the index of the geometry to delete. A value of -1 is a special flag
    meaning that all geometries should be removed.
* `todelete`: if `true` the geometry will be destroyed, otherwise it will not.
    The default is `true` as the existing geometry is considered to own the
    geometries in it.
"""
function removegeom!(
    geom::G,
    i::Integer,
    todelete::Bool = true,
)::G where {G<:AbstractGeometry}
    result = GDAL.ogr_g_removegeometry(geom.ptr, i, todelete)
    @ogrerr result "Failed to remove geometry. The index could be out of range."
    return geom
end

"""
    removeallgeoms!(geom::AbstractGeometry, todelete::Bool = true)

Remove all geometries from an exiting geometry container.

### Parameters
* `geom`: the existing geometry to delete from.
* `todelete`: if `true` the geometry will be destroyed, otherwise it will not.
    The default is `true` as the existing geometry is considered to own the
    geometries in it.
"""
function removeallgeoms!(
    geom::G,
    todelete::Bool = true,
)::G where {G<:AbstractGeometry}
    result = GDAL.ogr_g_removegeometry(geom.ptr, -1, todelete)
    @ogrerr result "Failed to remove all geometries."
    return geom
end

"""
    hascurvegeom(geom::AbstractGeometry, nonlinear::Bool)

Returns if this geometry is or has curve geometry.

### Parameters
* `geom`: the geometry to operate on.
* `nonlinear`: set it to `true` to check if the geometry is or contains a
    CIRCULARSTRING.
"""
hascurvegeom(geom::AbstractGeometry, nonlinear::Bool)::Bool =
    Bool(GDAL.ogr_g_hascurvegeometry(geom.ptr, nonlinear))

"""
    lineargeom(geom::AbstractGeometry, stepsize::Real = 0)

Return, possibly approximate, linear version of this geometry.

Returns a geometry that has no CIRCULARSTRING, COMPOUNDCURVE, CURVEPOLYGON,
MULTICURVE or MULTISURFACE in it, by approximating curve geometries.

### Parameters
* `geom`: the geometry to operate on.
* `stepsize`: the largest step in degrees along the arc, zero to use the
    default setting.
* `options`: options as a null-terminated list of strings or NULL.
    See OGRGeometryFactory::curveToLineString() for valid options.
"""

function lineargeom(
    geom::AbstractGeometry,
    stepsize::Real = 0;
    kwargs...,
)::IGeometry
    return lineargeom(geom, String["$k=$v" for (k, v) in kwargs], stepsize)
end

function unsafe_lineargeom(
    geom::AbstractGeometry,
    stepsize::Real = 0;
    kwargs...,
)::Geometry
    return unsafe_lineargeom(
        geom,
        String["$k=$v" for (k, v) in kwargs],
        stepsize,
    )
end

function lineargeom(
    geom::AbstractGeometry,
    options::Vector{String},
    stepsize::Real = 0,
)::IGeometry
    return IGeometry(GDAL.ogr_g_getlineargeometry(geom.ptr, stepsize, options))
end

function unsafe_lineargeom(
    geom::AbstractGeometry,
    options::Vector{String},
    stepsize::Real = 0,
)::Geometry
    return Geometry(GDAL.ogr_g_getlineargeometry(geom.ptr, stepsize, options))
end

"""
    curvegeom(geom::AbstractGeometry)

Return curve version of this geometry.

Returns a geometry that has possibly CIRCULARSTRING, COMPOUNDCURVE,
CURVEPOLYGON, MULTICURVE or MULTISURFACE in it, by de-approximating linear into
curve geometries.

If the geometry has no curve portion, the returned geometry will be a clone.

The reverse function is OGR_G_GetLinearGeometry().
"""
curvegeom(geom::AbstractGeometry)::IGeometry =
    IGeometry(GDAL.ogr_g_getcurvegeometry(geom.ptr, C_NULL))

unsafe_curvegeom(geom::AbstractGeometry)::Geometry =
    Geometry(GDAL.ogr_g_getcurvegeometry(geom.ptr, C_NULL))

"""
    polygonfromedges(lines::AbstractGeometry, tol::Real; besteffort = false,
        autoclose = false)

Build a ring from a bunch of arcs.

### Parameters
* `lines`: handle to an OGRGeometryCollection (or OGRMultiLineString)
    containing the line string geometries to be built into rings.
* `tol`: whether two arcs are considered close enough to be joined.

### Keyword Arguments
* `besteffort`: (defaults to `false`) not yet implemented???.
* `autoclose`: indicates if the ring should be close when first and last
    points of the ring are the same. (defaults to `false`)
"""
function polygonfromedges(
    lines::AbstractGeometry,
    tol::Real;
    besteffort::Bool = false,
    autoclose::Bool = false,
)::IGeometry
    perr = Ref{GDAL.OGRErr}()
    result = GDAL.ogrbuildpolygonfromedges(
        lines.ptr,
        besteffort,
        autoclose,
        tol,
        perr,
    )
    @ogrerr perr[] "Failed to build polygon from edges."
    return IGeometry(result)
end

function unsafe_polygonfromedges(
    lines::AbstractGeometry,
    tol::Real;
    besteffort::Bool = false,
    autoclose::Bool = false,
)::Geometry
    perr = Ref{GDAL.OGRErr}()
    result = GDAL.ogrbuildpolygonfromedges(
        lines.ptr,
        besteffort,
        autoclose,
        tol,
        perr,
    )
    @ogrerr perr[] "Failed to build polygon from edges."
    return Geometry(result)
end

"""
    setnonlineargeomflag!(flag::Bool)

Set flag to enable/disable returning non-linear geometries in the C API.

This flag has only an effect on the OGR_F_GetGeometryRef(),
OGR_F_GetGeomFieldRef(), OGR_L_GetGeomType(), OGR_GFld_GetType() and
OGR_FD_GetGeomType() C API methods. It is meant as making it simple for
applications using the OGR C API not to have to deal with non-linear geometries,
even if such geometries might be returned by drivers. In which case, they will
be transformed into their closest linear geometry, by doing linear
approximation, with OGR_G_ForceTo().

Libraries should generally not use that method, since that could interfere with
other libraries or applications.

### Parameters
* `flag`: `true` if non-linear geometries might be returned (default value).
          `false` to ask for non-linear geometries to be approximated as linear
          geometries.

### Returns
a point or NULL.
"""
function setnonlineargeomflag!(flag::Bool)::Nothing
    GDAL.ogrsetnonlineargeometriesenabledflag(flag)
    return nothing
end

"""
    getnonlineargeomflag()

Get flag to enable/disable returning non-linear geometries in the C API.
"""
getnonlineargeomflag()::Bool = Bool(GDAL.ogrgetnonlineargeometriesenabledflag())

for (geom, wkbgeom) in (
    (:geomcollection, wkbGeometryCollection),
    (:linestring, wkbLineString),
    (:linearring, wkbLinearRing),
    (:multilinestring, wkbMultiLineString),
    (:multipoint, wkbMultiPoint),
    (:multipolygon, wkbMultiPolygon),
    (:multipolygon_noholes, wkbMultiPolygon),
    (:point, wkbPoint),
    (:polygon, wkbPolygon),
)
    eval(
        quote
            $(Symbol("create$geom"))()::IGeometry = creategeom($wkbgeom)
            $(Symbol("unsafe_create$geom"))()::Geometry =
                unsafe_creategeom($wkbgeom)
        end,
    )
end

for (f, rt) in ((:create, :IGeometry), (:unsafe_create, :Geometry))
    for (args, typedargs) in (
        ((:x, :y), (:(x::Real), :(y::Real))),
        ((:x, :y, :z), (:(x::Real), :(y::Real), :(z::Real))),
    )
        eval(quote
            function $(Symbol("$(f)point"))($(typedargs...))::$rt
                geom = $(Symbol("$(f)point"))()
                addpoint!(geom, $(args...))
                return geom
            end
        end)
    end

    for (args, typedargs) in (
        ((:xs, :ys), (:(xs::Vector{Cdouble}), :(ys::Vector{Cdouble}))),
        (
            (:xs, :ys, :zs),
            (
                :(xs::Vector{Cdouble}),
                :(ys::Vector{Cdouble}),
                :(zs::Vector{Cdouble}),
            ),
        ),
    )
        for geom in (:linestring, :linearring)
            eval(quote
                function $(Symbol("$f$geom"))($(typedargs...))::$rt
                    geom = $(Symbol("$f$geom"))()
                    for pt in zip($(args...))
                        addpoint!(geom, pt...)
                    end
                    return geom
                end
            end)
        end

        for (geom, component) in ((:polygon, :linearring),)
            eval(
                quote
                    function $(Symbol("$f$geom"))($(typedargs...))::$rt
                        geom = $(Symbol("$f$geom"))()
                        subgeom =
                            $(Symbol("unsafe_create$component"))($(args...))
                        result = GDAL.ogr_g_addgeometrydirectly(
                            geom.ptr,
                            subgeom.ptr,
                        )
                        @ogrerr result "Failed to add $component."
                        return geom
                    end
                end,
            )
        end

        for (geom, component) in ((:multipoint, :point),)
            eval(
                quote
                    function $(Symbol("$f$geom"))($(typedargs...))::$rt
                        geom = $(Symbol("$f$geom"))()
                        for pt in zip($(args...))
                            subgeom = $(Symbol("unsafe_create$component"))(pt)
                            result = GDAL.ogr_g_addgeometrydirectly(
                                geom.ptr,
                                subgeom.ptr,
                            )
                            @ogrerr result "Failed to add point."
                        end
                        return geom
                    end
                end,
            )
        end
    end

    for typeargs in
        (Vector{<:Real}, Tuple{<:Real,<:Real}, Tuple{<:Real,<:Real,<:Real})
        eval(quote
            function $(Symbol("$(f)point"))(coords::$typeargs)::$rt
                geom = $(Symbol("$(f)point"))()
                addpoint!(geom, coords...)
                return geom
            end
        end)
    end

    for typeargs in (
        Vector{Tuple{Cdouble,Cdouble}},
        Vector{Tuple{Cdouble,Cdouble,Cdouble}},
        Vector{Vector{Cdouble}},
    )
        for geom in (:linestring, :linearring)
            eval(quote
                function $(Symbol("$f$geom"))(coords::$typeargs)::$rt
                    geom = $(Symbol("$f$geom"))()
                    for coord in coords
                        addpoint!(geom, coord...)
                    end
                    return geom
                end
            end)
        end

        for (geom, component) in ((:polygon, :linearring),)
            eval(
                quote
                    function $(Symbol("$f$geom"))(coords::$typeargs)::$rt
                        geom = $(Symbol("$f$geom"))()
                        subgeom = $(Symbol("unsafe_create$component"))(coords)
                        result = GDAL.ogr_g_addgeometrydirectly(
                            geom.ptr,
                            subgeom.ptr,
                        )
                        @ogrerr result "Failed to add $component."
                        return geom
                    end
                end,
            )
        end
    end

    for (variants, typeargs) in (
        (
            ((:multipoint, :point),),
            (
                Vector{Tuple{Cdouble,Cdouble}},
                Vector{Tuple{Cdouble,Cdouble,Cdouble}},
                Vector{Vector{Cdouble}},
            ),
        ),
        (
            (
                (:polygon, :linearring),
                (:multilinestring, :linestring),
                (:multipolygon_noholes, :polygon),
            ),
            (
                Vector{Vector{Tuple{Cdouble,Cdouble}}},
                Vector{Vector{Tuple{Cdouble,Cdouble,Cdouble}}},
                Vector{Vector{Vector{Cdouble}}},
            ),
        ),
        (
            ((:multipolygon, :polygon),),
            (
                Vector{Vector{Vector{Tuple{Cdouble,Cdouble}}}},
                Vector{Vector{Vector{Tuple{Cdouble,Cdouble,Cdouble}}}},
                Vector{Vector{Vector{Vector{Cdouble}}}},
            ),
        ),
    )
        for typearg in typeargs, (geom, component) in variants
            eval(
                quote
                    function $(Symbol("$f$geom"))(coords::$typearg)::$rt
                        geom = $(Symbol("$f$geom"))()
                        for coord in coords
                            subgeom =
                                $(Symbol("unsafe_create$component"))(coord)
                            result = GDAL.ogr_g_addgeometrydirectly(
                                geom.ptr,
                                subgeom.ptr,
                            )
                            @ogrerr result "Failed to add $component."
                        end
                        return geom
                    end
                end,
            )
        end
    end
end

# Conversion from GeoInterface geometry
# TODO handle the case of geometry collections
@generated function convert(T::Type{IGeometry}, g::U) where U <: GeoInterface.AbstractGeometry
    if g <: IGeometry
        return :(g)
    elseif g <: GeoInterface.AbstractPoint
        return :(createpoint(GeoInterface.coordinates(g)))
    elseif g <: GeoInterface.AbstractMultiPoint
        return :(createmultipoint(GeoInterface.coordinates(g)))
    elseif g <: GeoInterface.AbstractLineString
        return :(createlinestring(GeoInterface.coordinates(g)))
    elseif g <: GeoInterface.AbstractMultiLineString
        return :(createmultilinestring(GeoInterface.coordinates(g)))
    elseif g <: GeoInterface.AbstractPolygon
        return :(createpolygon(GeoInterface.coordinates(g)))
    elseif g <: GeoInterface.AbstractMultiPolygon
        return :(createmultipolygon(GeoInterface.coordinates(g)))
    else
        return :(error("No convert method to convert $g to $T"))
    end
end

