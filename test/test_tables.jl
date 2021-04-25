using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

@testset "test_tables.jl" begin

@testset "Tables Support" begin
    dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
    dataset1 = AG.read(joinpath(@__DIR__, "data/multi_geom.csv"), options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])
    dataset2 = AG.read(joinpath(@__DIR__, "data/missing_testcase.csv"), options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])
    @test dataset isa ArchGDAL.IDataset
    @test dataset1 isa ArchGDAL.IDataset
    @test dataset2 isa ArchGDAL.IDataset
    layer = AG.getlayer(dataset, 0)
    layer1 = AG.getlayer(dataset1, 0)
    layer2 = AG.getlayer(dataset2, 0)
    gt = AG.Table(layer)
    gt1 = AG.Table(layer1)
    gt2 = AG.Table(layer2)

    @testset "read layer to table" begin
        @test sprint(print, gt) == "Table with 4 features\n"
        @test sprint(print, gt1) == "Table with 2 features\n"
        @test sprint(print, gt2) == "Table with 9 features\n"
    end

    @testset "Tables methods" begin
        @test Tables.schema(layer1) == Tables.Schema(
            (:id, :zoom, :location, :point, :linestring),
            (String, String, String, AG.IGeometry, AG.IGeometry)
        )
        @test Tables.istable(AG.Table) == true
    end

    @testset "Misc. methods" begin
        AG.resetreading!(layer)
        AG.resetreading!(layer1)
        
        @test AG.nextnamedtuple(layer) isa NamedTuple{(:FID, :pointname, Symbol("")),Tuple{Float64,String,ArchGDAL.IGeometry}}
        @test AG.nextnamedtuple(layer1) isa NamedTuple{(:id, :zoom, :location, :point, :linestring),Tuple{String,String,String,ArchGDAL.IGeometry,ArchGDAL.IGeometry}}
        for i in 1:4
            @test AG.schema_names(layer)[i] isa Base.Generator || AG.schema_names(layer)[i] isa ArchGDAL.IFeatureDefnView
            @test AG.schema_names(layer1)[i] isa Base.Generator || AG.schema_names(layer1)[i] isa ArchGDAL.IFeatureDefnView
        end
    end
end

end
