"""
Create a geometry object of the appropriate type from it's well known
binary (WKB) representation.

### Parameters
* `data`: pointer to the input BLOB data.
* `spatialref`: handle to the spatial reference to be assigned to the created
    geometry object. This may be `NULL` (default).
"""
# * `nBytes`: the number of bytes of data available in pabyData, or -1 if
#     it is not known, but assumed to be sufficient.
function unsafe_fromWKB(data, spatialref::SpatialRef=SpatialRef(C_NULL))
    geom = Ref{Geometry}()
    result = ccall((:OGR_G_CreateFromWkb,GDAL.libgdal),GDAL.OGRErr,(Ptr{Cuchar},
                    SpatialRef,Ptr{Geometry},Cint),data, spatialref, geom,
                    sizeof(data))
    @ogrerr result "Failed to create geometry from WKB"
    (geom[] == C_NULL) && error("Failed to create geometry from WKB")
    geom[]
end

"""
Create a geometry object of the appropriate type from its well known text
(WKT) representation.

### Parameters
* `data`: input zero terminated string containing WKT representation of the
    geometry to be created. The pointer is updated to point just beyond that
    last character consumed.
* `spatialref`: handle to the spatial reference to be assigned to the created
    geometry object. This may be `NULL` (default).
"""
function unsafe_fromWKT{T <: AbstractString}(data::Vector{T},
                        spatialref::SpatialRef=SpatialRef(C_NULL))
    geom = Ref{Geometry}()
    result = ccall((:OGR_G_CreateFromWkt,GDAL.libgdal),GDAL.OGRErr,
                   (Ptr{Ptr{UInt8}},SpatialRef,Ptr{Geometry}),data,spatialref,
                   geom)
    @ogrerr result "Failed to create geometry from WKT"
    (geom[] == C_NULL) && error("Failed to create geometry from WKT")
    geom[]
end

# potential clash with `unsafe_fromWKT` for SpatialRef averted by the second
# argument
function unsafe_fromWKT(data::AbstractString,
                        spatialref::SpatialRef=SpatialRef(C_NULL))
    geom = Ref{Geometry}()
    result = ccall((:OGR_G_CreateFromWkt,GDAL.libgdal),GDAL.OGRErr,
                   (Ptr{Ptr{UInt8}},SpatialRef,Ptr{Geometry}),[data],spatialref,
                   geom)
    @ogrerr result "Failed to create geometry from WKT"
    (geom[] == C_NULL) && error("Failed to create geometry from WKT")
    geom[]
end

"""
Destroy geometry object.

Equivalent to invoking delete on a geometry, but it guaranteed to take place
within the context of the GDAL/OGR heap.
"""
destroy(geom::Geometry) = GDAL.destroygeometry(geom)

"""
Create an empty geometry of desired type.

This is equivalent to allocating the desired geometry with new, but the
allocation is guaranteed to take place in the context of the GDAL/OGR heap.
"""
unsafe_creategeom(geomtype::GDAL.OGRwkbGeometryType) =
    GDAL.creategeometry(geomtype)

"""
Convert to another geometry type.

### Parameters
* `geom`: the input geometry - ownership is passed to the method.
* `targettype`: target output geometry type.
# `options`: (optional) options as a null-terminated vector of strings
"""
forceto!(geom::Geometry, targettype::GDAL.OGRwkbGeometryType) =
    GDAL.forceto(geom, targettype, C_NULL)

forceto!{T <: AbstractString}(geom::Geometry,
                              targettype::GDAL.OGRwkbGeometryType,
                              options::Vector{T}) =
    GDAL.checknull(ccall((:OGR_G_ForceTo,libgdal),Geometry,(Geometry,
        GDAL.OGRwkbGeometryType,StringList),geom,targettype,options))

"""
Get the dimension of the geometry. 0 for points, 1 for lines and 2 for surfaces.

This function corresponds to the SFCOM IGeometry::GetDimension() method. It
indicates the dimension of the geometry, but does not indicate the dimension of
the underlying space (as indicated by OGR_G_GetCoordinateDimension() function).
"""
getdim(geom::Geometry) = GDAL.getdimension(geom)

"""
Get the dimension of the coordinates in this geometry.

### Returns
In practice this will return 2 or 3. It can also return 0 in the case of an
empty point.
"""
getcoorddim(geom::Geometry) = GDAL.getcoordinatedimension(geom)

