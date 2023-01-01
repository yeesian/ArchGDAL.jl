import GDAL
import ArchGDAL as AG
using Test

@testset "test_gdalutilities.jl" begin
    AG.read("data/utmsmall.tif") do ds_small
        @testset "GDAL Info" begin
            infostr = AG.gdalinfo(ds_small, ["-checksum"])
            @test occursin("Checksum=50054", infostr)
            info_default = AG.gdalinfo(ds_small)
            @test occursin("Driver: GTiff/GeoTIFF", info_default)
        end

        AG.gdaltranslate(
            ds_small, # resample to a 5×5 ascii grid
            ["-of", "AAIGrid", "-r", "cubic", "-tr", "1200", "1200"],
        ) do ds_tiny
            @testset "GDAL Translate" begin
                @test AG.read(ds_tiny, 1) == [
                    128 171 127 93 83
                    126 164 148 114 101
                    161 175 177 164 140
                    185 206 205 172 128
                    193 205 209 181 122
                ]
            end

            @testset "GDAL Build VRT" begin
                AG.gdalbuildvrt([ds_tiny]) do ds_vrt
                    @test AG.read(ds_vrt, 1) == [
                        128 171 127 93 83
                        126 164 148 114 101
                        161 175 177 164 140
                        185 206 205 172 128
                        193 205 209 181 122
                    ]
                end
            end

            @testset "GDAL DEM Processing" begin
                AG.gdaldem(ds_tiny, "hillshade", ["-of", "AAIGrid"]) do ds_dempr
                    @test AG.read(ds_dempr, 1) == [
                        0 0 0 0 0
                        0 183 180 181 0
                        0 184 182 181 0
                        0 183 181 177 0
                        0 0 0 0 0
                    ]
                end
                AG.gdaldem(
                    ds_tiny,
                    "color-relief",
                    colorfile = "data/color_relief.txt",
                ) do ds_dempr
                    @test AG.read(ds_dempr, 1) == [
                        0x80 0x87 0x80 0x7b 0x7a
                        0x80 0x86 0x83 0x7e 0x7d
                        0x85 0x87 0x88 0x86 0x82
                        0x89 0x8c 0x8c 0x87 0x80
                        0x8a 0x8c 0x8c 0x88 0x80
                    ]
                end
            end

            @testset "GDAL Near Black" begin
                AG.gdalnearblack(
                    ds_tiny,
                    ["-of", "GTiff", "-color", "0"],
                ) do ds_nearblack
                    @test AG.read(ds_nearblack, 1) == UInt8[
                        0x80 0xab 0x7f 0x5d 0x53
                        0x7e 0xa4 0x94 0x72 0x65
                        0xa1 0xaf 0xb1 0xa4 0x8c
                        0xb9 0xce 0xcd 0xac 0x80
                        0xc1 0xcd 0xd1 0xb5 0x7a
                    ]
                end
            end
        end

        @testset "GDAL Warp" begin
            AG.gdalwarp(
                [ds_small],
                ["-of", "MEM", "-t_srs", "EPSG:4326"],
            ) do ds_warped
                @test AG.width(ds_small) == 100
                @test AG.height(ds_small) == 100
                @test AG.width(ds_warped) == 109
                @test AG.height(ds_warped) == 91
            end
        end
        @testset "GDAL Warp" begin
            AG.gdalwarp([ds_small], ["-of", "MEM"]) do ds_warped
                @test AG.width(ds_small) == 100
                @test AG.height(ds_small) == 100
                @test AG.shortname(AG.getdriver(ds_small)) == "GTiff"
                @test AG.width(ds_warped) == 100
                @test AG.height(ds_warped) == 100
                @test AG.shortname(AG.getdriver(ds_warped)) == "MEM"
            end
        end
    end

    AG.read("data/point.geojson") do ds_point
        @testset "GDAL Grid" begin
            AG.gdalgrid(
                ds_point,
                [
                    "-of",
                    "MEM",
                    "-outsize",
                    "3",
                    "10",
                    "-txe",
                    "100",
                    "100.3",
                    "-tye",
                    "0",
                    "0.1",
                ],
            ) do ds_grid
                @test AG.getgeotransform(ds_grid) ≈
                      [100.0, 0.1, 0.0, 0.1, 0.0, -0.01]
            end
        end

        @testset "GDAL Rasterize" begin
            AG.gdalrasterize(
                ds_point,
                ["-of", "MEM", "-tr", "0.05", "0.05"],
            ) do ds_rasterize
                @test AG.getgeotransform(ds_rasterize) ≈
                      [99.975, 0.05, 0.0, 0.1143, 0.0, -0.05]
            end
        end

        @testset "GDAL Vector Translate" begin
            AG.destroy(
                AG.unsafe_gdalvectortranslate(
                    [ds_point],
                    ["-f", "CSV", "-lco", "GEOMETRY=AS_XY"],
                    dest = "data/point.csv",
                ),
            )
            @test replace(read("data/point.csv", String), "\r" => "") == """
            X,Y,FID,pointname
            100,0,2,point-a
            100.2785,0.0893,3,point-b
            100,0,0,a
            100.2785,0.0893,3,b
            """
            rm("data/point.csv")
        end
    end
