using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

@testset "Tables Support" begin
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    layer = AG.getlayer(dataset, 0)

    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeometries = AG.ngeom(featuredefn)

    #testing the main GeoTable function
    @test sprint(print, AG.GeoTable(layer)) == "GeoTable with 7 Features\n"
    @test sprint(print, AG.GeoTable(layer)) != "Layer is not a valid ArchGDAL layer\n"      
    
    #testing Tables.schema
    @test sprint(print, AG.Tables.schema(layer)) == "Tables.Schema:\n :fid        Int32             \n :uuid       String            \n Symbol(\"\")  GDAL.wkbLineString"

    #testing Base.iterate
    @test sprint(print, AG.Base.iterate(AG.GeoTable(layer))) == "(ArchGDAL.FeatureRow(NamedTuple{(:uuid, :geometry, :fid),Tuple{String,ArchGDAL.IGeometry,Int32}}[(uuid = \"{2c66f90e-befb-49d5-8083-c5642194be06}\", geometry = Geometry: LINESTRING (-9.14617603432751 2.17229654185419,-9. ... 9273), fid = 183521)], 0), 1)"

    @test Tables.istable(AG.GeoTable(layer)) == true
    @test Tables.rowaccess(AG.GeoTable(layer)) == true
    @test Tables.rows(AG.GeoTable(layer)) == AG.GeoTable(layer)

    @test Base.size(AG.GeoTable(layer)) == 7
    @test Base.length(AG.GeoTable(layer)) == 21

end

