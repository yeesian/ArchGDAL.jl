# adapted from http://pcjericks.github.io/py-gdalogr-cookbook/geometry.html
using Test
import GeoInterface
import GDAL, ArchGDAL; const AG = ArchGDAL

@testset "Create a Point" begin

    x, y = 1198054.34, 648493.09
    wktpoint = "POINT (1198054.34 648493.09)"

    # Method 1
    AG.createpoint(x, y) do point
        @test AG.toWKT(point) == wktpoint
    end
    AG.createpoint((x, y)) do point
        @test AG.toWKT(point) == wktpoint
    end

    # Method 2
    AG.createpoint() do point
        AG.addpoint!(point, x, y)
        @test AG.toWKT(point) == wktpoint
    end

    # Method 3
    AG.creategeom(GDAL.wkbPoint) do point
        AG.addpoint!(point, x, y)
        @test AG.toWKT(point) == wktpoint
    end

    # Method 4
    point = AG.creategeom(GDAL.wkbPoint)
    AG.addpoint!(point, x, y)
    @test AG.toWKT(point) == wktpoint

    # Method 5
    @test AG.toWKT(AG.createpoint(x, y)) == wktpoint
end

@testset "Create a LineString" begin
    # Method 1
    wktline = "LINESTRING (1116651.43937912 637392.696988746," *
    "1188804.01084985 652655.740953707,1226730.36252036 634155.081602239,1281307.30760719 636467.664021172)"
    AG.createlinestring([(1116651.439379124,  637392.6969887456),
                         (1188804.0108498496, 652655.7409537067),
                         (1226730.3625203592, 634155.0816022386),
                         (1281307.30760719,   636467.6640211721)]) do line
        @test AG.toWKT(line) == wktline
    end

    # Method 2
    AG.createlinestring() do line
        AG.addpoint!(line, 1116651.439379124,  637392.6969887456)
        AG.addpoint!(line, 1188804.0108498496, 652655.7409537067)
        AG.addpoint!(line, 1226730.3625203592, 634155.0816022386)
        AG.addpoint!(line, 1281307.30760719,   636467.6640211721)
        @test AG.toWKT(line) == wktline
    end

    # Method 3
    AG.creategeom(GDAL.wkbLineString) do line
        AG.addpoint!(line, 1116651.439379124,  637392.6969887456)
        AG.addpoint!(line, 1188804.0108498496, 652655.7409537067)
        AG.addpoint!(line, 1226730.3625203592, 634155.0816022386)
        AG.addpoint!(line, 1281307.30760719,   636467.6640211721)
        @test AG.toWKT(line) == wktline
    end

    # Method 4
    line = AG.creategeom(GDAL.wkbLineString)
    AG.addpoint!(line, 1116651.439379124,  637392.6969887456)
    AG.addpoint!(line, 1188804.0108498496, 652655.7409537067)
    AG.addpoint!(line, 1226730.3625203592, 634155.0816022386)
    AG.addpoint!(line, 1281307.30760719,   636467.6640211721)
    @test AG.toWKT(line) == wktline

    # Method 5
    @test AG.toWKT(AG.createlinestring([
        (1116651.439379124,  637392.6969887456),
        (1188804.0108498496, 652655.7409537067),
        (1226730.3625203592, 634155.0816022386),
        (1281307.30760719,   636467.6640211721)
    ])) == wktline
end

