"""
Create a geometry object of the appropriate type from it's well known
binary (WKB) representation.

### Parameters
* `data`: pointer to the input BLOB data.
* `spatialref`: handle to the spatial reference to be assigned to the created
    geometry object. This may be `NULL` (default).
"""
function unsafe_fromWKB(
        ::Type{G},
        data,
        spatialref::SpatialRef = SpatialRef(C_NULL)
    ) where G <: AbstractGeometry
    geom = Ref{GDALGeometry}()
    result = @gdal(OGR_G_CreateFromWkb::GDAL.OGRErr,
        data::Ptr{Cuchar},
        spatialref.ptr::GDALSpatialRef,
        geom::Ptr{GDALGeometry},
        sizeof(data)::Cint
    )
    @ogrerr result "Failed to create geometry from WKB"
    G(geom[])
end

unsafe_fromWKB(data, args...) = unsafe_fromWKB(Geometry, data, args...)

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
function unsafe_fromWKT(
        ::Type{G},
        data::Vector{String},
        spatialref::SpatialRef = SpatialRef(C_NULL)
    ) where G <: AbstractGeometry
    geom = Ref{GDALGeometry}()
    result = @gdal(OGR_G_CreateFromWkt::GDAL.OGRErr,
        data::StringList,
        spatialref.ptr::GDALSpatialRef,
        geom::Ptr{GDALGeometry}
    )
    @ogrerr result "Failed to create geometry from WKT"
    G(geom[])
end
unsafe_fromWKT(data::Vector{String}, args...) = unsafe_fromWKT(Geometry, data, args...)
unsafe_fromWKT(data::String, args...) = unsafe_fromWKT([data], args...)

"""
Destroy geometry object.

Equivalent to invoking delete on a geometry, but it guaranteed to take place
within the context of the GDAL/OGR heap.
"""
function destroy(geom::AbstractGeometry)
    GDAL.destroygeometry(geom.ptr)
    geom.ptr = C_NULL
end

"Returns a copy of the geometry with the original spatial reference system."
function unsafe_clone(::Type{G}, geom::AbstractGeometry) where G <: AbstractGeometry
    G(GDAL.clone(geom.ptr))
end
unsafe_clone(geom::G) where {G <: AbstractGeometry} = unsafe_clone(G, geom)

"""
Create an empty geometry of desired type.

This is equivalent to allocating the desired geometry with new, but the
allocation is guaranteed to take place in the context of the GDAL/OGR heap.
"""
function unsafe_creategeom(::Type{G}, geomtype::OGRwkbGeometryType ) where G <: AbstractGeometry
    G(GDAL.checknull(@gdal(OGR_G_CreateGeometry::GDALGeometry, geomtype::GDAL.OGRwkbGeometryType)))
end

unsafe_creategeom(geomtype::OGRwkbGeometryType) = unsafe_creategeom(Geometry, geomtype)

"""
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
function unsafe_forceto(
        ::Type{G},
        geom::AbstractGeometry,
        targettype::OGRwkbGeometryType,
        options = StringList(C_NULL)
    ) where G <: AbstractGeometry
    G(GDAL.checknull(@gdal(OGR_G_ForceTo::GDALGeometry,
        unsafe_clone(geom).ptr::GDALGeometry,
        targettype::GDAL.OGRwkbGeometryType,
        options::StringList
    )))
end
unsafe_forceto(geom::AbstractGeometry, args...) =
    unsafe_forceto(Geometry, geom, args...)


"""
Get the dimension of the geometry. 0 for points, 1 for lines and 2 for surfaces.

This function corresponds to the SFCOM IGeometry::GetDimension() method. It
indicates the dimension of the geometry, but does not indicate the dimension of
the underlying space (as indicated by OGR_G_GetCoordinateDimension() function).
"""
getdim(geom::AbstractGeometry) = GDAL.getdimension(geom.ptr)

"""
Get the dimension of the coordinates in this geometry.

### Returns
In practice this will return 2 or 3. It can also return 0 in the case of an
empty point.
"""
getcoorddim(geom::AbstractGeometry) = GDAL.getcoordinatedimension(geom.ptr)

"""
Set the coordinate dimension.

