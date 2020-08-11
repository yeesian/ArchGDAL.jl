using Test
import ArchGDAL; const AG = ArchGDAL

@testset "Tables Support" begin
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    layer = AG.getlayer(dataset, 0)
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeometries = AG.ngeom(featuredefn)

    @test sprint(print, AG.GeoTable(layer)) == "GeoTable with 4 Features\n"
    @test sprint(print, AG.GeoTable(layer)) != "Layer is not a valid ArchGDAL layer\n"      
    @test getproperty(Tables.schema(layer), :types) == (Float64, String, AG.GDAL.wkbPoint)
    @test getproperty(Tables.schema(layer), :names) == (:FID, :pointname, Symbol(""))
    @test AG.Tables.istable(AG.GeoTable(layer)) == true
    @test AG.Tables.rowaccess(AG.GeoTable(layer)) == true
    @test AG.Tables.rows(AG.GeoTable(layer)) == AG.GeoTable(layer)
    @test Base.size(AG.GeoTable(layer)) == 4
    @test Base.length(AG.GeoTable(layer)) == 12
end