@testset "Create a Polygon" begin

    wktpoly = "POLYGON ((1179091.16469033 712782.883845978,1161053.02182265 667456.268434881," *
    "1214704.9339419 641092.828859039,1228580.42845551 682719.312399842," *
    "1218405.0658122 721108.180554139,1179091.16469033 712782.883845978))"

    # Method 1
    AG.createpolygon([(1179091.1646903288, 712782.8838459781),
                      (1161053.0218226474, 667456.2684348812),
                      (1214704.933941905,  641092.8288590391),
                      (1228580.428455506,  682719.3123998424),
                      (1218405.0658121984, 721108.1805541387),
                      (1179091.1646903288, 712782.8838459781)]) do poly
        @test AG.toWKT(poly) == wktpoly
    end

    # Method 2
    AG.createpolygon() do poly
        ring = AG.createlinearring(
                    [(1179091.1646903288, 712782.8838459781),
                     (1161053.0218226474, 667456.2684348812),
                     (1214704.933941905,  641092.8288590391),
                     (1228580.428455506,  682719.3123998424),
                     (1218405.0658121984, 721108.1805541387),
                     (1179091.1646903288, 712782.8838459781)])
        AG.addgeom!(poly, ring)
    end

    AG.createlinearring(
                    [(1179091.1646903288, 712782.8838459781),
                     (1161053.0218226474, 667456.2684348812),
                     (1214704.933941905,  641092.8288590391),
                     (1228580.428455506,  682719.3123998424),
                     (1218405.0658121984, 721108.1805541387),
                     (1179091.1646903288, 712782.8838459781)]) do ring
        AG.createpolygon() do poly
            AG.addgeom!(poly, ring)
            @test AG.toWKT(poly) == wktpoly
        end
    end

    # Method 3
    AG.creategeom(GDAL.wkbLinearRing) do ring
        AG.addpoint!(ring, 1179091.1646903288, 712782.8838459781)
        AG.addpoint!(ring, 1161053.0218226474, 667456.2684348812)
        AG.addpoint!(ring, 1214704.933941905, 641092.8288590391)
        AG.addpoint!(ring, 1228580.428455506, 682719.3123998424)
        AG.addpoint!(ring, 1218405.0658121984, 721108.1805541387)
        AG.addpoint!(ring, 1179091.1646903288, 712782.8838459781)

        AG.creategeom(GDAL.wkbPolygon) do poly
            AG.addgeom!(poly, ring)
            @test AG.toWKT(poly) == wktpoly
        end
    end

    # Method 4
    ring = AG.creategeom(GDAL.wkbLinearRing)
        AG.addpoint!(ring, 1179091.1646903288, 712782.8838459781)
        AG.addpoint!(ring, 1161053.0218226474, 667456.2684348812)
        AG.addpoint!(ring, 1214704.933941905, 641092.8288590391)
        AG.addpoint!(ring, 1228580.428455506, 682719.3123998424)
        AG.addpoint!(ring, 1218405.0658121984, 721108.1805541387)
        AG.addpoint!(ring, 1179091.1646903288, 712782.8838459781)

    poly = AG.creategeom(GDAL.wkbPolygon)
    AG.addgeom!(poly, ring)
    @test AG.toWKT(poly) == wktpoly

    @test AG.toWKT(AG.createpolygon([
        (1179091.1646903288, 712782.8838459781),
        (1161053.0218226474, 667456.2684348812),
        (1214704.933941905,  641092.8288590391),
        (1228580.428455506,  682719.3123998424),
        (1218405.0658121984, 721108.1805541387),
        (1179091.1646903288, 712782.8838459781)
    ])) == wktpoly
end