This method sets the explicit coordinate dimension. Setting the coordinate
dimension of a geometry to 2 should zero out any existing Z values. Setting the
dimension of a geometry collection, a compound curve, a polygon, etc. will
affect the children geometries. This will also remove the M dimension if present
before this call.
"""
function setcoorddim!(geom::AbstractGeometry, dim::Integer)
    GDAL.setcoordinatedimension(geom.ptr ,dim)
end

"Computes and returns the bounding envelope for this geometry"
function getenvelope(geom::AbstractGeometry)
    envelope = Ref{GDAL.OGREnvelope}(GDAL.OGREnvelope(0, 0, 0, 0))
    GDAL.getenvelope(geom.ptr, envelope)
    envelope[]
end

"Computes and returns the bounding envelope (3D) for this geometry"
function getenvelope3d(geom::AbstractGeometry)
    envelope = Ref{GDAL.OGREnvelope3D}(GDAL.OGREnvelope3D(0, 0, 0, 0, 0, 0))
    GDAL.getenvelope3d(geom.ptr, envelope)
    envelope[]
end

"""
Convert a geometry well known binary format.

### Parameters
* `geom`: handle on the geometry to convert to a well know binary data from.
* `order`: One of wkbXDR or [wkbNDR] indicating MSB or LSB byte order resp.
"""
function toWKB(geom::AbstractGeometry, order::OGRwkbByteOrder=GDAL.wkbNDR)
    buffer = Array{Cuchar}(wkbsize(geom))
    result = @gdal(OGR_G_ExportToWkb::GDAL.OGRErr,
        geom.ptr::GDALGeometry,
        order::GDAL.OGRwkbByteOrder,
        buffer::Ptr{Cuchar}
    )
    @ogrerr result "Failed to export geometry to WKB"
    buffer
end

"""
Convert a geometry into SFSQL 1.2 / ISO SQL/MM Part 3 well known binary format.

### Parameters
* `geom`: handle on the geometry to convert to a well know binary data from.
* `order`: One of wkbXDR or [wkbNDR] indicating MSB or LSB byte order resp.
"""
function toISOWKB(geom::AbstractGeometry, order::OGRwkbByteOrder=GDAL.wkbNDR)
    buffer = Array{Cuchar}(wkbsize(geom))
    result = @gdal(OGR_G_ExportToIsoWkb::GDAL.OGRErr,
        geom.ptr::GDALGeometry,
        order::GDAL.OGRwkbByteOrder,
        buffer::Ptr{Cuchar}
    )
    @ogrerr result "Failed to export geometry to ISO WKB"
    buffer
end

"Returns size (in bytes) of related binary representation."
wkbsize(geom::AbstractGeometry) = GDAL.wkbsize(geom.ptr)

"Convert a geometry into well known text format."
function toWKT(geom::AbstractGeometry)
    wkt_ptr = Ref{Ptr{UInt8}}()
    result = GDAL.exporttowkt(geom.ptr, wkt_ptr)
    @ogrerr result "OGRErr $result: failed to export geometry to WKT"
    wkt = unsafe_string(wkt_ptr[])
    GDAL.C.OGRFree(Ptr{UInt8}(wkt_ptr[]))
    wkt
end

"Convert a geometry into SFSQL 1.2 / ISO SQL/MM Part 3 well known text format."
function toISOWKT(geom::AbstractGeometry)
    isowkt_ptr = Ref{Ptr{UInt8}}()
    result = GDAL.exporttoisowkt(geom.ptr, isowkt_ptr)
    @ogrerr result "OGRErr $result: failed to export geometry to ISOWKT"
    wkt = unsafe_string(isowkt_ptr[])
    GDAL.C.OGRFree(Ptr{UInt8}(isowkt_ptr[]))
    wkt
end

"Fetch geometry type code"
getgeomtype(geom::AbstractGeometry) =
    OGRwkbGeometryType(GDAL.getgeometrytype(geom.ptr))

"Fetch WKT name for geometry type."
getgeomname(geom::AbstractGeometry) = GDAL.getgeometryname(geom.ptr)

"Convert geometry to strictly 2D."
function flattento2d!(geom::G) where G <: AbstractGeometry
    GDAL.flattento2d(geom.ptr)
    geom
end

"""
Force rings to be closed.

