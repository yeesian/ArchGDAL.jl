using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Test methods for raster dataset" begin
    AG.read("data/utmsmall.tif") do dataset
        AG.createcopy(dataset, filename = "/vsimem/utmcopy.tif") do copydataset
            @test AG.ngcp(copydataset) == 0
            @test AG.noverview(AG.getband(copydataset,1)) == 0
            AG.buildoverviews!(copydataset, Cint[2,4,8])
            @test AG.noverview(AG.getband(copydataset,1)) == 3
            AG.copywholeraster(dataset, copydataset,
                               progressfunc=GDAL.C.GDALTermProgress)
        end
        AG.copyfiles("GTiff", "/vsimem/utmcopy2.tif", "/vsimem/utmcopy.tif")
        AG.update("/vsimem/utmcopy2.tif") do copydataset
            @test AG.ngcp(copydataset) == 0
            @test AG.noverview(AG.getband(copydataset,1)) == 3
            AG.copywholeraster(dataset, copydataset, options = ["COMPRESS=LZW"])
        end
    end
end

@testset "Test methods for vector dataset" begin
    dataset1 = AG.read("data/point.geojson")
    @test AG.nlayer(dataset1) == 1
    layer1 = AG.getlayer(dataset1, 0)
    @test AG.nfeature(layer1) == 4
    
    dataset2 = AG.createcopy(dataset1)
    @test AG.nlayer(dataset2) == 1
    @test AG.nfeature(AG.getlayer(dataset2, 0)) == -1 # it is not populated

    dataset3 = AG.create(AG.getdriver("Memory"))
    @test AG.nlayer(dataset3) == 0
    
    AG.copylayer(dataset3, layer1, "copy")
    @test AG.nlayer(dataset3) == 1
    layer3a = AG.getlayer(dataset3, "copy")
    @test AG.nfeature(layer3a) == 4
    @test AG.getname(layer3a) == "copy"
    
    AG.copylayer(dataset3, layer3a, "copy2")
    @test AG.nlayer(dataset3) == 2
    @test AG.getname(AG.getlayer(dataset3, 1)) == "copy2"
    AG.deletelayer!(dataset3, 1)
    @test AG.nlayer(dataset3) == 1

    dataset4 = AG.create(tempname(), driver = AG.getdriver("KML"))
    @test AG.nlayer(dataset4) == 0
    layer4 = AG.createlayer(dataset4, "layer4", geom = GDAL.wkbLineString)
    @test AG.nlayer(dataset4) == 1
    
    AG.create(tempname(), driver = AG.getdriver(dataset4)) do dataset5
        @test AG.nlayer(dataset5) == 0
        AG.createlayer(dataset5, "layer5", geom = GDAL.wkbLineString)
        @test AG.nlayer(dataset5) == 1
    end
end