@testset "Create a Polygon with holes" begin

    wktpoly = "POLYGON ((1154115.27456585 686419.444270136,1154115.27456585 653118.257437493," *
    "1165678.18666051 653118.257437493,1165678.18666051 686419.444270136," *
    "1154115.27456585 686419.444270136)," *
    "(1149490.10972798 691044.609108003,1149490.10972798 648030.57611584," *
    "1191579.10975257 648030.57611584,1191579.10975257 691044.609108003," *
    "1149490.10972798 691044.609108003))"

    # Method 1
    AG.createpolygon([# outring
                      [(1154115.274565847,  686419.4442701361),
                       (1154115.274565847,  653118.2574374934),
                       (1165678.1866605144, 653118.2574374934),
                       (1165678.1866605144, 686419.4442701361),
                       (1154115.274565847,  686419.4442701361)],
                      # innerring(s)
                      [(1149490.1097279799, 691044.6091080031),
                       (1149490.1097279799, 648030.5761158396),
                       (1191579.1097525698, 648030.5761158396),
                       (1191579.1097525698, 691044.6091080031),
                       (1149490.1097279799, 691044.6091080031)]
                     ]) do poly
        @test AG.toWKT(poly) == wktpoly
    end

    # Method 2
    AG.createpolygon() do poly
        outring = AG.creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)

        innerring = AG.creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)

        AG.addgeom!(poly, outring)
        AG.addgeom!(poly, innerring)
        @test AG.toWKT(poly) == wktpoly
    end

    # Method 3
    AG.creategeom(GDAL.wkbPolygon) do poly
        outring = AG.creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)

        innerring = AG.creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)

        AG.addgeom!(poly, outring)
        AG.addgeom!(poly, innerring)
        @test AG.toWKT(poly) == wktpoly
    end

    # Method 4
    poly = AG.creategeom(GDAL.wkbPolygon)
        outring = AG.creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
        AG.addgeom!(poly, outring)

        innerring = AG.creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
        AG.addgeom!(poly, innerring)
    @test AG.toWKT(poly) == wktpoly

    # Method 5
    @test AG.toWKT(AG.createpolygon([
        # outerring
        [(1154115.274565847,  686419.4442701361),
         (1154115.274565847,  653118.2574374934),
         (1165678.1866605144, 653118.2574374934),
         (1165678.1866605144, 686419.4442701361),
         (1154115.274565847,  686419.4442701361)],
        # innerring(s)
        [(1149490.1097279799, 691044.6091080031),
         (1149490.1097279799, 648030.5761158396),
         (1191579.1097525698, 648030.5761158396),
         (1191579.1097525698, 691044.6091080031),
         (1149490.1097279799, 691044.6091080031)]
    ])) == wktpoly
end

@testset "Create a MultiPoint" begin

    wktpoints = "MULTIPOINT (1251243.73616105 598078.795866876," *
    "1240605.85703396 601778.927737169,1250318.70319348 606404.092575036)"

    # Method 1
    AG.createmultipoint([(1251243.7361610543, 598078.7958668759),
                         (1240605.8570339603, 601778.9277371694),
                         (1250318.7031934808, 606404.0925750365)]) do multipoint
        @test AG.toWKT(multipoint) == wktpoints
    end

    # Method 2
    AG.createmultipoint() do multipoint
        point1 = AG.createpoint(1251243.7361610543, 598078.7958668759)
        point2 = AG.createpoint(1240605.8570339603, 601778.9277371694)
        point3 = AG.createpoint(1250318.7031934808, 606404.0925750365)
        AG.addgeom!(multipoint, point1)
        AG.addgeom!(multipoint, point2)
        AG.addgeom!(multipoint, point3)
        @test AG.toWKT(multipoint) == wktpoints
    end

    # Method 3
    AG.creategeom(GDAL.wkbMultiPoint) do multipoint
        point1 = AG.createpoint(1251243.7361610543, 598078.7958668759)
        point2 = AG.createpoint(1240605.8570339603, 601778.9277371694)
        point3 = AG.createpoint(1250318.7031934808, 606404.0925750365)
        AG.addgeom!(multipoint, point1)
        AG.addgeom!(multipoint, point2)
        AG.addgeom!(multipoint, point3)
        @test AG.toWKT(multipoint) == wktpoints
    end

    # Method 4
    multipoint = AG.creategeom(GDAL.wkbMultiPoint)
        point1 = AG.createpoint(1251243.7361610543, 598078.7958668759)
        point2 = AG.createpoint(1240605.8570339603, 601778.9277371694)
        point3 = AG.createpoint(1250318.7031934808, 606404.0925750365)
        AG.addgeom!(multipoint, point1)
        AG.addgeom!(multipoint, point2)
        AG.addgeom!(multipoint, point3)
    @test AG.toWKT(multipoint) == wktpoints

    # Method 5
    @test AG.toWKT(AG.createmultipoint([
        (1251243.7361610543, 598078.7958668759),
        (1240605.8570339603, 601778.9277371694),
        (1250318.7031934808, 606404.0925750365)
    ])) == wktpoints