If this geometry, or any contained geometries has polygon rings that are not
closed, they will be closed by adding the starting point at the end.
"""
closerings!(geom::G) where {G <: AbstractGeometry} = (GDAL.closerings(geom.ptr); geom)

"""
Create geometry from GML.

This method translates a fragment of GML containing only the geometry portion
into a corresponding OGRGeometry. There are many limitations on the forms of GML
geometries supported by this parser, but they are too numerous to list here.

The following GML2 elements are parsed : Point, LineString, Polygon, MultiPoint,
MultiLineString, MultiPolygon, MultiGeometry.
"""
unsafe_fromGML(::Type{G}, data) where {G <: AbstractGeometry} =
    G(GDAL.createfromgml(data))
unsafe_fromGML(data) = unsafe_fromGML(Geometry, data)

"Convert a geometry into GML format."
toGML(geom::AbstractGeometry) = GDAL.exporttogml(geom.ptr)

"Convert a geometry into KML format."
# * `altitudemode`: value to write in altitudeMode element, or NULL.
toKML(geom::AbstractGeometry, altitudemode = Ptr{UInt8}(C_NULL)) =
    GDAL.exporttokml(geom.ptr, altitudemode)

"Convert a geometry into GeoJSON format."
toJSON(geom::AbstractGeometry) = GDAL.exporttojson(geom.ptr)

"""
Convert a geometry into GeoJSON format.
### Parameters
* `geom`: handle to the geometry.
* `options`: a list of options.
### Returns
A GeoJSON fragment or NULL in case of error.
"""
toJSON(geom::AbstractGeometry, options) =
    unsafe_string(@gdal(OGR_G_ExportToJsonEx::Cstring,
        geom.ptr::GDALGeometry,
        options::StringList
    ))

"Create a geometry object from its GeoJSON representation"
unsafe_fromJSON(::Type{G}, data::String) where {G <: AbstractGeometry} =
    G(GDAL.creategeometryfromjson(data))
unsafe_fromJSON(data::String) = unsafe_fromJSON(Geometry, data)

"Assign spatial reference to this object."
setspatialref!(geom::G, spatialref::SpatialRef) where {G <: AbstractGeometry} =
    (GDAL.assignspatialreference(geom.ptr, spatialref.ptr); geom)

"""
Returns spatial reference system for geometry.

The object may be shared with many geometry objects, and should not be modified.
"""
getspatialref(geom::AbstractGeometry) =
    SpatialRef(GDAL.getspatialreference(geom.ptr))

"""
Apply arbitrary coordinate transformation to geometry.

### Parameters
* `geom`: handle on the geometry to apply the transform to.
* `coordtransform`: handle on the transformation to apply.
"""
function transform!(geom::G,
        coordtransform::CoordTransform
    ) where G <: AbstractGeometry
    result = GDAL.transform(geom.ptr, coordtransform.ptr)
    @ogrerr result "Failed to transform geometry"
    geom
end

"Transform geometry to new spatial reference system."
function transform!(geom::G, spatialref::SpatialRef) where G <: AbstractGeometry
    result = GDAL.transformto(geom.ptr, spatialref.ptr)
    @ogrerr result "Failed to transform geometry to the new SRS"
    geom
end

"""
Compute a simplified geometry.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.
"""
function unsafe_simplify(::Type{G},
        geom::AbstractGeometry, tol::Real
    ) where G <: AbstractGeometry
    G(GDAL.simplify(geom.ptr, tol))
end
unsafe_simplify(geom::AbstractGeometry, args...) =
    unsafe_simplify(Geometry, geom, args...)

"""
Simplify the geometry while preserving topology.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.
"""
function unsafe_simplifypreservetopology(::Type{G},
        geom::AbstractGeometry, tol::Real
    ) where G <: AbstractGeometry
    G(GDAL.simplifypreservetopology(geom.ptr, tol))
end
unsafe_simplifypreservetopology(geom::AbstractGeometry, args...) =
    unsafe_simplifypreservetopology(Geometry, geom, args...)

"""
Return a Delaunay triangulation of the vertices of the geometry.

