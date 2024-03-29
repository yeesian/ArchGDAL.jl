using Test
import ArchGDAL as AG

@testset "test_gdal_tutorials.jl" begin
    @testset "Raster Tutorial" begin
        driver = AG.getdriver("GTiff")

        AG.read("data/utmsmall.tif") do dataset
            @test AG.shortname(driver) == "GTiff"
            @test AG.longname(driver) == "GeoTIFF"
            @test AG.width(dataset) == 100
            @test AG.height(dataset) == 100
            @test AG.nraster(dataset) == 1

            nad27_prefix = "PROJCS[\"NAD27 / UTM zone 11N\",GEOGCS[\"NAD27\",DATUM[\"North_American_Datum_1927\","
            @test startswith(AG.getproj(dataset), nad27_prefix) == true
            @test AG.getgeotransform(dataset) ≈
                  [440720.0, 60.0, 0.0, 3.75132e6, 0.0, -60.0]

            band = AG.getband(dataset, 1)
            @test AG.blocksize(band) ≈ [100, 81]
            @test AG.pixeltype(band) == UInt8
            @test AG.getname(AG.getcolorinterp(band)) == "Gray"

            @test AG.minimum(band) ≈ 0.0
            @test AG.maximum(band) ≈ 255.0

            @test AG.noverview(band) == 0

            # Reading Raster Data
            @test AG.width(band) == 100
            data = map(Float32, AG.read(dataset, 1))
            #! format: off
            @test data[:, 1] ≈ Float32[107.0f0, 123.0f0, 132.0f0, 115.0f0, 132.0f0, 132.0f0, 140.0f0, 132.0f0, 132.0f0, 132.0f0, 107.0f0, 132.0f0, 107.0f0, 132.0f0, 132.0f0, 107.0f0, 123.0f0, 115.0f0, 156.0f0, 148.0f0, 107.0f0, 132.0f0, 107.0f0, 115.0f0, 99.0f0, 123.0f0, 99.0f0, 74.0f0, 115.0f0, 82.0f0, 115.0f0, 115.0f0, 107.0f0, 123.0f0, 123.0f0, 99.0f0, 123.0f0, 123.0f0, 115.0f0, 115.0f0, 107.0f0, 90.0f0, 99.0f0, 107.0f0, 107.0f0, 99.0f0, 123.0f0, 107.0f0, 140.0f0, 123.0f0, 123.0f0, 115.0f0, 99.0f0, 132.0f0, 123.0f0, 115.0f0, 115.0f0, 123.0f0, 132.0f0, 115.0f0, 123.0f0, 132.0f0, 214.0f0, 156.0f0, 165.0f0, 148.0f0, 115.0f0, 148.0f0, 156.0f0, 148.0f0, 140.0f0, 165.0f0, 156.0f0, 197.0f0, 156.0f0, 197.0f0, 140.0f0, 173.0f0, 156.0f0, 165.0f0, 148.0f0, 156.0f0, 206.0f0, 214.0f0, 181.0f0, 206.0f0, 173.0f0, 222.0f0, 206.0f0, 255.0f0, 214.0f0, 173.0f0, 214.0f0, 255.0f0, 214.0f0, 247.0f0, 255.0f0, 230.0f0, 206.0f0, 197.0f0]
            #! format: on

            @test AG.metadatadomainlist(dataset) ==
                  ["IMAGE_STRUCTURE", "", "DERIVED_SUBDATASETS"]
            @test AG.metadata(dataset) == ["AREA_OR_POINT=Area"]
            @test AG.metadataitem(dataset, "AREA_OR_POINT") == "Area"
            @test AG.metadata(dataset, domain = "IMAGE_STRUCTURE") ==
                  ["INTERLEAVE=BAND"]
            @test AG.metadata(dataset, domain = "") == ["AREA_OR_POINT=Area"]
            @test AG.metadata(dataset, domain = "DERIVED_SUBDATASETS") == [
                "DERIVED_SUBDATASET_1_NAME=DERIVED_SUBDATASET:LOGAMPLITUDE:data/utmsmall.tif",
                "DERIVED_SUBDATASET_1_DESC=log10 of amplitude of input bands from data/utmsmall.tif",
            ]
        end

        # Get metadata from a RasterDataset
        AG.readraster("data/utmsmall.tif") do dataset
            # interestingly the list order below is different from the order above
            @test AG.metadatadomainlist(dataset) ==
                  ["IMAGE_STRUCTURE", "DERIVED_SUBDATASETS", ""]
            @test AG.metadata(dataset) == ["AREA_OR_POINT=Area"]
            @test AG.metadataitem(dataset, "AREA_OR_POINT") == "Area"
        end

        # Techniques for Creating Files
        @test AG.metadataitem(driver, "DCAP_CREATE", domain = "") == "YES"
        @test AG.metadataitem(driver, "DCAP_CREATECOPY", domain = "") == "YES"

        AG.read("data/utmsmall.tif") do ds_src
            AG.write(ds_src, "/vsimem/utmsmall.tif")
            AG.read("/vsimem/utmsmall.tif") do ds_copy
                @test AG.read(ds_src) == AG.read(ds_copy)
            end
        end
    end

    @testset "Vector Tutorial" begin
        AG.read("data/point.geojson") do dataset
            @test AG.nlayer(dataset) == 1
            layer = AG.getlayer(dataset, 0)
            @test (AG.getname(layer) in ["point", "OGRGeoJSON"]) == true
            layerbyname = AG.getlayer(dataset, "point")
            @test layerbyname.ptr == layer.ptr
            AG.resetreading!(layer)

            featuredefn = AG.layerdefn(layer)
            @test AG.nfield(featuredefn) == 2
            fielddefn = AG.getfielddefn(featuredefn, 0)
            @test AG.gettype(fielddefn) == AG.OFTReal
            fielddefn = AG.getfielddefn(featuredefn, 1)
            @test AG.gettype(fielddefn) == AG.OFTString

            AG.nextfeature(layer) do feature
                @test AG.asdouble(feature, 0) ≈ 2.0
                @test AG.asstring(feature, 1) == "point-a"
            end
            AG.nextfeature(layer) do feature # second feature
                @test AG.asdouble(feature, 0) ≈ 3.0
                @test AG.asstring(feature, 1) == "point-b"

                geometry = AG.getgeom(feature)
                @test AG.geomname(geometry) == "POINT"
                @test AG.getgeomtype(geometry) == AG.wkbPoint
                @test AG.nfield(featuredefn) == 2
                @test AG.getx(geometry, 0) ≈ 100.2785
                @test AG.gety(geometry, 0) ≈ 0.0893
                @test AG.getpoint(geometry, 0) == (100.2785, 0.0893, 0.0)
            end
        end

        AG.create(AG.getdriver("MEMORY")) do dataset
            layer = AG.createlayer(
                name = "point_out",
                dataset = dataset,
                geom = AG.wkbPoint,
            )
            AG.addfielddefn!(layer, "Name", AG.OFTString, nwidth = 32)
            featuredefn = AG.layerdefn(layer)
            @test AG.getname(featuredefn) == "point_out"
            @test AG.nfeature(layer) == 0
            AG.createfeature(layer) do feature
                AG.setfield!(
                    feature,
                    AG.findfieldindex(feature, "Name"),
                    "myname",
                )
                AG.setgeom!(feature, AG.createpoint(100.123, 0.123))
                return nothing
            end
            @test AG.nfeature(layer) == 1
        end
    end
end