end

@testset "Create a MultiLineString" begin

    wktline = "MULTILINESTRING ((1214242.41745812 617041.971702131,1234593.14274473 629529.916764372)," *
    "(1184641.36249577 626754.817861651,1219792.61526356 606866.609058823))"

    # Method 1
    AG.createmultilinestring(Vector{Tuple{Float64,Float64}}[
                              [(1214242.4174581182, 617041.9717021306),
                               (1234593.142744733,  629529.9167643716)],
                              [(1184641.3624957693, 626754.8178616514),
                               (1219792.6152635587, 606866.6090588232)]
                             ]) do multiline
        @test GeoInterface.geotype(multiline) == :MultiLineString
        @test AG.toWKT(multiline) == wktline
    end

    # Method 2
    AG.createmultilinestring() do multiline
        AG.addgeom!(multiline, AG.createlinestring(
            [(1214242.4174581182, 617041.9717021306),
             (1234593.142744733,  629529.9167643716)]))
        AG.addgeom!(multiline, AG.createlinestring(
            [(1184641.3624957693, 626754.8178616514),
             (1219792.6152635587, 606866.6090588232)]))
        @test AG.toWKT(multiline) == wktline
    end

    # Method 3
    AG.creategeom(GDAL.wkbMultiLineString) do multiline
        line = AG.creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, 1214242.4174581182, 617041.9717021306)
            AG.addpoint!(line, 1234593.142744733, 629529.9167643716)
        AG.addgeom!(multiline, line)

        line = AG.creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, 1184641.3624957693, 626754.8178616514)
            AG.addpoint!(line, 1219792.6152635587, 606866.6090588232)
        AG.addgeom!(multiline, line)

        @test AG.toWKT(multiline) == wktline
    end

    # Method 4
    multiline = AG.creategeom(GDAL.wkbMultiLineString)
        line = AG.creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, 1214242.4174581182, 617041.9717021306)
            AG.addpoint!(line, 1234593.142744733, 629529.9167643716)
        AG.addgeom!(multiline, line)
        line = AG.creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, 1184641.3624957693, 626754.8178616514)
            AG.addpoint!(line, 1219792.6152635587, 606866.6090588232)
        AG.addgeom!(multiline, line)
    
    @test AG.toWKT(multiline) == wktline

    # Method 5
    @test AG.toWKT(AG.createmultilinestring(Vector{Tuple{Float64,Float64}}[
        [(1214242.4174581182, 617041.9717021306),
         (1234593.142744733,  629529.9167643716)],
        [(1184641.3624957693, 626754.8178616514),
         (1219792.6152635587, 606866.6090588232)]
    ])) == wktline
end

