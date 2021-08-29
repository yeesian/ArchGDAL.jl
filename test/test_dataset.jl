using Test
import ArchGDAL;
const AG = ArchGDAL;

@testset "test_dataset.jl" begin
    @testset "Test methods for raster dataset" begin
        AG.read("data/utmsmall.tif") do dataset
            @testset "Method 1" begin
                AG.copy(
                    dataset,
                    filename = "/vsimem/utmcopy.tif",
                ) do copydataset
                    @test AG.ngcp(copydataset) == 0
                    AG.getband(copydataset, 1) do band
                        @test AG.noverview(band) == 0
                        AG.buildoverviews!(copydataset, Cint[2, 4, 8])
                        @test AG.noverview(band) == 3
                        AG.copywholeraster!(dataset, copydataset)
                        return nothing
                    end
                end
            end
            @testset "Method 2" begin
                copydataset = AG.copy(dataset, filename = "/vsimem/utmcopy.tif")
                @test AG.ngcp(copydataset) == 0
                @test AG.noverview(AG.getband(copydataset, 1)) == 0
                AG.buildoverviews!(copydataset, Cint[2, 4, 8])
                @test AG.noverview(AG.getband(copydataset, 1)) == 3
                AG.copywholeraster!(dataset, copydataset)
            end
            AG.copyfiles("GTiff", "/vsimem/utmcopy2.tif", "/vsimem/utmcopy.tif")
            AG.update("/vsimem/utmcopy2.tif") do copydataset
                @test AG.ngcp(copydataset) == 0
                @test AG.noverview(AG.getband(copydataset, 1)) == 3
                AG.copywholeraster!(
                    dataset,
                    copydataset,
                    options = ["COMPRESS=LZW"],
                )
                return nothing
            end
        end
    end

    @testset "Test methods for vector dataset" begin
        dataset1 = AG.read("data/point.geojson")
        @test AG.nlayer(dataset1) == 1
        layer1 = AG.getlayer(dataset1, 0)
        @test AG.nfeature(layer1) == 4
        AG.getlayer(dataset1, 0) do layer1
            @test AG.nfeature(layer1) == 4
        end
        @test AG.getgeotransform(dataset1) ≈ [0,1,0,0,0,1]

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
        AG.getlayer(dataset2, "copy") do layer3a
            @test AG.nfeature(layer3a) == 4
            @test AG.getname(layer3a) == "copy"
        end

        layer3b = AG.copy(layer3a)
        @test AG.nlayer(dataset2) == 1 # layer3b is not associated with dataset2
        @test AG.getname(layer3b) == "copy(copy)"

        AG.copy(layer3b, dataset = dataset2)
        @test AG.nlayer(dataset2) == 2
        AG.deletelayer!(dataset2, 1)
        @test AG.nlayer(dataset2) == 1

        # the following test is to cover an example of `macro ogrerr(code, message)`
        @test_throws ErrorException AG.deletelayer!(dataset2, -1)

        dataset4 = AG.create(tempname(), driver = AG.getdriver("KML"))
        @test AG.nlayer(dataset4) == 0
        layer4 = AG.createlayer(
            name = "layer4",
            dataset = dataset4,
            geom = AG.wkbLineString,
        )
        @test AG.nlayer(dataset4) == 1

        AG.create(tempname(), driver = AG.getdriver("KML")) do dataset5
            @test AG.nlayer(dataset5) == 0
            AG.createlayer(
                name = "layer5",
                dataset = dataset5,
                geom = AG.wkbLineString,
            ) do layer5
                @test AG.nfeature(layer5) == 0
            end
            @test AG.nlayer(dataset5) == 1
        end

        layer5 = AG.createlayer()
        @test AG.getname(layer5) == ""
        @test AG.nfeature(layer5) == 0
        @test AG.nfield(layer5) == 0
        @test AG.ngeom(layer5) == 1

        AG.create(AG.getdriver("Memory")) do dataset6
            for i in 1:20
                AG.createlayer(name = "layer$(i - 1)", dataset = dataset6)
            end
            @test AG.nlayer(dataset6) == 20
            @test sprint(print, dataset6) == """
            GDAL Dataset (Driver: Memory/Memory)
            File(s): 

            Number of feature layers: 20
              Layer 0: layer0 (wkbUnknown)
              Layer 1: layer1 (wkbUnknown)
              Layer 2: layer2 (wkbUnknown)
              Layer 3: layer3 (wkbUnknown)
              Layer 4: layer4 (wkbUnknown)
              Remaining layers:
                layer5, layer6, layer7, layer8, layer9, 
                layer10, layer11, layer12, layer13, layer14, 
                layer15, layer16, layer17, layer18, layer19, """
        end
    end
end
