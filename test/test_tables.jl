using Test
import ArchGDAL;
const AG = ArchGDAL;
using Tables

@testset "test_tables.jl" begin

    @testset "Tables Support" begin
        dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
        dataset1 = AG.read(
            joinpath(@__DIR__, "data/multi_geom.csv"),
            options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"],
        )
        dataset2 = AG.read(
            joinpath(@__DIR__, "data/missing_testcase.csv"),
            options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"],
        )
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
                (String, String, String, AG.IGeometry, AG.IGeometry),
            )
            @test Tables.istable(AG.Table) == true
            @test Tables.rowaccess(AG.Table) == true
            @test Tables.rows(gt) isa AG.AbstractFeatureLayer
            @test Tables.rows(gt1) isa AG.AbstractFeatureLayer
            @test Tables.rows(gt2) isa AG.AbstractFeatureLayer

            features = collect(Tables.rows(gt1))
            @test length(features) == 2

            @test Tables.columnnames(features[1]) ==
                  (:id, :zoom, :location, :point, :linestring)
            @test Tables.getcolumn(features[2], -5) == nothing
            @test Tables.getcolumn(features[2], 0) == nothing
            @test Tables.getcolumn(features[1], 1) == "5.1"
            @test Tables.getcolumn(features[1], 2) == "1.0"
            @test Tables.getcolumn(features[1], 3) == "Mumbai"
            @test AG.toWKT(Tables.getcolumn(features[1], 4)) == "POINT (30 10)"
            @test AG.toWKT(Tables.getcolumn(features[1], 5)) ==
                  "LINESTRING (30 10,10 30,40 40)"
            @test Tables.getcolumn(features[1], :id) == "5.1"
            @test Tables.getcolumn(features[1], :zoom) == "1.0"
            @test Tables.getcolumn(features[1], :location) == "Mumbai"
            @test AG.toWKT(Tables.getcolumn(features[1], :point)) == "POINT (30 10)"
            @test AG.toWKT(Tables.getcolumn(features[1], :linestring)) ==
                  "LINESTRING (30 10,10 30,40 40)"
            @test isnothing(Tables.getcolumn(features[1], :fake))

            @test Tables.columnnames(features[2]) ==
                  (:id, :zoom, :location, :point, :linestring)
            @test Tables.getcolumn(features[2], -5) == nothing
            @test Tables.getcolumn(features[2], 0) == nothing
            @test Tables.getcolumn(features[2], 1) == "5.2"
            @test Tables.getcolumn(features[2], 2) == "2.0"
            @test Tables.getcolumn(features[2], 3) == "New Delhi"
            @test AG.toWKT(Tables.getcolumn(features[2], 4)) == "POINT (35 15)"
            @test AG.toWKT(Tables.getcolumn(features[2], 5)) ==
                  "LINESTRING (35 15,15 35,45 45)"
            @test Tables.getcolumn(features[2], :id) == "5.2"
            @test Tables.getcolumn(features[2], :zoom) == "2.0"
            @test Tables.getcolumn(features[2], :location) == "New Delhi"
            @test AG.toWKT(Tables.getcolumn(features[2], :point)) == "POINT (35 15)"
            @test AG.toWKT(Tables.getcolumn(features[2], :linestring)) ==
                  "LINESTRING (35 15,15 35,45 45)"
            @test isnothing(Tables.getcolumn(features[2], :fake))
        end

        @testset "Misc. methods" begin
            AG.resetreading!(layer)
            AG.resetreading!(layer1)

            schema_names = AG.schema_names(AG.layerdefn(layer))
            schema_names1 = AG.schema_names(AG.layerdefn(layer1))

            for i = 1:4
                @test schema_names[i] isa Base.Generator ||
                      schema_names[i] isa ArchGDAL.IFeatureDefnView
                @test schema_names1[i] isa Base.Generator ||
                      schema_names1[i] isa ArchGDAL.IFeatureDefnView
            end
        end
    end

end