@testset "Create a MultiPolygon" begin

    wktmultipolygon = "MULTIPOLYGON " *
    "(((1204067.05481481 634617.598086025,1204067.05481481 620742.103572424," *
    "1215167.45042569 620742.103572424,1215167.45042569 634617.598086025," *
    "1204067.05481481 634617.598086025))," *
    "((1179553.68117412 647105.543148266,1179553.68117412 626292.301377865," *
    "1194354.20865529 626292.301377865,1194354.20865529 647105.543148266," *
    "1179553.68117412 647105.543148266)))"

    # Method 1
    AG.createmultipolygon_noholes(Vector{Tuple{Float64,Float64}}[
             [(1204067.0548148106, 634617.5980860253),
              (1204067.0548148106, 620742.1035724243),
              (1215167.4504256917, 620742.1035724243),
              (1215167.4504256917, 634617.5980860253),
              (1204067.0548148106, 634617.5980860253)],
             [(1179553.6811741155, 647105.5431482664),
              (1179553.6811741155, 626292.3013778647),
              (1194354.20865529,   626292.3013778647),
              (1194354.20865529,   647105.5431482664),
              (1179553.6811741155, 647105.5431482664)]
            ]) do multipolygon
        @test AG.toWKT(multipolygon) == wktmultipolygon
    end

    # Method 2
    AG.createmultipolygon() do multipolygon
        poly = AG.createpolygon(
            [(1204067.0548148106, 634617.5980860253),
             (1204067.0548148106, 620742.1035724243),
             (1215167.4504256917, 620742.1035724243),
             (1215167.4504256917, 634617.5980860253),
             (1204067.0548148106, 634617.5980860253)])
        AG.addgeom!(multipolygon,poly)

        poly = AG.createpolygon(
            [(1179553.6811741155, 647105.5431482664),
             (1179553.6811741155, 626292.3013778647),
             (1194354.20865529,   626292.3013778647),
             (1194354.20865529,   647105.5431482664),
             (1179553.6811741155, 647105.5431482664)])
        AG.addgeom!(multipolygon,poly)

        @test AG.toWKT(multipolygon) == wktmultipolygon
    end

    # Method 3
    AG.creategeom(GDAL.wkbMultiPolygon) do multipolygon
        poly = AG.creategeom(GDAL.wkbPolygon)
            ring = AG.creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
            AG.addgeom!(poly, ring)
        AG.addgeom!(multipolygon,poly)

        poly = AG.creategeom(GDAL.wkbPolygon)
            ring = AG.creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
            AG.addgeom!(poly, ring)
        AG.addgeom!(multipolygon,poly)

        @test AG.toWKT(multipolygon) == wktmultipolygon
    end

    # Method 4
    multipolygon = AG.creategeom(GDAL.wkbMultiPolygon)
        poly = AG.creategeom(GDAL.wkbPolygon)
            ring = AG.creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
            AG.addgeom!(poly, ring)
        AG.addgeom!(multipolygon,poly)

        poly = AG.creategeom(GDAL.wkbPolygon)
            ring = AG.creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
            AG.addgeom!(poly, ring)
        AG.addgeom!(multipolygon,poly)

    @test AG.toWKT(multipolygon) == wktmultipolygon

    # Method 5
    @test AG.toWKT(AG.createmultipolygon_noholes(Vector{Tuple{Float64,Float64}}[
             [(1204067.0548148106, 634617.5980860253),
              (1204067.0548148106, 620742.1035724243),
              (1215167.4504256917, 620742.1035724243),
              (1215167.4504256917, 634617.5980860253),
              (1204067.0548148106, 634617.5980860253)],
             [(1179553.6811741155, 647105.5431482664),
              (1179553.6811741155, 626292.3013778647),
              (1194354.20865529,   626292.3013778647),
              (1194354.20865529,   647105.5431482664),
              (1179553.6811741155, 647105.5431482664)]
            ])) == wktmultipolygon
end

