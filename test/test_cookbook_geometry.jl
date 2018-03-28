# adapted from http://pcjericks.github.io/py-gdalogr-cookbook/geometry.html
using Base.Test
import GDAL, ArchGDAL; const AG = ArchGDAL

@testset "Create a Point" begin
    # Method 1
    AG.createpoint(1198054.34, 648493.09) do point
        println(AG.toWKT(point))
    end
    AG.createpoint((1198054.34, 648493.09)) do point
        println(AG.toWKT(point))
    end

    # Method 2
    AG.createpoint() do point
        AG.addpoint!(point, 1198054.34, 648493.09)
        println(AG.toWKT(point))
    end

    # Method 3
    AG.creategeom(GDAL.wkbPoint) do point
        AG.addpoint!(point, 1198054.34, 648493.09)
        println(AG.toWKT(point))
    end

    # Method 4
    point = AG.unsafe_creategeom(GDAL.wkbPoint)
        AG.addpoint!(point, 1198054.34, 648493.09)
        println(AG.toWKT(point))
    AG.destroy(point)

    # Method 5
    println(AG.toWKT(AG.createpoint(1198054.34, 648493.09)))
end

@testset "Create a LineString" begin
    # Method 1
    AG.createlinestring([(1116651.439379124,  637392.6969887456),
                         (1188804.0108498496, 652655.7409537067),
                         (1226730.3625203592, 634155.0816022386),
                         (1281307.30760719,   636467.6640211721)]) do line
        println(AG.toWKT(line))
    end

    # Method 2
    AG.createlinestring() do line
        AG.addpoint!(line, 1116651.439379124,  637392.6969887456)
        AG.addpoint!(line, 1188804.0108498496, 652655.7409537067)
        AG.addpoint!(line, 1226730.3625203592, 634155.0816022386)
        AG.addpoint!(line, 1281307.30760719,   636467.6640211721)
        println(AG.toWKT(line))
    end

    # Method 3
    AG.creategeom(GDAL.wkbLineString) do line
        AG.addpoint!(line, 1116651.439379124,  637392.6969887456)
        AG.addpoint!(line, 1188804.0108498496, 652655.7409537067)
        AG.addpoint!(line, 1226730.3625203592, 634155.0816022386)
        AG.addpoint!(line, 1281307.30760719,   636467.6640211721)
        println(AG.toWKT(line))
    end

    # Method 4
    line = AG.unsafe_creategeom(GDAL.wkbLineString)
        AG.addpoint!(line, 1116651.439379124,  637392.6969887456)
        AG.addpoint!(line, 1188804.0108498496, 652655.7409537067)
        AG.addpoint!(line, 1226730.3625203592, 634155.0816022386)
        AG.addpoint!(line, 1281307.30760719,   636467.6640211721)
        println(AG.toWKT(line))
    AG.destroy(line)

    # Method 5
    println(AG.toWKT(AG.createlinestring([
        (1116651.439379124,  637392.6969887456),
        (1188804.0108498496, 652655.7409537067),
        (1226730.3625203592, 634155.0816022386),
        (1281307.30760719,   636467.6640211721)
    ])))
end

