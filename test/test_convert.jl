using Test
import ArchGDAL; const AG = ArchGDAL
import GeoFormatTypes; const GFT = GeoFormatTypes

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
    wkt4326 = GFT.WellKnownText(GFT.CRS, "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]")
    wkt26912 = GFT.WellKnownText(GFT.CRS, "PROJCS[\"NAD83 / UTM zone 12N\",GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY[\"EPSG\",\"6269\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4269\"]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",-111],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],AUTHORITY[\"EPSG\",\"26912\"]]")
    proj4326 = GFT.ProjString("+proj=longlat +datum=WGS84 +no_defs")
    proj26912 = GFT.ProjString("+proj=utm +zone=12 +datum=NAD83 +units=m +no_defs")
    esri4326 = GFT.ESRIWellKnownText(GFT.CRS, "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433],AXIS[\"Longitude\",EAST],AXIS[\"Latitude\",NORTH]]")
    esri26912 = GFT.ESRIWellKnownText(GFT.CRS, "PROJCS[\"NAD83 / UTM zone 12N\",GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],AUTHORITY[\"EPSG\",\"6269\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",-111],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH]]")
    convert(GFT.ProjString, GFT.CRS(), wkt26912)
    convert(GFT.WellKnownText, GFT.CRS(), proj26912)
    convert(GFT.ESRIWellKnownText, GFT.CRS(), proj26912)
end