### Parameters
* `geom`: the geometry.
* `tol`: optional snapping tolerance to use for improved robustness
* `onlyedges`: if TRUE, will return a MULTILINESTRING, otherwise it
    will return a GEOMETRYCOLLECTION containing triangular POLYGONs.
"""
function unsafe_delaunaytriangulation(::Type{G},
        geom::AbstractGeometry, tol::Real, onlyedges::Bool
    ) where G <: AbstractGeometry
    G(GDAL.delaunaytriangulation(geom.ptr, tol, onlyedges))
end
unsafe_delaunaytriangulation(geom::AbstractGeometry, args...) =
    unsafe_delaunaytriangulation(Geometry, geom, args...)

"""
Modify the geometry such it has no segment longer than the given distance.

Interpolated points will have Z and M values (if needed) set to 0. Distance
computation is performed in 2d only

### Parameters
* `geom`: the geometry to segmentize
* `maxlength`: the maximum distance between 2 points after segmentization
"""
function segmentize!(geom::G, maxlength::Real) where G <: AbstractGeometry
    GDAL.segmentize(geom.ptr, maxlength)
    geom
end

"""
Returns whether the geometries intersect

Determines whether two geometries intersect. If GEOS is enabled, then this is
done in rigorous fashion otherwise TRUE is returned if the envelopes (bounding
boxes) of the two geometries overlap.
"""
function intersects(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.intersects(g1.ptr, g2.ptr))
end

"Returns TRUE if the geometries are equivalent."
function equals(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.equals(g1.ptr, g2.ptr))
end

"Returns TRUE if the geometries are disjoint."
function disjoint(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.disjoint(g1.ptr, g2.ptr))
end

"Returns TRUE if the geometries are touching."
function touches(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.touches(g1.ptr, g2.ptr))
end

"Returns TRUE if the geometries are crossing."
function crosses(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.crosses(g1.ptr, g2.ptr))
end

"Returns TRUE if g1 is contained within g2."
function within(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.within(g1.ptr, g2.ptr))
end

"Returns TRUE if g1 contains g2."
function contains(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.contains(g1.ptr, g2.ptr))
end

"Returns TRUE if the geometries overlap."
function overlaps(g1::AbstractGeometry, g2::AbstractGeometry)
    Bool(GDAL.overlaps(g1.ptr, g2.ptr))
end

"""
Returns the boundary of the geometry.

A new geometry object is created and returned containing the boundary of the
geometry on which the method is invoked.
"""
unsafe_boundary(::Type{G}, geom::AbstractGeometry) where {G <: AbstractGeometry} =
    G(GDAL.boundary(geom.ptr))
unsafe_boundary(geom::AbstractGeometry, args...) =
    unsafe_boundary(Geometry, geom, args...)

"""
Returns the convex hull of the geometry.

A new geometry object is created and returned containing the convex hull of the
geometry on which the method is invoked.
"""
unsafe_convexhull(::Type{G}, geom::AbstractGeometry) where {G <: AbstractGeometry} =
    G(GDAL.convexhull(geom.ptr))
unsafe_convexhull(geom::AbstractGeometry, args...) =
    unsafe_convexhull(Geometry, geom, args...)

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
function unsafe_buffer(::Type{G},
        geom::AbstractGeometry, dist::Real, quadsegs::Integer = 30
    ) where G <: AbstractGeometry
    G(GDAL.buffer(geom.ptr, dist, quadsegs))
end
unsafe_buffer(geom::AbstractGeometry, args...) =
    unsafe_buffer(Geometry, geom, args...)

"""
Returns a new geometry representing the intersection of the geometries, or NULL
if there is no intersection or an error occurs.