"""
Set the coordinate dimension.

This method sets the explicit coordinate dimension. Setting the coordinate
dimension of a geometry to 2 should zero out any existing Z values. Setting the
dimension of a geometry collection, a compound curve, a polygon, etc. will
affect the children geometries. This will also remove the M dimension if present
before this call.
"""
setcoorddim!(geom::Geometry, dim::Integer)=GDAL.setcoordinatedimension(geom,dim)

"""
Computes and returns the bounding envelope for this geometry

### Parameters
* `hGeom`: handle of the geometry to get envelope from.
* `psEnvelope`: the structure in which to place the results.
"""
function getenvelope(geom::Geometry)
    envelope = Ref{Envelope}()
    GDAL.getenvelope(geom, envelope)
    envelope[]
end

"""
Computes and returns the bounding envelope (3D) for this geometry

### Parameters
* `hGeom`: handle of the geometry to get envelope from.
"""
function getenvelope3d(geom::Geometry)
    envelope = Ref{Envelope3D}()
    GDAL.getenvelope3d(geom, envelope)
    envelope[]
end

"""
Convert a geometry well known binary format.
### Parameters
* `geom`: handle on the geometry to convert to a well know binary data from.
* `order`: One of wkbXDR or [wkbNDR] indicating MSB or LSB byte order resp.
"""
# * `pabyDstBuffer`: a buffer into which the binary representation is written.
#     This buffer must be at least OGR_G_WkbSize() byte in size.
function toWKB(geom::Geometry, order::GDAL.OGRwkbByteOrder = GDAL.wkbNDR)
    buffer = Array(Cuchar, wkbsize(geom))
    result = GDAL.exporttowkb(geom, order, pointer(buffer))
    @ogrerr result "Failed to export geometry to WKB"
    buffer
end

"""
Convert a geometry into SFSQL 1.2 / ISO SQL/MM Part 3 well known binary format.
### Parameters
* `geom`: handle on the geometry to convert to a well know binary data from.
* `order`: One of wkbXDR or [wkbNDR] indicating MSB or LSB byte order resp.
"""
# * `pabyDstBuffer`: a buffer into which the binary representation is written.
#                 This buffer must be at least OGR_G_WkbSize() byte in size.
function toISOWKB(geom::Geometry, order::GDAL.OGRwkbByteOrder = GDAL.wkbNDR)
    buffer = Array(Cuchar, wkbsize(geom))
    result = GDAL.exporttoisowkb(geom, order, pointer(buffer))
    @ogrerr result "Failed to export geometry to ISO WKB"
    buffer
end

"Returns size (in bytes) of related binary representation."
wkbsize(geom::Geometry) = GDAL.wkbsize(geom)

"Convert a geometry into well known text format."
function toWKT(geom::Geometry)
    wkt_ptr = Ref{Cstring}()
    result = GDAL.exporttowkt(geom, wkt_ptr)
    @ogrerr result "OGRErr $result: failed to export geometry to WKT"
    wkt = bytestring(wkt_ptr[])
    GDAL.C.OGRFree(Ptr{UInt8}(wkt_ptr[]))
    wkt
end

"Convert a geometry into SFSQL 1.2 / ISO SQL/MM Part 3 well known text format."
function toISOWKT(geom::Geometry)
    isowkt_ptr = Ref{Cstring}()
    result = GDAL.exporttoisowkt(point, result)
    @ogrerr result "OGRErr $result: failed to export geometry to ISOWKT"
    wkt = bytestring(isowkt_ptr[])
    GDAL.C.OGRFree(Ptr{UInt8}(wkt_ptr[]))
    wkt
end

"Fetch geometry type code"
getgeomtype(geom::Geometry) = GDAL.getgeometrytype(geom)

"Fetch WKT name for geometry type."
getgeomname(geom::Geometry) = GDAL.getgeometryname(geom)

"Convert geometry to strictly 2D."
flattento2d!(geom::Geometry) = GDAL.flattento2d(geom)

"""
Force rings to be closed.

If this geometry, or any contained geometries has polygon rings that are not
closed, they will be closed by adding the starting point at the end.
"""
closerings!(geom::Geometry) = GDAL.closerings(geom)

