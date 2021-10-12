using Test
import ArchGDAL;
const AG = ArchGDAL;

@testset "test_utils.jl" begin
    @testset "metadataitem" begin
        driver = AG.getdriver("DERIVED")
        @test AG.metadataitem(driver, "DMD_EXTENSIONS") == ""
        driver = AG.getdriver("GTiff")
        @test AG.metadataitem(driver, "DMD_EXTENSIONS") == "tif tiff"
    end
    @testset "gdal error macros" begin
        @test_throws ErrorException AG.createlayer() do layer
            AG.addfeature(layer) do feature
                AG.setgeom!(feature, 1, AG.createpoint(1, 1))
            end
        end
    end
end
