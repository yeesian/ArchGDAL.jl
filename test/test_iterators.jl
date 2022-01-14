using Test
import ArchGDAL as AG

@testset "test_iterators.jl" begin
    @testset "Iterator interface Window Iterator" begin
        ds = AG.readraster("ospy/data4/aster.img")
        band = AG.getband(ds, 1)
        window = AG.windows(band)
        @test Base.IteratorSize(window) == Base.HasShape{2}()
        @test Base.IteratorEltype(window) == Base.HasEltype()
        @test eltype(window) == Tuple{UnitRange{Int},UnitRange{Int}}
        @test size(window) == (79, 89)
        @test length(window) == 7031
    end

    @testset "Iterator interface AbstractFeatureLayer Iterator" begin
        ds = AG.read(
            joinpath(@__DIR__, "data/multi_geom.csv"),
            options = [
                "GEOM_POSSIBLE_NAMES=point,linestring",
                "KEEP_GEOM_COLUMNS=NO",
            ],
        )
        layer = AG.getlayer(ds, 0)
        @test length(layer) == 2
    end
end