@testset "Create a GeometryCollection" begin

    wktcollection = "GEOMETRYCOLLECTION " *
    "(POINT (-122.23 47.09),LINESTRING (-122.6 47.14,-122.48 47.23))"

    # Method not applicable here

    # Method 2
    AG.creategeomcollection() do geomcol
        for g in [AG.createpoint(-122.23, 47.09),
                  AG.createlinestring([(-122.60, 47.14), (-122.48, 47.23)])]
            AG.addgeom!(geomcol, g)
        end
        @test AG.toWKT(geomcol) == wktcollection
    end

    # Method 3
    AG.creategeom(GDAL.wkbGeometryCollection) do geomcol
        point = AG.creategeom(GDAL.wkbPoint)
            AG.addpoint!(point, -122.23, 47.09)
        AG.addgeom!(geomcol, point)

        line = AG.creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, -122.60, 47.14)
            AG.addpoint!(line, -122.48, 47.23)
        AG.addgeom!(geomcol, line)

        @test AG.toWKT(geomcol) == wktcollection
    end

    # Method 4
    geomcol =  AG.creategeom(GDAL.wkbGeometryCollection)
        point = AG.creategeom(GDAL.wkbPoint)
            AG.addpoint!(point, -122.23, 47.09)
        AG.addgeom!(geomcol, point)

        line = AG.creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, -122.60, 47.14)
            AG.addpoint!(line, -122.48, 47.23)
        AG.addgeom!(geomcol, line)

    @test AG.toWKT(geomcol) == wktcollection
end

@testset "Create Geometry from WKT" begin
    wkt = "POINT (1120351.5712494177 741921.4223245403)"
    x, y = 1120351.5712494177, 741921.4223245403

    # Method 1
    AG.fromWKT(wkt) do point
        @test AG.getx(point, 0) ≈ x
        @test AG.gety(point, 0) ≈ y
    end

    # Method 2
    point = AG.fromWKT(wkt)
    @test AG.getx(point, 0) ≈ x
    @test AG.gety(point, 0) ≈ y
end

@testset "Create Geometry from GeoJSON" begin
    geojson = """{"type":"Point","coordinates":[108420.33,753808.59]}"""
    x, y = 108420.33, 753808.59

    # Method 1
    AG.fromJSON(geojson) do point
        @test AG.getx(point, 0) ≈ x
        @test AG.gety(point, 0) ≈ y
    end

    # Method 2
    point = AG.fromJSON(geojson)
    @test AG.getx(point, 0) ≈ x
    @test AG.gety(point, 0) ≈ y
end

@testset "Create Geometry from GML" begin
    gml = """<gml:Point xmlns:gml="http://www.opengis.net/gml">
             <gml:coordinates>108420.33,753808.59</gml:coordinates>
             </gml:Point>"""
    x, y = 108420.33, 753808.59

    # Method 1
    AG.fromGML(gml) do point
        @test AG.getx(point, 0) ≈ x
        @test AG.gety(point, 0) ≈ y
    end

    # Method 2
    point = AG.fromGML(gml)
    @test AG.getx(point, 0) ≈ x
    @test AG.gety(point, 0) ≈ y
end

@testset "Create Geometry from WKB" begin
    wkb = [0x01,0x01,0x00,0x00,0x00,0x7b,0x14,0xae,0x47,0x45,0x78,0xfa,0x40,
           0xe1,0x7a,0x14,0x2e,0x21,0x01,0x27,0x41]
    x, y = 108420.33, 753808.59

    # Method 1
    AG.fromWKB(wkb) do point
        @test AG.getx(point, 0) ≈ x
        @test AG.gety(point, 0) ≈ y
    end

    # Method 2
    point = AG.fromWKB(wkb)
    @test AG.getx(point, 0) ≈ x
    @test AG.gety(point, 0) ≈ y
end

@testset "Count Points in a LineString" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"

    # Method 1
    AG.fromWKT(wkt) do geom
        @test AG.ngeom(geom) == 4
    end

    # Method 2
    @test AG.ngeom(AG.fromWKT(wkt)) == 4
end

@testset "Count Points in a MultiPoint" begin
    wkt = "MULTIPOINT (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"

    # Method 1
    AG.fromWKT(wkt) do geom
        @test AG.ngeom(geom) == 4
    end

    # Method 2
    @test AG.ngeom(AG.fromWKT(wkt)) == 4
end

@testset "Iterate over Geometries in a Geometry" begin
    wkt = "MULTIPOINT (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do geom
        # TODO Should getgeom use Julian counting from 1?
        @test AG.toWKT(AG.getgeom(geom, 3)) == "POINT (1224880.29658521 665143.686015948)"
    end
