using FactCheck
import ArchGDAL; const AG = ArchGDAL

facts("Testing ConfigOptions") do
    @fact AG.getconfigoption("GDAL_CACHEMAX") --> ""
    AG.setconfigoption("GDAL_CACHEMAX","64")
    @fact AG.getconfigoption("GDAL_CACHEMAX") --> "64"
    AG.clearconfigoption("GDAL_CACHEMAX")
    @fact AG.getconfigoption("GDAL_CACHEMAX", "32") --> "32"
    @fact AG.getconfigoption("GDAL_CACHEMAX") --> ""

    @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> ""
    AG.setthreadconfigoption("GDAL_CACHEMAX","64")
    @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> "64"
    AG.clearthreadconfigoption("GDAL_CACHEMAX")
    @fact AG.getthreadconfigoption("GDAL_CACHEMAX", "32") --> "32"
    @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> ""
end

AG.registerdrivers() do
    drivers = AG.drivers()
    println(drivers)
    AG.options(AG.shortname(AG.getdriver("GTiff")))
    println(AG.identifydriver("data/point.geojson"))
    println(AG.identifydriver("data/utmsmall.tif"))
    println(AG.identifydriver("data/A.tif"))
    for options in Vector{ASCIIString}[["COMPRESS=LZW","INTERLEAVE=PIXEL"],
                                       ["COMPRESS=LZW"],["INTERLEAVE=PIXEL"]]
        println("isvalid: $(AG.validate(AG.getdriver("GTiff"), options)) for $options")
    end
end
