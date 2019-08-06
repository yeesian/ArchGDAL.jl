using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Test methods for raster dataset" begin
    AG.read("data/utmsmall.tif") do dataset
        @testset "Method 1" begin
            AG.copy(dataset, filename = "/vsimem/utmcopy.tif") do copydataset
                @test AG.ngcp(copydataset) == 0
                @test AG.noverview(AG.getband(copydataset,1)) == 0
                AG.buildoverviews!(copydataset, Cint[2,4,8])
                @test AG.noverview(AG.getband(copydataset,1)) == 3
                AG.copywholeraster(dataset, copydataset,
                                   progressfunc=GDAL.C.GDALTermProgress)
            end
        end
        @testset "Method 2" begin
            copydataset = AG.copy(dataset, filename = "/vsimem/utmcopy.tif")
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

    dataset2 = AG.create(AG.getdriver("Memory"))
    @test AG.nlayer(dataset2) == 0
    layer2 = AG.copy(layer1, dataset = dataset2, name = "copy")
    @test AG.nlayer(dataset2) == 1
    @test AG.nfeature(layer2) == 4
    @test AG.getname(layer2) == "copy"

    layer3a = AG.getlayer(dataset2, "copy")
    @test AG.nlayer(dataset2) == 1
    @test AG.nfeature(layer3a) == 4
    @test AG.getname(layer3a) == "copy"
    
    layer3b = AG.copy(layer3a)
    @test AG.nlayer(dataset2) == 1 # layer3b is not associated with dataset2
    @test AG.getname(layer3b) == "copy(copy)"

    AG.copy(layer3b, dataset = dataset2)
    @test AG.nlayer(dataset2) == 2
    AG.deletelayer!(dataset2, 1)
    @test AG.nlayer(dataset2) == 1

    dataset4 = AG.create(tempname(), driver = AG.getdriver("KML"))
    @test AG.nlayer(dataset4) == 0
    layer4 = AG.createlayer(
        name = "layer4",
        dataset = dataset4,
        geom = GDAL.wkbLineString
    )
    @test AG.nlayer(dataset4) == 1

    AG.create(tempname(), driver = AG.getdriver("KML")) do dataset5
        @test AG.nlayer(dataset5) == 0
        layer4 = AG.createlayer(
            name = "layer5",
            dataset = dataset5,
            geom = GDAL.wkbLineString
        )
        @test AG.nlayer(dataset5) == 1
    end
    
    layer5 = AG.createlayer()
    @test AG.getname(layer5) == ""
    @test AG.nfeature(layer5) == 0
    @test AG.nfield(layer5) == 0
    @test AG.ngeom(layer5) == 1
end
