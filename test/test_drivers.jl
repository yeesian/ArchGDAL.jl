using FactCheck
import ArchGDAL; const AG = ArchGDAL

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

# Untested
# destroy(drv::Driver) = GDAL.destroydriver(drv)
# register(drv::Driver) = GDAL.registerdriver(drv)
# deregister(drv::Driver) = GDAL.deregisterdriver(drv)