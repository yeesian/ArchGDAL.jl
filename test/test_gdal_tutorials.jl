using FactCheck
import ArchGDAL; const AG = ArchGDAL

AG.registerdrivers() do
    facts("Raster Tutorial") do
        AG.read("data/utmsmall.tif") do dataset
            driver = AG.getdriver("GTiff")
            @fact AG.shortname(driver) --> "GTiff"
            @fact AG.longname(driver) --> "GeoTIFF"
            @fact AG.width(dataset) --> 100
            @fact AG.height(dataset) --> 100
            @fact AG.nraster(dataset) --> 1

            nad27_prefix = "PROJCS[\"NAD27 / UTM zone 11N\",GEOGCS[\"NAD27\",DATUM[\"North_American_Datum_1927\","
            @fact startswith(AG.getproj(dataset), nad27_prefix) --> true
            @fact AG.getgeotransform(dataset) -->
                    roughly([440720.0,60.0,0.0,3.75132e6,0.0,-60.0])

            band = AG.getband(dataset, 1)
            @fact AG.getblocksize(band) --> roughly([100, 81])
            @fact AG.getdatatype(band) --> UInt8
            @fact AG.getname(AG.getcolorinterp(band)) --> "Gray"

            @fact AG.getminimum(band) --> roughly(0.0)
            @fact AG.getmaximum(band) --> roughly(255.0)

            @fact AG.noverview(band) --> 0

            # Reading Raster Data
            @fact AG.width(band) --> 100
            data = map(Float32, AG.read(dataset, 1))
            @fact data[:,1] --> roughly(Float32[107.0f0,123.0f0,132.0f0,115.0f0,
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
                    247.0f0,255.0f0,230.0f0,206.0f0,197.0f0])

            println(AG.metadatadomainlist(dataset))
            println(AG.metadata(dataset))
            for d in AG.metadatadomainlist(dataset)
                println("domain $d: $(AG.metadata(dataset, domain=d))")
            end
        end

        # Techniques for Creating Files
        #@test GDAL.getmetadataitem(driver, "DCAP_CREATE", "") == "YES"
        #@test GDAL.getmetadataitem(driver, "DCAP_CREATECOPY", "") == "YES"

        AG.read("data/utmsmall.tif") do ds_src
            AG.write(ds_src, "tmp/utmsmall.tif")
        end
        rm("tmp/utmsmall.tif")
    end

    facts("Vector Tutorial") do
        AG.read("data/point.geojson") do dataset
            @fact AG.nlayer(dataset) --> 1
            layer = AG.getlayer(dataset, 0)
            @fact AG.getname(layer) --> "OGRGeoJSON"
            layerbyname = AG.getlayer(dataset, "OGRGeoJSON")
            @fact layerbyname.ptr --> layer.ptr
            AG.resetreading!(layer)

            featuredefn = AG.getlayerdefn(layer)
            @fact AG.nfield(featuredefn) --> 2
            fielddefn = AG.getfielddefn(featuredefn, 0)
            @fact AG.gettype(fielddefn) --> AG.OFTReal
            fielddefn = AG.getfielddefn(featuredefn, 1)
            @fact AG.gettype(fielddefn) --> AG.OFTString

            AG.nextfeature(layer) do feature
                @fact AG.asdouble(feature, 0) --> roughly(2.0)
                @fact AG.asstring(feature, 1) --> "point-a"
            end
            AG.nextfeature(layer) do feature # second feature
                @fact AG.asdouble(feature, 0) --> roughly(3.0)
                @fact AG.asstring(feature, 1) --> "point-b"

                geometry = AG.getgeom(feature)
                @fact AG.getgeomname(geometry) --> "POINT"
                @fact AG.getgeomtype(geometry) --> AG.wkbPoint
                @fact AG.nfield(featuredefn) --> 2
                @fact AG.getx(geometry, 0) --> roughly(100.2785)
                @fact AG.gety(geometry, 0) --> roughly(0.0893)
                @fact AG.getpoint(geometry, 0) --> (100.2785,0.0893,0.0)
            end
        end

        pointshapefile = "tmp/point_out"
        AG.create("$pointshapefile.shp", "ESRI Shapefile") do dataset
            layer = AG.createlayer(dataset, "point_out", geom=AG.wkbPoint)
            AG.createfielddefn("Name", AG.OFTString) do fielddefn
                AG.setwidth!(fielddefn, 32)
                AG.createfield!(layer, fielddefn, true)
            end
            featuredefn = AG.getlayerdefn(layer)
            @fact AG.getname(featuredefn) --> "point_out"
            AG.createfeature(featuredefn) do feature
                AG.setfield!(feature, AG.getfieldindex(feature, "Name"), "myname")
                AG.setgeomdirectly!(feature, AG.unsafe_createpoint(100.123, 0.123))
            end
        end

        rm("$pointshapefile.dbf")
        rm("$pointshapefile.shp")
        rm("$pointshapefile.shx")
    end
end