Generates a new geometry which is the region of intersection of the two
geometries operated on. The OGR_G_Intersects() function can be used to test if
two geometries intersect.
"""
function unsafe_intersection(::Type{G},
        g1::AbstractGeometry, g2::AbstractGeometry
    ) where G <: AbstractGeometry
    G(GDAL.intersection(g1.ptr, g2.ptr))
end
unsafe_intersection(g1::AbstractGeometry, g2::AbstractGeometry, args...) =
    unsafe_intersection(Geometry, g1, g2, args...)

"""
Returns a new geometry representing the union of the geometries.

Generates a new geometry which is the region of union of the two geometries
operated on.
"""
function unsafe_union(::Type{G},
        g1::AbstractGeometry, g2::AbstractGeometry
    ) where G <: AbstractGeometry
    G(GDAL.union(g1.ptr, g2.ptr))
end

"Compute the union of the geometry using cascading."
unsafe_union(::Type{G}, geom::AbstractGeometry) where {G <: AbstractGeometry} =
    G(GDAL.unioncascaded(geom.ptr))

unsafe_union(geom::AbstractGeometry, args...) =
    unsafe_union(Geometry, geom, args...)

"""
Returns a point guaranteed to lie on the surface.

This method relates to the SFCOM ISurface::get_PointOnSurface() method however
the current implementation based on GEOS can operate on other geometry types
than the types that are supported by SQL/MM-Part 3 : surfaces (polygons) and
multisurfaces (multipolygons).
"""
function unsafe_pointonsurface(::Type{G},
        geom::AbstractGeometry
    ) where G <: AbstractGeometry
    G(GDAL.pointonsurface(geom.ptr))
end

unsafe_pointonsurface(geom::AbstractGeometry, args...) =
    unsafe_pointonsurface(Geometry, geom, args...)

"""
Generates a new geometry which is the region of this geometry with the region of
the other geometry removed.

### Returns
A new geometry representing the difference of the geometries, or NULL
if the difference is empty.
"""
function unsafe_difference(::Type{G},
        g1::AbstractGeometry, g2::AbstractGeometry
    ) where G <: AbstractGeometry
    G(GDAL.difference(g1.ptr, g2.ptr))
end

unsafe_difference(geom::AbstractGeometry, args...) =
    unsafe_difference(Geometry, geom, args...)

"""
Returns a new geometry representing the symmetric difference of the geometries
or NULL if the difference is empty or an error occurs.
"""
function unsafe_symdifference(::Type{G},
        g1::AbstractGeometry, g2::AbstractGeometry
    ) where G <: AbstractGeometry
    G(GDAL.symdifference(g1.ptr, g2.ptr))
end

unsafe_symdifference(geom::AbstractGeometry, args...) =
    unsafe_symdifference(Geometry, geom, args...)

"Returns the distance between the geometries or -1 if an error occurs."
distance(g1::AbstractGeometry, g2::AbstractGeometry) = GDAL.distance(g1.ptr, g2.ptr)

"Returns the length of the geometry, or 0.0 for unsupported geometry types."
geomlength(geom::AbstractGeometry) = GDAL.length(geom.ptr)

"Returns the area of the geometry or 0.0 for unsupported geometry types."
geomarea(geom::AbstractGeometry) = GDAL.area(geom.ptr)

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
function centroid!(
        geom::AbstractGeometry, centroid::G
    ) where G <: AbstractGeometry
    result = GDAL.centroid(geom.ptr, centroid.ptr)
    @ogrerr result "Failed to compute the geometry centroid"
    centroid
end

unsafe_centroid(geom::AbstractGeometry) = centroid!(geom, unsafe_createpoint())

"""
Fetch point at given distance along curve.

### Parameters
* `geom`: curve geometry.
* `distance`: distance along the curve at which to sample position. This
    distance should be between zero and geomlength() for this curve.

### Returns
a point or NULL.
"""
function unsafe_pointalongline(::Type{G},
        geom::AbstractGeometry, distance::Real
    ) where G <: AbstractGeometry
    G(GDAL.value(geom.ptr, distance))
end

unsafe_pointalongline(geom::AbstractGeometry, args...) =
    unsafe_pointalongline(Geometry, geom, args...)

"""
Clear geometry information.

