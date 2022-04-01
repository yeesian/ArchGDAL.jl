# Geometric Operations

```@setup geometries
using ArchGDAL
```

In this section, we consider some of the common kinds of geometries that arises in applications. These include `Point`, `LineString`, `Polygon`, `GeometryCollection`, `MultiPolygon`, `MultiPoint`, and `MultiLineString`.

## Geometry Creation
To create geometries of different types, 

```@example geometries
point = ArchGDAL.createpoint(1.0, 2.0)
linestring = ArchGDAL.createlinestring([(i,i+1) for i in 1.0:3.0])
linearring = ArchGDAL.createlinearring([(0.,0.), (0.,1.), (1.,1.)])
simplepolygon = ArchGDAL.createpolygon([(0.,0.), (0.,1.), (1.,1.)])
complexpolygon = ArchGDAL.createpolygon([[(0.,0.), (0.,j), (j,j)] for j in 1.0:-0.1:0.9])
multipoint = ArchGDAL.createlinearring([(0.,0.), (0.,1.), (1.,1.)])
multilinestring = ArchGDAL.createmultilinestring([[(i,i+1) for i in j:j+3] for j in 1.0:5.0:6.0])
multipolygon = ArchGDAL.createmultipolygon([[[(0.,0.), (0.,j), (j,j)]] for j in 1.0:-0.1:0.9])
```

Alternatively, they can be assembled from their components.
```@example geometries
point = ArchGDAL.createpoint()
ArchGDAL.addpoint!(point, 1.0, 2.0)

linestring = ArchGDAL.createlinestring()
for i in 1.0:3.0
    ArchGDAL.addpoint!(linestring, i, i+1)
end

linearring = ArchGDAL.createlinearring()
for i in 1.0:3.0
    ArchGDAL.addpoint!(linearring, i, i+1)
end

polygon = ArchGDAL.createpolygon()
for j in 1.0:-0.1:0.9
    ring = ArchGDAL.createlinearring([(0.,0.), (0.,j), (j,j)])
    ArchGDAL.addgeom!(polygon, ring)
end

multipoint = ArchGDAL.createmultipoint()
for i in 1.0:3.0
    pt = ArchGDAL.createpoint(i, i+1)
    ArchGDAL.addgeom!(multipoint, pt)
end

multilinestring = ArchGDAL.createmultilinestring()
for j in 1.0:5.0:6.0
    line = ArchGDAL.createlinestring([(i,i+1) for i in j:j+3])
    ArchGDAL.addgeom!(multilinestring, line)
end

multipolygon = ArchGDAL.createmultipolygon()
for j in 1.0:-0.1:0.9
    poly = ArchGDAL.createpolygon([(0.,0.), (0.,j), (j,j)])
    ArchGDAL.addgeom!(multipolygon, poly)
end
```

They can also be constructed from other data formats such as:
* Well-Known Binary (WKB): [`ArchGDAL.fromWKB`](@ref)`([0x01,0x01,...,0x27,0x41])`
* Well-Known Text (WKT): [`ArchGDAL.fromWKT("POINT (1 2)")`](@ref)
* JavaScript Object Notation (JSON): [`ArchGDAL.fromJSON("""{"type":"Point","coordinates":[1,2]}""")`](@ref)

## Geometry Modification
The following methods are commonly used for retrieving elements of a geometry.

* [`ArchGDAL.getcoorddim(geom)`](@ref): dimension of the coordinates. Returns `0` for an empty point
* [`ArchGDAL.getspatialref(geom)`](@ref)
* [`ArchGDAL.getx(geom, i)`](@ref)
* [`ArchGDAL.gety(geom, i)`](@ref)
* [`ArchGDAL.getz(geom, i)`](@ref)
* [`ArchGDAL.getpoint(geom, i)`](@ref)
* [`ArchGDAL.getgeom(geom, i)`](@ref)

The following methods are commonly used for modifying or adding to a geometry.
* [`ArchGDAL.setcoorddim!(geom, dim)`](@ref)
* [`ArchGDAL.setpointcount!(geom, n)`](@ref)
* [`ArchGDAL.setpoint!(geom, i, x, y)`](@ref)
* [`ArchGDAL.setpoint!(geom, i, x, y, z)`](@ref)
* [`ArchGDAL.addpoint!(geom, x, y)`](@ref)
* [`ArchGDAL.addpoint!(geom, x, y, z)`](@ref)
* [`ArchGDAL.addgeom!(geom1, geom2)`](@ref)
* [`ArchGDAL.removegeom!(geom, i)`](@ref)
* [`ArchGDAL.removeallgeoms!(geom)`](@ref)

## Unary Operations
The following is an non-exhaustive list of unary operations available for geometries.

### Attributes

* [`ArchGDAL.geomdim(geom)`](@ref): `0` for points, `1` for lines and `2` for surfaces
* [`ArchGDAL.getcoorddim(geom)`](@ref): dimension of the coordinates. Returns `0` for an empty point
* [`ArchGDAL.envelope(geom)`](@ref): the bounding envelope for this geometry
* [`ArchGDAL.envelope3d(geom)`](@ref): the bounding envelope for this geometry
* [`ArchGDAL.wkbsize(geom)`](@ref): size (in bytes) of related binary representation
* [`ArchGDAL.getgeomtype(geom)`](@ref): geometry type code (in `OGRwkbGeometryType`)
* [`ArchGDAL.geomname(geom)`](@ref): WKT name for geometry type
* [`ArchGDAL.getspatialref(geom)`](@ref): spatial reference system. May be `NULL`
* [`ArchGDAL.geomlength(geom)`](@ref): the length of the geometry, or `0.0` for unsupported types
* [`ArchGDAL.geomarea(geom)`](@ref): the area of the geometry, or `0.0` for unsupported types

