# Working with Spatialite

Here is an example of how you can work with a SQLite Database in ArchGDAL.jl, and follows the tutorial in http://www.gaia-gis.it/gaia-sins/spatialite-tutorial-2.3.1.html.

We will work with the following database:

```@example spatialite
import ArchGDAL
const AG = ArchGDAL

filepath = download("https://github.com/yeesian/ArchGDALDatasets/raw/e0b15dca5ad493c5ebe8111688c5d14b031b7305/spatialite/test-2.3.sqlite", "test.sqlite")
```

Here's a quick summary of `test.sqlite`:

```@example spatialite
AG.read(filepath) do dataset
    print(dataset)
end
```

We will display the results of running `query` on the dataset using the following function:

```@example spatialite
function inspect(query, filename=filepath)
    AG.read(filename) do dataset
        AG.executesql(dataset, query) do results
            print(results)
        end
    end
end
```

## Constructing SQL Queries

### A Simple LIMIT Query
Here's a first query:
```@example spatialite
inspect("SELECT * FROM towns LIMIT 5")
```

A few points to understand:
* the `SELECT` statement requests SQLite to perform a query
* fetching all columns `[*]`
* `FROM` the database table of name `towns`
* retrieving only the first five rows [`LIMIT 5`]

### A Simple ORDER BY Query
Now try this second SQL query:

```@example spatialite
inspect("select name AS Town, peoples as Population from towns ORDER BY name LIMIT 5")
```

Some remarks:
* in SQL, constructs using lower- or upper-case have identical effects; So the commands constructed using `SELECT` and `select`, or `FROM` and `from` are equivalent.
* you can freely choose which columns to fetch, determine their ordering, and rename then if you wish by using the `AS` clause.
* you can order the fetched rows by using the `ORDER BY` clause.

### The WHERE and ORDER BY clauses
A more complex SQL query:
```@example spatialite
inspect("""select name, peoples from towns
           WHERE peoples > 350000 order by peoples DESC""")
```

Some remarks:
* you can filter a specific set of rows by imposing a `WHERE` clause; only those rows that satisfies the logical expression you specify will be fetched.
* In this example only `towns` with a population greater than `350000` peoples has been fetched.
* you can order rows in *descending* order if appropriate, by using the `DESC` clause.

### Using SQL functions
```@example spatialite
inspect("""
select COUNT(*) as '# Towns',
    MIN(peoples) as Smaller,
    MAX(peoples) as Bigger,
    SUM(peoples) as 'Total peoples',
    SUM(peoples) / COUNT(*) as 'mean peoples for town'
from towns
""")
```

* you can split complex queries along many lines
* you can use *functions* in an SQL query. `COUNT()`, `MIN()`, `MAX()` and `SUM()` are functions. Not at all surprisingly:
    * `COUNT()` returns the total number of rows.
    * `MIN()` returns the minimum value for the given column.
    * `MAX()` returns the maximum value for the given column.
    * `SUM()` returns the total of all values for the given column.
* you can do *calculations* in your query. e.g. we have calculated the `mean` of peoples per village dividing the `SUM()` by the `COUNT()` values.

### Constructing Expressions

```@example spatialite
inspect("select (10 - 11) * 2 as Number, ABS((10 - 11) * 2) as AbsoluteValue")
```

* the `(10 - 11) * 2` term is an example of an `expression`.
* the `ABS()` function returns the *absolute value* of a number.
* note that in this example we have not used any DB column or DB table at all.

### The HEX() function
```@example spatialite
inspect("""
select name, peoples, HEX(Geometry)
from Towns where peoples > 350000 order by peoples DESC
""")
```

* the `HEX()` function returns the hexadecimal representation of a `BLOB` column value.
* in the preceding execution of this query, the geom column seemed empty; now, by using the `HEX()` function, we discover that it contains lots of strange binary data.
* *geom* contains `GEOMETRY` values, stored as `BLOB`s and encoded in the internal representation used by SpatiaLite.

!!! note
    
    SQLite in its own hasn't the slightest idea of what `GEOMETRY` is, and cannot do any other operation on it. To really use `GEOMETRY` values, it's time use the SpatiaLite extension.

## Spatialite Features

### Well-Known Text
```@example spatialite
inspect("""
SELECT name, peoples, AsText(Geometry)
from Towns where peoples > 350000 order by peoples DESC
""")
```
* the `AsText()` function comes from SpatiaLite, and returns the *Well Known Text - WKT* representation for a `GEOMETRY` column value. WKT is a standard notation conformant to OpenGIS specification.
* in the preceding execution of this query, the `HEX()` function returned lots of strange binary data. Now the `AsText()` function shows useful and quite easily understandable `GEOMETRY` values.
* a `POINT` is the simplest `GEOMETRY` class, and has only a couple of `[X,Y]` coordinates.