This restores the geometry to its initial state after construction, and before
assignment of actual geometry.
"""
empty!(geom::G) where {G <: AbstractGeometry} = (GDAL.empty(geom.ptr); geom)

"Returns TRUE if the geometry has no points, otherwise FALSE."
isempty(geom::AbstractGeometry) = Bool(GDAL.isempty(geom.ptr))

"Returns TRUE if the geometry is valid, otherwise FALSE."
isvalid(geom::AbstractGeometry) = Bool(GDAL.isvalid(geom.ptr))

"Returns TRUE if the geometry is simple, otherwise FALSE."
issimple(geom::AbstractGeometry) = Bool(GDAL.issimple(geom.ptr))

"Returns TRUE if the geometry is a ring, otherwise FALSE."
isring(geom::AbstractGeometry) = Bool(GDAL.isring(geom.ptr))

"""
Polygonizes a set of sparse edges.

A new geometry object is created and returned containing a collection of
reassembled Polygons: NULL will be returned if the input collection doesn't
correspond to a MultiLinestring, or when reassembling Edges into Polygons is
impossible due to topological inconsistencies.

### Returns
a handle to a newly allocated geometry now owned by the caller, or NULL on
failure.
"""
unsafe_polygonize(::Type{G}, geom::AbstractGeometry) where {G <: AbstractGeometry} =
    G(GDAL.polygonize(geom.ptr))
unsafe_polygonize(geom::AbstractGeometry, args...) =
    unsafe_polygonize(Geometry, geom, args...)

"Fetch number of points from a geometry."
npoint(geom::AbstractGeometry) = GDAL.getpointcount(geom.ptr)

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
getx(geom::AbstractGeometry, i::Integer) = GDAL.getx(geom.ptr, i)

"Fetch the y coordinate of a point from a geometry, at index i."
gety(geom::AbstractGeometry, i::Integer) = GDAL.gety(geom.ptr, i)

"Fetch the z coordinate of a point from a geometry, at index i."
getz(geom::AbstractGeometry, i::Integer) = GDAL.getz(geom.ptr, i)

"""
Fetch a point in line string or a point geometry, at index i.

### Parameters
* `i`: the vertex to fetch, from 0 to getNumPoints()-1, zero for a point.
"""
getpoint!(geom::AbstractGeometry, i::Integer, x, y, z) =
    (GDAL.getpoint(geom.ptr, i, x, y, z); (x[], y[], z[]))

getpoint(geom::AbstractGeometry, i::Integer) =
    getpoint!(geom, i, Ref{Cdouble}(), Ref{Cdouble}(), Ref{Cdouble}())

"""
Set number of points in a geometry.

### Parameters
* `geom`: the geometry.
* `n`: the new number of points for geometry.
"""
setpointcount!(geom::AbstractGeometry, n::Integer) =
    (GDAL.setpointcount(geom.ptr, n); geom)

"""
Set the location of a vertex in a point or linestring geometry.

### Parameters
* `geom`: handle to the geometry to add a vertex to.
* `i`: the index of the vertex to assign (zero based) or zero for a point.
* `x`: input X coordinate to assign.
* `y`: input Y coordinate to assign.
* `z`: input Z coordinate to assign (defaults to zero).
"""
setpoint!(geom::AbstractGeometry, i::Integer, x::Real, y::Real, z::Real) =
    (GDAL.setpoint(geom.ptr, i, x, y, z); geom)

"""
Set the location of a vertex in a point or linestring geometry.

### Parameters
* `geom`: handle to the geometry to add a vertex to.
* `i`: the index of the vertex to assign (zero based) or zero for a point.
* `x`: input X coordinate to assign.
* `y`: input Y coordinate to assign.
"""
setpoint!(geom::AbstractGeometry, i::Integer, x::Real, y::Real) =
    (GDAL.setpoint_2d(geom.ptr, i, x, y); geom)

"""
Add a point to a geometry (line string or point).

### Parameters
* `geom`: the geometry to add a point to.
* `x`: x coordinate of point to add.
* `y`: y coordinate of point to add.
* `z`: z coordinate of point to add.
"""
addpoint!(geom::AbstractGeometry, x::Real, y::Real, z::Real) =
    (GDAL.addpoint(geom.ptr, x, y, z); geom)

"""
Add a point to a geometry (line string or point).