@testset "Create a Polygon" begin
    # Method 1
    AG.createpolygon([(1179091.1646903288, 712782.8838459781),
                      (1161053.0218226474, 667456.2684348812),
                      (1214704.933941905,  641092.8288590391),
                      (1228580.428455506,  682719.3123998424),
                      (1218405.0658121984, 721108.1805541387),
                      (1179091.1646903288, 712782.8838459781)]) do poly
        println(AG.toWKT(poly))
    end

    # Method 2
    AG.createpolygon() do poly
        ring = AG.unsafe_createlinearring(
                    [(1179091.1646903288, 712782.8838459781),
                     (1161053.0218226474, 667456.2684348812),
                     (1214704.933941905,  641092.8288590391),
                     (1228580.428455506,  682719.3123998424),
                     (1218405.0658121984, 721108.1805541387),
                     (1179091.1646903288, 712782.8838459781)])
        AG.addgeomdirectly!(poly, ring)
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
            println(AG.toWKT(poly))
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
            println(AG.toWKT(poly))
        end
    end

    # Method 4
    ring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
        AG.addpoint!(ring, 1179091.1646903288, 712782.8838459781)
        AG.addpoint!(ring, 1161053.0218226474, 667456.2684348812)
        AG.addpoint!(ring, 1214704.933941905, 641092.8288590391)
        AG.addpoint!(ring, 1228580.428455506, 682719.3123998424)
        AG.addpoint!(ring, 1218405.0658121984, 721108.1805541387)
        AG.addpoint!(ring, 1179091.1646903288, 712782.8838459781)

    poly = AG.unsafe_creategeom(GDAL.wkbPolygon)
        AG.addgeomdirectly!(poly, ring) # ownership of ring passed to poly
        println(AG.toWKT(poly))
    AG.destroy(poly)

    println(AG.toWKT(AG.createpolygon([
        (1179091.1646903288, 712782.8838459781),
        (1161053.0218226474, 667456.2684348812),
        (1214704.933941905,  641092.8288590391),
        (1228580.428455506,  682719.3123998424),
        (1218405.0658121984, 721108.1805541387),
        (1179091.1646903288, 712782.8838459781)
    ])))
end 

@testset "Create a Polygon with holes" begin
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
        println(AG.toWKT(poly))
    end

    # Method 2
    AG.createpolygon() do poly
        outring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)

        innerring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
    
        AG.addgeomdirectly!(poly, outring)
        AG.addgeomdirectly!(poly, innerring)
        println(AG.toWKT(poly))
    end

    # Method 3
    AG.creategeom(GDAL.wkbPolygon) do poly
        outring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)

        innerring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
    
        AG.addgeomdirectly!(poly, outring)
        AG.addgeomdirectly!(poly, innerring)
        println(AG.toWKT(poly))
    end

    # Method 4
    poly = AG.unsafe_creategeom(GDAL.wkbPolygon)
        outring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 653118.2574374934)
            AG.addpoint!(outring, 1165678.1866605144, 686419.4442701361)
            AG.addpoint!(outring, 1154115.274565847, 686419.4442701361)

        innerring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 648030.5761158396)
            AG.addpoint!(innerring, 1191579.1097525698, 691044.6091080031)
            AG.addpoint!(innerring, 1149490.1097279799, 691044.6091080031)
    
        AG.addgeomdirectly!(poly, outring)
        AG.addgeomdirectly!(poly, innerring)
        println(AG.toWKT(poly))
    AG.destroy(poly)

    # Method 5
    println(AG.toWKT(AG.createpolygon([
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
    ])))
end

@testset "Create a MultiPoint" begin
    # Method 1
    AG.createmultipoint([(1251243.7361610543, 598078.7958668759),
                         (1240605.8570339603, 601778.9277371694),
                         (1250318.7031934808, 606404.0925750365)]) do multipoint
        println(AG.toWKT(multipoint))
    end

    # Method 2
    println("method 2")
    AG.createmultipoint() do multipoint
        point1 = AG.unsafe_createpoint(1251243.7361610543, 598078.7958668759)
        point2 = AG.unsafe_createpoint(1240605.8570339603, 601778.9277371694)
        point3 = AG.unsafe_createpoint(1250318.7031934808, 606404.0925750365)
        AG.addgeomdirectly!(multipoint, point1)
        AG.addgeomdirectly!(multipoint, point2)
        AG.addgeomdirectly!(multipoint, point3)
        println(AG.toWKT(multipoint))
    end

    # Method 3
    AG.creategeom(GDAL.wkbMultiPoint) do multipoint
        point1 = AG.unsafe_createpoint(1251243.7361610543, 598078.7958668759)
        point2 = AG.unsafe_createpoint(1240605.8570339603, 601778.9277371694)
        point3 = AG.unsafe_createpoint(1250318.7031934808, 606404.0925750365)
        AG.addgeomdirectly!(multipoint, point1)
        AG.addgeomdirectly!(multipoint, point2)
        AG.addgeomdirectly!(multipoint, point3)
        println(AG.toWKT(multipoint))
    end

    # Method 4
    multipoint = AG.unsafe_creategeom(GDAL.wkbMultiPoint)
        point1 = AG.unsafe_createpoint(1251243.7361610543, 598078.7958668759)
        point2 = AG.unsafe_createpoint(1240605.8570339603, 601778.9277371694)
        point3 = AG.unsafe_createpoint(1250318.7031934808, 606404.0925750365)
        AG.addgeomdirectly!(multipoint, point1)
        AG.addgeomdirectly!(multipoint, point2)
        AG.addgeomdirectly!(multipoint, point3)
        println(AG.toWKT(multipoint))
    AG.destroy(multipoint)

    # Method 5
    println(AG.toWKT(AG.createmultipoint([
        (1251243.7361610543, 598078.7958668759),
        (1240605.8570339603, 601778.9277371694),
        (1250318.7031934808, 606404.0925750365)
    ])))
