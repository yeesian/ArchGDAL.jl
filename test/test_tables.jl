using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

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
        @test AG.getlayer(gt) === layer
        @test AG.getlayer(gt1) === layer1
        @test AG.getlayer(gt2) === layer2
        @test sprint(print, gt) == "Table with 4 features\n"
        @test sprint(print, gt1) == "Table with 2 features\n"
        @test sprint(print, gt2) == "Table with 9 features\n"
    end

    @testset "Tables methods" begin
        @test Tables.schema(layer).names == propertynames(gt)
        @test Tables.schema(layer1).names == propertynames(gt1)
        @test Tables.schema(layer2).names == propertynames(gt2)
        @test Tables.istable(AG.Table) == true
        @test Tables.rows(gt) == AG.Table(layer)
        @test Tables.rows(gt1) == AG.Table(layer1)
        @test Tables.rows(gt2) == AG.Table(layer2)
    end

    @testset "Misc. methods" begin
        @test Base.size(gt) == 4
        @test Base.size(gt1) == 2
        @test Base.size(gt2) == 9
        @test Base.length(gt) == 4
        @test Base.length(gt1) == 2
        @test Base.length(gt2) == 9
        @test Base.IteratorSize(typeof(gt)) == Base.HasLength()
        @test Base.IteratorEltype(typeof(gt1)) == Base.HasEltype()
        @test propertynames(gt) == (:geometry, :FID, :pointname)
        @test propertynames(gt1) == (:point, :linestring, :id, :zoom, :location)
        @test propertynames(gt2) == (:point, :linestring, :id, :zoom, :location)
        @test getproperty(gt, :FID) == [iterate(gt, i)[1].FID for i in 0:size(gt)-1]
        @test getproperty(gt1, :zoom) == [iterate(gt1, i)[1].zoom for i in 0:size(gt1)-1]
        @test sprint(print, gt2[5].linestring) == sprint(print, gt2[3].point)
        @test sprint(print, gt2[9].linestring) == sprint(print, gt2[7].point)
        @test collect(findall(x->x=="missing", getproperty(gt2, i)) for i in [:id, :zoom, :location]) == [[6], [4, 8], [3, 7, 8]]
        @test iterate(gt, 5) === nothing
        @test iterate(gt1, 3) === nothing
        @test typeof([getindex(gt, i) for i in 1:size(gt)]) == typeof([iterate(gt, i)[1] for i in 0:size(gt)-1])
        @test typeof([getindex(gt1, i) for i in 1:size(gt1)]) == typeof([iterate(gt1, i)[1] for i in 0:size(gt1)-1])

        AG.resetreading!(layer)
        AG.resetreading!(layer1)

        @test AG.nextnamedtuple(layer) isa NamedTuple{(:geometry, :FID, :pointname),Tuple{ArchGDAL.IGeometry{AG.GDAL.wkbPoint},Float64,String}}
        @test AG.nextnamedtuple(layer1) isa NamedTuple{(:point, :linestring, :id, :zoom, :location),Tuple{ArchGDAL.IGeometry{AG.GDAL.wkbPoint},ArchGDAL.IGeometry{AG.GDAL.wkbLineString},String,String,String}}
        for i in (1,3,4)
            @test AG.schema_names(layer)[i] isa Base.Generator || AG.schema_names(layer)[i] isa ArchGDAL.IFeatureDefnView
            @test AG.schema_names(layer1)[i] isa Base.Generator || AG.schema_names(layer1)[i] isa ArchGDAL.IFeatureDefnView
        end
    end
end