### Working with Coordinates
```@example spatialite
inspect("""
SELECT name, X(Geometry), Y(Geometry) FROM Towns
WHERE peoples > 350000 
ORDER BY peoples DESC
""")
```
* the SpatiaLite `X()` function returns the *X coordinate* for a `POINT`.
* the `Y()` function returns the *Y coordinate* for a `POINT`.

```@example spatialite
inspect("SELECT HEX(GeomFromText('POINT(10 20)'))")
```

### Format Conversions
you can use the following `GEOMETRY` format conversion functions:
```@example spatialite
inspect("SELECT HEX(AsBinary(GeomFromText('POINT(10 20)')))")
```
```@example spatialite
inspect("SELECT AsText(GeomFromWKB(X'010100000000000000000024400000000000003440'))")
```
* the SpatiaLite `GeomFromText()` function returns the internal `BLOB` representation for a `GEOMETRY`.
* the `AsBinary()` function returns the *Well Known Binary - WKB* representation for a `GEOMETRY` column value. WKB is a standard notation conformant to OpenGIS specification.
* the `GeomFromWKB()` function converts a WKB value into the corresponding internal `BLOB` value.

## GEOMETRY Classes

### LINESTRING
```@example spatialite
inspect("SELECT PK_UID, AsText(Geometry) FROM HighWays WHERE PK_UID = 10")
```
* `LINESTRING` is another `GEOMETRY` class, and has lots of `POINT`s.
* in this case you have fetched a very simple `LINESTRING`, representing a polyline with just 4 vertices.
* it isn't unusual to encounter `LINESTRING`s with thousands of vertices in real GIS data.

```@example spatialite
inspect("""
SELECT PK_UID, NumPoints(Geometry), GLength(Geometry),
       Dimension(Geometry), GeometryType(Geometry)
FROM HighWays ORDER BY NumPoints(Geometry) DESC LIMIT 5
""")
```
* the SpatiaLite `NumPoints()` function returns the *number of vertices* for a `LINESTRING GEOMETRY`.
* the `GLength()` function returns the *geometric length* [expressed in *map units*] for a `LINESTRING GEOMETRY`.
* the `Dimension()` function returns the *dimensions'* number for any `GEOMETRY` class [e.g. 1 for lines].
* the `GeometryType()` function returns the *class type* for any kind of `GEOMETRY` value.

```@example spatialite
inspect("""
SELECT PK_UID, NumPoints(Geometry),
       AsText(StartPoint(Geometry)), AsText(EndPoint(Geometry)),
       X(PointN(Geometry, 2)), Y(PointN(Geometry, 2))
FROM HighWays ORDER BY NumPoints(Geometry) DESC LIMIT 5
""")
```

* the SpatiaLite `StartPoint()` function returns the first `POINT` for a `LINESTRING GEOMETRY`.
* the `EndPoint()` function returns the last `POINT` for a `LINESTRING GEOMETRY`.
* the `PointN()` function returns the selected vertex as a `POINT`; each one vertex is identified by a relative index. The first vertex is identified by an index value `1`, the second by an index value `2` and so on.
* You can freely nest the various SpatiaLite functions, by passing the return value of the inner function as an argument for the outer one.