end

@testset "Create a MultiLineString" begin
    # Method 1
    AG.createmultilinestring(Vector{Tuple{Float64,Float64}}[
                              [(1214242.4174581182, 617041.9717021306),
                               (1234593.142744733,  629529.9167643716)],
                              [(1184641.3624957693, 626754.8178616514),
                               (1219792.6152635587, 606866.6090588232)]
                             ]) do multiline
        @test GeoInterface.geotype(multiline) == :MultiLineString
        println(AG.toWKT(multiline))
    end

    # Method 2
    AG.createmultilinestring() do multiline
        AG.addgeomdirectly!(multiline, AG.unsafe_createlinestring(
            [(1214242.4174581182, 617041.9717021306),
             (1234593.142744733,  629529.9167643716)]))
        AG.addgeomdirectly!(multiline, AG.unsafe_createlinestring(
            [(1184641.3624957693, 626754.8178616514),
             (1219792.6152635587, 606866.6090588232)]))
        println(AG.toWKT(multiline))
    end

    # Method 3
    AG.creategeom(GDAL.wkbMultiLineString) do multiline
        line = AG.unsafe_creategeom(GDAL.wkbLineString)
        AG.addpoint!(line, 1214242.4174581182, 617041.9717021306)
        AG.addpoint!(line, 1234593.142744733, 629529.9167643716)
        AG.addgeomdirectly!(multiline, line)

        line = AG.unsafe_creategeom(GDAL.wkbLineString)
        AG.addpoint!(line, 1184641.3624957693, 626754.8178616514)
        AG.addpoint!(line, 1219792.6152635587, 606866.6090588232)
        AG.addgeomdirectly!(multiline, line)

        println(AG.toWKT(multiline))
    end

    # Method 4
    multiline = AG.unsafe_creategeom(GDAL.wkbMultiLineString)
        line = AG.unsafe_creategeom(GDAL.wkbLineString)
        AG.addpoint!(line, 1214242.4174581182, 617041.9717021306)
        AG.addpoint!(line, 1234593.142744733, 629529.9167643716)
        AG.addgeomdirectly!(multiline, line)

        line = AG.unsafe_creategeom(GDAL.wkbLineString)
        AG.addpoint!(line, 1184641.3624957693, 626754.8178616514)
        AG.addpoint!(line, 1219792.6152635587, 606866.6090588232)
        AG.addgeomdirectly!(multiline, line)

        println(AG.toWKT(multiline))
    AG.destroy(multiline)

    # Method 5
    println(AG.toWKT(AG.createmultilinestring(Vector{Tuple{Float64,Float64}}[
        [(1214242.4174581182, 617041.9717021306),
         (1234593.142744733,  629529.9167643716)],
        [(1184641.3624957693, 626754.8178616514),
         (1219792.6152635587, 606866.6090588232)]
    ])))
end