### Parameters
* `geom`: the geometry to add a point to.
* `x`: x coordinate of point to add.
* `y`: y coordinate of point to add.
"""
addpoint!(geom::AbstractGeometry, x::Real, y::Real) =
    (GDAL.addpoint_2d(geom.ptr, x, y); geom)

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
ngeom(geom::AbstractGeometry) = GDAL.getgeometrycount(geom.ptr)

"""
Fetch geometry from a geometry container.

This function returns an handle to a geometry within the container. The returned
geometry remains owned by the container, and should not be modified. The handle
is only valid until the next change to the geometry container. Use OGR_G_Clone()
to make a copy.

For a polygon, `getgeom(polygon,i)` returns the exterior ring if
`i == 0`, and the interior rings for `i > 0`.

### Parameters
* `geom`: the geometry container from which to get a geometry from.
* `i`: index of the geometry to fetch, between 0 and getNumGeometries() - 1.
"""
function getgeom(::Type{G},
        geom::AbstractGeometry, i::Integer
    ) where G <: AbstractGeometry
    G(GDAL.getgeometryref(geom.ptr, i))
end
getgeom(geom::AbstractGeometry, args...) =
    getgeom(Geometry, geom, args...)

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
function addgeom!(geomcontainer::G, subgeom::AbstractGeometry) where G <: AbstractGeometry
    result = GDAL.addgeometry(geomcontainer.ptr, subgeom.ptr)
    @ogrerr result "Failed to add geometry. The geometry type could be illegal"
    geomcontainer
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
function addgeomdirectly!(geomcontainer::G, subgeom::AbstractGeometry) where G <: AbstractGeometry
    result = GDAL.addgeometrydirectly(geomcontainer.ptr, subgeom.ptr)
    @ogrerr result "Failed to add geometry. The geometry type could be illegal"
    geomcontainer
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
function removegeom!(geom::G,
        i::Integer, todelete::Bool = true
    ) where G <: AbstractGeometry
    result = GDAL.removegeometry(geom.ptr, i, todelete)
    @ogrerr result "Failed to remove geometry. The index could be out of range."
    geom
end

"""
Remove all geometries from an exiting geometry container.

### Parameters
* `geom`: the existing geometry to delete from.
* `todelete`: if TRUE the geometry will be destroyed, otherwise it will not.
    The default is TRUE as the existing geometry is considered to own the
    geometries in it.
"""
function removeallgeoms!(geom::G, todelete::Bool = true) where G <: AbstractGeometry
    result = GDAL.removegeometry(geom.ptr, -1, todelete)
    @ogrerr result "Failed to remove all geometries."
    geom
end

"""
Returns if this geometry is or has curve geometry.

### Parameters
* `geom`: the geometry to operate on.
* `nonlinear`: set it to TRUE to check if the geometry is or contains a
    CIRCULARSTRING.
"""
hascurvegeom(geom::AbstractGeometry, nonlinear::Bool) =
    Bool(GDAL.hascurvegeometry(geom.ptr, nonlinear))

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
function unsafe_getlineargeom(::Type{G},
        geom::AbstractGeometry, stepsize::Real = 0
    ) where G <: AbstractGeometry
    G(GDAL.getlineargeometry(geom.ptr, stepsize, C_NULL))
end

function unsafe_getlineargeom(::Type{G},
        geom::AbstractGeometry, options::Vector
    ) where G <: AbstractGeometry
    G(GDAL.getlineargeometry(geom.ptr, 0, options))
end

function unsafe_getlineargeom(::Type{G},
        geom::AbstractGeometry, stepsize::Real, options::Vector
    ) where G <: AbstractGeometry
    G(GDAL.getlineargeometry(geom.ptr, stepsize, options))
end
unsafe_getlineargeom(geom::AbstractGeometry, args...) =
    unsafe_getlineargeom(Geometry, geom, args...)

"""
Return curve version of this geometry.

Returns a geometry that has possibly CIRCULARSTRING, COMPOUNDCURVE,
CURVEPOLYGON, MULTICURVE or MULTISURFACE in it, by de-approximating linear into
curve geometries.