"""
Create geometry from GML.

This method translates a fragment of GML containing only the geometry portion
into a corresponding OGRGeometry. There are many limitations on the forms of GML
geometries supported by this parser, but they are too numerous to list here.

The following GML2 elements are parsed : Point, LineString, Polygon, MultiPoint,
MultiLineString, MultiPolygon, MultiGeometry.
"""
# warning: might clash with fromGML for SpatialRefs if they exist in the future
unsafe_fromGML(data) = GDAL.createfromgml(data)

"Convert a geometry into GML format."
toGML(geom::Geometry) = GDAL.exporttogml(geom)

"Convert a geometry into KML format."
# * `altitudemode`: value to write in altitudeMode element, or NULL.
toKML(geom::Geometry) = GDAL.exporttokml(geom, Ptr{UInt8}(C_NULL))
toKML(geom::Geometry, altitudemode) = GDAL.exporttokml(geom, altitude)

"Convert a geometry into GeoJSON format."
toJSON(geom::Geometry) = GDAL.exporttojson(geom)

"""
Convert a geometry into GeoJSON format.
### Parameters
* `geom`: handle to the geometry.
* `options`: a list of options.
### Returns
A GeoJSON fragment or NULL in case of error.
"""
toJSON(geom::Geometry, options) =
    bytestring(ccall((:OGR_G_ExportToJsonEx,GDAL.libgdal), Cstring,
               (Geometry,Ptr{Ptr{UInt8}}), geom, options))

"Create a geometry object from its GeoJSON representation"
unsafe_fromJSON(data::AbstractString) = GDAL.creategeometryfromjson(data)

"Assign spatial reference to this object."
assignspatialref!(geom::Geometry, spatialref::SpatialRef) = 
    GDAL.assignspatialreference(geom, spatialref)

"""
Returns spatial reference system for geometry.

The object may be shared with many geometry objects, and should not be modified.
"""
borrow_getspatialref(geom::Geometry) = GDAL.getspatialreference(geom)

"""
Apply arbitrary coordinate transformation to geometry.

### Parameters
* `geom`: handle on the geometry to apply the transform to.
* `coordtransform`: handle on the transformation to apply.
"""
function transform!(geom::Geometry, coordtransform::CoordTransform)
    result = GDAL.transform(geom, coordtransform)
    @ogrerr result "Failed to transform geometry"
    geom
end


"Transform geometry to new spatial reference system."
function transform!(geom::Geometry, spatialref::SpatialRef)
    result = GDAL.transformto(geom, spatialref)
    @ogrerr result "Failed to transform geometry to the new SRS"
    geom
end

"""
Compute a simplified geometry.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.
"""
simplify!(geom::Geometry, tol::Real) = GDAL.simplify(geom, tol)

"""
Simplify the geometry while preserving topology.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.
"""
simplifypreservetopology!(geom::Geometry, tol::Real) =
    GDAL.simplifypreservetopology(geom, tol)

"""
Return a Delaunay triangulation of the vertices of the geometry.

### Parameters
* `geom`: the geometry.
* `tol`: optional snapping tolerance to use for improved robustness
* `onlyedges`: if TRUE, will return a MULTILINESTRING, otherwise it
    will return a GEOMETRYCOLLECTION containing triangular POLYGONs.
"""
unsafe_delaunaytriangulation(geom::Geometry, tol::Real, onlyedges::Bool) =
    GDAL.delaunaytriangulation(geom, tol, onlyedges)

"""
Modify the geometry such it has no segment longer than the given distance.

Interpolated points will have Z and M values (if needed) set to 0. Distance
computation is performed in 2d only

### Parameters
* `geom`: the geometry to segmentize
* `maxlength`: the maximum distance between 2 points after segmentization
"""
function segmentize!(geom::Geometry, maxlength::Real)
    GDAL.segmentize(geom, maxlength)
    geom
end

"""
Returns whether the geometries intersect

Determines whether two geometries intersect. If GEOS is enabled, then this is
done in rigorous fashion otherwise TRUE is returned if the envelopes (bounding
boxes) of the two geometries overlap.
"""
intersects(g1::Geometry, g2::Geometry) = Bool(GDAL.intersects(g1, g2))