@testset "Create a MultiPolygon" begin
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
        println(AG.toWKT(multipolygon))
    end

    # Method 2
    AG.createmultipolygon() do multipolygon
        poly = AG.unsafe_createpolygon(
            [(1204067.0548148106, 634617.5980860253),
             (1204067.0548148106, 620742.1035724243),
             (1215167.4504256917, 620742.1035724243),
             (1215167.4504256917, 634617.5980860253),
             (1204067.0548148106, 634617.5980860253)])
        AG.addgeomdirectly!(multipolygon,poly)

        poly = AG.unsafe_createpolygon(
            [(1179553.6811741155, 647105.5431482664),
             (1179553.6811741155, 626292.3013778647),
             (1194354.20865529,   626292.3013778647),
             (1194354.20865529,   647105.5431482664),
             (1179553.6811741155, 647105.5431482664)])
        AG.addgeomdirectly!(multipolygon,poly)

        println(AG.toWKT(multipolygon))
    end

    # Method 3
    AG.creategeom(GDAL.wkbMultiPolygon) do multipolygon
        poly = AG.unsafe_creategeom(GDAL.wkbPolygon)
            ring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
            AG.addgeomdirectly!(poly, ring)
        AG.addgeomdirectly!(multipolygon,poly)

        poly = AG.unsafe_creategeom(GDAL.wkbPolygon)
            ring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
            AG.addgeomdirectly!(poly, ring)
        AG.addgeomdirectly!(multipolygon,poly)
        
        println(AG.toWKT(multipolygon))
    end

    # Method 4
    multipolygon = AG.unsafe_creategeom(GDAL.wkbMultiPolygon)
        poly = AG.unsafe_creategeom(GDAL.wkbPolygon)
            ring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 620742.1035724243)
                AG.addpoint!(ring, 1215167.4504256917, 634617.5980860253)
                AG.addpoint!(ring, 1204067.0548148106, 634617.5980860253)
            AG.addgeomdirectly!(poly, ring)
        AG.addgeomdirectly!(multipolygon,poly)

        poly = AG.unsafe_creategeom(GDAL.wkbPolygon)
            ring = AG.unsafe_creategeom(GDAL.wkbLinearRing)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   626292.3013778647)
                AG.addpoint!(ring, 1194354.20865529,   647105.5431482664)
                AG.addpoint!(ring, 1179553.6811741155, 647105.5431482664)
            AG.addgeomdirectly!(poly, ring)
        AG.addgeomdirectly!(multipolygon,poly)

        println(AG.toWKT(multipolygon))
    AG.destroy(multipolygon)

    # Method 5
    println(AG.toWKT(AG.createmultipolygon_noholes(Vector{Tuple{Float64,Float64}}[
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
            ])))
end

@testset "Create a GeometryCollection" begin
    # Method 2
    AG.creategeomcollection() do geomcol
        for g in [AG.unsafe_createpoint(-122.23, 47.09),
                  AG.unsafe_createlinestring([(-122.60, 47.14),
                                              (-122.48, 47.23)])]
            AG.addgeomdirectly!(geomcol, g)
        end
        println(AG.toWKT(geomcol))
    end

    # Method 3
    AG.creategeom(GDAL.wkbGeometryCollection) do geomcol
        point = AG.unsafe_creategeom(GDAL.wkbPoint)
            AG.addpoint!(point, -122.23, 47.09)
        AG.addgeomdirectly!(geomcol, point)

        line = AG.unsafe_creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, -122.60, 47.14)
            AG.addpoint!(line, -122.48, 47.23)
        AG.addgeomdirectly!(geomcol, line)

        println(AG.toWKT(geomcol))
    end

    # Method 4
    geomcol =  AG.unsafe_creategeom(GDAL.wkbGeometryCollection)
        point = AG.unsafe_creategeom(GDAL.wkbPoint)
            AG.addpoint!(point, -122.23, 47.09)
        AG.addgeomdirectly!(geomcol, point)

        line = AG.unsafe_creategeom(GDAL.wkbLineString)
            AG.addpoint!(line, -122.60, 47.14)
            AG.addpoint!(line, -122.48, 47.23)
        AG.addgeomdirectly!(geomcol, line)

        println(AG.toWKT(geomcol))
    AG.destroy(geomcol)
end

@testset "Create Geometry from WKT" begin
    wkt = "POINT (1120351.5712494177 741921.4223245403)"

    # Method 1
    point = AG.unsafe_fromWKT(wkt)
        println((AG.getx(point, 0), AG.gety(point, 0)))
    AG.destroy(point)

    # Method 2
    AG.fromWKT(wkt) do point
        println((AG.getx(point, 0), AG.gety(point, 0)))
    end

    # Method 3
    point = AG.fromWKT(wkt)
    println((AG.getx(point, 0), AG.gety(point, 0)))
end

