using FactCheck
import ArchGDAL; const AG = ArchGDAL

facts("Testing ConfigOptions") do
    @fact AG.getconfigoption("GDAL_CACHEMAX") --> ""
    AG.setconfigoption("GDAL_CACHEMAX", "64")
    @fact AG.getconfigoption("GDAL_CACHEMAX") --> "64"
    AG.clearconfigoption("GDAL_CACHEMAX")
    @fact AG.getconfigoption("GDAL_CACHEMAX", "128") --> "128"

    @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> ""
    AG.setthreadconfigoption("GDAL_CACHEMAX","32")
    @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> "32"
    AG.clearthreadconfigoption("GDAL_CACHEMAX")
    @fact AG.getthreadconfigoption("GDAL_CACHEMAX", "128") --> "128"

    @fact AG.getconfigoption("GDAL_CACHEMAX") --> ""
    @fact AG.getconfigoption("CPL_LOG_ERRORS") --> ""
    @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> ""
    @fact AG.getthreadconfigoption("CPL_LOG_ERRORS") --> ""

    AG.registerdrivers(globalconfig=[("GDAL_CACHEMAX","64"),
                                     ("CPL_LOG_ERRORS","ON")],
                       threadconfig=[("GDAL_CACHEMAX","32"),
                                     ("CPL_LOG_ERRORS","OFF")]) do
        # it seems that thread settings overwrites global settings?
        @fact AG.getconfigoption("GDAL_CACHEMAX") --> "32"
        @fact AG.getconfigoption("CPL_LOG_ERRORS") --> "OFF"
        @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> "32"
        @fact AG.getthreadconfigoption("CPL_LOG_ERRORS") --> "OFF"
    end

    AG.registerdrivers(globalconfig=[("GDAL_CACHEMAX","64"),
                                     ("CPL_LOG_ERRORS","ON")]) do
        # everything normal here
        @fact AG.getconfigoption("GDAL_CACHEMAX") --> "64"
        @fact AG.getconfigoption("CPL_LOG_ERRORS") --> "ON"
        @fact AG.getthreadconfigoption("GDAL_CACHEMAX") --> ""
        @fact AG.getthreadconfigoption("CPL_LOG_ERRORS") --> ""
    end
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
