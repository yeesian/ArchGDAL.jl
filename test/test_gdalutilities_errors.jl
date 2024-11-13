import GDAL
import ArchGDAL as AG
using Test

@testset "test_gdalutilities_errors.jl" begin
    @testset "GDAL Error" begin
        AG.read("data/utmsmall.tif") do ds_small
            @test_throws GDAL.GDALError AG.gdalinfo(
                ds_small,
                ["-novalidoption"],
            )
            @test_throws GDAL.GDALError AG.unsafe_gdaltranslate(
                ds_small,
                ["-novalidoption"],
            )
            @test_throws GDAL.GDALError AG.unsafe_gdalbuildvrt(
                [ds_small],
                ["-novalidoption"],
            )
            # This throws 
            # signal 6: Abort trap: 6
            # libc++abi: terminating due to uncaught exception of type std::invalid_argument
            # @test_throws GDAL.GDALError AG.unsafe_gdaldem(
            # ds_small,
            # "hillshade",
            # ["-novalidoption"],
            # )
            @test_throws GDAL.GDALError AG.unsafe_gdalnearblack(
                ds_small,
                ["-novalidoption"],
            )
            @test_throws GDAL.GDALError AG.unsafe_gdalwarp(
                [ds_small],
                ["-novalidoption"],
            )
        end
    end

    @testset "Interactive data/utmsmall.tif" begin
        ds_small = AG.read("data/utmsmall.tif")
        @test_throws GDAL.GDALError AG.gdalinfo(ds_small, ["-novalidoption"])
        @test_throws GDAL.GDALError AG.unsafe_gdaltranslate(
            ds_small,
            ["-novalidoption"],
        )
        @test_throws GDAL.GDALError AG.unsafe_gdalbuildvrt(
            [ds_small],
            ["-novalidoption"],
        )
        # This throws 
        # signal 6: Abort trap: 6
        # libc++abi: terminating due to uncaught exception of type std::invalid_argument
        # @test_throws GDAL.GDALError AG.unsafe_gdaldem(
        #     ds_small,
        #     "hillshade",
        #     ["-novalidoption"],
        # )
        @test_throws GDAL.GDALError AG.unsafe_gdalnearblack(
            ds_small,
            ["-novalidoption"],
        )
        @test_throws GDAL.GDALError AG.unsafe_gdalwarp(
            [ds_small],
            ["-novalidoption"],
        )
    end
end
