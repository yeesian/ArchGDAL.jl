using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

@testset "Tables Support" begin
    
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    dataset1 = AG.read(joinpath(@__DIR__, "data/multi_geom.csv"), options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])
    @test dataset isa ArchGDAL.IDataset
    @test dataset1 isa ArchGDAL.IDataset
    layer = AG.getlayer(dataset, 0)
    layer1 = AG.getlayer(dataset1, 0)
    gt = AG.Table(layer)
    gt1 = AG.Table(layer1)
        

    @testset "read layer to table" begin
        @test AG.getlayer(gt) === layer
        @test AG.getlayer(gt1) === layer1
        @test sprint(print, gt) == "Table with 4 features\n"
        @test sprint(print, gt1) == "Table with 2 features\n"
    end

    @testset "Tables methods" begin
        @test Tables.schema(layer).names == propertynames(gt)
        @test Tables.schema(layer1).names == propertynames(gt1)
        @test Tables.istable(AG.Table) == true
        @test Tables.rows(gt) == AG.Table(layer)
        @test Tables.rows(gt1) == AG.Table(layer1)
    end

    @testset "Misc. methods" begin
        @test Base.size(gt) == 4
        @test Base.size(gt1) == 2
        @test Base.length(gt) == 4
        @test Base.length(gt1) == 2
        @test Base.IteratorSize(typeof(gt)) == Base.HasLength()
        @test Base.IteratorEltype(typeof(gt1)) == Base.HasEltype()
        @test propertynames(gt) == (:FID, :pointname, Symbol(""))
        @test propertynames(gt1) == (:id, :zoom, :location, :point, :linestring)
        @test getproperty(gt, :FID) == [iterate(gt, i)[1].FID for i in 0:size(gt)-1]
        @test getproperty(gt1, :zoom) == [iterate(gt1, i)[1].zoom for i in 0:size(gt1)-1]
        @test iterate(gt, 5) === nothing
        @test iterate(gt1, 3) === nothing
        @test typeof([getindex(gt, i) for i in 0:size(gt)-1]) == typeof([iterate(gt, i)[1] for i in 0:size(gt)-1])
        @test typeof([getindex(gt1, i) for i in 0:size(gt1)-1]) == typeof([iterate(gt1, i)[1] for i in 0:size(gt1)-1])
    end
end