"Returns TRUE if the geometries are equivalent."
equals(geom1::Geometry, geom2::Geometry) = Bool(GDAL.equals(geom1, geom2))

"Returns TRUE if the geometries are disjoint."
disjoint(geom1::Geometry, geom2::Geometry) = Bool(GDAL.disjoint(geom1, geom2))

"Returns TRUE if the geometries are touching."
touches(geom1::Geometry, geom2::Geometry) = Bool(GDAL.touches(geom1, geom2))

"Returns TRUE if the geometries are crossing."
crosses(geom1::Geometry, geom2::Geometry) = Bool(GDAL.crosses(geom1, geom2))

"Returns TRUE if geom1 is contained within geom2."
within(geom1::Geometry, geom2::Geometry) = Bool(GDAL.within(geom1, geom2))

"Returns TRUE if geom1 contains geom2."
contains(geom1::Geometry, geom2::Geometry) = Bool(GDAL.contains(geom1, geom2))

"Returns TRUE if the geometries overlap."
overlaps(geom1::Geometry, geom2::Geometry) = Bool(GDAL.overlaps(geom1, geom2))

"""
Returns the boundary of the geometry.

A new geometry object is created and returned containing the boundary of the
geometry on which the method is invoked.
"""
unsafe_boundary(geom1::Geometry, geom2::Geometry) = GDAL.boundary(geom1, geom2)

"""
Returns the convex hull of the geometry.

A new geometry object is created and returned containing the convex hull of the
geometry on which the method is invoked.
"""
unsafe_convexhull(geom::Geometry) = GDAL.convexhull(geom)

"""
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
unsafe_buffer(geom::Geometry, dist::Real, quadsegs::Integer=8) =
    GDAL.buffer(geom, dist, quadsegs)

"""
Returns a new geometry representing the intersection of the geometries, or NULL
if there is no intersection or an error occurs.

Generates a new geometry which is the region of intersection of the two
geometries operated on. The OGR_G_Intersects() function can be used to test if
two geometries intersect.
"""
unsafe_intersection(geom1::Geometry, geom2::Geometry) =
    GDAL.intersection(geom1, geom2)

"""
Returns a new geometry representing the union of the geometries.

Generates a new geometry which is the region of union of the two geometries
operated on.
"""
unsafe_union(geom1::Geometry, geom2::Geometry) = GDAL.union(geom1, geom2)

"Compute the union of the geometry using cascading."
unsafe_union(geom::Geometry) = GDAL.unioncascaded(geom)

"""
Returns a point guaranteed to lie on the surface.

This method relates to the SFCOM ISurface::get_PointOnSurface() method however
the current implementation based on GEOS can operate on other geometry types
than the types that are supported by SQL/MM-Part 3 : surfaces (polygons) and
multisurfaces (multipolygons).
"""
unsafe_pointonsurface(geom::Geometry) = GDAL.pointonsurface(geom)

"""
Generates a new geometry which is the region of this geometry with the region of
the other geometry removed.

### Returns
A new geometry representing the difference of the geometries, or NULL
if the difference is empty.
"""
unsafe_difference(geom1::Geometry, geom2::Geometry) =
    GDAL.difference(geom1, geom2)

"""
Returns a new geometry representing the symmetric difference of the geometries
or NULL if the difference is empty or an error occurs.
"""
unsafe_symdifference(g1::Geometry, g2::Geometry) = GDAL.symdifference(g1, g2)

"Returns the distance between the geometries or -1 if an error occurs."
distance(geom1::Geometry, geom2::Geometry) = GDAL.distance(geom1, geom2)

"Returns the length of the geometry, or 0.0 for unsupported geometry types."
geomlength(geom::Geometry) = GDAL.length(geom)

"Returns the area of the geometry or 0.0 for unsupported geometry types."
geomarea(geom::Geometry) = GDAL.area(geom)

"""
Compute the geometry centroid.

The centroid location is applied to the passed in OGRPoint object. The centroid
is not necessarily within the geometry.

