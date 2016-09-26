using FactCheck
import ArchGDAL; const AG = ArchGDAL

facts("Test methods for dataset") do
    AG.registerdrivers() do
        AG.read("data/utmsmall.tif") do dataset
            AG.createcopy(dataset, "tmp/utmcopy.tif","GTiff") do copydataset
                @fact AG.ngcp(copydataset) --> 0
                @fact AG.noverview(AG.getband(copydataset,1)) --> 0
                AG.buildoverviews!(copydataset, Cint[2,4,8])
                @fact AG.noverview(AG.getband(copydataset,1)) --> 3
                AG.copywholeraster(dataset, copydataset,
                                   progressfunc=GDAL.C.GDALTermProgress)
            end
            AG.copyfiles("GTiff", "tmp/utmcopy2.tif", "tmp/utmcopy.tif")
            AG.update("tmp/utmcopy2.tif") do copydataset
                AG.copywholeraster(dataset, copydataset, ["COMPRESS=LZW"])
            end
        end
    end
    rm("tmp/utmcopy.tif")
    rm("tmp/utmcopy2.tif")
end

# untested: AG.deletelayer!(copydataset, 0)