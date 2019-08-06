# Geometric Operations

In this section, we consider some of the common kinds of geometries that arises in applications. These include `Point`, `LineString`, `Polygon`, `GeometryCollection`, `MultiPolygon`, `MultiPoint`, and `MultiLineString`. For brevity in the examples, we will use the prefix `const AG = ArchGDAL`.

## Geometry Creation
To create geometries of different types.

```julia
point = AG.createpoint(1.0, 2.0)
linestring = AG.createlinestring([(i,i+1) for i in 1.0:3.0])
linearring = AG.createlinearring([(0.,0.), (0.,1.), (1.,1.)])
simplepolygon = AG.createpolygon([(0.,0.), (0.,1.), (1.,1.)])
complexpolygon = AG.createpolygon([[(0.,0.), (0.,j), (j,j)] for j in 1.0:-0.1:0.9])
multipoint = AG.createlinearring([(0.,0.), (0.,1.), (1.,1.)])
multilinestring = AG.createmultilinestring([[(i,i+1) for i in j:j+3] for j in 1.0:5.0:6.0])
multipolygon = AG.createmultipolygon([[[(0.,0.), (0.,j), (j,j)]] for j in 1.0:-0.1:0.9])
```

Alternatively, they can be assembled from their components.
```julia
point = AG.createpoint()
    AG.addpoint!(point, 1.0, 2.0)
linestring = AG.createlinestring()
    for i in 1.0:3.0
        AG.addpoint!(linestring, i, i+1)
    end
linearring = AG.createlinearring()
    for i in 1.0:3.0
        AG.addpoint!(linearring, i, i+1)
    end
polygon = AG.createpolygon()
    for j in 1.0:-0.1:0.9
        ring = AG.createlinearring([(0.,0.), (0.,j), (j,j)])
        AG.push!(polygon, ring)
    end
multipoint = AG.createmultipoint()
    for i in 1.0:3.0
        pt = AG.createpoint(i, i+1)
        AG.push!(multipoint, pt)
    end
multilinestring = AG.createmultilinestring()
    for j in 1.0:5.0:6.0
        line = AG.createlinestring([(i,i+1) for i in j:j+3])
        AG.push!(multilinestring, line)
    end
multipolygon = AG.createmultipolygon()
    for j in 1.0:-0.1:0.9
        poly = AG.createpolygon([(0.,0.), (0.,j), (j,j)])
        AG.push!(multipolygon, poly)
    end
```

They can also be constructed from other data formats such as:
* Well-Known Binary (WKB): `AG.fromWKB([0x01,0x01,...,0x27,0x41])`
* Well-Known Text (WKT): `AG.fromWKT("POINT (1 2)")`
* JavaScript Object Notation (JSON): `AG.fromJSON("""{"type":"Point","coordinates":[1,2]}""")`

## Geometry Modification
The following methods are commonly used for retrieving elements of a geometry.

* `AG.getcoorddim(geom)`: dimension of the coordinates. Returns `0` for an empty point
* `AG.getspatialref(geom)`
* `AG.getx(geom, i)`
* `AG.gety(geom, i)`
* `AG.getz(geom, i)`
* `AG.getpoint(geom, i)`
* `AG.getgeom(geom, i)`

The following methods are commonly used for modifying or adding to a geometry.
* `AG.setcoorddim!(geom, dim)`
* `AG.setpointcount!(geom, n)`
* `AG.setpoint!(geom, i, x, y)`
* `AG.setpoint!(geom, i, x, y, z)`
* `AG.addpoint!(geom, x, y)`
* `AG.addpoint!(geom, x, y, z)`
* `AG.push!(geom1, geom2)`
* `AG.removegeom!(geom, i)`
* `AG.removeallgeoms!(geom)`

## Unary Operations
The following is an non-exhaustive list of unary operations available for geometries.

### Attributes

