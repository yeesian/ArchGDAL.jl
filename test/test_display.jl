using Test
import ArchGDAL; const AG = ArchGDAL

function read(f, filename)
    AG.read(filename) do dataset
        f(dataset)
    end
end

@testset "Testing Displays for different objects" begin
    read("data/point.geojson") do dataset
        @test sprint(print, dataset) == """
        GDAL Dataset (Driver: GeoJSON/GeoJSON)
        File(s): 
          data/point.geojson

        Number of feature layers: 1
          Layer 0: point (wkbPoint)
        """
    end

    read("data/point.geojson") do dataset
        @test sprint(print, AG.getlayer(dataset, 0)) == """
        Layer: point
          Geometry 0 (): [wkbPoint], POINT (100 0), POINT (100.2785 0.0893), ...
             Field 0 (FID): [OFTReal], 2.0, 3.0, 0.0, 3.0
             Field 1 (pointname): [OFTString], point-a, point-b, a, b
        """
    end

    read("data/point.geojson") do dataset
        AG.getfeature(AG.getlayer(dataset, 0), 2) do feature
            @test sprint(print, feature) == """
            Feature
              (index 0) geom => POINT
              (index 0) FID => 0.0
              (index 1) pointname => a
            """
        end
    end;

    read("gdalworkshop/world.tif") do dataset
        @test sprint(print, dataset) == """
        GDAL Dataset (Driver: GTiff/GeoTIFF)
        File(s): 
          gdalworkshop/world.tif

        Dataset (width x height): 2048 x 1024 (pixels)
        Number of raster bands: 3
          [GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
          [GA_ReadOnly] Band 2 (Green): 2048 x 1024 (UInt8)
          [GA_ReadOnly] Band 3 (Blue): 2048 x 1024 (UInt8)
        """
    end

    read("gdalworkshop/world.tif") do dataset
        @test sprint(print, AG.getband(dataset, 1)) == """
        [GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
            blocksize: 256×256, nodata: -1.0e10, units: 1.0px + 0.0
            overviews: (0) 1024x512 (1) 512x256 (2) 256x128 
                       (3) 128x64 (4) 64x32 (5) 32x16 
                       (6) 16x8 """
    end
end