This method relates to the SFCOM ISurface::get_Centroid() method however the
current implementation based on GEOS can operate on other geometry types such as
multipoint, linestring, geometrycollection such as multipolygons. OGC SF SQL 1.1
defines the operation for surfaces (polygons). SQL/MM-Part 3 defines the
operation for surfaces and multisurfaces (multipolygons).
"""
function centroid!(geom::Geometry, centroid::Geometry)
    result = GDAL.centroid(geom, centroid)
    @ogrerr result "Failed to compute the geometry centroid"
    centroid
end

unsafe_centroid(geom::Geometry) = centroid!(geom, unsafe_createpoint())

"""
Fetch point at given distance along curve.

### Parameters
* `geom`: curve geometry.
* `distance`: distance along the curve at which to sample position. This
    distance should be between zero and geomlength() for this curve.

### Returns
a point or NULL.
"""
unsafe_pointalongline(geom::Geometry, distance::Real) =
    GDAL.value(geom, distance)

"""
Clear geometry information.

This restores the geometry to its initial state after construction, and before
assignment of actual geometry.
"""
empty!(geom::Geometry) = GDAL.empty(geom)

"Returns TRUE if the geometry has no points, otherwise FALSE."
isempty(geom::Geometry) = Bool(GDAL.isempty(geom))

"Returns TRUE if the geometry is valid, otherwise FALSE."
isvalid(geom::Geometry) = Bool(GDAL.isvalid(geom))

"Returns TRUE if the geometry is simple, otherwise FALSE."
issimple(geom::Geometry) = Bool(GDAL.issimple(geom))

"Returns TRUE if the geometry is a ring, otherwise FALSE."
isring(geom::Geometry) = Bool(GDAL.isring(geom))

"""
Polygonizes a set of sparse edges.

A new geometry object is created and returned containing a collection of
reassembled Polygons: NULL will be returned if the input collection doesn't
corresponds to a MultiLinestring, or when reassembling Edges into Polygons is
impossible due to topological inconsistencies.

### Returns
a handle to a newly allocated geometry now owned by the caller, or NULL on
failure.
"""
unsafe_polygonize(geom::Geometry) = GDAL.polygonize(geom)

equal(geom1::Geometry, geom2::Geometry) = Bool(GDAL.equal(geom1, geom2))

"Fetch number of points from a geometry."
npoint(geom::Geometry) = GDAL.getpointcount(geom)

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
#     ccall((:OGR_G_GetPoints,libgdal),Cint,(Ptr{OGRGeometryH},Ptr{Void},Cint,
# Ptr{Void},Cint,Ptr{Void},Cint),hGeom,pabyX,nXStride,pabyY,nYStride,pabyZ,
# nZStride)
# end


"Fetch the x coordinate of a point from a geometry, at index i."
getx(geom::Geometry, i::Integer) = GDAL.getx(geom, i)

"Fetch the y coordinate of a point from a geometry, at index i."
gety(geom::Geometry, i::Integer) = GDAL.gety(geom, i)

"Fetch the z coordinate of a point from a geometry, at index i."
getz(geom::Geometry, i::Integer) = GDAL.getz(geom, i)

"""
Fetch a point in line string or a point geometry, at index i.

### Parameters
* `i`: the vertex to fetch, from 0 to getNumPoints()-1, zero for a point.
"""
getpoint!(geom::Geometry, i::Integer, x, y, z) =
    GDAL.getpoint(geom, i, x, y, z)

function getpoint(geom::Geometry, i::Integer)
    x = Ref{Cdouble}(); y = Ref{Cdouble}(); z = Ref{Cdouble}()
    getpoint!(geom, i, x, y, z)
    (x[], y[], z[])
end

"""
Set number of points in a geometry.

### Parameters
* `geom`: the geometry.
* `n`: the new number of points for geometry.
"""
npoint!(geom::Geometry, n::Integer) = GDAL.setpointcount(geom, n)

"""
Set the location of a vertex in a point or linestring geometry.

### Parameters
* `geom`: handle to the geometry to add a vertex to.
* `i`: the index of the vertex to assign (zero based) or zero for a point.
* `x`: input X coordinate to assign.
* `y`: input Y coordinate to assign.
* `z`: input Z coordinate to assign (defaults to zero).
"""
setpoint!(geom::Geometry, i::Integer, x, y, z) = GDAL.setpoint(geom, i, x, y, z)

"""
Set the location of a vertex in a point or linestring geometry.