@testset "Create Geometry from GeoJSON" begin
    geojson = """{"type":"Point","coordinates":[108420.33,753808.59]}"""

    # Method 1
    point = AG.unsafe_fromJSON(geojson)
        println((AG.getx(point, 0), AG.gety(point, 0)))
    AG.destroy(point)

    # Method 2
    AG.fromJSON(geojson) do point
        println((AG.getx(point, 0), AG.gety(point, 0)))
    end

    # Method 3
    point = AG.fromJSON(geojson)
    println((AG.getx(point, 0), AG.gety(point, 0)))
end

@testset "Create Geometry from GML" begin
    gml = """<gml:Point xmlns:gml="http://www.opengis.net/gml">
             <gml:coordinates>108420.33,753808.59</gml:coordinates>
             </gml:Point>"""

    # Method 1
    point = AG.unsafe_fromGML(gml)
        println((AG.getx(point, 0), AG.gety(point, 0)))
    AG.destroy(point)

    # Method 2
    AG.fromGML(gml) do point
        println((AG.getx(point, 0), AG.gety(point, 0)))
    end

    # Method 3
    point = AG.fromGML(gml)
    println((AG.getx(point, 0), AG.gety(point, 0)))
end

@testset "Create Geometry from WKB" begin
    wkb = [0x01,0x01,0x00,0x00,0x00,0x7b,0x14,0xae,0x47,0x45,0x78,0xfa,0x40,
           0xe1,0x7a,0x14,0x2e,0x21,0x01,0x27,0x41]

    # Method 1
    point = AG.unsafe_fromWKB(wkb)
        println((AG.getx(point, 0), AG.gety(point, 0)))
    AG.destroy(point)

    # Method 2
    AG.fromWKB(wkb) do point
        println((AG.getx(point, 0), AG.gety(point, 0)))
    end

    # Method 3
    point = AG.fromWKB(wkb)
    println((AG.getx(point, 0), AG.gety(point, 0)))
end

@testset "Count Points in a Geometry" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"

    # Method 1
    AG.fromWKT(wkt) do geom
        println("Geometry has $(AG.npoint(geom)) points")
    end

    # Method 2
    println("Geometry has $(AG.npoint(AG.fromWKT(wkt))) points")
end

@testset "Count Geometries in a Geometry" begin
    wkt = "MULTIPOINT (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"

    # Method 1
    AG.fromWKT(wkt) do geom
        println("Geometry has $(AG.npoint(geom)) points")
    end

    # Method 2
    println("Geometry has $(AG.npoint(AG.fromWKT(wkt))) points")
end

@testset "Iterate over Geometries in a Geometry" begin
    wkt = "MULTIPOINT (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do geom
        for i in 0:(AG.ngeom(geom)-1)
            println("$i). $(AG.toWKT(AG.getgeom(geom,i)))")
        end
    end
end

@testset "Iterate over Points in a Geometry" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do geom
        for i in 0:(AG.npoint(geom)-1)
            println("$i). POINT $(AG.getpoint(geom, i))")
        end
    end
end

@testset "Buffer a Geometry" begin
    wkt = "POINT (1198054.34 648493.09)"

    # Method 1
    AG.fromWKT(wkt) do pt
        bufferdist = 500
        AG.buffer(pt, bufferdist) do poly
            println("$(AG.toWKT(pt)) buffered by $bufferdist is ")
            println("$(AG.toWKT(poly))")
        end
    end

    # Method 2
    println("$(AG.toWKT(AG.buffer(AG.fromWKT(wkt), 500)))")
end

# @testset "Calculate Envelope of a Geometry" begin
#     wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
#     geom = ogr.CreateGeometryFromWkt(wkt)
#     # Get Envelope returns a tuple (minX, maxX, minY, maxY)
#     env = geom.GetEnvelope()
#     print "minX: %d, minY: %d, maxX: %d, maxY: %d" %(env[0],env[2],env[1],env[3])
# end

@testset "Calculate the Area of a Geometry" begin
    wkt = "POLYGON ((1162440.5712740074 672081.4332727483, 1162440.5712740074 647105.5431482664, 1195279.2416228633 647105.5431482664, 1195279.2416228633 672081.4332727483, 1162440.5712740074 672081.4332727483))"
    AG.fromWKT(wkt) do poly
        println("Area = $(AG.geomarea(poly))")
    end
