using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Testing ConfigOptions" begin
    @test AG.getconfigoption("GDAL_CACHEMAX") == ""
    AG.setconfigoption("GDAL_CACHEMAX", "64")
    @test AG.getconfigoption("GDAL_CACHEMAX") == "64"
    AG.clearconfigoption("GDAL_CACHEMAX")
    @test AG.getconfigoption("GDAL_CACHEMAX", "128") == "128"

    @test AG.getthreadconfigoption("GDAL_CACHEMAX") == ""
    AG.setthreadconfigoption("GDAL_CACHEMAX","32")
    @test AG.getthreadconfigoption("GDAL_CACHEMAX") == "32"
    AG.clearthreadconfigoption("GDAL_CACHEMAX")
    @test AG.getthreadconfigoption("GDAL_CACHEMAX", "128") == "128"

    @test AG.getconfigoption("GDAL_CACHEMAX") == ""
    @test AG.getconfigoption("CPL_LOG_ERRORS") == ""
    @test AG.getthreadconfigoption("GDAL_CACHEMAX") == ""
    @test AG.getthreadconfigoption("CPL_LOG_ERRORS") == ""

    AG.registerdrivers(globalconfig=[("GDAL_CACHEMAX","64"),
                                     ("CPL_LOG_ERRORS","ON")],
                       threadconfig=[("GDAL_CACHEMAX","32"),
                                     ("CPL_LOG_ERRORS","OFF")]) do
        # it seems that thread settings overwrites global settings?
        @test AG.getconfigoption("GDAL_CACHEMAX") == "32"
        @test AG.getconfigoption("CPL_LOG_ERRORS") == "OFF"
        @test AG.getthreadconfigoption("GDAL_CACHEMAX") == "32"
        @test AG.getthreadconfigoption("CPL_LOG_ERRORS") == "OFF"
    end

    AG.registerdrivers(globalconfig=[("GDAL_CACHEMAX","64"),
                                     ("CPL_LOG_ERRORS","ON")]) do
        # everything normal here
        @test AG.getconfigoption("GDAL_CACHEMAX") == "64"
        @test AG.getconfigoption("CPL_LOG_ERRORS") == "ON"
        @test AG.getthreadconfigoption("GDAL_CACHEMAX") == ""
        @test AG.getthreadconfigoption("CPL_LOG_ERRORS") == ""
    end
end

@testset "Test Driver Capabilities" begin
AG.registerdrivers() do
    drivers = AG.listdrivers()
    println(drivers)
    println(AG.driveroptions("GTiff"))
    println(AG.identifydriver("data/point.geojson"))
    println(AG.identifydriver("data/utmsmall.tif"))
    println(AG.identifydriver("data/A.tif"))
    for options in Vector{String}[["COMPRESS=LZW","INTERLEAVE=PIXEL"],
                                       ["COMPRESS=LZW"],["INTERLEAVE=PIXEL"]]
        println("isvalid: $(AG.validate(AG.getdriver("GTiff"), options)) for $options")
    end
    AG.read("data/point.geojson") do dataset
        @test AG.listcapability(dataset) == Dict(
            "CreateLayer"=>false,
            "DeleteLayer"=>false,
            "CreateGeomFieldAfterCreateLayer"=>false,
            "CurveGeometries"=>false,
            "Transactions"=>false,
            "EmulatedTransactions"=>false
        )
        @test AG.listcapability(AG.getlayer(dataset,0)) == Dict(
            "SequentialWrite"=>false,    "DeleteField"=>false,
            "IgnoreFields"=>false,       "FastSpatialFilter"=>false,
            "DeleteFeature"=>false,      "FastFeatureCount"=>true,
            "StringsAsUTF8"=>true,       "CreateGeomField"=>false,
            "ReorderFields"=>false,      "MeasuredGeometries"=>true,
            "FastSetNextByIndex"=>true, "CreateField"=>false,
            "RandomWrite"=>false,        "RandomRead"=>true,
            "CurveGeometries"=>false,    "FastGetExtent"=>false,
            "Transactions"=>false,       "AlterFieldDefn"=>false
        )
    end
end
end