### Parameters
* `geom`: handle to the geometry to add a vertex to.
* `i`: the index of the vertex to assign (zero based) or zero for a point.
* `x`: input X coordinate to assign.
* `y`: input Y coordinate to assign.
"""
setpoint!(geom::Geometry, i::Integer, x, y) = GDAL.setpoint_2d(geom, i, x, y)

"""
Add a point to a geometry (line string or point).

### Parameters
* `geom`: the geometry to add a point to.
* `x`: x coordinate of point to add.
* `y`: y coordinate of point to add.
* `z`: z coordinate of point to add.
"""
addpoint!(geom::Geometry, x::Real, y::Real, z::Real) = GDAL.addpoint(geom,x,y,z)

"""
Add a point to a geometry (line string or point).

### Parameters
* `geom`: the geometry to add a point to.
* `x`: x coordinate of point to add.
* `y`: y coordinate of point to add.
"""
addpoint!(geom::Geometry, x::Real, y::Real) = GDAL.addpoint_2d(geom, x, y)

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
#     ccall((:OGR_G_SetPoints,libgdal),Void,(Ptr{OGRGeometryH},Cint,Ptr{Void},
# Cint,Ptr{Void},Cint,Ptr{Void},Cint),hGeom,nPointsIn,pabyX,nXStride,pabyY,
# nYStride,pabyZ,nZStride)
# end


"The number of elements in a geometry or number of geometries in container."
ngeom(geom::Geometry) = GDAL.getgeometrycount(geom)

"""
Fetch geometry from a geometry container.

This function returns an handle to a geometry within the container. The returned
geometry remains owned by the container, and should not be modified. The handle
is only valid until the next change to the geometry container. Use OGR_G_Clone()
to make a copy.

For a polygon, `OGR_G_GetGeometryRef(i)` returns the exterior ring if
`i == 0`, and the interior rings for `i > 0`.

### Parameters
* `geom`: the geometry container from which to get a geometry from.
* `i`: index of the geometry to fetch, between 0 and getNumGeometries() - 1.
"""
borrow_getgeom(geom::Geometry, i::Integer) = GDAL.getgeometryref(geom, i)

"""
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
function addgeom!(geomcontainer::Geometry, subgeom::Geometry)
    result = GDAL.addgeometry(geomcontainer, subgeom)
    @ogrerr result "Failed to add geometry. The geometry type could be illegal"
end

"""
Add a geometry directly to an existing geometry container.

Some subclasses of OGRGeometryCollection restrict the types of geometry that can
be added, and may return an error. Ownership of the passed geometry is taken by
the container rather than cloning as addGeometry() does.

For a polygon, hNewSubGeom must be a linearring. If the polygon is empty, the
first added subgeometry will be the exterior ring. The next ones will be the
interior rings.

### Parameters
* `geomcontainer`: existing geometry.
* `subgeom`: geometry to add to the existing geometry.
"""
function addgeomdirectly!(geomcontainer::Geometry, subgeom::Geometry)
    result = GDAL.addgeometrydirectly(geomcontainer, subgeom)
    @ogrerr result "Failed to add geometry. The geometry type could be illegal"
end

"""
Remove a geometry from an exiting geometry container.

### Parameters
* `geom`: the existing geometry to delete from.
* `i`: the index of the geometry to delete. A value of -1 is a special flag
    meaning that all geometries should be removed.
* `todelete`: if TRUE the geometry will be destroyed, otherwise it will not.
    The default is TRUE as the existing geometry is considered to own the
    geometries in it.
"""
function removegeom(geom::Geometry, i::Integer, todelete::Bool = true)
    result = GDAL.removegeometry(geom, i, todelete)
    @ogrerr result "Failed to remove geometry. The index could be out of range."
end

function removeallgeoms(geom::Geometry, todelete::Bool = true)
    result = GDAL.removegeometry(geom, -1, todelete)
    @ogrerr result "Failed to remove all geometries."
end

"""
Returns if this geometry is or has curve geometry.

### Parameters
* `geom`: the geometry to operate on.
* `nonlinear`: set it to TRUE to check if the geometry is or contains a
    CIRCULARSTRING.
"""
hascurvegeom(geom::Geometry, nonlinear::Bool) =
    Bool(GDAL.hascurvegeometry(geom, nonlinear))