end

@testset "Calculate the Length of a Geometry" begin
    wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
    AG.fromWKT(wkt) do line
        println("Length = $(AG.geomlength(line))")
    end
end

@testset "Get the geometry type (as a string) from a Geometry" begin
    wkts = [
        "POINT (1198054.34 648493.09)",
        "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)",
        "POLYGON ((1162440.5712740074 672081.4332727483, 1162440.5712740074 647105.5431482664, 1195279.2416228633 647105.5431482664, 1195279.2416228633 672081.4332727483, 1162440.5712740074 672081.4332727483))"
    ]
    for wkt in wkts
        AG.fromWKT(wkt) do geom
            println(AG.getgeomname(geom))
        end
    end
end

@testset "Calculate intersection between two Geometries" begin
    wkt1 = "POLYGON ((1208064.271243039 624154.6783778917, 1208064.271243039 601260.9785661874, 1231345.9998651114 601260.9785661874, 1231345.9998651114 624154.6783778917, 1208064.271243039 624154.6783778917))"
    wkt2 = "POLYGON ((1199915.6662253144 633079.3410163528, 1199915.6662253144 614453.958118695, 1219317.1067437078 614453.958118695, 1219317.1067437078 633079.3410163528, 1199915.6662253144 633079.3410163528)))"

    # Method 1
    AG.fromWKT(wkt1) do poly1
    AG.fromWKT(wkt2) do poly2
        AG.intersection(poly1, poly2) do poly3
            println(AG.toWKT(poly3))
        end
    end
    end

    # Method 2
    println(AG.toWKT(AG.intersection(AG.fromWKT(wkt1), AG.fromWKT(wkt2))))
end

@testset "Calculate union between two Geometries" begin
    wkt1 = "POLYGON ((1208064.271243039 624154.6783778917, 1208064.271243039 601260.9785661874, 1231345.9998651114 601260.9785661874, 1231345.9998651114 624154.6783778917, 1208064.271243039 624154.6783778917))"
    wkt2 = "POLYGON ((1199915.6662253144 633079.3410163528, 1199915.6662253144 614453.958118695, 1219317.1067437078 614453.958118695, 1219317.1067437078 633079.3410163528, 1199915.6662253144 633079.3410163528)))"

    # Method 1
    AG.fromWKT(wkt1) do poly1
    AG.fromWKT(wkt2) do poly2
        AG.union(poly1, poly2) do poly3
            println(AG.toWKT(poly1))
            println(AG.toWKT(poly2))
            println(AG.toWKT(poly3))
        end
    end
    end

    # Method 2
    println(AG.toWKT(AG.union(AG.fromWKT(wkt1), AG.fromWKT(wkt2))))
end

@testset "Write Geometry to GeoJSON|GML|WKT|WKB" begin
    AG.createpolygon([(1179091.1646903288, 712782.8838459781),
                      (1161053.0218226474, 667456.2684348812),
                      (1214704.933941905,  641092.8288590391),
                      (1228580.428455506,  682719.3123998424),
                      (1218405.0658121984, 721108.1805541387),
                      (1179091.1646903288, 712782.8838459781)]) do poly
        println(AG.toJSON(poly))
        println(AG.toGML(poly))
        println(AG.toWKT(poly))
        println(AG.toWKB(poly))
    end
end

@testset "Force polygon to multipolygon" begin
    wkt = "POLYGON ((1179091.164690328761935 712782.883845978067257,1161053.021822647424415 667456.268434881232679,1214704.933941904921085 641092.828859039116651,1228580.428455505985767 682719.312399842427112,1218405.065812198445201 721108.180554138729349,1179091.164690328761935 712782.883845978067257))"

    # Method 1
    AG.fromWKT([wkt]) do poly
        println("Before: $(AG.toWKT(poly))")
        if AG.getgeomtype(poly) == GDAL.wkbPolygon
            AG.forceto(poly, GDAL.wkbMultiPolygon) do mpoly
                println("After: $mpoly")
            end
        end
    end

    # Method 2
    println(AG.forceto(AG.fromWKT([wkt]), GDAL.wkbMultiPolygon))
end
