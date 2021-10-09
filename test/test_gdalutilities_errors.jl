import ArchGDAL, GDAL;
const AG = ArchGDAL
using Test

@testset "test_gdalutilities_errors.jl" begin
    AG.read("data/utmsmall.tif") do ds_small
        @testset "GDAL Error" begin
            # @test_throws GDAL.GDALError AG.gdalinfo(
            #     ds_small,
            #     ["-novalidoption"],
            # )
            @test begin 
                "GDAL.GDALError(GDAL.CE_Failure, 6, \"Unknown option name '-novalidoption'\")" == 
                    try
                        AG.gdalinfo(
                            ds_small,
                            ["-novalidoption"],
                        )
                    catch e
                        string(e)
                    end
            end
            # @test_throws GDAL.GDALError AG.unsafe_gdaltranslate(
            #     ds_small,
            #     ["-novalidoption"],
            # )
            # @test_throws GDAL.GDALError AG.unsafe_gdalbuildvrt(
            #     [ds_small],
            #     ["-novalidoption"],
            # )
            # @test_throws GDAL.GDALError AG.unsafe_gdaldem(
            #     ds_small,
            #     "hillshade",
            #     ["-novalidoption"],
            # )
            # @test_throws GDAL.GDALError AG.unsafe_gdalnearblack(
            #     ds_small,
            #     ["-novalidoption"],
            # )
            # @test_throws GDAL.GDALError AG.unsafe_gdalwarp(
            #     [ds_small],
            #     ["-novalidoption"],
            # )
        end
    end

    # @testset "Interactive data/utmsmall.tif" begin
    #     ds_small = AG.read("data/utmsmall.tif")
    #     @test_throws GDAL.GDALError AG.gdalinfo(ds_small, ["-novalidoption"])
    #     @test_throws GDAL.GDALError AG.unsafe_gdaltranslate(
    #         ds_small,
    #         ["-novalidoption"],
    #     )
    #     @test_throws GDAL.GDALError AG.unsafe_gdalbuildvrt(
    #         [ds_small],
    #         ["-novalidoption"],
    #     )
    #     @test_throws GDAL.GDALError AG.unsafe_gdaldem(
    #         ds_small,
    #         "hillshade",
    #         ["-novalidoption"],
    #     )
    #     @test_throws GDAL.GDALError AG.unsafe_gdalnearblack(
    #         ds_small,
    #         ["-novalidoption"],
    #     )
    #     @test_throws GDAL.GDALError AG.unsafe_gdalwarp(
    #         [ds_small],
    #         ["-novalidoption"],
    #     )
    # end
end
