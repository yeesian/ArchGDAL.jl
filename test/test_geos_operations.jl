using Base.Test
import ArchGDAL; const AG = ArchGDAL

function equivalent_to_wkt(geom::ArchGDAL.Geometry, wkt::String)
    fromWKT(wkt) do test_geom
        @test toWKT(geom) == toWKT(test_geom)
    end
end

@testset "Interpolation along a LineString" begin
    AG.createlinestring([(8.,1.),(9.,1.),(9.,2.),(8.,2.)]) do ls
        for (dist,dest) in [(1.0,(9,1)),    (2.0,(9,2)),
                            (1.5,(9.0,1.5)),(2.5,(8.5,2.0))]
            AG.pointalongline(ls, dist) do pt1
            AG.createpoint(dest) do pt2
                @test AG.toWKT(pt1) == AG.toWKT(pt2)
            end
            end
            @test AG.toWKT(AG.pointalongline(ls, dist)) == AG.toWKT(AG.createpoint(dest))
        end
    end
end

@testset "Contains operation" begin
    AG.fromWKT("POLYGON EMPTY") do g1
    AG.fromWKT("POLYGON EMPTY") do g2
        @test AG.contains(g1, g2) == false
        @test AG.contains(g2, g1) == false
    end
    end

    AG.fromWKT("POLYGON((1 1,1 5,5 5,5 1,1 1))") do g1
    AG.fromWKT("POINT(2 2)") do g2
        @test AG.contains(g1, g2) == true
        @test AG.contains(g2, g1) == false
    end
    end

    AG.fromWKT("MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))") do g1
    AG.fromWKT("POLYGON((1 1,1 2,2 2,2 1,1 1))") do g2
        @test AG.contains(g1, g2) == true
        @test AG.contains(g2, g1) == false
    end
    end
end

@testset "Convex Hull" begin
    AG.fromWKT("MULTIPOINT (130 240, 130 240, 130 240, 570 240, 570 240, 570 240, 650 240)") do input
    AG.fromWKT("LINESTRING (130 240, 650 240)") do expected
        AG.convexhull(input) do output
            @test AG.isempty(output) == false
            @test AG.toWKT(output) == AG.toWKT(expected)
        end
        @test AG.toWKT(AG.convexhull(input)) == AG.toWKT(expected)
    end
    end
end

@testset "Delaunay Triangulation" begin
    AG.fromWKT("POLYGON EMPTY") do g1
        AG.delaunaytriangulation(g1,0,true) do g2
            @test AG.isempty(g1) == true
            @test AG.isempty(g2) == true
            @test AG.toWKT(g2) == "MULTILINESTRING EMPTY"
        end
        @test AG.toWKT(AG.delaunaytriangulation(g1,0,true)) == "MULTILINESTRING EMPTY"
    end
    AG.fromWKT("POINT(0 0)") do g1
        AG.delaunaytriangulation(g1,0,false) do g2
            @test AG.isempty(g2) == true
            @test AG.toWKT(g2) == "GEOMETRYCOLLECTION EMPTY"
        end
        @test AG.toWKT(AG.delaunaytriangulation(g1,0,false)) == "GEOMETRYCOLLECTION EMPTY"
    end
    AG.fromWKT("MULTIPOINT(0 0, 5 0, 10 0)") do g1
        AG.delaunaytriangulation(g1,0,false) do g2
            @test AG.toWKT(g2) == "GEOMETRYCOLLECTION EMPTY"
        end
        AG.delaunaytriangulation(g1,0,true) do g2
            @test AG.toWKT(g2) == "MULTILINESTRING ((5 0,10 0),(0 0,5 0))"
        end
    end
    AG.fromWKT("MULTIPOINT(0 0, 10 0, 10 10, 11 10)") do g1
        AG.delaunaytriangulation(g1,2.0,true) do g2
            @test AG.toWKT(g2) == "MULTILINESTRING ((0 0,10 10),(0 0,10 0),(10 0,10 10))"
        end
    end
end

@testset "Distance" begin
    AG.fromWKT("POINT(10 10)") do g1
    AG.fromWKT("POINT(3 6)") do g2
        @test AG.distance(g1, g2) ≈ 8.06225774829855 atol=1e-12
    end
    end
end

function test_method(f::Function, wkt1::AbstractString, wkt2::AbstractString)
    AG.fromWKT(wkt1) do geom
        f(geom) do result
            @test AG.toWKT(result) == wkt2
        end
        @test AG.toWKT(f(geom)) == wkt2
    end
end

@testset "Centroid" begin
    test_method(AG.centroid, "POINT(10 0)", "POINT (10 0)")
    test_method(AG.centroid, "LINESTRING(0 0, 10 0)", "POINT (5 0)")
    test_method(AG.centroid, "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))", "POINT (5 5)")
    test_method(AG.centroid, "LINESTRING EMPTY", "POINT EMPTY")
end

