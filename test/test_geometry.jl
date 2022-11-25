using Test
import GeoInterface as GI
import ArchGDAL as AG
import GeoFormatTypes as GFT

@testset "test_geometry.jl" begin
    @testset "GeoInterface" begin
        AG.createpoint(100, 70) do point
            @test GI.geomtrait(point) == GI.PointTrait()
            @test GI.testgeometry(point)
            @test GI.bbox(point).X[1] == 100
            @test GI.x(point) == 100
            @test GI.y(point) == 70
            @test GI.z(point) == nothing
            @test GI.m(point) == nothing
            @test GI.getcoord(point, 1) == 100
            @test GI.getcoord(point, 2) == 70
            @test GI.getcoord(point, 3) == nothing
            @test GI.getcoord(point, 4) == nothing
        end
        AG.createpoint(100, 70, 1) do point
            @test GI.geomtrait(point) == GI.PointTrait()
            @test GI.testgeometry(point)
            @test GI.bbox(point).Z[1] == 1
            @test GI.x(point) == 100
            @test GI.y(point) == 70
            @test GI.z(point) == 1
            @test GI.m(point) == nothing
            @test GI.getcoord(point, 1) == 100
            @test GI.getcoord(point, 2) == 70
            @test GI.getcoord(point, 3) == 1
            @test GI.getcoord(point, 4) == nothing
        end
        @test GI.isgeometry(AG.IGeometry)
    end

    @testset "Create a Point" begin
        # Method 1
        AG.createpoint(100, 70) do point
            @test point isa AG.Geometry{AG.wkbPoint}
            @test isapprox(GI.coordinates(point), [100, 70], atol = 1e-6)
            @test AG.geomdim(point) == 0
            @test AG.getcoorddim(point) == 2
            AG.setcoorddim!(point, 3)
            @test AG.getcoorddim(point) == 3
            @test AG.isvalid(point) == true
            @test AG.issimple(point) == true
            @test AG.isring(point) == false
            @test AG.getz(point, 0) == 0

            @test sprint(print, AG.envelope(point)) ==
                  "GDAL.OGREnvelope(100.0, 100.0, 70.0, 70.0)"
            @test sprint(print, AG.envelope3d(point)) ==
                  "GDAL.OGREnvelope3D(100.0, 100.0, 70.0, 70.0, 0.0, 0.0)"
            @test AG.toISOWKB(point, AG.wkbNDR) == UInt8[
                0x01,
                0xe9,
                0x03,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x59,
                0x40,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x80,
                0x51,
                0x40,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ]
            @test AG.toISOWKB(point, AG.wkbXDR) == UInt8[
                0x00,
                0x00,
                0x00,
                0x03,
                0xe9,
                0x40,
                0x59,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x40,
                0x51,
                0x80,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ]
            @test AG.toKML(point, "relativeToGround") ==
                  "<Point><altitudeMode>relativeToGround</altitudeMode>" *
                  "<coordinates>100,70,0</coordinates></Point>"
            @test AG.toKML(point, "clampToGround") ==
                  "<Point><altitudeMode>clampToGround</altitudeMode>" *
                  "<coordinates>100,70,0</coordinates></Point>"
            @test AG.toKML(point) ==
                  "<Point><coordinates>100,70,0</coordinates></Point>"
            @test AG.toJSON(point) ==
                  "{ \"type\": \"Point\", \"coordinates\": " *
                  "[ 100.0, 70.0, 0.0 ] }"
            @test startswith(
                AG.toJSON(point, SIGNIFICANT_FIGURES = 1),
                "{ \"type\": \"Point\", \"coordinates\": [",
            )
            @test startswith(
                AG.toJSON(point, ["SIGNIFICANT_FIGURES=1"]),
                "{ \"type\": \"Point\", \"coordinates\": [",
            )
            AG.createpoint(100, 70, 0) do pointz
                @test isapprox(
                    GI.coordinates(pointz),
                    [100, 70, 0],
                    atol = 1e-6,
                )
                @test pointz isa AG.Geometry{AG.wkbPoint25D}
                @test point == pointz
                @test AG.equals(point, pointz) == true
            end
            AG.createpoint((100, 70, 0)) do point3
                @test AG.equals(point, point3) == true
            end
            AG.createpoint([100, 70, 0]) do point4
                @test AG.equals(point, point4) == true
            end
            point5 = AG.createpoint([100, 70, 0])
            @test AG.equals(point, point5) == true
            AG.flattento2d!(point)
            @test AG.getcoorddim(point) == 2
            @test AG.getnonlineargeomflag() == true
            AG.setnonlineargeomflag!(false)
            @test AG.getnonlineargeomflag() == false
            AG.setnonlineargeomflag!(true)
            @test AG.getnonlineargeomflag() == true
            AG.closerings!(point)
            @test AG.toJSON(point) ==
                  "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0 ] }"
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
        @test typeof(point) == AG.IGeometry{AG.wkbPoint}
        @test sprint(print, AG.envelope(point)) ==
              "GDAL.OGREnvelope(100.0, 100.0, 70.0, 70.0)"
        @test sprint(print, AG.envelope3d(point)) ==
              "GDAL.OGREnvelope3D(100.0, 100.0, 70.0, 70.0, 0.0, 0.0)"
        @test AG.toISOWKB(point, AG.wkbNDR) == UInt8[
            0x01,
            0xe9,
            0x03,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x59,
            0x40,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x80,
            0x51,
            0x40,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ]
        @test AG.toISOWKB(point, AG.wkbXDR) == UInt8[
            0x00,
            0x00,
            0x00,
            0x03,
            0xe9,
            0x40,
            0x59,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x40,
            0x51,
            0x80,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ]
        @test AG.toKML(point, "relativeToGround") ==
              "<Point><altitudeMode>relativeToGround</altitudeMode>" *
              "<coordinates>100,70,0</coordinates></Point>"
        @test AG.toKML(point, "clampToGround") ==
              "<Point><altitudeMode>clampToGround</altitudeMode>" *
              "<coordinates>100,70,0</coordinates></Point>"
        @test AG.toKML(point) ==
              "<Point><coordinates>100,70,0</coordinates></Point>"
        @test AG.toJSON(point) ==
              "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0, 0.0 ] }"
        @test AG.equals(point, AG.createpoint(100, 70, 0)) == true
        @test AG.equals(point, AG.createpoint((100, 70, 0))) == true
        AG.flattento2d!(point)
        @test AG.getcoorddim(point) == 2
        @test AG.getnonlineargeomflag() == true
        AG.setnonlineargeomflag!(false)
        @test AG.getnonlineargeomflag() == false
        AG.setnonlineargeomflag!(true)
        @test AG.getnonlineargeomflag() == true
        AG.closerings!(point)
        @test AG.toJSON(point) ==
              "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0 ] }"
    end

    @testset "Testing construction of complex geometries" begin
        @testset "linestring" begin
            @test AG.toWKT(
                      AG.createlinestring(
                          [1.0f0, 2.0f0, 3.0f0],
                          [4.0f0, 5.0f0, 6.0f0],
                      ),
                  ) ==
                  AG.toWKT(
                      AG.createlinestring([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]),
                  ) ==
                  "LINESTRING (1 4,2 5,3 6)"
            # create
            AG.createlinestring([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]) do geom
                @test GI.geomtrait(geom) == GI.LineStringTrait()
                @test GI.testgeometry(geom)
                @test !AG.is3d(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbLineString}
                @test typeof(AG.getgeom(geom, 0)) == AG.IGeometry{AG.wkbPoint}
                @test isapprox(
                    GI.coordinates(geom),
                    [[1, 4], [2, 5], [3, 6]],
                    atol = 1e-6,
                )
                @test AG.toWKT(geom) == "LINESTRING (1 4,2 5,3 6)"
                AG.closerings!(geom)
                @test AG.toWKT(geom) == "LINESTRING (1 4,2 5,3 6)"
                AG.setpoint!(geom, 1, 10, 10)
                @test AG.toWKT(geom) == "LINESTRING (1 4,10 10,3 6)"
                @test GFT.val(convert(GFT.WellKnownText, geom)) ==
                      AG.toWKT(geom)
            end
            # unsafe_create
            geom = AG.unsafe_createlinestring([1.0, 2.0, 3.0], [4.0, 5.0, 6.0])
            @test GI.geomtrait(geom) == GI.LineStringTrait()
            @test GI.testgeometry(geom)
            @test typeof(geom) == AG.Geometry{AG.wkbLineString}
            @test typeof(AG.getgeom(geom, 0)) == AG.IGeometry{AG.wkbPoint}
            @test isapprox(
                GI.coordinates(geom),
                [[1, 4], [2, 5], [3, 6]],
                atol = 1e-6,
            )
            @test AG.toWKT(geom) == "LINESTRING (1 4,2 5,3 6)"
            AG.closerings!(geom)
            @test AG.toWKT(geom) == "LINESTRING (1 4,2 5,3 6)"
            AG.setpoint!(geom, 1, 10, 10)
            @test AG.toWKT(geom) == "LINESTRING (1 4,10 10,3 6)"
            @test GFT.val(convert(GFT.WellKnownText, geom)) == AG.toWKT(geom)
            AG.destroy(geom)
            # create 25D
            AG.createlinestring(
                [1.0, 2.0, 3.0],
                [4.0, 5.0, 6.0],
                [7.0, 8.0, 9.0],
            ) do geom
                @test GI.geomtrait(geom) == GI.LineStringTrait()
                @test AG.is3d(geom)
                @test GI.testgeometry(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbLineString25D}
                @test typeof(AG.getgeom(geom, 0)) ==
                      AG.IGeometry{AG.wkbPoint25D}
                @test AG.toWKT(geom) == "LINESTRING (1 4 7,2 5 8,3 6 9)"
                AG.setpoint!(geom, 1, 10, 10, 10)
                @test AG.toWKT(geom) == "LINESTRING (1 4 7,10 10 10,3 6 9)"
                AG.addpoint!(geom, 11, 11, 11)
                @test AG.toWKT(geom) ==
                      "LINESTRING (1 4 7,10 10 10,3 6 9,11 11 11)"
            end
        end

        @testset "linearring" begin
            @test AG.toWKT(AG.createlinearring([1, 2, 3], [4, 5, 6])) ==
                  AG.toWKT(
                      AG.createlinearring([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]),
                  ) ==
                  "LINEARRING (1 4,2 5,3 6)"
            AG.createlinearring([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]) do geom
                @test GI.geomtrait(geom) == GI.LineStringTrait()
                @test GI.testgeometry(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbLineString} # GDAL only uses the LinearRing enum during construction
                @test AG._infergeomtype(geom) == AG.wkbLineString
                @test !AG.is3d(geom)
                @test GDAL.ogr_g_is3d(geom) == 0
                @test typeof(AG.getgeom(geom, 0)) == AG.IGeometry{AG.wkbPoint}
                @test isapprox(
                    GI.coordinates(geom),
                    [[1, 4], [2, 5], [3, 6]],
                    atol = 1e-6,
                )
                @test AG.toWKT(geom) == "LINEARRING (1 4,2 5,3 6)"
                AG.setpointcount!(geom, 5)
                @test AG.toWKT(geom) == "LINEARRING (1 4,2 5,3 6,0 0,0 0)"
                AG.empty!(geom)
                @test AG.toWKT(geom) == "LINEARRING EMPTY"
            end
            points = [1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]
            AG.createlinearring(points...) do geom
                @test GI.testgeometry(geom)
                @test AG._infergeomtype(geom) == AG.wkbLineString25D
                @test AG.is3d(geom)
                @test GDAL.ogr_g_is3d(geom) == 1
                @test typeof(geom) == AG.Geometry{AG.wkbLineString25D}
                @test typeof(AG.getgeom(geom, 0)) ==
                      AG.IGeometry{AG.wkbPoint25D}
                # @test typeof(AG.getgeom(geom, 0)) == AG.IGeometry{AG.wkbPoint25D}
                @test AG.toWKT(geom) == "LINEARRING (1 4 7,2 5 8,3 6 9)"
                AG.closerings!(geom)
                @test AG.toWKT(geom) == "LINEARRING (1 4 7,2 5 8,3 6 9,1 4 7)"
            end
            geom = AG.unsafe_createlinearring(points...)
            @test AG.toWKT(geom) == "LINEARRING (1 4 7,2 5 8,3 6 9)"
            AG.closerings!(geom)
            @test AG.toWKT(geom) == "LINEARRING (1 4 7,2 5 8,3 6 9,1 4 7)"
            AG.destroy(geom)
        end

        @testset "polygon" begin
            @test AG.toWKT(
                      AG.createpolygon([0x01, 0x02, 0x03], [0x04, 0x05, 0x06]),
                  ) ==
                  AG.toWKT(
                      AG.createpolygon([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]),
                  ) ==
                  "POLYGON ((1 4,2 5,3 6))"
            AG.createpolygon([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]) do geom
                @test GI.geomtrait(geom) == GI.PolygonTrait()
                @test GI.testgeometry(geom)
                @test !GI.is3d(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbPolygon}
                @test typeof(AG.getgeom(geom, 0)) ==
                      AG.IGeometry{AG.wkbLineString}
                @test isapprox(
                    GI.coordinates(geom),
                    [[[1, 4], [2, 5], [3, 6]]],
                    atol = 1e-6,
                )
                @test AG.toWKT(geom) == "POLYGON ((1 4,2 5,3 6))"
            end
            AG.createpolygon(
                [1.0, 2.0, 3.0],
                [4.0, 5.0, 6.0],
                [7.0, 8.0, 9.0],
            ) do geom
                @test GI.geomtrait(geom) == GI.PolygonTrait()
                @test GI.is3d(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbPolygon25D}
                @test typeof(AG.getgeom(geom, 0)) ==
                      AG.IGeometry{AG.wkbLineString25D}
                @test AG.toWKT(geom) == "POLYGON ((1 4 7,2 5 8,3 6 9))"
                AG.closerings!(geom)
                @test AG.toWKT(geom) == "POLYGON ((1 4 7,2 5 8,3 6 9,1 4 7))"
            end
        end

        @testset "multipoint" begin
            @test AG.toWKT(AG.createmultipoint([1, 2, 3], [4, 5, 6])) ==
                  AG.toWKT(
                      AG.createmultipoint([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]),
                  ) ==
                  "MULTIPOINT (1 4,2 5,3 6)"
            AG.createmultipoint([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]) do geom
                @test GI.geomtrait(geom) == GI.MultiPointTrait()
                @test GI.testgeometry(geom)
                @test !GI.is3d(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbMultiPoint}
                @test typeof(AG.getgeom(geom, 0)) == AG.IGeometry{AG.wkbPoint}
                @test isapprox(
                    GI.coordinates(geom),
                    [[1, 4], [2, 5], [3, 6]],
                    atol = 1e-6,
                )
                @test AG.toWKT(geom) == "MULTIPOINT (1 4,2 5,3 6)"
            end
            AG.createmultipoint(
                [1.0, 2.0, 3.0],
                [4.0, 5.0, 6.0],
                [7.0, 8.0, 9.0],
            ) do geom
                @test GI.geomtrait(geom) == GI.MultiPointTrait()
                @test GI.is3d(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbMultiPoint25D}
                @test typeof(AG.getgeom(geom, 0)) ==
                      AG.IGeometry{AG.wkbPoint25D}
                @test AG.toWKT(geom) == "MULTIPOINT (1 4 7,2 5 8,3 6 9)"
            end
        end

        @testset "multipolygon" begin
            @test AG.toWKT(
                      AG.createmultipolygon(
                          Vector{Vector{Tuple{Int,Int}}}[
                              Vector{Tuple{Int,Int}}[
                                  [(0, 0), (0, 4), (4, 4), (4, 0)],
                                  [(1, 1), (1, 3), (3, 3), (3, 1)],
                              ],
                              Vector{Tuple{Int,Int}}[
                                  [(10, 0), (10, 4), (14, 4), (14, 0)],
                                  [(11, 1), (11, 3), (13, 3), (13, 1)],
                              ],
                          ],
                      ),
                  ) ==
                  AG.toWKT(
                      AG.createmultipolygon(
                          Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                              Vector{Tuple{Cdouble,Cdouble}}[
                                  [
                                      (0.0, 0.0),
                                      (0.0, 4.0),
                                      (4.0, 4.0),
                                      (4.0, 0.0),
                                  ],
                                  [
                                      (1.0, 1.0),
                                      (1.0, 3.0),
                                      (3.0, 3.0),
                                      (3.0, 1.0),
                                  ],
                              ],
                              Vector{Tuple{Cdouble,Cdouble}}[
                                  [
                                      (10.0, 0.0),
                                      (10.0, 4.0),
                                      (14.0, 4.0),
                                      (14.0, 0.0),
                                  ],
                                  [
                                      (11.0, 1.0),
                                      (11.0, 3.0),
                                      (13.0, 3.0),
                                      (13.0, 1.0),
                                  ],
                              ],
                          ],
                      ),
                  ) ==
                  "MULTIPOLYGON (" *
                  "((0 0,0 4,4 4,4 0),(1 1,1 3,3 3,3 1))," *
                  "((10 0,10 4,14 4,14 0),(11 1,11 3,13 3,13 1)))"
            AG.createmultipolygon(
                Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                    Vector{Tuple{Cdouble,Cdouble}}[
                        [(0, 0), (0, 4), (4, 4), (4, 0)],
                        [(1, 1), (1, 3), (3, 3), (3, 1)],
                    ],
                    Vector{Tuple{Cdouble,Cdouble}}[
                        [(10, 0), (10, 4), (14, 4), (14, 0)],
                        [(11, 1), (11, 3), (13, 3), (13, 1)],
                    ],
                ],
            ) do geom
                @test GI.geomtrait(geom) == GI.MultiPolygonTrait()
                @test GI.testgeometry(geom)
                @test GDAL.ogr_g_is3d(geom) == 0
                @test !GI.is3d(geom)
                @test typeof(geom) == AG.Geometry{AG.wkbMultiPolygon}
                @test typeof(AG.getgeom(geom, 0)) == AG.IGeometry{AG.wkbPolygon}
                child = AG.unsafe_getgeom(geom, 0)
                @test typeof(child) == AG.Geometry{AG.wkbPolygon}
                AG.destroy(child)
                @test isapprox(
                    GI.coordinates(geom),
                    [
                        [
                            [[0, 0], [0, 4], [4, 4], [4, 0]],
                            [[1, 1], [1, 3], [3, 3], [3, 1]],
                        ],
                        [
                            [[10, 0], [10, 4], [14, 4], [14, 0]],
                            [[11, 1], [11, 3], [13, 3], [13, 1]],
                        ],
                    ],
                    atol = 1e-6,
                )
                @test AG.toWKT(geom) ==
                      "MULTIPOLYGON (" *
                      "((0 0,0 4,4 4,4 0),(1 1,1 3,3 3,3 1))," *
                      "((10 0,10 4,14 4,14 0),(11 1,11 3,13 3,13 1)))"
            end
        end

        @testset "circularstring" begin
            AG.fromWKT(
                "CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0)",
            ) do geom
                @test typeof(geom) == AG.Geometry{AG.wkbCircularString}
                @test GI.geomtrait(geom) == GI.CircularStringTrait()
                # Other tests ???
            end
        end

        @testset "curvepolygon" begin
            AG.fromWKT(
                "CURVEPOLYGON (" *
                "CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0)," *
                "(-1 0,0 0.5,1 0,0 1,-1 0))",
            ) do geom
                @test GI.geomtrait(geom) == GI.CurvePolygonTrait()
                @test typeof(geom) == AG.Geometry{AG.wkbCurvePolygon}
                child = AG.unsafe_getgeom(geom, 0)
                @test typeof(child) == AG.Geometry{AG.wkbCircularString}
                AG.destroy(child)
                @test typeof(AG.getgeom(geom, 0)) ==
                      AG.IGeometry{AG.wkbCircularString}
                @test AG.toWKT(AG.curvegeom(AG.lineargeom(geom, 0.5))) ==
                      "CURVEPOLYGON (" *
                      "CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0)," *
                      "(-1 0,0.0 0.5,1 0,0 1,-1 0))"
                AG.lineargeom(geom, 0.5) do lgeom
                    @test typeof(lgeom) == AG.Geometry{AG.wkbPolygon}
                    AG.curvegeom(lgeom) do clgeom
                        @test AG.toWKT(clgeom) ==
                              "CURVEPOLYGON (" *
                              "CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0)," *
                              "(-1 0,0.0 0.5,1 0,0 1,-1 0))"
                        @test typeof(clgeom) == AG.Geometry{AG.wkbCurvePolygon}
                    end
                    @test AG.ngeom(
                        AG.polygonize(AG.forceto(lgeom, AG.wkbMultiLineString)),
                    ) == 2
                    AG.forceto(lgeom, AG.wkbMultiLineString) do mlsgeom
                        @test typeof(mlsgeom) ==
                              AG.Geometry{AG.wkbMultiLineString}
                        AG.polygonize(mlsgeom) do plgeom
                            @test AG.ngeom(plgeom) == 2
                            @test typeof(plgeom) ==
                                  AG.Geometry{AG.wkbGeometryCollection}
                        end
                    end
                end

                @test startswith(
                    AG.toWKT(
                        AG.curvegeom(
                            AG.lineargeom(
                                geom,
                                0.5,
                                ADD_INTERMEDIATE_POINT = "NO",
                            ),
                        ),
                    ),
                    "CURVEPOLYGON (CIRCULARSTRING (",
                )
                AG.lineargeom(geom, 0.5, ADD_INTERMEDIATE_POINT = "NO") do lgeom
                    AG.curvegeom(lgeom) do clgeom
                        @test startswith(
                            AG.toWKT(clgeom),
                            "CURVEPOLYGON (CIRCULARSTRING (",
                        )
                    end
                    @test AG.ngeom(
                        AG.polygonize(AG.forceto(lgeom, AG.wkbMultiLineString)),
                    ) == 2
                    AG.forceto(lgeom, AG.wkbMultiLineString) do mlsgeom
                        AG.polygonize(mlsgeom) do plgeom
                            @test AG.ngeom(plgeom) == 2
                        end
                    end
                end

                @test startswith(
                    AG.toWKT(
                        AG.curvegeom(
                            AG.lineargeom(
                                geom,
                                ["ADD_INTERMEDIATE_POINT=NO"],
                                0.5,
                            ),
                        ),
                    ),
                    "CURVEPOLYGON (CIRCULARSTRING (",
                )
                AG.lineargeom(geom, ["ADD_INTERMEDIATE_POINT=NO"], 0.5) do lgeom
                    AG.curvegeom(lgeom) do clgeom
                        @test startswith(
                            AG.toWKT(clgeom),
                            "CURVEPOLYGON (CIRCULARSTRING (",
                        )
                    end
                    @test AG.ngeom(
                        AG.polygonize(AG.forceto(lgeom, AG.wkbMultiLineString)),
                    ) == 2
                    AG.forceto(lgeom, AG.wkbMultiLineString) do mlsgeom
                        AG.polygonize(mlsgeom) do plgeom
                            @test AG.ngeom(plgeom) == 2
                        end
                    end
                end
            end
        end
    end

    @testset "Testing remaining methods for geometries" begin
        geom1 = AG.createmultipolygon(
            Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                Vector{Tuple{Cdouble,Cdouble}}[
                    [(0, 0), (0, 4), (4, 4), (4, 0)],
                    [(1, 1), (1, 3), (3, 3), (3, 1)],
                ],
                Vector{Tuple{Cdouble,Cdouble}}[
                    [(10, 0), (10, 4), (14, 4), (14, 0)],
                    [(11, 1), (11, 3), (13, 3), (13, 1)],
                ],
            ],
        )
        geom2 = AG.createmultipoint(
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
            [7.0, 8.0, 9.0],
        )

        AG.closerings!(geom1)
        @test AG.disjoint(geom1, geom2) == false
        @test AG.touches(geom1, geom2) == true
        @test AG.crosses(geom1, geom2) == false
        @test AG.overlaps(geom1, geom2) == false

        @test AG.toWKT(AG.boundary(geom2)) == "GEOMETRYCOLLECTION EMPTY"
        AG.boundary(geom2) do result
            @test AG.toWKT(result) == "GEOMETRYCOLLECTION EMPTY"
        end

        @test AG.toWKT(AG.union(geom1, geom2)) ==
              "GEOMETRYCOLLECTION (" *
              "POLYGON (" *
              "(0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
              "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
              "POLYGON (" *
              "(10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
              "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8))," *
              "POINT (2 5 8),POINT (3 6 9))"
        AG.union(geom1, geom2) do result
            @test AG.toWKT(result) ==
                  "GEOMETRYCOLLECTION (" *
                  "POLYGON (" *
                  "(0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
                  "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
                  "POLYGON (" *
                  "(10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
                  "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8))," *
                  "POINT (2 5 8),POINT (3 6 9))"
            @test AG.hascurvegeom(result, true) == false
            @test AG.hascurvegeom(result, false) == false
        end

        @test AG.toWKT(AG.difference(geom1, geom2)) ==
              "MULTIPOLYGON (" *
              "((0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
              "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
              "((10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
              "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8)))"
        AG.difference(geom1, geom2) do result
            @test AG.toWKT(result) ==
                  "MULTIPOLYGON (" *
                  "((0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
                  "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
                  "((10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
                  "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8)))"
            AG.segmentize!(result, 20)
            @test AG.toWKT(result) ==
                  "MULTIPOLYGON (" *
                  "((0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
                  "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
                  "((10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
                  "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8)))"
            AG.segmentize!(result, 2)
            @test AG.toWKT(result) ==
                  "MULTIPOLYGON (" *
                  "(" *
                  "(" *
                  "0 4 8," *
                  "2 4 8," *
                  "4 4 8," *
                  "4 2 8," *
                  "4 0 8," *
                  "2 0 8," *
                  "0 0 8," *
                  "0 2 8," *
                  "0 4 8)," *
                  "(" *
                  "3 1 8," *
                  "3 3 8," *
                  "1 3 8," *
                  "1 1 8," *
                  "3 1 8))," *
                  "(" *
                  "(" *
                  "10 4 8," *
                  "12 4 8," *
                  "14 4 8," *
                  "14 2 8," *
                  "14 0 8," *
                  "12 0 8," *
                  "10 0 8," *
                  "10 2 8," *
                  "10 4 8)," *
                  "(" *
                  "13 1 8," *
                  "13 3 8," *
                  "11 3 8," *
                  "11 1 8," *
                  "13 1 8)))"
            @test typeof(result) == AG.Geometry{AG.wkbMultiPolygon25D}
        end

        @test AG.toWKT(AG.symdifference(geom1, geom2)) ==
              "GEOMETRYCOLLECTION (" *
              "POLYGON (" *
              "(0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
              "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
              "POLYGON (" *
              "(10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
              "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8))," *
              "POINT (2 5 8),POINT (3 6 9))"
        AG.symdifference(geom1, geom2) do result
            @test GI.geomtrait(result) == GI.GeometryCollectionTrait()
            @test AG.toWKT(result) ==
                  "GEOMETRYCOLLECTION (" *
                  "POLYGON (" *
                  "(0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
                  "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
                  "POLYGON (" *
                  "(10 4 8,14 4 8,14 0 8,10 0 8,10 4 8)," *
                  "(13 1 8,13 3 8,11 3 8,11 1 8,13 1 8))," *
                  "POINT (2 5 8)," *
                  "POINT (3 6 9))"
            AG.removegeom!(result, 1)
            @test AG.toWKT(result) ==
                  "GEOMETRYCOLLECTION (" *
                  "POLYGON (" *
                  "(0 4 8,4 4 8,4 0 8,0 0 8,0 4 8)," *
                  "(3 1 8,3 3 8,1 3 8,1 1 8,3 1 8))," *
                  "POINT (2 5 8)," *
                  "POINT (3 6 9))"
            AG.removeallgeoms!(result)
            @test AG.toWKT(result) == "GEOMETRYCOLLECTION EMPTY"
            @test typeof(result) == AG.Geometry{AG.wkbGeometryCollection25D}
        end

        geom3 = AG.fromWKT(
            "GEOMETRYCOLLECTION (" *
            "POINT (2 5 8)," *
            "POLYGON (" *
            "(0 0 8,0 4 8,4 4 8,4 0 8,0 0 8)," *
            "(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8))," *
            "POLYGON (" *
            "(10 0 8,10 4 8,14 4 8,14 0 8,10 0 8)," *
            "(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8))," *
            "POINT EMPTY)",
        )
        AG.clone(geom3) do geom4
            @test sprint(print, AG.clone(geom3)) ==
                  "Geometry: GEOMETRYCOLLECTION (" *
                  "POINT (2 5 8)," *
                  "POLYGON ((0 0 8," *
                  " ... MPTY)"
            @test sprint(print, AG.clone(geom4)) ==
                  "Geometry: GEOMETRYCOLLECTION (" *
                  "POINT (2 5 8)," *
                  "POLYGON ((0 0 8," *
                  " ... MPTY)"
            @test typeof(geom4) == AG.Geometry{AG.wkbGeometryCollection25D}
        end
        AG.clone(AG.getgeom(geom3, 3)) do geom4
            @test sprint(print, geom4) == "Geometry: POINT EMPTY"
        end

        @test AG.toISOWKT(geom3) ==
              "GEOMETRYCOLLECTION Z (" *
              "POINT Z (2 5 8)," *
              "POLYGON Z (" *
              "(0 0 8,0 4 8,4 4 8,4 0 8,0 0 8)," *
              "(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8))," *
              "POLYGON Z (" *
              "(10 0 8,10 4 8,14 4 8,14 0 8,10 0 8)," *
              "(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8))," *
              "POINT Z EMPTY)"
        # the JSON driver in GDAL 3.0 does not handle null geometries well yet
        AG.removegeom!(geom3, AG.ngeom(geom3) - 1)
        @test AG.toJSON(geom3) ==
              """{ "type": "GeometryCollection", "geometries": [ """ *
              """{ "type": "Point", "coordinates": [ 2.0, 5.0, 8.0 ] }, """ *
              """{ "type": "Polygon", "coordinates": [ """ *
              "[ " *
              "[ 0.0, 0.0, 8.0 ], " *
              "[ 0.0, 4.0, 8.0 ], " *
              "[ 4.0, 4.0, 8.0 ], " *
              "[ 4.0, 0.0, 8.0 ], " *
              "[ 0.0, 0.0, 8.0 ] ], " *
              "[ " *
              "[ 1.0, 1.0, 8.0 ], " *
              "[ 3.0, 1.0, 8.0 ], " *
              "[ 3.0, 3.0, 8.0 ], " *
              "[ 1.0, 3.0, 8.0 ], " *
              "[ 1.0, 1.0, 8.0 ] ] ] }, " *
              """{ "type": "Polygon", "coordinates": [ """ *
              "[ " *
              "[ 10.0, 0.0, 8.0 ], " *
              "[ 10.0, 4.0, 8.0 ], " *
              "[ 14.0, 4.0, 8.0 ], " *
              "[ 14.0, 0.0, 8.0 ], " *
              "[ 10.0, 0.0, 8.0 ] ], " *
              "[ " *
              "[ 11.0, 1.0, 8.0 ], " *
              "[ 13.0, 1.0, 8.0 ], " *
              "[ 13.0, 3.0, 8.0 ], " *
              "[ 11.0, 3.0, 8.0 ], " *
              "[ 11.0, 1.0, 8.0 ] ] ] } ] }"

        AG.createmultilinestring([[
            [1.0, 4.0],
            [2.0, 5.0],
            [3.0, 6.0],
            [1.0, 4.0],
        ]]) do geom4
            @test AG.toWKT(geom4) == "MULTILINESTRING ((1 4,2 5,3 6,1 4))"
            @test AG.toWKT(AG.polygonfromedges(geom4, 0.1)) ==
                  "POLYGON ((1 4,2 5,3 6,1 4))"
            AG.polygonfromedges(geom4, 0.1) do geom5
                @test AG.toWKT(geom5) == "POLYGON ((1 4,2 5,3 6,1 4))"
            end
        end

        @test AG.getgeomtype(AG.getgeom(geom3, 0)) == AG.wkbPoint25D
        @test AG.getgeomtype(AG.getgeom(geom3, 1)) == AG.wkbPolygon25D
        @test AG.getgeomtype(AG.getgeom(geom3, 2)) == AG.wkbPolygon25D
        @test sprint(print, AG.getgeom(geom3, 3)) == "NULL Geometry"
        @test sprint(print, AG.getgeom(AG.IGeometry(), 3)) == "NULL Geometry"
        AG.getgeom(geom3, 0) do geom4
            @test AG.getgeomtype(geom4) == AG.wkbPoint25D
        end
        AG.getgeom(geom3, 1) do geom4
            @test AG.getgeomtype(geom4) == AG.wkbPolygon25D
        end
        AG.getgeom(geom3, 2) do geom4
            @test AG.getgeomtype(geom4) == AG.wkbPolygon25D
        end
        AG.getgeom(geom3, 3) do geom4
            @test sprint(print, geom4) == "NULL Geometry"
        end
        AG.getgeom(AG.IGeometry(), 0) do geom
            @test sprint(print, geom) == "NULL Geometry"
        end
    end

    @testset "Spatial Reference Systems" begin
        @test sprint(print, AG.getspatialref(AG.IGeometry())) ==
              "NULL Spatial Reference System"
        AG.getspatialref(AG.IGeometry()) do spatialref
            @test sprint(print, spatialref) == "NULL Spatial Reference System"
        end

        AG.createpoint(100, 70, 0) do geom
            @test sprint(print, AG.getspatialref(geom)) ==
                  "NULL Spatial Reference System"
            AG.getspatialref(geom) do spatialref
                @test sprint(print, spatialref) ==
                      "NULL Spatial Reference System"
            end
        end

        AG.read("data/point.geojson") do dataset
            layer = AG.getlayer(dataset, 0)
            AG.nextfeature(layer) do feature
                geom = AG.getgeom(feature)
                @test AG.toPROJ4(AG.getspatialref(geom)) ==
                      "+proj=longlat +datum=WGS84 +no_defs"
                AG.getspatialref(geom) do spatialref
                    @test AG.toPROJ4(spatialref) ==
                          "+proj=longlat +datum=WGS84 +no_defs"
                end
            end
            AG.createpoint(1, 2) do point
                @test sprint(print, AG.getspatialref(point)) ==
                      "NULL Spatial Reference System"
                AG.getspatialref(point) do spatialref
                    @test sprint(print, spatialref) ==
                          "NULL Spatial Reference System"
                end
            end
        end

        AG.importEPSG(2927) do source
            AG.importEPSG(4326) do target
                AG.createcoordtrans(source, target) do transform
                    AG.fromWKT("POINT (1120351.57 741921.42)") do point
                        @test AG.toWKT(point) == "POINT (1120351.57 741921.42)"
                        AG.transform!(point, transform)
                        @test GI.coordinates(point) ≈
                              [47.3488070138318, -122.5981499431438]
                    end
                end
            end
        end
    end

    @testset "Cloning NULL geometries" begin
        geom = AG.IGeometry()
        @test AG.geomname(geom) === missing
        @test sprint(print, AG.clone(geom)) == "NULL Geometry"
        AG.clone(geom) do g
            @test sprint(print, g) == "NULL Geometry"
        end
    end

    @testset "Test coordinate dimensions" begin
        AG.createpoint(1, 2, 3) do point
            @test GI.getcoord(point, 3) == 3
            @test isnothing(GI.getcoord(point, 4))
            @test !GI.isempty(point)
            @test !GI.ismeasured(point)
            @test GI.is3d(point)
        end
        AG.createpoint(1, 2) do point
            @test isnothing(GI.getcoord(point, 3))
            @test isnothing(GI.getcoord(point, 4))
            @test !GI.isempty(point)
            @test !GI.ismeasured(point)
            @test !GI.is3d(point)
        end
        AG.createpoint() do point
            @test GI.isempty(point)
            @test !GI.ismeasured(point)
            @test !GI.is3d(point)
        end
    end

    @testset "GeoInterface conversion" begin
        struct MyPoint end
        struct MyLine end

        GI.isgeometry(::MyPoint) = true
        GI.geomtrait(::MyPoint) = GI.PointTrait()
        GI.ncoord(::GI.PointTrait, geom::MyPoint) = 2
        GI.getcoord(::GI.PointTrait, geom::MyPoint, i) = [1.0, 2.0][i]

        GI.isgeometry(::MyLine) = true
        GI.geomtrait(::MyLine) = GI.LineStringTrait()
        GI.ngeom(::GI.LineStringTrait, geom::MyLine) = 2
        GI.getgeom(::GI.LineStringTrait, geom::MyLine, i) = MyPoint()

        geom = MyLine()
        ag_geom = convert(AG.IGeometry, geom)
        GI.coordinates(ag_geom) == [[1, 2], [1, 2]]
    end
end
