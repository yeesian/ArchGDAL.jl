using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Raster Tutorial" begin
    AG.read("data/utmsmall.tif") do dataset
        driver = AG.getdriver("GTiff")
        @test AG.shortname(driver) == "GTiff"
        @test AG.longname(driver) == "GeoTIFF"
        @test AG.width(dataset) == 100
        @test AG.height(dataset) == 100
        @test AG.nraster(dataset) == 1

        nad27_prefix = "PROJCS[\"NAD27 / UTM zone 11N\",GEOGCS[\"NAD27\",DATUM[\"North_American_Datum_1927\","
        @test startswith(AG.getproj(dataset), nad27_prefix) == true
        @test AG.getgeotransform(dataset) ≈
                [440720.0,60.0,0.0,3.75132e6,0.0,-60.0]

        band = AG.getband(dataset, 1)
        @test AG.getblocksize(band) ≈ [100, 81]
        @test AG.getdatatype(band) == UInt8
        @test AG.getname(AG.getcolorinterp(band)) == "Gray"

        @test AG.getminimum(band) ≈ 0.0
        @test AG.getmaximum(band) ≈ 255.0

        @test AG.noverview(band) == 0

        # Reading Raster Data
        @test AG.width(band) == 100
        data = map(Float32, AG.read(dataset, 1))
        @test data[:,1] ≈ Float32[107.0f0,123.0f0,132.0f0,115.0f0,
                132.0f0,132.0f0,140.0f0,132.0f0,132.0f0,132.0f0,107.0f0,
                132.0f0,107.0f0,132.0f0,132.0f0,107.0f0,123.0f0,115.0f0,
                156.0f0,148.0f0,107.0f0,132.0f0,107.0f0,115.0f0,99.0f0,
                123.0f0,99.0f0,74.0f0,115.0f0,82.0f0,115.0f0,115.0f0,
                107.0f0,123.0f0,123.0f0,99.0f0,123.0f0,123.0f0,115.0f0,
                115.0f0,107.0f0,90.0f0,99.0f0,107.0f0,107.0f0,99.0f0,
                123.0f0,107.0f0,140.0f0,123.0f0,123.0f0,115.0f0,99.0f0,
                132.0f0,123.0f0,115.0f0,115.0f0,123.0f0,132.0f0,115.0f0,
                123.0f0,132.0f0,214.0f0,156.0f0,165.0f0,148.0f0,115.0f0,
                148.0f0,156.0f0,148.0f0,140.0f0,165.0f0,156.0f0,197.0f0,
                156.0f0,197.0f0,140.0f0,173.0f0,156.0f0,165.0f0,148.0f0,
                156.0f0,206.0f0,214.0f0,181.0f0,206.0f0,173.0f0,222.0f0,
                206.0f0,255.0f0,214.0f0,173.0f0,214.0f0,255.0f0,214.0f0,
                247.0f0,255.0f0,230.0f0,206.0f0,197.0f0]

        @test AG.metadatadomainlist(dataset) == ["IMAGE_STRUCTURE", "", "DERIVED_SUBDATASETS"]
        @test AG.metadata(dataset) == ["AREA_OR_POINT=Area"]
        @test AG.metadata(dataset, domain = "IMAGE_STRUCTURE") == ["INTERLEAVE=BAND"]
        @test AG.metadata(dataset, domain = "") == ["AREA_OR_POINT=Area"]
        @test AG.metadata(dataset, domain = "DERIVED_SUBDATASETS") == [
            "DERIVED_SUBDATASET_1_NAME=DERIVED_SUBDATASET:LOGAMPLITUDE:data/utmsmall.tif",
            "DERIVED_SUBDATASET_1_DESC=log10 of amplitude of input bands from data/utmsmall.tif"
        ]
    end

    # Techniques for Creating Files
    #@test GDAL.getmetadataitem(driver, "DCAP_CREATE", "") == "YES"
    #@test GDAL.getmetadataitem(driver, "DCAP_CREATECOPY", "") == "YES"

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
        # layerbyname = AG.getlayer(dataset, "point")
        # @test layerbyname.ptr == layer.ptr
        AG.resetreading!(layer)

        featuredefn = AG.getlayerdefn(layer)
        @test AG.nfield(featuredefn) == 2
        fielddefn = AG.getfielddefn(featuredefn, 0)
        @test AG.gettype(fielddefn) == GDAL.OFTReal
        fielddefn = AG.getfielddefn(featuredefn, 1)
        @test AG.gettype(fielddefn) == GDAL.OFTString

        AG.nextfeature(layer) do feature
            @test AG.asdouble(feature, 0) ≈ 2.0
            @test AG.asstring(feature, 1) == "point-a"
        end
        AG.nextfeature(layer) do feature # second feature
            @test AG.asdouble(feature, 0) ≈ 3.0
            @test AG.asstring(feature, 1) == "point-b"

            geometry = AG.getgeom(feature)
            @test AG.getgeomname(geometry) == "POINT"
            @test AG.getgeomtype(geometry) == GDAL.wkbPoint
            @test AG.nfield(featuredefn) == 2
            @test AG.getx(geometry, 0) ≈ 100.2785
            @test AG.gety(geometry, 0) ≈ 0.0893
            @test AG.getpoint(geometry, 0) == (100.2785,0.0893,0.0)
        end
    end

    @testset "Approach 1" begin
        AG.create(AG.getdriver("MEMORY")) do dataset
            layer = AG.createlayer(dataset, "point_out", geom=GDAL.wkbPoint)
            AG.createfielddefn("Name", GDAL.OFTString) do fielddefn
                AG.setwidth!(fielddefn, 32)
                AG.write!(layer, fielddefn, true)
            end
            featuredefn = AG.getlayerdefn(layer)
            @test AG.getname(featuredefn) == "point_out"
            @test AG.nfeature(layer) == 0
            AG.createfeature(featuredefn) do feature
                AG.setfield!(feature, AG.getfieldindex(feature, "Name"), "myname")
                AG.setgeom!(feature, AG.createpoint(100.123, 0.123))
                AG.write!(layer, feature)
            end
            @test AG.nfeature(layer) == 1
        end
    end

    @testset "Approach 2" begin
        AG.create(AG.getdriver("MEMORY")) do dataset
            layer = AG.createlayer(dataset, "point_out", geom=GDAL.wkbPoint)
            AG.createfielddefn("Name", GDAL.OFTString) do fielddefn
                AG.setwidth!(fielddefn, 32)
                AG.write!(layer, fielddefn, true)
            end
            featuredefn = AG.getlayerdefn(layer)
            @test AG.getname(featuredefn) == "point_out"
            @test AG.nfeature(layer) == 0
            AG.createfeature(layer) do feature
                AG.setfield!(feature, AG.getfieldindex(feature, "Name"), "myname")
                AG.setgeom!(feature, AG.createpoint(100.123, 0.123))
            end
            @test AG.nfeature(layer) == 1
        end
    end
end