"""
Return, possibly approximate, linear version of this geometry.

Returns a geometry that has no CIRCULARSTRING, COMPOUNDCURVE, CURVEPOLYGON,
MULTICURVE or MULTISURFACE in it, by approximating curve geometries.

The ownership of the returned geometry belongs to the caller.

### Parameters
* `geom`: the geometry to operate on.
* `stepsize`: the largest step in degrees along the arc, zero to use the
    default setting.
* `options`: options as a null-terminated list of strings or NULL.
    See OGRGeometryFactory::curveToLineString() for valid options.
"""
unsafe_getlineargeom(geom::Geometry, stepsize::Real=0) = 
    GDAL.getlineargeometry(geom, stepsize, C_NULL)

unsafe_getlineargeom{T <: AbstractString}(geom::Geometry, options::Vector{T}) = 
    GDAL.getlineargeometry(geom, 0, options)

unsafe_getlineargeom{T <: AbstractString}(geom::Geometry, stepsize::Real,
                                   options::Vector{T}) = 
    GDAL.getlineargeometry(geom, stepsize, options)

"""
Return curve version of this geometry.

Returns a geometry that has possibly CIRCULARSTRING, COMPOUNDCURVE,
CURVEPOLYGON, MULTICURVE or MULTISURFACE in it, by de-approximating linear into
curve geometries.

If the geometry has no curve portion, the returned geometry will be a clone.

The ownership of the returned geometry belongs to the caller.

The reverse function is OGR_G_GetLinearGeometry().
"""
unsafe_getcurvegeom(geom::Geometry) = GDAL.getcurvegeometry(geom, C_NULL)

"""
Build a ring from a bunch of arcs.

### Parameters
* `lines`: handle to an OGRGeometryCollection (or OGRMultiLineString)
    containing the line string geometries to be built into rings.
* `besteffort`: not yet implemented???.
* `autoclose`: indicates if the ring should be close when first and last
    points of the ring are the same.
* `tol`: whether two arcs are considered close enough to be joined.
"""
function unsafe_polygonfromedges(lines::Geometry, besteffort::Bool,
                                 autoclose::Bool, tol::Real)
    perr = Ref{GDAL.OGRErr}()
    result = GDAL.buildpolygonfromedges(lines, besteffort, autoclose, tol, perr)
    @ogrerr peErr[] "Failed to build polygon from edges."
    result
end

"""
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
* `flag`: TRUE if non-linear geometries might be returned (default value).
          FALSE to ask for non-linear geometries to be approximated as linear
          geometries.

### Returns
a point or NULL.
"""
enablenonlineargeom(flag::Bool) = GDAL.setnonlineargeometriesenabledflag(flag)

"Get flag to enable/disable returning non-linear geometries in the C API."
nonlineargeomisenabledflag() = GDAL.getnonlineargeometriesenabledflag()

for (geom, wkbgeom) in ((:geomcollection,   GDAL.wkbGeometryCollection),
                        (:linestring,       GDAL.wkbLineString),
                        (:linearring,       GDAL.wkbLinearRing),
                        (:multilinestring,  GDAL.wkbMultiLineString),
                        (:multipoint,       GDAL.wkbMultiPoint),
                        (:multipolygon,     GDAL.wkbMultiPolygon),
                        (:point,            GDAL.wkbPoint),
                        (:polygon,          GDAL.wkbPolygon))
    @eval $(symbol("unsafe_create$geom"))() = unsafe_creategeom($wkbgeom)
end

function unsafe_createpoint(x::Real, y::Real)
    geom = unsafe_creategeom(GDAL.wkbPoint)
    addpoint!(geom, x, y)
    geom
end

function unsafe_createpoint(x::Real, y::Real, z::Real)
    geom = unsafe_creategeom(GDAL.wkbPoint)
    addpoint!(geom, x, y, z)
    geom
end

function unsafe_createpoint{T <: Real, U <: Real}(xy::Tuple{T,U})
    geom = unsafe_creategeom(GDAL.wkbPoint)
    addpoint!(geom, xy...)
    geom
end

function unsafe_createpoint{T <: Real, U <: Real, V <: Real}(xyz::Tuple{T,U,V})
    geom = unsafe_creategeom(GDAL.wkbPoint)
    addpoint!(geom, xyz...)
    geom
end

