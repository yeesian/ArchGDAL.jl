using Test
import ArchGDAL as AG

@testset "test_drivers.jl" begin
    @testset "Testing ConfigOptions" begin
        @test AG.getconfigoption("GDAL_CACHEMAX") == ""
        AG.setconfigoption("GDAL_CACHEMAX", "64")
        @test AG.getconfigoption("GDAL_CACHEMAX") == "64"
        AG.clearconfigoption("GDAL_CACHEMAX")
        @test AG.getconfigoption("GDAL_CACHEMAX", "128") == "128"

        @test AG.getthreadconfigoption("GDAL_CACHEMAX") == ""
        AG.setthreadconfigoption("GDAL_CACHEMAX", "32")
        @test AG.getthreadconfigoption("GDAL_CACHEMAX") == "32"
        AG.clearthreadconfigoption("GDAL_CACHEMAX")
        @test AG.getthreadconfigoption("GDAL_CACHEMAX", "128") == "128"

        @test AG.getconfigoption("GDAL_CACHEMAX") == ""
        @test AG.getconfigoption("CPL_LOG_ERRORS") == ""
        @test AG.getthreadconfigoption("GDAL_CACHEMAX") == ""
        @test AG.getthreadconfigoption("CPL_LOG_ERRORS") == ""

        AG.environment(
            globalconfig = [("GDAL_CACHEMAX", "64"), ("CPL_LOG_ERRORS", "ON")],
            threadconfig = [("GDAL_CACHEMAX", "32"), ("CPL_LOG_ERRORS", "OFF")],
        ) do
            # it seems that thread settings overwrites global settings?
            @test AG.getconfigoption("GDAL_CACHEMAX") == "32"
            @test AG.getconfigoption("CPL_LOG_ERRORS") == "OFF"
            @test AG.getthreadconfigoption("GDAL_CACHEMAX") == "32"
            @test AG.getthreadconfigoption("CPL_LOG_ERRORS") == "OFF"
        end

        AG.environment(
            globalconfig = [("GDAL_CACHEMAX", "64"), ("CPL_LOG_ERRORS", "ON")],
        ) do
            # everything normal here
            @test AG.getconfigoption("GDAL_CACHEMAX") == "64"
            @test AG.getconfigoption("CPL_LOG_ERRORS") == "ON"
            @test AG.getthreadconfigoption("GDAL_CACHEMAX") == ""
            @test AG.getthreadconfigoption("CPL_LOG_ERRORS") == ""
        end
    end

    @testset "Test Driver Capabilities" begin
        drivers = AG.listdrivers()
        @test drivers["GTiff"] == "GeoTIFF"
        @test length(AG.driveroptions("GTiff")) > 100
        @test sprint(print, AG.identifydriver("data/point.geojson")) ==
              "Driver: GeoJSON/GeoJSON"
        @test sprint(print, AG.identifydriver("data/utmsmall.tif")) ==
              "Driver: GTiff/GeoTIFF"

        driver = AG.getdriver("GPX")
        @test isnothing(AG.deregister(driver))
        @test isnothing(AG.register(driver))

        driver = AG.getdriver("GTiff")
        @test AG.validate(driver, ["COMPRESS=LZW", "INTERLEAVE=PIXEL"]) == true
        @test AG.validate(driver, ["COMPRESS=LZW"]) == true
        @test AG.validate(driver, ["INTERLEAVE=PIXEL"]) == true

        AG.read("data/point.geojson") do dataset
            @test AG.listcapability(dataset) == Dict(
                "CreateLayer" => false,
                "DeleteLayer" => false,
                "CreateGeomFieldAfterCreateLayer" => false,
                "CurveGeometries" => false,
                "Transactions" => false,
                "EmulatedTransactions" => false,
            )
            @test AG.listcapability(AG.getlayer(dataset, 0)) == Dict(
                "SequentialWrite" => false,
                "DeleteField" => false,
                "IgnoreFields" => false,
                "FastSpatialFilter" => false,
                "DeleteFeature" => false,
                "FastFeatureCount" => true,
                "StringsAsUTF8" => true,
                "CreateGeomField" => false,
                "ReorderFields" => false,
                "MeasuredGeometries" => false,
                "FastSetNextByIndex" => true,
                "CreateField" => false,
                "RandomWrite" => false,
                "RandomRead" => true,
                "CurveGeometries" => false,
                "FastGetExtent" => true,
                "Transactions" => false,
                "AlterFieldDefn" => false,
            )
        end
    end

    @testset "Test extensions list" begin
        exts = AG.extensions()
        @test exts[".tiff"] == "GTiff"
        @test exts[".tif"] == "GTiff"
        @test exts[".grb"] == "GRIB"
        @test exts[".geojson"] == "GeoJSON"
        @test exts[".json"] == "GeoJSON"
    end

    @testset "Test getting extensiondriver" begin
        @test AG.extensiondriver("filename.tif") == "GTiff"
        @test AG.extensiondriver(".tif") == "GTiff"
        @test AG.extensiondriver("filename.asc") == "AAIGrid"
        @test AG.extensiondriver(".asc") == "AAIGrid"
        @test_throws ArgumentError AG.extensiondriver(".not_an_extension")
    end
end
