using Test
import ArchGDAL; const AG = ArchGDAL
import GeoFormatTypes; const GFT = GeoFormatTypes

# Tests high level convert methods

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
    proj4326 = GFT.ProjString("+proj=longlat +datum=WGS84 +no_defs")
    @test convert(GFT.ProjString, GFT.CRS(), 
                  convert(GFT.WellKnownText, GFT.CRS(), 
                          convert(GFT.ESRIWellKnownText, GFT.CRS(), 
                                  GFT.EPSG(4326)))) == proj4326
end