end

@testset "Interactive data/utmsmall.tif" begin
    ds_small = AG.read("data/utmsmall.tif")
    @testset "GDAL Info" begin
        infostr = AG.gdalinfo(ds_small, ["-checksum"])
        @test occursin("Checksum=50054", infostr)
        info_default = AG.gdalinfo(ds_small)
        @test occursin("Driver: GTiff/GeoTIFF", info_default)
    end

    ds_tiny = AG.unsafe_gdaltranslate(
        ds_small, # resample to a 5×5 ascii grid
        ["-of", "AAIGrid", "-r", "cubic", "-tr", "1200", "1200"],
    )
    @test typeof(ds_tiny) == AG.Dataset
    @testset "GDAL Translate" begin
        @test AG.read(ds_tiny, 1) == [
            128 171 127 93 83
            126 164 148 114 101
            161 175 177 164 140
            185 206 205 172 128
            193 205 209 181 122
        ]
    end

    @testset "GDAL Build VRT" begin
        ds_vrt = AG.unsafe_gdalbuildvrt([ds_tiny])
        @test AG.read(ds_vrt, 1) == [
            128 171 127 93 83
            126 164 148 114 101
            161 175 177 164 140
            185 206 205 172 128
            193 205 209 181 122
        ]
    end

    @testset "GDAL DEM Processing" begin
        ds_dempr = AG.unsafe_gdaldem(ds_tiny, "hillshade", ["-of", "AAIGrid"])
        @test AG.read(ds_dempr, 1) == [
            0 0 0 0 0
            0 183 180 181 0
            0 184 182 181 0
            0 183 181 177 0
            0 0 0 0 0
        ]
    end

    @testset "GDAL Near Black" begin
        ds_nearblack =
            AG.unsafe_gdalnearblack(ds_tiny, ["-of", "GTiff", "-color", "0"])
        @test AG.read(ds_nearblack, 1) == UInt8[
            0x80 0xab 0x7f 0x5d 0x53
            0x7e 0xa4 0x94 0x72 0x65
            0xa1 0xaf 0xb1 0xa4 0x8c
            0xb9 0xce 0xcd 0xac 0x80
            0xc1 0xcd 0xd1 0xb5 0x7a
        ]
    end

    @testset "GDAL Warp" begin
        AG.gdalwarp(
            [ds_small],
            ["-of", "MEM", "-t_srs", "EPSG:4326"],
        ) do ds_warped
            @test AG.width(ds_small) == 100
            @test AG.height(ds_small) == 100
            @test AG.width(ds_warped) == 109
            @test AG.height(ds_warped) == 91
        end
    end

    @testset "GDAL Warp #2" begin
        ds_warped = AG.unsafe_gdalwarp([ds_small], ["-of", "MEM"])
        @test AG.width(ds_small) == 100
        @test AG.height(ds_small) == 100
        @test AG.shortname(AG.getdriver(ds_small)) == "GTiff"
        @test AG.width(ds_warped) == 100
        @test AG.height(ds_warped) == 100
        @test AG.shortname(AG.getdriver(ds_warped)) == "MEM"
    end
end
