using FactCheck
import GDAL, ArchGDAL; const AG = ArchGDAL

facts("Create a Point") do
    # Method 1
    AG.createpoint(100, 70) do point
        @fact AG.getdim(point) --> 0
        @fact AG.getcoorddim(point) --> 2
        AG.setcoorddim!(point, 3)
        @fact AG.getcoorddim(point) --> 3
        @fact AG.isvalid(point) --> true
        @fact AG.issimple(point) --> true
        @fact AG.isring(point) --> false
        @fact AG.getz(point, 0) --> 0

        println(AG.getenvelope(point))
        println(AG.getenvelope3d(point))
        @fact AG.toISOWKB(point, AG.wkbNDR) --> UInt8[0x01,0xe9,0x03,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x59,0x40,0x00,0x00,0x00,0x00,0x00,0x80,
        0x51,0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
        @fact AG.toISOWKB(point, AG.wkbXDR) --> UInt8[0x00,0x00,0x00,0x03,0xe9,
        0x40,0x59,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x51,0x80,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
        @fact AG.toKML(point, "relativeToGround") --> "<Point><altitudeMode>relativeToGround</altitudeMode><coordinates>100,70,0</coordinates></Point>"
        @fact AG.toKML(point, "clampToGround") --> "<Point><altitudeMode>clampToGround</altitudeMode><coordinates>100,70,0</coordinates></Point>"
        @fact AG.toKML(point) --> "<Point><coordinates>100,70,0</coordinates></Point>"
        @fact AG.toJSON(point) --> "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0, 0.0 ] }"
        AG.createpoint(100,70,0) do point2
            @fact AG.equals(point, point2) --> true
        end
        AG.createpoint((100,70,0)) do point3
            @fact AG.equals(point, point3) --> true
        end
        AG.flattento2d!(point)
        @fact AG.getcoorddim(point) --> 2
        @fact AG.getnonlineargeomflag() --> true
        AG.setnonlineargeomflag!(false)
        @fact AG.getnonlineargeomflag() --> false
        AG.setnonlineargeomflag!(true)
        @fact AG.getnonlineargeomflag() --> true
        AG.closerings!(point)
        @fact AG.toJSON(point) --> "{ \"type\": \"Point\", \"coordinates\": [ 100.0, 70.0 ] }"
    end
end

facts("Testing construction of complex geometries") do
    AG.createlinestring([1.,2.,3.], [4.,5.,6.]) do geom
        @fact AG.toWKT(geom) --> "LINESTRING (1 4,2 5,3 6)"
        AG.closerings!(geom)
        @fact AG.toWKT(geom) --> "LINESTRING (1 4,2 5,3 6)"
        AG.setpoint!(geom, 1, 10, 10)
        @fact AG.toWKT(geom) --> "LINESTRING (1 4,10 10,3 6)"
    end
    AG.createlinestring([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @fact AG.toWKT(geom) --> "LINESTRING (1 4 7,2 5 8,3 6 9)"
        AG.setpoint!(geom, 1, 10, 10, 10)
        @fact AG.toWKT(geom) --> "LINESTRING (1 4 7,10 10 10,3 6 9)"
        AG.addpoint!(geom, 11, 11, 11)
        @fact AG.toWKT(geom) --> "LINESTRING (1 4 7,10 10 10,3 6 9,11 11 11)"
    end
    
    AG.createlinearring([1.,2.,3.], [4.,5.,6.]) do geom
        @fact AG.toWKT(geom) --> "LINEARRING (1 4,2 5,3 6)"
        AG.setpointcount!(geom, 5)
        @fact AG.toWKT(geom) --> "LINEARRING (1 4,2 5,3 6,0 0,0 0)"
        AG.empty!(geom)
        @fact AG.toWKT(geom) --> "LINEARRING EMPTY"
    end
    AG.createlinearring([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @fact AG.toWKT(geom) --> "LINEARRING (1 4 7,2 5 8,3 6 9)"
        AG.closerings!(geom)
        @fact AG.toWKT(geom) --> "LINEARRING (1 4 7,2 5 8,3 6 9,1 4 7)"
    end

    AG.createpolygon([1.,2.,3.], [4.,5.,6.]) do geom
        @fact AG.toWKT(geom) --> "POLYGON ((1 4,2 5,3 6))"
    end
    AG.createpolygon([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @fact AG.toWKT(geom) --> "POLYGON ((1 4 7,2 5 8,3 6 9))"
        AG.closerings!(geom)
        @fact AG.toWKT(geom) --> "POLYGON ((1 4 7,2 5 8,3 6 9,1 4 7))"
    end

    AG.createmultipoint([1.,2.,3.], [4.,5.,6.]) do geom
        @fact AG.toWKT(geom) --> "MULTIPOINT (1 4,2 5,3 6)"
    end
    AG.createmultipoint([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom
        @fact AG.toWKT(geom) --> "MULTIPOINT (1 4 7,2 5 8,3 6 9)"
    end

    AG.createmultipolygon(Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(0,0),(0,4),(4,4),(4,0)],
                                [(1,1),(1,3),(3,3),(3,1)]],
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(10,0),(10,4),(14,4),(14,0)],
                                [(11,1),(11,3),(13,3),(13,1)]]]) do geom
        @fact AG.toWKT(geom) --> "MULTIPOLYGON (((0 0,0 4,4 4,4 0),(1 1,1 3,3 3,3 1)),((10 0,10 4,14 4,14 0),(11 1,11 3,13 3,13 1)))"
    end

    AG.fromWKT("CURVEPOLYGON(CIRCULARSTRING(-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0),(-1 0,0 0.5,1 0,0 1,-1 0))") do geom
        AG.getlineargeom(geom, 0.5) do lgeom
            AG.getcurvegeom(lgeom) do clgeom
                @fact AG.toWKT(clgeom) --> "CURVEPOLYGON (CIRCULARSTRING (-2 0,-1 -1,0 0,1 -1,2 0,0 2,-2 0),(-1 0,0.0 0.5,1 0,0 1,-1 0))"
            end
            AG.forceto(lgeom, AG.wkbMultiLineString) do mlsgeom
                AG.polygonize(mlsgeom) do plgeom
                    @fact AG.ngeom(plgeom) --> 2
                end
            end
        end
    end
end

facts("Testing remaining methods for geometries") do
    AG.createmultipolygon(Vector{Vector{Tuple{Cdouble,Cdouble}}}[
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(0,0),(0,4),(4,4),(4,0)],
                                [(1,1),(1,3),(3,3),(3,1)]],
                            Vector{Tuple{Cdouble,Cdouble}}[
                                [(10,0),(10,4),(14,4),(14,0)],
                                [(11,1),(11,3),(13,3),(13,1)]]]) do geom1
    AG.createmultipoint([1.,2.,3.], [4.,5.,6.], [7.,8.,9.]) do geom2
        AG.closerings!(geom1)
        @fact AG.disjoint(geom1, geom2) --> false
        @fact AG.touches(geom1, geom2) --> true
        @fact AG.crosses(geom1, geom2) --> false
        @fact AG.overlaps(geom1, geom2) --> false
        AG.boundary(geom2) do result
            @fact AG.toWKT(result) --> "GEOMETRYCOLLECTION EMPTY"
        end
        AG.union(geom1, geom2) do result
            @fact AG.toWKT(result) --> "GEOMETRYCOLLECTION (POINT (2 5 8),POINT (3 6 9),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
            @fact AG.hascurvegeom(result, true) --> false
            @fact AG.hascurvegeom(result, false) --> false
        end
        AG.difference(geom1, geom2) do result
            @fact AG.toWKT(result) --> "MULTIPOLYGON (((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
            AG.segmentize!(result, 20)
            @fact AG.toWKT(result) --> "MULTIPOLYGON (((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
            AG.segmentize!(result, 2)
            @fact AG.toWKT(result) --> "MULTIPOLYGON (((0 0 8,0.0 1.33333333333333 8,0.0 2.66666666666667 8,0 4 8,1.33333333333333 4.0 8,2.66666666666667 4.0 8,4 4 8,4.0 2.66666666666667 8,4.0 1.33333333333333 8,4 0 8,2.66666666666667 0.0 8,1.33333333333333 0.0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),((10 0 8,10.0 1.33333333333333 8,10.0 2.66666666666667 8,10 4 8,11.3333333333333 4.0 8,12.6666666666667 4.0 8,14 4 8,14.0 2.66666666666667 8,14.0 1.33333333333333 8,14 0 8,12.6666666666667 0.0 8,11.3333333333333 0.0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
        end
        AG.symdifference(geom1, geom2) do result
            @fact AG.toWKT(result) --> "GEOMETRYCOLLECTION (POINT (2 5 8),POINT (3 6 9),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
            AG.removegeom!(result, 1)
            @fact AG.toWKT(result) --> "GEOMETRYCOLLECTION (POINT (2 5 8),POLYGON ((0 0 8,0 4 8,4 4 8,4 0 8,0 0 8),(1 1 8,3 1 8,3 3 8,1 3 8,1 1 8)),POLYGON ((10 0 8,10 4 8,14 4 8,14 0 8,10 0 8),(11 1 8,13 1 8,13 3 8,11 3 8,11 1 8)))"
            AG.removeallgeoms!(result)
            @fact AG.toWKT(result) --> "GEOMETRYCOLLECTION EMPTY"
        end
    end
    end
end

# Untested
# toISOWKT(geom::Geometry)
# unsafe_polygonfromedges(lines::Geometry, besteffort::Bool,autoclose::Bool, tol::Real)
# setspatialref!(geom::Geometry, spatialref::SpatialRef)
# getspatialref(geom::Geometry) = GDAL.getspatialreference(geom)
# transform!(geom::Geometry, coordtransform::CoordTransform)
# transform!(geom::Geometry, spatialref::SpatialRef)
