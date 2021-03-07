using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "metadataitem" begin
    driver = AG.getdriver("DERIVED")
    @test AG.metadataitem(driver, "DMD_EXTENSIONS") == ""
    driver = AG.getdriver("GTiff")
    @test AG.metadataitem(driver, "DMD_EXTENSIONS") == "tif tiff"
end
