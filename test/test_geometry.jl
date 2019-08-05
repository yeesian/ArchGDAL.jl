using Test
import GeoInterface, GDAL, ArchGDAL; const AG = ArchGDAL

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
        @test AG.getdim(point) == 0
        @test AG.getcoorddim(point) == 2
        AG.setcoorddim!(point, 3)
        @test AG.getcoorddim(point) == 3
        @test AG.isvalid(point) == true
        @test AG.issimple(point) == true
        @test AG.isring(point) == false
        @test AG.getz(point, 0) == 0

        @test sprint(print, AG.getenvelope(point)) == "GDAL.OGREnvelope(100.0, 100.0, 70.0, 70.0)"
        @test sprint(print, AG.getenvelope3d(point)) == "GDAL.OGREnvelope3D(100.0, 100.0, 70.0, 70.0, 0.0, 0.0)"
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
    @test AG.getdim(point) == 0
    @test AG.getcoorddim(point) == 2
    AG.setcoorddim!(point, 3)
    @test AG.getcoorddim(point) == 3
    @test AG.isvalid(point) == true
    @test AG.issimple(point) == true
    @test AG.isring(point) == false
    @test AG.getz(point, 0) == 0
    @test sprint(print, AG.getenvelope(point)) == "GDAL.OGREnvelope(100.0, 100.0, 70.0, 70.0)"
    @test sprint(print, AG.getenvelope3d(point)) == "GDAL.OGREnvelope3D(100.0, 100.0, 70.0, 70.0, 0.0, 0.0)"
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
        @test AG.toWKT(AG.getcurvegeom(AG.getlineargeom(geom, 0.5))) == "CURVEPOLYGON (CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0),(-1 0,0.0 0.5,1 0,0 1,-1 0))"
        AG.getlineargeom(geom, 0.5) do lgeom
            AG.getcurvegeom(lgeom) do clgeom
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
            @test AG.toWKT(result) == "MULTIPOLYGON (((0 0 8,0.0 1.33333333333333 8,0.0 2.66666666666667 8,0 4 8,1.33333333333333 4.0 8,2.66666666666667 4.0 8,4 4 8,4.0 2.66666666666667 8,4.0 1.33333333333333 8,4 0 8,2.66666666666667 0.0 8,1.33333333333333 0.0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10.0 1.33333333333333 8,10.0 2.66666666666667 8,10 4 8,11.3333333333333 4.0 8,12.6666666666667 4.0 8,14 4 8,14.0 2.66666666666667 8,14.0 1.33333333333333 8,14 0 8,12.6666666666667 0.0 8,11.3333333333333 0.0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
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
end

# Untested
# g = clone(geom)
# C_NULL == clone(geom)
# clone(geom) do C_NULL
# toISOWKT(geom::Geometry)
# toJSON(geom, options)
# g = getgeom(g, i)
# C_NULL == getgeom(g, i)
# getgeom(g, i) do g
# getgeom(g, i) do C_NULL
# g = getlineargeom(geom, options, stepsize)
# getlineargeom(geom, options, stepsize) do g
# g = polygonfromedges(lines::Geometry, besteffort::Bool,autoclose::Bool, tol::Real)
# polygonfromedges(lines, besteffort,autoclose, tol) do g
# spref = getspatialref(geom::Geometry)
# C_NULL == getspatialref(geom::Geometry)
# getspatialref(geom) do spref
# getspatialref(geom) do C_NULL
# transform!(geom::Geometry, coordtransform::CoordTransform)