end

@testset "Iterate over Points in a Geometry" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do geom
        @test AG.getpoint(geom, 3) == (1.2248802965852122e6, 665143.6860159477, 0.0)
    end
end

@testset "Buffer a Geometry" begin
    wkt = "POINT (1198054.34 648493.09)"

    # Method 1
    AG.fromWKT(wkt) do pt
        bufferdist = 500
        AG.buffer(pt, bufferdist) do poly
            @test AG.getgeomtype(poly) == GDAL.wkbPolygon
        end
    end

    # Method 2
    @test AG.getgeomtype(AG.buffer(AG.fromWKT(wkt), 500)) == GDAL.wkbPolygon
end

@testset "Calculate Envelope of a Geometry" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do line
        env = AG.envelope(line)
        @test (env.MaxX - env.MinX) * (env.MaxY - env.MinY) ≈ 2.2431808256625123e9
    end
end

@testset "Calculate the Area of a Geometry" begin
    wkt = "POLYGON ((1162440.5712740074 672081.4332727483, 1162440.5712740074 647105.5431482664, 1195279.2416228633 647105.5431482664, 1195279.2416228633 672081.4332727483, 1162440.5712740074 672081.4332727483))"
    AG.fromWKT(wkt) do poly
        @test AG.geomarea(poly) ≈ 8.201750224671059e8
    end
end

@testset "Calculate the Length of a Geometry" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do line
        @test AG.geomlength(line) ≈ 76121.94397805972
    end
end

@testset "Get the geometry type (as a string) from a Geometry" begin
    types = ["POINT", "LINESTRING", "POLYGON"]
    wkts = [
        "POINT (1198054.34 648493.09)",
        "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)",
        "POLYGON ((1162440.5712740074 672081.4332727483, 1162440.5712740074 647105.5431482664, 1195279.2416228633 647105.5431482664, 1195279.2416228633 672081.4332727483, 1162440.5712740074 672081.4332727483))"
    ]
    for (i, wkt) in enumerate(wkts)
        AG.fromWKT(wkt) do geom
            @test AG.getgeomname(geom) == types[i]
        end
    end
end

@testset "Calculate intersection between two Geometries" begin
    wkt1 = "POLYGON ((1208064.271243039 624154.6783778917, 1208064.271243039 601260.9785661874, 1231345.9998651114 601260.9785661874, 1231345.9998651114 624154.6783778917, 1208064.271243039 624154.6783778917))"
    wkt2 = "POLYGON ((1199915.6662253144 633079.3410163528, 1199915.6662253144 614453.958118695, 1219317.1067437078 614453.958118695, 1219317.1067437078 633079.3410163528, 1199915.6662253144 633079.3410163528)))"
    wkt3 = "POLYGON ((1208064.27124304 614453.958118695,1208064.27124304 624154.678377892,1219317.10674371 624154.678377892,1219317.10674371 614453.958118695,1208064.27124304 614453.958118695))"


    # Method 1
    AG.fromWKT(wkt1) do poly1
    AG.fromWKT(wkt2) do poly2
        AG.intersection(poly1, poly2) do poly3
            @test AG.toWKT(poly3) == wkt3
        end
    end
    end

    # Method 2
    @test AG.toWKT(AG.intersection(AG.fromWKT(wkt1), AG.fromWKT(wkt2))) == wkt3
end

