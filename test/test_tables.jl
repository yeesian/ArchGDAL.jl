using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

@testset "Tables Support" begin
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    layer = AG.getlayer(dataset, 0)
    gt = AG.geotable(layer)
    fr = iterate(gt, 1)[1]
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    featuredefn = AG.layerdefn(layer)
    ngeometries = AG.ngeom(featuredefn)
    f2 = AG.geometry(gt)

    @test sprint(print, gt) == "GeoTable with 4 Features\n"
    @test getproperty(Tables.schema(layer), :types) == (Float64, String)
    @test getproperty(Tables.schema(layer), :names) == propertynames(gt)
    @test Tables.istable(AG.GeoTable) == true
    @test Tables.rowaccess(AG.GeoTable) == true
    @test Tables.rows(gt) == AG.geotable(layer)
    @test Base.size(gt) == 4
    @test Base.length(gt) == 4
    @test propertynames(iterate(gt, 1)[1]) == (:pointname, :FID)
    @test f2 isa Array{AG.IGeometry}
    @test typeof(f2) === typeof([AG.geometry(gt, i) for i in 1:length(gt)])
    @test iterate(gt, 5) === nothing
end