### Predicates
The following predicates return a `Bool`.

* [`ArchGDAL.isempty(geom)`](@ref)
* [`ArchGDAL.isvalid(geom)`](@ref)
* [`ArchGDAL.issimple(geom)`](@ref)
* [`ArchGDAL.isring(geom)`](@ref)
* [`ArchGDAL.hascurvegeom(geom, nonlinear::Bool)`](@ref)

### Immutable Operations
The following methods do not modify `geom`.

* [`ArchGDAL.clone(geom)`](@ref): a copy of the geometry with the original spatial reference system.
* [`ArchGDAL.forceto(geom, targettype)`](@ref): force the provided geometry to the specified geometry type.
* [`ArchGDAL.simplify(geom, tol)`](@ref): Compute a simplified geometry.
* [`ArchGDAL.simplifypreservetopology(geom, tol)`](@ref): Simplify the geometry while preserving topology.
* [`ArchGDAL.delaunaytriangulation(geom, tol, onlyedges)`](@ref): a delaunay triangulation of the vertices of the geometry.
* [`ArchGDAL.boundary(geom)`](@ref): the boundary of the geometry
* [`ArchGDAL.convexhull(geom)`](@ref): the convex hull of the geometry.
* [`ArchGDAL.buffer(geom, dist, quadsegs)`](@ref): a polygon containing the region within the buffer distance of the original geometry.
* [`ArchGDAL.union(geom)`](@ref): the union of the geometry using cascading
* [`ArchGDAL.pointonsurface(geom)`](@ref): Returns a point guaranteed to lie on the surface.
* [`ArchGDAL.centroid(geom)`](@ref): Compute the geometry centroid. It is not necessarily within the geometry.
* [`ArchGDAL.pointalongline(geom, distance)`](@ref): Fetch point at given distance along curve.
* [`ArchGDAL.polygonize(geom)`](@ref): Polygonizes a set of sparse edges.

### Mutable Operations
The following methods modifies the first argument `geom`.

* [`ArchGDAL.setcoorddim!(geom, dim)`](@ref): sets the explicit coordinate dimension.
* [`ArchGDAL.flattento2d!(geom)`](@ref): Convert geometry to strictly 2D.
* [`ArchGDAL.closerings!(geom)`](@ref): Force rings to be closed by adding the start point to the end.
* [`ArchGDAL.transform!(geom, coordtransform)`](@ref): Apply coordinate transformation to geometry.
* [`ArchGDAL.segmentize!(geom, maxlength)`](@ref): Modify the geometry such it has no segment longer than the given distance.
* [`ArchGDAL.empty!(geom)`](@ref): Clear geometry information.

### Export Formats

* [`ArchGDAL.toWKB(geom)`](@ref)
* [`ArchGDAL.toISOWKB(geom)`](@ref)
* [`ArchGDAL.toWKT(geom)`](@ref)
* [`ArchGDAL.toISOWKT(geom)`](@ref)
* [`ArchGDAL.toGML(geom)`](@ref)
* [`ArchGDAL.toKML(geom)`](@ref)
* [`ArchGDAL.toJSON(geom)`](@ref)

## Binary Operations
The following is an non-exhaustive list of binary operations available for geometries.

### Predicates
The following predicates return a `Bool`.

* [`ArchGDAL.intersects(g1, g2)`](@ref)
* [`ArchGDAL.equals(g1, g2)`](@ref)
* [`ArchGDAL.disjoint(g1, g2)`](@ref)
* [`ArchGDAL.touches(g1, g2)`](@ref)
* [`ArchGDAL.crosses(g1, g2)`](@ref)
* [`ArchGDAL.within(g1, g2)`](@ref)
* [`ArchGDAL.contains(g1, g2)`](@ref)
* [`ArchGDAL.overlaps(g1, g2)`](@ref)

### Prepared geometry
When repeatedly calling [`ArchGDAL.intersects(g1, g2)`](@ref) and [`ArchGDAL.contains(g1, g2)`](@ref) on the same
geometry, for example, when intersecting 50 points with a 100 polygons, it is possible to increase performance
by caching required--otherwise repeatedly calculated--information on geometries.
You can do this by *preparing* a geometry by calling [`ArchGDAL.preparegeom(geom)`](@ref) and using the
resulting prepared geometry as the first argument for [`ArchGDAL.intersects(g1, g2)`](@ref) or [`ArchGDAL.contains(g1, g2)`](@ref).

If you use a custom GDAL installation, you can check whether it supports prepared geometries by calling [`ArchGDAL.has_preparedgeom_support()`](@ref).

### Immutable Operations
The following methods do not mutate the input geomteries `g1` and `g2`.

* [`ArchGDAL.intersection(g1, g2)`](@ref)
* [`ArchGDAL.union(g1, g2)`](@ref)
* [`ArchGDAL.difference(g1, g2)`](@ref)
* [`ArchGDAL.symdifference(g1, g2)`](@ref)

### Mutable Operations
The following method modifies the first argument `g1`.

* [`ArchGDAL.addgeom!(g1, g2)`](@ref)