@testset "Point on Surface" begin
    test_method(AG.pointonsurface, "POINT(10 0)", "POINT (10 0)")
    test_method(AG.pointonsurface, "LINESTRING(0 0, 5 0, 10 0)", "POINT (5 0)")
    test_method(AG.pointonsurface, "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))", "POINT (5 5)")
    test_method(AG.pointonsurface, "LINESTRING EMPTY", "POINT EMPTY")
    test_method(AG.pointonsurface, "LINESTRING(0 0, 0 0)", "POINT (0 0)")
end

function test_method(f::Function, wkt1::AbstractString,
                     wkt2::AbstractString, wkt3::AbstractString)
    AG.fromWKT(wkt1) do geom1
    AG.fromWKT(wkt2) do geom2
        f(geom1, geom2) do result
            @test AG.toWKT(result) == wkt3
        end
        @test AG.toWKT(f(geom1, geom2)) == wkt3
    end
    end
end

@testset "Intersection" begin
    test_method(AG.intersection,
                "POLYGON EMPTY",
                "POLYGON EMPTY",
                "GEOMETRYCOLLECTION EMPTY")
    test_method(AG.intersection,
                "POLYGON((1 1,1 5,5 5,5 1,1 1))",
                "POINT(2 2)",
                "POINT (2 2)")
    test_method(AG.intersection,
                "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))",
                "POLYGON((-1 1,-1 2,2 2,2 1,-1 1))",
                "POLYGON ((0 1,0 2,2 2,2 1,0 1))")
    test_method(AG.intersection,
                "MULTIPOLYGON(((0 0,5 10,10 0,0 0),(1 1,1 2,2 2,2 1,1 1),(100 100,100 102,102 102,102 100,100 100)))",
                "POLYGON((0 1,0 2,10 2,10 1,0 1))",
                "GEOMETRYCOLLECTION (LINESTRING (1 2,2 2),LINESTRING (2 1,1 1),POLYGON ((0.5 1.0,1 2,1 1,0.5 1.0)),POLYGON ((9 2,9.5 1.0,2 1,2 2,9 2)))")
end

function test_predicate(f::Function, wkt1, wkt2, result::Bool)
    AG.fromWKT(wkt1) do geom1
    AG.fromWKT(wkt2) do geom2
        @test f(geom1, geom2) == result
    end
    end
end

@testset "Intersects" begin
    test_predicate(AG.intersects,
                   "POLYGON EMPTY",
                   "POLYGON EMPTY",
                   false)
    test_predicate(AG.intersects,
                   "POLYGON((1 1,1 5,5 5,5 1,1 1))",
                   "POINT(2 2)",
                   true)
    test_predicate(AG.intersects,
                   "POINT(2 2)",
                   "POLYGON((1 1,1 5,5 5,5 1,1 1))",
                   true)
    test_predicate(AG.intersects,
                   "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))",
                   "POLYGON((1 1,1 2,2 2,2 1,1 1))",
                   true)
    test_predicate(AG.intersects,
                   "POLYGON((1 1,1 2,2 2,2 1,1 1))",
                   "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))",
                   true)
end

@testset "Within" begin
    test_predicate(AG.within,
                   "POLYGON EMPTY",
                   "POLYGON EMPTY",
                   false)
    test_predicate(AG.within,
                   "POLYGON((1 1,1 5,5 5,5 1,1 1))",
                   "POINT(2 2)",
                   false)
    test_predicate(AG.within,
                   "POINT(2 2)",
                   "POLYGON((1 1,1 5,5 5,5 1,1 1))",
                   true)
    test_predicate(AG.within,
                   "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))",
                   "POLYGON((1 1,1 2,2 2,2 1,1 1))",
                   false)
    test_predicate(AG.within,
                   "POLYGON((1 1,1 2,2 2,2 1,1 1))",
                   "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))",
                   true)
end

@testset "Simplify" begin
    AG.fromWKT("POLYGON((56.528666666700 25.2101666667, 56.529000000000 25.2105000000, 56.528833333300 25.2103333333, 56.528666666700 25.2101666667))") do g1
        AG.simplify(g1, 0.0) do g2
            @test AG.toWKT(g2) == "POLYGON EMPTY"
        end
        @test AG.toWKT(AG.simplify(g1, 0.0)) == "POLYGON EMPTY"
    end

    AG.fromWKT("POLYGON((56.528666666700 25.2101666667, 56.529000000000 25.2105000000, 56.528833333300 25.2103333333, 56.528666666700 25.2101666667))") do g1
        AG.simplifypreservetopology(g1, 43.2) do g2
            @test AG.toWKT(g2) == "POLYGON ((56.5286666667 25.2101666667,56.529 25.2105,56.5288333333 25.2103333333,56.5286666667 25.2101666667))"
        end
        @test AG.toWKT(AG.simplifypreservetopology(g1, 43.2)) == "POLYGON ((56.5286666667 25.2101666667,56.529 25.2105,56.5288333333 25.2103333333,56.5286666667 25.2101666667))"
    end
end
