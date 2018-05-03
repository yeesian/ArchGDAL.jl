using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Reproject a Geometry" begin
    @testset "Method 1" begin
        source = AG.unsafe_importEPSG(2927); target = AG.unsafe_importEPSG(4326)
            transform = AG.unsafe_createcoordtrans(source, target)
                point = AG.unsafe_fromWKT("POINT (1120351.57 741921.42)")
                    @test AG.toWKT(point) == "POINT (1120351.57 741921.42)"
                    AG.transform!(point, transform)
                    @test AG.toWKT(point) == "POINT (-122.598135130878 47.3488013802885)"
                AG.destroy(point)
            AG.destroy(transform)
        AG.destroy(target); AG.destroy(source)
    end

    @testset "Method 2" begin
        AG.importEPSG(2927) do source; AG.importEPSG(4326) do target
            AG.createcoordtrans(source, target) do transform
                AG.fromWKT("POINT (1120351.57 741921.42)") do point
                    @test AG.toWKT(point) == "POINT (1120351.57 741921.42)"
                    AG.transform!(point, transform)
                    @test AG.toWKT(point) == "POINT (-122.598135130878 47.3488013802885)"
        end end end end
    end
end

@testset "Get Projection" begin
    AG.registerdrivers() do
        AG.read("ospy/data1/sites.shp") do dataset
            layer = AG.getlayer(dataset, 0)
            spatialref = AG.getspatialref(layer)
            @test AG.toWKT(spatialref) == """PROJCS["WGS_1984_UTM_Zone_12N",GEOGCS["GCS_WGS_1984",DATUM["WGS_1984",SPHEROID["WGS_84",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433],AUTHORITY["EPSG","4326"]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-111.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0],AUTHORITY["EPSG","32612"]]"""
            @test AG.toWKT(spatialref, false) == """
            PROJCS["WGS_1984_UTM_Zone_12N",
                GEOGCS["GCS_WGS_1984",
                    DATUM["WGS_1984",
                        SPHEROID["WGS_84",6378137.0,298.257223563]],
                    PRIMEM["Greenwich",0.0],
                    UNIT["Degree",0.0174532925199433],
                    AUTHORITY["EPSG","4326"]],
                PROJECTION["Transverse_Mercator"],
                PARAMETER["False_Easting",500000.0],
                PARAMETER["False_Northing",0.0],
                PARAMETER["Central_Meridian",-111.0],
                PARAMETER["Scale_Factor",0.9996],
                PARAMETER["Latitude_Of_Origin",0.0],
                UNIT["Meter",1.0],
                AUTHORITY["EPSG","32612"]]"""
            @test AG.toWKT(spatialref, true) == """
            PROJCS["WGS_1984_UTM_Zone_12N",
                GEOGCS["GCS_WGS_1984",
                    DATUM["WGS_1984",
                        SPHEROID["WGS_84",6378137.0,298.257223563]],
                    PRIMEM["Greenwich",0.0],
                    UNIT["Degree",0.0174532925199433]],
                PROJECTION["Transverse_Mercator"],
                PARAMETER["False_Easting",500000.0],
                PARAMETER["False_Northing",0.0],
                PARAMETER["Central_Meridian",-111.0],
                PARAMETER["Scale_Factor",0.9996],
                PARAMETER["Latitude_Of_Origin",0.0],
                UNIT["Meter",1.0]]"""
            @test AG.toPROJ4(spatialref) == "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs "
            @test AG.toXML(spatialref)[1:17] == "<gml:ProjectedCRS"
            @test AG.toMICoordSys(spatialref) == "Earth Projection 8, 104, \"m\", -111, 0, 0.9996, 500000, 0"
            AG.nextfeature(layer) do feature
                @test AG.toWKT(AG.getspatialref(AG.getgeom(feature))) == """PROJCS["WGS_1984_UTM_Zone_12N",GEOGCS["GCS_WGS_1984",DATUM["WGS_1984",SPHEROID["WGS_84",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433],AUTHORITY["EPSG","4326"]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-111.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0],AUTHORITY["EPSG","32612"]]"""
            end
        end
    end

    AG.importEPSG(26912) do spatialref
        @test AG.toPROJ4(spatialref) == "+proj=utm +zone=12 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs "
        @test AG.toWKT(spatialref) == """PROJCS["NAD83 / UTM zone 12N",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4269"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-111],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","26912"]]"""
        AG.morphtoESRI!(spatialref)
        @test AG.toPROJ4(spatialref) == "+proj=utm +zone=12 +ellps=GRS80 +units=m +no_defs "
        AG.toWKT(spatialref) == """PROJCS["NAD_1983_UTM_Zone_12N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-111],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["Meter",1]]"""
    end
end