@testset "Calculate union between two Geometries" begin
    wkt1 = "POLYGON ((1208064.271243039 624154.6783778917, 1208064.271243039 601260.9785661874, 1231345.9998651114 601260.9785661874, 1231345.9998651114 624154.6783778917, 1208064.271243039 624154.6783778917))"
    wkt2 = "POLYGON ((1199915.6662253144 633079.3410163528, 1199915.6662253144 614453.958118695, 1219317.1067437078 614453.958118695, 1219317.1067437078 633079.3410163528, 1199915.6662253144 633079.3410163528)))"
    wkt3 = "POLYGON ((1219317.10674371 624154.678377892,1231345.99986511 624154.678377892,1231345.99986511 601260.978566187,1208064.27124304 601260.978566187,1208064.27124304 614453.958118695,1199915.66622531 614453.958118695,1199915.66622531 633079.341016353,1219317.10674371 633079.341016353,1219317.10674371 624154.678377892))"

    # Method 1
    AG.fromWKT(wkt1) do poly1
    AG.fromWKT(wkt2) do poly2
        AG.union(poly1, poly2) do poly3
            @test AG.toWKT(poly3) == wkt3
        end
    end
    end

    # Method 2
    @test AG.toWKT(AG.union(AG.fromWKT(wkt1), AG.fromWKT(wkt2))) == wkt3
end

@testset "Write Geometry to GeoJSON|GML|WKT|WKB" begin
    AG.createpolygon([(1179091.1646903288, 712782.8838459781),
                      (1161053.0218226474, 667456.2684348812),
                      (1214704.933941905,  641092.8288590391),
                      (1228580.428455506,  682719.3123998424),
                      (1218405.0658121984, 721108.1805541387),
                      (1179091.1646903288, 712782.8838459781)]) do poly
        @test AG.toJSON(poly)[1:19] == "{ \"type\": \"Polygon\""
        @test AG.toGML(poly)[1:13] == "<gml:Polygon>"
        @test AG.toWKT(poly)[1:7] == "POLYGON"
        @test AG.toWKB(poly) == UInt8[0x01, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x38, 0x25, 0x29, 0x2a, 0xd3, 0xfd, 0x31, 0x41, 0xc5, 0x75, 0x87, 0xc4, 0x9d, 0xc0, 0x25, 0x41, 0x45, 0x2b, 0x96, 0x05, 0x5d, 0xb7, 0x31, 0x41, 0xf8, 0x4b, 0x70, 0x89, 0x80, 0x5e, 0x24, 0x41, 0x12, 0xd1, 0x16, 0xef, 0xf0, 0x88, 0x32, 0x41, 0x44, 0x36, 0x60, 0xa8, 0x89, 0x90, 0x23, 0x41, 0x92, 0x42, 0xaf, 0x6d, 0x24, 0xbf, 0x32, 0x41, 0x45, 0xdf, 0xf2, 0x9f, 0xbe, 0xd5, 0x24, 0x41, 0x78, 0x11, 0xd9, 0x10, 0x65, 0x97, 0x32, 0x41, 0x92, 0x97, 0x71, 0x5c, 0xa8, 0x01, 0x26, 0x41, 0x38, 0x25, 0x29, 0x2a, 0xd3, 0xfd, 0x31, 0x41, 0xc5, 0x75, 0x87, 0xc4, 0x9d, 0xc0, 0x25, 0x41]
    end
end

@testset "Force polygon to multipolygon" begin
    wkt = "POLYGON ((1179091.164690328761935 712782.883845978067257,1161053.021822647424415 667456.268434881232679,1214704.933941904921085 641092.828859039116651,1228580.428455505985767 682719.312399842427112,1218405.065812198445201 721108.180554138729349,1179091.164690328761935 712782.883845978067257))"

    # Method 1
    AG.fromWKT(wkt) do poly
        @test AG.getgeomtype(poly) == GDAL.wkbPolygon
        AG.forceto(poly, GDAL.wkbMultiPolygon) do mpoly
            @test AG.getgeomtype(mpoly) == GDAL.wkbMultiPolygon
        end
    end

    # Method 2
    @test AG.getgeomtype(AG.forceto(AG.fromWKT(wkt), GDAL.wkbMultiPolygon)) == GDAL.wkbMultiPolygon
end
