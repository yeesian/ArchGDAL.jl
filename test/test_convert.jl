
@testset "convert point format" begin
    point = AG.createpoint(100, 70)
    json = convert(GFT.GeoJSON, point)
    kml = convert(GFT.KML, point)
    gml = convert(GFT.GML, point)
    wkb = convert(GFT.WellKnownBinary, point) 
    wkt = convert(GFT.WellKnownText, point) 
    @test json.val == AG.toJSON(point)
    @test kml.val == AG.toKML(point)
    @test gml.val == AG.toGML(point)
    @test wkb.val == AG.toWKB(point)
    @test wkt.val == AG.toWKT(point)
    @test convert(GFT.GeoJSON, json) == convert(GFT.GeoJSON, wkb) == 
          convert(GFT.GeoJSON, wkt) == convert(GFT.GeoJSON, gml) == json
    @test convert(GFT.KML, gml) == convert(GFT.KML, wkt)
end


@testset "convert crs format" begin
    @testset "PROJ4 Format" begin
        proj4326 = "+proj=longlat +datum=WGS84 +no_defs"
        proj26912 = "+proj=utm +zone=12 +datum=NAD83 +units=m +no_defs"
        AG.importPROJ4(proj4326) do spatialref
            spatialref2 = AG.importPROJ4(proj26912)
            @test AG.toPROJ4(spatialref2) == proj26912
            AG.importPROJ4!(spatialref2, AG.toPROJ4(spatialref))
            @test AG.toPROJ4(spatialref2) == proj4326
        end
    end

    @testset "WKT Format" begin
        wkt4326 = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]"
        wkt26912 = "PROJCS[\"NAD83 / UTM zone 12N\",GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY[\"EPSG\",\"6269\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4269\"]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",-111],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],AUTHORITY[\"EPSG\",\"26912\"]]"
        AG.importWKT(wkt4326) do spatialref
            spatialref2 = AG.importWKT(wkt26912)
            @test AG.toWKT(spatialref2) == wkt26912
            AG.importWKT!(spatialref2, AG.toWKT(spatialref))
            @test AG.toWKT(spatialref2) == wkt4326
        end
    end

    @testset "ESRI Format" begin
        esri4326 = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433],AXIS[\"Longitude\",EAST],AXIS[\"Latitude\",NORTH]]"
        esri26912 = "PROJCS[\"NAD83 / UTM zone 12N\",GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],AUTHORITY[\"EPSG\",\"6269\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",-111],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH]]"
        AG.importESRI(esri4326) do spatialref
            spatialref2 = AG.importESRI(esri26912)
            @test AG.toWKT(spatialref2) == esri26912
            AG.importESRI!(spatialref2, AG.toWKT(spatialref))
            @test AG.toWKT(spatialref2) == esri4326
        end
    end
end
