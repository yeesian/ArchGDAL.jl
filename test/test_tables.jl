using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

@testset "Tables Support" begin
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    layer = AG.getlayer(dataset, 0)
    gt = AG.GeoTable(layer)
    fr = iterate(gt, 1)[1]
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeometries = AG.ngeom(featuredefn)

    @test sprint(print, gt) == "GeoTable with 4 Features\n"
    @test sprint(print, gt) != "Layer is not a valid ArchGDAL layer\n"      
    @test getproperty(Tables.schema(layer), :types) == (Float64, String, AG.GDAL.wkbPoint)
    @test getproperty(Tables.schema(layer), :names) == propertynames(gt)
    @test Tables.istable(AG.GeoTable) == true
    @test Tables.rowaccess(AG.GeoTable) == true
    @test Tables.rows(gt) == AG.GeoTable(layer)
    @test Base.size(gt) == 4
    @test Base.length(gt) == 4
    @test propertynames(iterate(gt, 1)[1]) == (:pointname, :geometry, :FID)
    @test AG.geometry(gt) isa Array{AG.IGeometry}
    @test iterate(gt, 5) === nothing
end