* `AG.getdim(geom)`: `0` for points, `1` for lines and `2` for surfaces
* `AG.getcoorddim(geom)`: dimension of the coordinates. Returns `0` for an empty point
* `AG.getenvelope(geom)`: the bounding envelope for this geometry
* `AG.getenvelope3d(geom)`: the bounding envelope for this geometry
* `AG.wkbsize(geom)`: size (in bytes) of related binary representation
* `AG.getgeomtype(geom)`: geometry type code (in `OGRwkbGeometryType`)
* `AG.getgeomname(geom)`: WKT name for geometry type
* `AG.getspatialref(geom)`: spatial reference system. May be `NULL`
* `AG.geomlength(geom)`: the length of the geometry, or `0.0` for unsupported types
* `AG.geomarea(geom)`: the area of the geometry, or `0.0` for unsupported types

### Predicates
The following predicates return a `Bool`.

* `AG.isempty(geom)`
* `AG.isvalid(geom)`
* `AG.issimple(geom)`
* `AG.isring(geom)`
* `AG.hascurvegeom(geom, nonlinear::Bool)`

### Immutable Operations
The following methods do not modify `geom`.

* `AG.clone(geom)`: a copy of the geometry with the original spatial reference system.
* `AG.forceto(geom, targettype)`: force the provided geometry to the specified geometry type.
* `AG.simplify(geom, tol)`: Compute a simplified geometry.
* `AG.simplifypreservetopology(geom, tol)`: Simplify the geometry while preserving topology.
* `AG.delaunaytriangulation(geom, tol, onlyedges)`: a delaunay triangulation of the vertices of the geometry.
* `AG.boundary(geom)`: the boundary of the geometry
* `AG.convexhull(geom)`: the convex hull of the geometry.
* `AG.buffer(geom, dist, quadsegs)`: a polygon containing the region within the buffer distance of the original geometry.
* `AG.union(geom)`: the union of the geometry using cascading
* `AG.pointonsurface(geom)`: Returns a point guaranteed to lie on the surface.
* `AG.centroid(geom)`: Compute the geometry centroid. It is not necessarily within the geometry.
* `AG.pointalongline(geom, distance)`: Fetch point at given distance along curve.
* `AG.polygonize(geom)`: Polygonizes a set of sparse edges.

### Mutable Operations
The following methods modifies the first argument `geom`.

* `AG.setcoorddim!(geom, dim)`: sets the explicit coordinate dimension.
* `AG.flattento2d!(geom)`: Convert geometry to strictly 2D.
* `AG.closerings!(geom)`: Force rings to be closed by adding the start point to the end.
* `AG.transform!(geom, coordtransform)`: Apply coordinate transformation to geometry.
* `AG.segmentize!(geom, maxlength)`: Modify the geometry such it has no segment longer than the given distance.
* `AG.empty!(geom)`: Clear geometry information.

### Export Formats

* `AG.toWKB(geom)`
* `AG.toISOWKB(geom)`
* `AG.toWKT(geom)`
* `AG.toISOWKT(geom)`
* `AG.toGML(geom)`
* `AG.toKML(geom)`
* `AG.toJSON(geom)`

## Binary Operations
The following is an non-exhaustive list of binary operations available for geometries.

### Predicates
The following predicates return a `Bool`.

* `AG.intersects(g1, g2)`
* `AG.equals(g1, g2)`
* `AG.disjoint(g1, g2)`
* `AG.touches(g1, g2)`
* `AG.crosses(g1, g2)`
* `AG.within(g1, g2)`
* `AG.contains(g1, g2)`
* `AG.overlaps(g1, g2)`

### Immutable Operations
The following methods do not mutate the input geomteries `g1` and `g2`.

* `AG.intersection(g1, g2)`
* `AG.union(g1, g2)`
* `AG.difference(g1, g2)`
* `AG.symdifference(g1, g2)`

### Mutable Operations
The following method modifies the first argument `g1`.

* `AG.push!(g1, g2)`

