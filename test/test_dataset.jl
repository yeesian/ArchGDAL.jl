using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Test methods for dataset" begin
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

# untested: AG.deletelayer!(copydataset, 0)