# Tuples of Vectors
for (geom, wkbgeom) in ((:linestring, GDAL.wkbLineString),
                        (:linearring, GDAL.wkbLinearRing))
    eval(quote 
        function $(symbol("unsafe_create$geom"))(xs::Vector{Cdouble},
                                                 ys::Vector{Cdouble})
            geom = unsafe_creategeom($wkbgeom)
            for (x,y) in zip(xs, ys)
                addpoint!(geom, x, y)
            end
            geom
        end

        function $(symbol("unsafe_create$geom"))(xs::Vector{Cdouble},
                             ys::Vector{Cdouble},zs::Vector{Cdouble})
            geom = unsafe_creategeom($wkbgeom)
            for (x,y,z) in zip(xs, ys, zs)
                addpoint!(geom, x, y, z)
            end
            geom
        end
    end)
end

function unsafe_createpolygon(xs::Vector{Cdouble}, ys::Vector{Cdouble})
    geom = unsafe_creategeom(GDAL.wkbPolygon)
    addgeomdirectly!(geom, unsafe_createlinearring(xs, ys))
    geom
end

function unsafe_createpolygon(xs::Vector{Cdouble}, ys::Vector{Cdouble},
                              zs::Vector{Cdouble})
    geom = unsafe_creategeom(GDAL.wkbPolygon)
    addgeomdirectly!(geom, unsafe_createlinearring(xs, ys, zs))
    geom
end

function unsafe_createmultipoint(xs::Vector{Cdouble}, ys::Vector{Cdouble})
    geom = unsafe_creategeom(GDAL.wkbMultiPoint)
    for (x, y) in zip(xs, ys)
        addgeomdirectly!(geom, unsafe_createpoint(x, y))
    end
    geom
end

function unsafe_createmultipoint(xs::Vector{Cdouble}, ys::Vector{Cdouble},
                                 zs::Vector{Cdouble})
    geom = unsafe_creategeom(GDAL.wkbMultiPoint)
    for (x, y, z) in zip(xs, ys, zs)
        addgeomdirectly!(geom, unsafe_createpoint(x, y, z))
    end
    geom
end

# Vectors of Tuples
for typeargs in (Vector{Tuple{Cdouble,Cdouble}},
                 Vector{Tuple{Cdouble,Cdouble,Cdouble}})
    for (geom, wkbgeom) in ((:linestring, GDAL.wkbLineString),
                            (:linearring, GDAL.wkbLinearRing))
        @eval function $(symbol("unsafe_create$geom"))(coords::$typeargs)
                  geom = unsafe_creategeom($wkbgeom)
                  for coord in coords
                      addpoint!(geom, coord...)
                  end
                  geom
              end 
    end

    eval(quote
        function unsafe_createpolygon(coords::$typeargs)
            geom = unsafe_creategeom(GDAL.wkbPolygon)
            addgeomdirectly!(geom, unsafe_createlinearring(coords))
            geom
        end

        function unsafe_createmultipoint(coords::$typeargs)
            geom = unsafe_creategeom(GDAL.wkbMultiPoint)
            for point in coords
                addgeomdirectly!(geom, unsafe_createpoint(point))
            end
            geom
        end
    end)
end

for typeargs in (Vector{Vector{Tuple{Cdouble,Cdouble}}},
                 Vector{Vector{Tuple{Cdouble,Cdouble,Cdouble}}})
    for (geom, wkbgeom, f) in ((:polygon,              GDAL.wkbPolygon,
                                :unsafe_createlinearring),
                               (:multilinestring,      GDAL.wkbMultiLineString,
                                :unsafe_createlinestring),
                               (:multipolygon_noholes, GDAL.wkbMultiPolygon,
                                :unsafe_createpolygon))
        @eval function $(symbol("unsafe_create$geom"))(coords::$typeargs)
                  geom = unsafe_creategeom($wkbgeom)
                  for coord in coords
                      addgeomdirectly!(geom, $(f)(coord))
                  end
                  geom
              end
    end
end

function unsafe_createmultipolygon(coords::Vector{Vector{
                                           Vector{Tuple{Cdouble,Cdouble}}}})
    geom = unsafe_creategeom(GDAL.wkbMultiPolygon)
    for coord in coords
        addgeomdirectly!(geom, unsafe_createpolygon(coord))
    end
    geom
end