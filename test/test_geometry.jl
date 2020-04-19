using Test
import GeoInterface, GeoFormatTypes, GDAL, ArchGDAL;
const AG = ArchGDAL
const GFT = GeoFormatTypes

@testset "Incomplete GeoInterface geometries" begin
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbCircularString))
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbCompoundCurve))
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbCurvePolygon))
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbMultiSurface))
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbPolyhedralSurface))
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbTIN))
    @test_logs (:warn, "unknown geometry type") GeoInterface.geotype(AG.creategeom(GDAL.wkbTriangle))
end

@testset "Create a Point" begin
    # Method 1
    AG.createpoint(100, 70) do point
        @test GeoInterface.geotype(point) == :Point
        @test isapprox(GeoInterface.coordinates(point), [100,70], atol=1e-6)
        @test AG.geomdim(point) == 0
        @test AG.getcoorddim(point) == 2
        AG.setcoorddim!(point, 3)
        @test AG.getcoorddim(point) == 3
        @test AG.isvalid(point) == true
        @test AG.issimple(point) == true
        @test AG.isring(point) == false
        @test AG.getz(point, 0) == 0

        @test sprint(print, AG.envelope(point)) == "GDAL.OGREnvelope(100.0, 100.0, 70.0, 70.0)"
        @test sprint(print, AG.envelope3d(point)) == "GDAL.OGREnvelope3D(100.0, 100.0, 70.0, 70.0, 0.0, 0.0)"
        @test AG.toISOWKB(point, GDAL.wkbNDR) == UInt8[0x01,0xe9,0x03,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x59,0x40,0x00,0x00,0x00,0x00,0x00,0x80,
        0x51,0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
        @test AG.toISOWKB(point, GDAL.wkbXDR) == UInt8[0x00,0x00,0x00,0x03,0xe9,
        0x40,0x59,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x51,0x80,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
        @test AG.toKML(point, "relativeToGround") == "<Point><altitudeMode>relativeToGround</altitudeMode><coordinates>100,70,0</coordinates></Point>"
        @test AG.toKML(point, "clampToGround") == "<Point><altitudeMode>clampToGround</altitudeMode><coordinates>100,70,0</coordinates></Point>"
        @test AG.toKML(point) == "<Point><coordinates>100,70,0</coordinates></Point>"
        @test AG.toJSON(point) == "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0, 0.0 ] }"
        AG.createpoint(100,70,0) do point2
            @test isapprox(GeoInterface.coordinates(point2), [100,70,0], atol=1e-6)
            @test AG.equals(point, point2) == true
        end
        AG.createpoint((100,70,0)) do point3
            @test AG.equals(point, point3) == true
        end
        AG.createpoint([100,70,0]) do point4
            @test AG.equals(point, point4) == true
        end
        point5 = AG.createpoint([100,70,0])
        @test AG.equals(point, point5) == true
        AG.flattento2d!(point)
        @test AG.getcoorddim(point) == 2
        @test AG.getnonlineargeomflag() == true
        AG.setnonlineargeomflag!(false)
        @test AG.getnonlineargeomflag() == false
        AG.setnonlineargeomflag!(true)
        @test AG.getnonlineargeomflag() == true
        AG.closerings!(point)
        @test AG.toJSON(point) == "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0 ] }"
    end

    # Method 2
    point = AG.createpoint(100, 70)
    @test AG.geomdim(point) == 0
    @test AG.getcoorddim(point) == 2
    AG.setcoorddim!(point, 3)
    @test AG.getcoorddim(point) == 3
    @test AG.isvalid(point) == true
    @test AG.issimple(point) == true
    @test AG.isring(point) == false
    @test AG.getz(point, 0) == 0
    @test sprint(print, AG.envelope(point)) == "GDAL.OGREnvelope(100.0, 100.0, 70.0, 70.0)"
    @test sprint(print, AG.envelope3d(point)) == "GDAL.OGREnvelope3D(100.0, 100.0, 70.0, 70.0, 0.0, 0.0)"
    @test AG.toISOWKB(point, GDAL.wkbNDR) == UInt8[0x01,0xe9,0x03,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x59,0x40,0x00,0x00,0x00,0x00,0x00,0x80,
    0x51,0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
    @test AG.toISOWKB(point, GDAL.wkbXDR) == UInt8[0x00,0x00,0x00,0x03,0xe9,
    0x40,0x59,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x51,0x80,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
    @test AG.toKML(point, "relativeToGround") == "<Point><altitudeMode>relativeToGround</altitudeMode><coordinates>100,70,0</coordinates></Point>"
    @test AG.toKML(point, "clampToGround") == "<Point><altitudeMode>clampToGround</altitudeMode><coordinates>100,70,0</coordinates></Point>"
    @test AG.toKML(point) == "<Point><coordinates>100,70,0</coordinates></Point>"
    @test AG.toJSON(point) == "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0, 0.0 ] }"
    @test AG.equals(point, AG.createpoint(100,70,0)) == true
    @test AG.equals(point, AG.createpoint((100,70,0))) == true
    AG.flattento2d!(point)
    @test AG.getcoorddim(point) == 2
    @test AG.getnonlineargeomflag() == true
    AG.setnonlineargeomflag!(false)
    @test AG.getnonlineargeomflag() == false
    AG.setnonlineargeomflag!(true)
    @test AG.getnonlineargeomflag() == true
    AG.closerings!(point)
    @test AG.toJSON(point) == "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0 ] }"
end

@testset "Testing construction of complex geometries" begin
    @test AG.toWKT(AG.createlinestring([1.,2.,3.], [4.,5.,6.])) == "LINESTRING (1 4,2 5,3 6)"
    AG.createlinestring([1.,2.,3.], [4.,5.,6.]) do geom
        @test GeoInterface.geotype(geom) == :LineString
        @test isapprox(GeoInterface.coordinates(geom), [[1,4],[2,5],[3,6]], atol=1e-6)
        @test AG.toWKT(geom) == "LINESTRING (1 4,2 5,3 6)"
        AG.closerings!(geom)
        @test AG.toWKT(geom) == "LINESTRING (1 4,2 5,3 6)"
        AG.setpoint!(geom, 1, 10, 10)
        @test AG.toWKT(geom) == "LINESTRING (1 4,10 10,3 6)"
        @test GFT.val(convert(GFT.WellKnownText, geom)) == AG.toWKT(geom)  
    end
    AG.createlinestring([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @test AG.toWKT(geom) == "LINESTRING (1 4 7,2 5 8,3 6 9)"
        AG.setpoint!(geom, 1, 10, 10, 10)
        @test AG.toWKT(geom) == "LINESTRING (1 4 7,10 10 10,3 6 9)"
        AG.addpoint!(geom, 11, 11, 11)
        @test AG.toWKT(geom) == "LINESTRING (1 4 7,10 10 10,3 6 9,11 11 11)"
    end
    
    @test AG.toWKT(AG.createlinearring([1.,2.,3.], [4.,5.,6.])) == "LINEARRING (1 4,2 5,3 6)"
    AG.createlinearring([1.,2.,3.], [4.,5.,6.]) do geom
        # @test GeoInterface.geotype(geom) == :LinearRing
        @test isapprox(GeoInterface.coordinates(geom), [[1,4],[2,5],[3,6]], atol=1e-6)
        @test AG.toWKT(geom) == "LINEARRING (1 4,2 5,3 6)"
        AG.setpointcount!(geom, 5)
        @test AG.toWKT(geom) == "LINEARRING (1 4,2 5,3 6,0 0,0 0)"
        AG.empty!(geom)
        @test AG.toWKT(geom) == "LINEARRING EMPTY"
    end
    AG.createlinearring([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @test AG.toWKT(geom) == "LINEARRING (1 4 7,2 5 8,3 6 9)"
        AG.closerings!(geom)
        @test AG.toWKT(geom) == "LINEARRING (1 4 7,2 5 8,3 6 9,1 4 7)"
    end

    @test AG.toWKT(AG.createpolygon([1.,2.,3.], [4.,5.,6.])) == "POLYGON ((1 4,2 5,3 6))"
    AG.createpolygon([1.,2.,3.], [4.,5.,6.]) do geom
        @test GeoInterface.geotype(geom) == :Polygon
        @test isapprox(GeoInterface.coordinates(geom), [[[1,4],[2,5],[3,6]]], atol=1e-6)
        @test AG.toWKT(geom) == "POLYGON ((1 4,2 5,3 6))"
    end
    AG.createpolygon([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @test AG.toWKT(geom) == "POLYGON ((1 4 7,2 5 8,3 6 9))"
        AG.closerings!(geom)
        @test AG.toWKT(geom) == "POLYGON ((1 4 7,2 5 8,3 6 9,1 4 7))"
    end

    @test AG.toWKT(AG.createmultipoint([1.,2.,3.], [4.,5.,6.])) == "MULTIPOINT (1 4,2 5,3 6)"
    AG.createmultipoint([1.,2.,3.], [4.,5.,6.]) do geom
        @test GeoInterface.geotype(geom) == :MultiPoint
        @test isapprox(GeoInterface.coordinates(geom), [[1,4],[2,5],[3,6]], atol=1e-6)
        @test AG.toWKT(geom) == "MULTIPOINT (1 4,2 5,3 6)"
    end
    AG.createmultipoint([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @test AG.toWKT(geom) == "MULTIPOINT (1 4 7,2 5 8,3 6 9)"
    end

    @test AG.toWKT(AG.createmultipolygon(Vector{Vector{Tuple{Cdouble,Cdouble}}}[
        Vector{Tuple{Cdouble,Cdouble}}[
            [(0,0),(0,4),(4,4),(4,0)],
            [(1,1),(1,3),(3,3),(3,1)]],
        Vector{Tuple{Cdouble,Cdouble}}[
            [(10,0),(10,4),(14,4),(14,0)],
            [(11,1),(11,3),(13,3),(13,1)]]]
    )) == "MULTIPOLYGON (((0 0,0 4,4 4,4 0),(1 1,1 3,3 3,3 1)),((10 0,10 4,14 4,14 0),(11 1,11 3,13 3,13 1)))"
    AG.createmultipolygon(Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(0,0),(0,4),(4,4),(4,0)],
                                [(1,1),(1,3),(3,3),(3,1)]],
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(10,0),(10,4),(14,4),(14,0)],
                                [(11,1),(11,3),(13,3),(13,1)]]]) do geom
        @test GeoInterface.geotype(geom) == :MultiPolygon
        @test isapprox(
            GeoInterface.coordinates(geom), [
                [[[0,0],[0,4],[4,4],[4,0]], [[1,1],[1,3],[3,3],[3,1]]],
                [[[10,0],[10,4],[14,4],[14,0]], [[11,1],[11,3],[13,3],[13,1]]]
            ],
            atol=1e-6
        )
        @test AG.toWKT(geom) == "MULTIPOLYGON (((0 0,0 4,4 4,4 0),(1 1,1 3,3 3,3 1)),((10 0,10 4,14 4,14 0),(11 1,11 3,13 3,13 1)))"
    end

    AG.fromWKT("CURVEPOLYGON(CIRCULARSTRING(-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0),(-1 0,0 0.5,1 0,0 1,-1 0))") do geom
        @test AG.toWKT(AG.curvegeom(AG.lineargeom(geom, 0.5))) == "CURVEPOLYGON (CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0),(-1 0,0.0 0.5,1 0,0 1,-1 0))"
        AG.lineargeom(geom, 0.5) do lgeom
            AG.curvegeom(lgeom) do clgeom
                @test AG.toWKT(clgeom) == "CURVEPOLYGON (CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0),(-1 0,0.0 0.5,1 0,0 1,-1 0))"
            end
            @test AG.ngeom(AG.polygonize(AG.forceto(lgeom, GDAL.wkbMultiLineString))) == 2
            AG.forceto(lgeom, GDAL.wkbMultiLineString) do mlsgeom
                AG.polygonize(mlsgeom) do plgeom
                    @test AG.ngeom(plgeom) == 2
                end
            end
        end
    end
end

@testset "Testing remaining methods for geometries" begin
    geom1 = AG.createmultipolygon(Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(0,0),(0,4),(4,4),(4,0)],
                                [(1,1),(1,3),(3,3),(3,1)]],
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(10,0),(10,4),(14,4),(14,0)],
                                [(11,1),(11,3),(13,3),(13,1)]]])
    geom2 = AG.createmultipoint([1.,2.,3.], [4.,5.,6.], [7.,8.,9.])

    AG.closerings!(geom1)
    @test AG.disjoint(geom1, geom2) == false
    @test AG.touches(geom1, geom2) == true
    @test AG.crosses(geom1, geom2) == false
    @test AG.overlaps(geom1, geom2) == false

    @test AG.toWKT(AG.boundary(geom2)) == "GEOMETRYCOLLECTION EMPTY"
    AG.boundary(geom2) do result
        @test AG.toWKT(result) == "GEOMETRYCOLLECTION EMPTY"
    end

    @test AG.toWKT(AG.union(geom1, geom2)) == "GEOMETRYCOLLECTION (POINT (2 5 8),POINT (3 6 9),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
    AG.union(geom1, geom2) do result
        @test AG.toWKT(result) == "GEOMETRYCOLLECTION (POINT (2 5 8),POINT (3 6 9),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
        @test AG.hascurvegeom(result, true) == false
        @test AG.hascurvegeom(result, false) == false
    end

    @test AG.toWKT(AG.difference(geom1, geom2)) == "MULTIPOLYGON (((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
    AG.difference(geom1, geom2) do result
        @test AG.toWKT(result) == "MULTIPOLYGON (((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
        AG.segmentize!(result, 20)
        @test AG.toWKT(result) == "MULTIPOLYGON (((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
        AG.segmentize!(result, 2)
        @test AG.toWKT(result) == "MULTIPOLYGON (((0 0 8,0 2 8,0 4 8,2 4 8,4 4 8,4 2 8,4 0 8,2 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10 2 8,10 4 8,12 4 8,14 4 8,14 2 8,14 0 8,12 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
    end

    @test AG.toWKT(AG.symdifference(geom1, geom2)) == "GEOMETRYCOLLECTION (POINT (2 5 8),POINT (3 6 9),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
    AG.symdifference(geom1, geom2) do result
        @test GeoInterface.geotype(result) == :GeometryCollection
        @test AG.toWKT(result) == "GEOMETRYCOLLECTION (POINT (2 5 8),POINT (3 6 9),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
        AG.removegeom!(result, 1)
        @test AG.toWKT(result) == "GEOMETRYCOLLECTION (POINT (2 5 8),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
        AG.removeallgeoms!(result)
        @test AG.toWKT(result) == "GEOMETRYCOLLECTION EMPTY"
    end

    geom3 = AG.fromWKT("GEOMETRYCOLLECTION (POINT (2 5 8),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)), POINT EMPTY)")
    AG.clone(geom3) do geom4
        @test sprint(print, AG.clone(geom3)) == "Geometry: GEOMETRYCOLLECTION (POINT (2 5 8),POLYGON ((0 0 8, ... MPTY)"
        @test sprint(print, AG.clone(geom4)) == "Geometry: GEOMETRYCOLLECTION (POINT (2 5 8),POLYGON ((0 0 8, ... MPTY)"
    end
    AG.clone(AG.getgeom(geom3, 3)) do geom4
        @test sprint(print, geom4) == "Geometry: POINT EMPTY"
    end

    @test AG.toISOWKT(geom3) == "GEOMETRYCOLLECTION Z (POINT Z (2 5 8),POLYGON Z ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON Z ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)),POINT Z EMPTY)"
    AG.removegeom!(geom3, AG.ngeom(geom3)-1) # the JSON driver in GDAL 3.0 does not handle null geometries well yet
    @test AG.toJSON(geom3) == """{ "type": "GeometryCollection", "geometries": [ { "type": "Point", "coordinates": [ 2.0, 5.0, 8.0 ] }, { "type": "Polygon", "coordinates": [ [ [ 0.0, 0.0, 8.0 ], [ 0.0, 4.0, 8.0 ], [ 4.0, 4.0, 8.0 ], [ 4.0, 0.0, 8.0 ], [ 0.0, 0.0, 8.0 ] ], [ [ 1.0, 1.0, 8.0 ], [ 3.0, 1.0, 8.0 ], [ 3.0, 3.0, 8.0 ], [ 1.0, 3.0, 8.0 ], [ 1.0, 1.0, 8.0 ] ] ] }, { "type": "Polygon", "coordinates": [ [ [ 10.0, 0.0, 8.0 ], [ 10.0, 4.0, 8.0 ], [ 14.0, 4.0, 8.0 ], [ 14.0, 0.0, 8.0 ], [ 10.0, 0.0, 8.0 ] ], [ [ 11.0, 1.0, 8.0 ], [ 13.0, 1.0, 8.0 ], [ 13.0, 3.0, 8.0 ], [ 11.0, 3.0, 8.0 ], [ 11.0, 1.0, 8.0 ] ] ] } ] }"""

    AG.createmultilinestring([[[1.,4.], [2.,5.], [3.,6.], [1.,4.]]]) do geom4
        @test AG.toWKT(geom4) == "MULTILINESTRING ((1 4,2 5,3 6,1 4))"
        @test AG.toWKT(AG.polygonfromedges(geom4, 0.1)) == "POLYGON ((1 4,2 5,3 6,1 4))"
        AG.polygonfromedges(geom4, 0.1) do geom5
            @test AG.toWKT(geom5) == "POLYGON ((1 4,2 5,3 6,1 4))"
        end
    end

    @test AG.getgeomtype(AG.getgeom(geom3, 0)) == GDAL.wkbPoint25D
    @test AG.getgeomtype(AG.getgeom(geom3, 1)) == GDAL.wkbPolygon25D
    @test AG.getgeomtype(AG.getgeom(geom3, 2)) == GDAL.wkbPolygon25D
    @test sprint(print, AG.getgeom(geom3, 3)) == "NULL Geometry"
    AG.getgeom(geom3, 0) do geom4
        @test AG.getgeomtype(geom4) == GDAL.wkbPoint25D
    end
    AG.getgeom(geom3, 1) do geom4
        @test AG.getgeomtype(geom4) == GDAL.wkbPolygon25D
    end
    AG.getgeom(geom3, 2) do geom4
        @test AG.getgeomtype(geom4) == GDAL.wkbPolygon25D
    end
    AG.getgeom(geom3, 3) do geom4
        @test sprint(print, geom4) == "NULL Geometry"
    end
end

@testset "Spatial Reference Systems" begin
    AG.read("data/point.geojson") do dataset
        layer = AG.getlayer(dataset, 0)
        AG.nextfeature(layer) do feature
            geom = AG.getgeom(feature)
            @test AG.toPROJ4(AG.getspatialref(geom)) == "+proj=longlat +datum=WGS84 +no_defs"
            AG.getspatialref(geom) do spatialref
                @test AG.toPROJ4(spatialref) == "+proj=longlat +datum=WGS84 +no_defs"
            end
        end
        AG.createpoint(1,2) do point
            @test sprint(print, AG.getspatialref(point)) == "NULL Spatial Reference System"
            AG.getspatialref(point) do spatialref
                @test sprint(print, spatialref) == "NULL Spatial Reference System"
            end
        end
    end

    AG.importEPSG(2927) do source; AG.importEPSG(4326) do target
        AG.createcoordtrans(source, target) do transform
            AG.fromWKT("POINT (1120351.57 741921.42)") do point
                @test AG.toWKT(point) == "POINT (1120351.57 741921.42)"
                AG.transform!(point, transform)
                @test GeoInterface.coordinates(point) ≈ [47.348801, -122.598135]
    end end end end
end
