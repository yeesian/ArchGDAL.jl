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
    @test sprint(print, AG.GeoTable(layer)) == "GeoTable with 4 Features\n"
    @test sprint(print, AG.GeoTable(layer)) != "Layer is not a valid ArchGDAL layer\n"      
    
    #testing Tables.schema
    @test sprint(print, AG.Tables.schema(layer)) == "Tables.Schema:\n :FID        Float64      \n :pointname  String       \n Symbol(\"\")  GDAL.wkbPoint"
    #testing Base.iterate
    @test sprint(print, AG.Base.iterate(AG.GeoTable(layer))) == "(ArchGDAL.FeatureRow(NamedTuple{(:pointname, :geometry, :FID),Tuple{String,ArchGDAL.IGeometry,Float64}}[(pointname = \"point-a\", geometry = Geometry: POINT (100 0), FID = 2.0)], 0), 1)"
    @test Tables.istable(AG.GeoTable(layer)) == true
    @test Tables.rowaccess(AG.GeoTable(layer)) == true
    @test Tables.rows(AG.GeoTable(layer)) == AG.GeoTable(layer)

    @test Base.size(AG.GeoTable(layer)) == 4
    @test Base.length(AG.GeoTable(layer)) == 12

end