### POLYGON
```@example spatialite
inspect("SELECT name, AsText(Geometry) FROM Regions WHERE PK_UID = 52")
```
* `POLYGON` is another `GEOMETRY` class.
* in this case you have fetched a very simple `POLYGON`, having only the *exterior ring* [i.e. it doesn't contains any internal hole]. Remember that POLYGONs may optionally contain an arbitrary number of *internal holes*, each one delimited by an *interior ring*.
* the *exterior ring* in itself is simply a `LINESTRING` [and *interior rings* too are `LINESTRINGS`].
* note that a POLYGON is a *closed geometry*, and thus the first and the last POINT for each *ring* are exactly identical.

```@example spatialite
inspect("""
SELECT PK_UID, Area(Geometry), AsText(Centroid(Geometry)),
       Dimension(Geometry), GeometryType(Geometry)
FROM Regions ORDER BY Area(Geometry) DESC LIMIT 5
""")
```
* we have already meet the SpatiaLite `Dimension()` and `GeometryType()` functions; they works for `POLYGON`s exactly in same fashion as for any other kind of `GEOMETRY`.
* the SpatiaLite `Area()` function returns the geometric area [expressed in *square map units*] for a `POLYGON GEOMETRY`.
* the `Centroid()` function returns the `POINT` identifying the *centroid* for a `POLYGON GEOMETRY`.

```@example spatialite
inspect("""
SELECT PK_UID, NumInteriorRings(Geometry),
       NumPoints(ExteriorRing(Geometry)), NumPoints(InteriorRingN(Geometry, 1))
FROM regions ORDER BY NumInteriorRings(Geometry) DESC LIMIT 5
""")
```

* the SpatiaLite `ExteriorRing()` functions returns the exterior ring for a given `GEOMETRY`. Any valid `POLYGON` must have an *exterior ring*. Remember: each one of the rings belonging to a `POLYGON` is a closed `LINESTRING`.
* the SpatiaLite `NumInteriorRings()` function returns the number of interior rings belonging to a `POLYGON`. A valid `POLYGON` may have any number of interior rings, including *zero* i.e. no interior ring at all.
* The SpatiaLite `InteriorRingN()` function returns the selected interior rings as a `LINESTRING`; each one interior ring is identified by a relative index. The first interior ring is identified by an index value `1`, the second by an index value `2` and so on.
* Any ring is a `LINESTRING`, so we can use the `NumPoints()` function in order to detect the number of related vertices. If we call the `NumPoints()` function on a `NULL GEOMETRY` [or on a `GEOMETRY` of non-`LINESTRING` class] we'll get a `NULL` result. This explains why the the last three rows has a `NULL` `NumPoints()` result; there is no corresponding interior ring!

```@example spatialite
inspect("""
SELECT AsText(InteriorRingN(Geometry, 1)),
       AsText(PointN(InteriorRingN(Geometry, 1), 4)),
       X(PointN(InteriorRingN(Geometry, 1), 5)),
       Y(PointN(InteriorRingN(Geometry, 1), 5))
FROM Regions WHERE PK_UID = 55
""")
```
* we have already met in the preceding ones the usage of nested functions. For `POLYGON`s it becomes to be a little more tedious, but still easily understandable.
* e.g. to obtain the last column we have used `InteriorRingN()` in order to get the first interior ring, and then `PointN()` to get the *fifth* vertex. At last we can call `Y()` to get the coordinate value.

```@example spatialite
inspect("""
SELECT Name, AsText(Envelope(Geometry)) FROM Regions LIMIT 5
""")
```
* the SpatiaLite `Envelope()` function always returns a `POLYGON` that is the *Minimum Bounding Rectangle - MBR* for the given `GEOMETRY`. Because an MBR is a rectangle, it always has `5 POINT`s [remember: in closed geometries the last POINT must be identical to the first one].
* individual `POINT`s are as follows:
    * POINT #1: `minX,minY`
    * POINT #2: `maxX,minY`
    * POINT #3: `maxX,maxY`
    * POINT #4: `minX,maxY`
    * POINT #5: `minX,minY`
* MBRs are of peculiar interest, because by using them you can evaluate spatial relationships between two geometries in a simplified and roughly approximative way. But MBR comparisons are very fast to compute, so they are very useful and widely used to speed up data processing.
* MBRs are also widely referenced as *bounding boxes*, or "BBOX" as well.

### Complex Geometry Classes
`POINT`, `LINESTRING` and `POLYGON` are the elementary classes for `GEOMETRY`. But `GEOMETRY` supports the following complex classes as well:
* a `MULTIPOINT` is a collection of two or more `POINT`s belonging to the same entity.
* a `MULTILINESTRING` is a collection of two or more `LINESTRING`s.
* a `MULTIPOLYGON` is a collection of two or more `POLYGON`s.
* a `GEOMETRYCOLLECTION` is an arbitrary collection containing any other kind of geometries.

We'll not explain in detail this kind of collections, because it will be simply too boring and dispersive. Generally speaking, they extend in the expected way to their corresponding elementary classes, e.g.
* the SpatiaLite `NumGeometries()` function returns the number of elements for a collection.
* the `GeometryN()` function returns the *N-th* element for a collection.
* the `GLength()` function applied to a `MULTILINESTRING` returns the sum of individual lengths for each `LINESTRING` composing the collection.
* the `Area()` function applied to a `MULTIPOLYGON` returns the sum of individual areas for each `POLYGON` in the collection.
* the `Centroid()` function returns the *average centroid* when applied to a `MULTIPOLYGON`.