If the geometry has no curve portion, the returned geometry will be a clone.

The ownership of the returned geometry belongs to the caller.

The reverse function is OGR_G_GetLinearGeometry().
"""
unsafe_getcurvegeom(::Type{G}, geom::AbstractGeometry) where {G <: AbstractGeometry} =
    G(GDAL.getcurvegeometry(geom.ptr, C_NULL))
unsafe_getcurvegeom(geom::AbstractGeometry, args...) =
    unsafe_getcurvegeom(Geometry, geom, args...)

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
function unsafe_polygonfromedges(
        ::Type{G},
        lines::AbstractGeometry,
        besteffort::Bool,
        autoclose::Bool,
        tol::Real
    ) where G <: AbstractGeometry
    perr = Ref{GDAL.OGRErr}()
    result = GDAL.buildpolygonfromedges(lines, besteffort, autoclose, tol, perr)
    @ogrerr perr[] "Failed to build polygon from edges."
    G(result)
end
unsafe_polygonfromedges(geom::AbstractGeometry, args...) =
    unsafe_polygonfromedges(Geometry, geom, args...)

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
setnonlineargeomflag!(flag::Bool) = GDAL.setnonlineargeometriesenabledflag(flag)

"Get flag to enable/disable returning non-linear geometries in the C API."
getnonlineargeomflag() = Bool(GDAL.getnonlineargeometriesenabledflag())

for (geom, wkbgeom) in ((:geomcollection,   GDAL.wkbGeometryCollection),
                        (:linestring,       GDAL.wkbLineString),
                        (:linearring,       GDAL.wkbLinearRing),
                        (:multilinestring,  GDAL.wkbMultiLineString),
                        (:multipoint,       GDAL.wkbMultiPoint),
                        (:multipolygon,     GDAL.wkbMultiPolygon),
                        (:point,            GDAL.wkbPoint),
                        (:polygon,          GDAL.wkbPolygon))
    @eval $(Symbol("unsafe_create$geom"))() = unsafe_creategeom($wkbgeom)
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

function unsafe_createpoint(xy::Tuple{T,U}) where {T <: Real, U <: Real}
    geom = unsafe_creategeom(GDAL.wkbPoint)
    addpoint!(geom, xy...)
    geom
end

function unsafe_createpoint(xyz::Tuple{T,U,V}) where {T <: Real, U <: Real, V <: Real}
    geom = unsafe_creategeom(GDAL.wkbPoint)
    addpoint!(geom, xyz...)
    geom
end

# Tuples of Vectors
for (geom, wkbgeom) in ((:linestring, GDAL.wkbLineString),
                        (:linearring, GDAL.wkbLinearRing))
    eval(quote
        function $(Symbol("unsafe_create$geom"))(xs::Vector{Cdouble},
                                                 ys::Vector{Cdouble})
            geom = unsafe_creategeom($wkbgeom)
            for (x,y) in zip(xs, ys)
                addpoint!(geom, x, y)
            end
            geom
        end

        function $(Symbol("unsafe_create$geom"))(xs::Vector{Cdouble},
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
        @eval function $(Symbol("unsafe_create$geom"))(coords::$typeargs)
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
    for (geom, wkbgeom, f) in ((:polygon, GDAL.wkbPolygon, :unsafe_createlinearring),
                               (:multilinestring, GDAL.wkbMultiLineString, :unsafe_createlinestring),
                               (:multipolygon_noholes, GDAL.wkbMultiPolygon, :unsafe_createpolygon))
        @eval function $(Symbol("unsafe_create$geom"))(coords::$typeargs)
                  geom = unsafe_creategeom($wkbgeom)
                  for coord in coords
                      addgeomdirectly!(geom, $(f)(coord))
                  end
                  geom
              end
    end
end

function unsafe_createmultipolygon(
        coords::Vector{Vector{Vector{Tuple{Cdouble,Cdouble}}}}
    )
    geom = unsafe_creategeom(GDAL.wkbMultiPolygon)
    for coord in coords
        addgeomdirectly!(geom, unsafe_createpolygon(coord))
    end
    geom
end
