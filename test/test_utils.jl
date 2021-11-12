using Test
import GDAL
import ArchGDAL;
const AG = ArchGDAL;

"Test both that an ErrorException is thrown and that the message is as expected"
eval_ogrerr(err, expected_message) = @test (@test_throws ErrorException AG.@ogrerr err "e:").value.msg == "e: ($expected_message)"

@testset "test_utils.jl" begin
    @testset "metadataitem" begin
        driver = AG.getdriver("DERIVED")
        @test AG.metadataitem(driver, "DMD_EXTENSIONS") == ""
        driver = AG.getdriver("GTiff")
        @test AG.metadataitem(driver, "DMD_EXTENSIONS") == "tif tiff"
    end

    @testset "OGR Errors" begin
        @test isnothing(AG.@ogrerr GDAL.OGRERR_NONE "not an error")
        eval_ogrerr(GDAL.OGRERR_NOT_ENOUGH_DATA, "Not enough data.")
        eval_ogrerr(GDAL.OGRERR_NOT_ENOUGH_MEMORY, "Not enough memory.")
        eval_ogrerr(GDAL.OGRERR_UNSUPPORTED_GEOMETRY_TYPE, "Unsupported geometry type.")
        eval_ogrerr(GDAL.OGRERR_UNSUPPORTED_OPERATION, "Unsupported operation.")
        eval_ogrerr(GDAL.OGRERR_CORRUPT_DATA, "Corrupt data.")
        eval_ogrerr(GDAL.OGRERR_FAILURE, "Failure.")
        eval_ogrerr(GDAL.OGRERR_UNSUPPORTED_SRS, "Unsupported spatial reference system.")
        eval_ogrerr(GDAL.OGRERR_INVALID_HANDLE, "Invalid handle.")
        eval_ogrerr(GDAL.OGRERR_NON_EXISTING_FEATURE, "Non-existing feature.")
        # OGRERR_NON_EXISTING_FEATURE is the highest error code currently in GDAL. If another one is
        # added this test will fail.
        eval_ogrerr(GDAL.OGRERR_NON_EXISTING_FEATURE + 1, "Unknown error.")
    end
end
