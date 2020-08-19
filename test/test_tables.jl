using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

@testset "Tables Support" begin
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    dataset1 = AG.read(joinpath(@__DIR__, "data/multi_geom.csv"), options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])
    layer = AG.getlayer(dataset, 0)
    layer1 = AG.getlayer(dataset1, 0)
    gt = AG.Table(layer)
    gt1 = AG.Table(layer1)
    fr = iterate(gt, 1)[1]
    fr1 = iterate(gt, 1)[1]
    nfeat = AG.nfeature(layer)
    nfeat1 = AG.nfeature(layer1)
    nfield = AG.nfield(layer)
    nfield1 = AG.nfield(layer1)
    featuredefn = AG.layerdefn(layer)
    featuredefn1 = AG.layerdefn(layer1)
    ngeometries = AG.ngeom(featuredefn)
    ngeometries1 = AG.ngeom(featuredefn1)

    @test sprint(print, gt) == "Table with 4 features\n"
    @test sprint(print, gt1) == "Table with 2 features\n"
    @test getproperty(Tables.schema(layer), :types) == (Float64, String)
    @test getproperty(Tables.schema(layer1), :types) == (String, String, String)
    @test getproperty(Tables.schema(layer), :names) == propertynames(gt)
    @test getproperty(Tables.schema(layer1), :names) == propertynames(gt1)
    
    @test Tables.istable(AG.Table) == true
    @test Tables.rows(gt) == AG.Table(layer)
    @test Tables.rows(gt1) == AG.Table(layer1)
    @test Base.size(gt) == 4
    @test Base.size(gt1) == 2
    @test Base.length(gt) == 4
    @test Base.length(gt1) == 2
    @test propertynames(iterate(gt, 1)[1]) == (:FID, :pointname, Symbol(""))
    @test propertynames(iterate(gt1, 1)[1]) == (:id, :zoom, :location, :point, :linestring)
    @test iterate(gt, 5) === nothing
    @test iterate(gt1, 3) === nothing
end
