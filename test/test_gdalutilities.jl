using ArchGDAL, GDAL; AG = ArchGDAL
using Test

AG.read("data/utmsmall.tif") do ds_small
    @testset "GDAL Error" begin
        @test_throws GDAL.GDALError AG.gdalinfo(ds_small, ["-novalidoption"])
        @test_throws GDAL.GDALError AG.unsafe_gdaltranslate(ds_small, ["-novalidoption"])
        @test_throws GDAL.GDALError AG.unsafe_gdalbuildvrt([ds_small], ["-novalidoption"])
        @test_throws GDAL.GDALError AG.unsafe_gdaldem(ds_small, "hillshade", ["-novalidoption"])
        @test_throws GDAL.GDALError AG.unsafe_gdalnearblack(ds_small, ["-novalidoption"])
        @test_throws GDAL.GDALError AG.unsafe_gdalwarp([ds_small], ["-novalidoption"])
    end

    @testset "GDAL Info" begin
        infostr = AG.gdalinfo(ds_small, ["-checksum"])
        @test occursin("Checksum=50054", infostr)
        info_default = AG.gdalinfo(ds_small)
        @test occursin("Driver: GTiff/GeoTIFF", info_default)
    end

    AG.gdaltranslate(ds_small, # resample to a 5×5 ascii grid
        ["-of","AAIGrid","-r","cubic","-tr","1200","1200"]
    ) do ds_tiny
        @testset "GDAL Translate" begin
            @test AG.read(ds_tiny, 1) == [128  171  127   93   83;
                                          126  164  148  114  101;
                                          161  175  177  164  140;
                                          185  206  205  172  128;
                                          193  205  209  181  122]
        end

        @testset "GDAL Build VRT" begin
            AG.gdalbuildvrt([ds_tiny]) do ds_vrt
                @test AG.read(ds_vrt, 1) == [128  171  127   93   83;
                                             126  164  148  114  101;
                                             161  175  177  164  140;
                                             185  206  205  172  128;
                                             193  205  209  181  122]
            end
        end

        @testset "GDAL DEM Processing" begin
            AG.gdaldem(ds_tiny, "hillshade", ["-of","AAIGrid"]) do ds_dempr
                @test AG.read(ds_dempr, 1) == [ 0    0    0    0  0;
                                                0  183  180  181  0;
                                                0  184  182  181  0;
                                                0  183  181  177  0;
                                                0    0    0    0  0]
            end
        end

        @testset "GDAL Near Black" begin
            AG.gdalnearblack(ds_tiny, ["-of","GTiff","-color","0"]) do ds_nearblack
                @test AG.read(ds_nearblack, 1) == [ 0  0    0  0  0;
                                                    0  0    0  0  0;
                                                    0  0  177  0  0;
                                                    0  0    0  0  0;
                                                    0  0    0  0  0]
            end
        end
    end

    # cannot reproject file on AppVeyor yet
    # GDALError (CE_Failure, code 4):
    #       Unable to open EPSG support file gcs.csv.  Try setting the
    #       GDAL_DATA environment variable to point to the directory
    #       containing EPSG csv files.
    # @testset "GDAL Warp" begin
    #     AG.gdalwarp([ds_small], ["-of","MEM","-t_srs","EPSG:4326"]) do ds_warped
    #         @test AG.width(ds_small) == 100
    #         @test AG.height(ds_small) == 100
    #         @test AG.width(ds_warped) == 109
    #         @test AG.height(ds_warped) == 91
    #     end
    # end
    @testset "GDAL Warp" begin
        AG.gdalwarp([ds_small], ["-of","MEM"]) do ds_warped
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
        AG.gdalgrid(ds_point, ["-of","MEM","-outsize","3",
            "10","-txe","100","100.3","-tye","0","0.1"]) do ds_grid
            @test AG.getgeotransform(ds_grid) ≈ [100.0,0.1,0.0,0.0,0.0,0.01]
        end
    end

    @testset "GDAL Rasterize" begin
        AG.gdalrasterize(ds_point, ["-of","MEM","-tr","0.05","0.05"]) do ds_rasterize
            @test AG.getgeotransform(ds_rasterize) ≈ [99.975,0.05,0.0,0.1143,0.0,-0.05]
        end
    end

    @testset "GDAL Vector Translate" begin
        AG.gdalvectortranslate([ds_point], ["-f","CSV","-lco",
            "GEOMETRY=AS_XY"], dest = "data/point.csv") do ds_csv
        end
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
