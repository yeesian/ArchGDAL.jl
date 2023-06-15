using Test
import ArchGDAL as AG

const supported_vector_drivers = [
    "FlatGeobuf",
    "GeoJSON",
    "GeoJSONSeq",
    "GML",
    "GPKG",
    "JML",
    "KML",
    "MapML",
    "ESRI Shapefile",
    "SQLite",
]

function assertsimilar(ds1, ds2)
    AG.nlayer(ds1) == AG.nlayer(ds2) || error("unequal layer count")
    for i in 0:AG.nlayer(ds1)-1
        AG.ngeom(AG.getlayer(ds1, i)) == AG.ngeom(AG.getlayer(ds2, i)) ||
            error("unequal number of geometries in layer $i")
    end
    AG.nraster(ds1) == AG.nraster(ds2) || error("unequal raster count")
    AG.height(ds1) == AG.height(ds2) || error("unequal height")
    return AG.width(ds1) == AG.width(ds2) || error("unequal width")
end

@testset "test_dataset.jl" begin
    @testset "Test methods for raster dataset" begin
        AG.read("data/utmsmall.tif") do dataset
            @testset "Method 1" begin
                io = IOBuffer()
                function showprogress(progress, message = "")
                    print(io, round(Int, progress * 100))
                    return true
                end

                AG.copy(
                    dataset,
                    filename = "/vsimem/utmcopy.tif",
                ) do copydataset
                    @test AG.ngcp(copydataset) == 0
                    AG.getband(copydataset, 1) do band
                        @test AG.noverview(band) == 0
                        AG.buildoverviews!(copydataset, Cint[2, 4, 8])
                        @test AG.noverview(band) == 3
                        AG.copywholeraster!(
                            dataset,
                            copydataset,
                            progressfunc = showprogress,
                        )
                        seek(io, 0)
                        @test occursin("100", String(readavailable(io)))
                        return nothing
                    end
                end
            end
            @testset "Method 2" begin
                copydataset = AG.copy(dataset, filename = "/vsimem/utmcopy.tif")
                @test AG.ngcp(copydataset) == 0
                @test AG.noverview(AG.getband(copydataset, 1)) == 0
                AG.buildoverviews!(copydataset, Cint[2, 4, 8])
                @test AG.noverview(AG.getband(copydataset, 1)) == 3
                AG.copywholeraster!(dataset, copydataset)
            end
            AG.copyfiles("GTiff", "/vsimem/utmcopy2.tif", "/vsimem/utmcopy.tif")
            AG.update("/vsimem/utmcopy2.tif") do copydataset
                @test AG.ngcp(copydataset) == 0
                @test AG.noverview(AG.getband(copydataset, 1)) == 3
                AG.copywholeraster!(
                    dataset,
                    copydataset,
                    options = ["COMPRESS=LZW"],
                )
                return nothing
            end
        end
    end

    @testset "Test methods for vector dataset" begin
        AG.read("data/point.geojson") do ds
            layer = AG.getlayer(ds)
            new_ds = AG.copy(layer; name = "duplicated layer 1").ownedby
            AG.copy(layer; dataset = new_ds, name = "duplicated layer 2")
            @test_throws ErrorException(
                "Dataset has multiple layers. Specify the layer number or name",
            ) AG.getlayer(new_ds)
        end

        AG.read("data/point.geojson") do ds
            AG.getlayer(ds) do layer
                new_ds = AG.copy(layer; name = "duplicated layer 1").ownedby
                AG.copy(layer; dataset = new_ds, name = "duplicated layer 2")
                @test_throws ErrorException(
                    "Dataset has multiple layers. Specify the layer number or name",
                ) AG.getlayer(new_ds) do layer
                    return nothing
                end
            end
        end

        @testset "write functionality" begin
            @testset "$driver" for driver in supported_vector_drivers
                # for driver in supported_vector_drivers
                fname = "test." * lowercase(join(split(driver)))
                # test point and multipolygon dataset
                for dsname in ("point", "metropole")
                    AG.read("data/$dsname.geojson") do input_ds
                        try
                            # the GPKG driver can handle field ids of type real, which is the case for point.geojson
                            if driver == "GPKG" && dsname == "point"
                                @test_throws GDAL.GDALError AG.write(
                                    input_ds,
                                    fname;
                                    driver = AG.getdriver(driver),
                                    use_gdal_copy = false,
                                )
                            else
                                AG.write(
                                    input_ds,
                                    fname;
                                    driver = AG.getdriver(driver),
                                    use_gdal_copy = true,
                                )
                                @test assertsimilar(input_ds, AG.read(fname))
                                # sleep and GC are for windows: let the gc run to close the file, otherwise it can't be deleted
                                sleep(0.05)
                                GC.gc()
                                rm(fname, force = true, recursive = true)

                                AG.write(
                                    input_ds,
                                    fname;
                                    driver = AG.getdriver(driver),
                                    use_gdal_copy = false,
                                )
                                @test assertsimilar(input_ds, AG.read(fname))
                                sleep(0.05)
                                GC.gc()
                                rm(fname, force = true, recursive = true)
                            end
                        finally
                            sleep(0.05)
                            GC.gc()
                            rm(fname, force = true, recursive = true)
                        end
                    end
                    rm("test.xsd", force = true, recursive = true)  # some driver creates this file, delete it manually
                end # datasets
            end # drivers

            # test setting individual layer options and layer counts
            AG.create(AG.getdriver("Memory")) do point_dataset
                # first layer
                AG.createlayer(
                    name = "point_out",
                    dataset = point_dataset,
                    geom = AG.wkbPoint,
                ) do layer
                    AG.addfielddefn!(layer, "Name", AG.OFTString, nwidth = 32)
                    AG.findfieldindex(layer, "Name", false)
                    AG.createfeature(layer) do feature
                        AG.setfid!(feature, 0)
                        AG.setfield!(
                            feature,
                            AG.findfieldindex(feature, "Name"),
                            "myname",
                        )
                        AG.setgeom!(feature, 0, AG.createpoint(100.123, 0.123))
                        return nothing
                    end
                end
                # second layer
                AG.createlayer(
                    name = "point_out_2",
                    dataset = point_dataset,
                    geom = AG.wkbPoint,
                ) do layer
                    AG.addfielddefn!(layer, "Name", AG.OFTString, nwidth = 32)
                    AG.findfieldindex(layer, "Name", false)
                    AG.createfeature(layer) do feature
                        AG.setfield!(
                            feature,
                            AG.findfieldindex(feature, "Name"),
                            "myname",
                        )
                        AG.setgeom!(feature, 0, AG.createpoint(100.123, 1.123))
                        return nothing
                    end
                end
                AG.write(
                    point_dataset,
                    "deleteme.sqlite";
                    driver = AG.getdriver("SQLite"),
                    layer_options = Dict(
                        0 => ["FORMAT=WKT", "LAUNDER=YES"],
                        1 => ["STRICT=NO"],
                    ),
                    use_gdal_copy = true,
                )
                AG.read("deleteme.sqlite") do read_ds
                    l0 = AG.getlayer(read_ds, 0)
                    l1 = AG.getlayer(read_ds, 1)
                    gd0 = AG.getgeomdefn(AG.layerdefn(l0))
                    gd1 = AG.getgeomdefn(AG.layerdefn(l1))

                    @test assertsimilar(point_dataset, read_ds)
                    @test AG.getname(gd0) == "WKT_GEOMETRY"
                    @test AG.getname(gd1) == "GEOMETRY"
                end
                AG.write(
                    point_dataset,
                    "deleteme.sqlite";
                    driver = AG.getdriver("SQLite"),
                    layer_indices = [1],
                    layer_options = Dict(1 => ["FORMAT=WKT", "LAUNDER=YES"]),
                    use_gdal_copy = true,
                )
                AG.read("deleteme.sqlite") do read_ds
                    @test AG.nlayer(read_ds) == 1
                    l0 = AG.getlayer(read_ds, 0)
                    gd0 = AG.getgeomdefn(AG.layerdefn(l0))
                    @test AG.getname(gd0) == "WKT_GEOMETRY"
                end
            end # individual layer options

            #copylayers
            AG.read("data/point.geojson") do src
                AG.read("deleteme.sqlite"; flags = AG.OF_UPDATE) do dst
                    AG.copylayers!(src, dst; use_gdal_copy = true)
                    AG.copylayers!(
                        src,
                        dst;
                        layer_options = ["OVERWRITE=YES"],
                        use_gdal_copy = false,
                    )
                    srclayer = AG.getlayer(src, 0)
                    dstlayer = AG.getlayer(dst, 1)
                    @test AG.getname(dstlayer) == AG.getname(srclayer)
                    return nothing
                end
            end

            sleep(0.05)
            GC.gc()
            rm("deleteme.sqlite", force = true)
        end # write functionality

        dataset1 = AG.read("data/point.geojson")
        @test AG.nlayer(dataset1) == 1
        layer1 = AG.getlayer(dataset1, 0)
        @test AG.nfeature(layer1) == 4
        AG.getlayer(dataset1, 0) do layer1
            @test AG.nfeature(layer1) == 4
        end
        @test AG.getgeotransform(dataset1) ≈ [0, 1, 0, 0, 0, 1]
        # the following test covers an example of `macro cplerr(code, message)`
        @test_throws ErrorException AG.setproj!(dataset1, "nonsensestring")

        dataset2 = AG.create(AG.getdriver("Memory"))
        @test AG.nlayer(dataset2) == 0
        layer2 = AG.copy(layer1, dataset = dataset2, name = "copy")
        @test AG.nlayer(dataset2) == 1
        @test AG.nfeature(layer2) == 4
        @test AG.getname(layer2) == "copy"

        layer3a = AG.getlayer(dataset2, "copy")
        @test AG.nlayer(dataset2) == 1
        @test AG.nfeature(layer3a) == 4
        @test AG.getname(layer3a) == "copy"
        AG.getlayer(dataset2, "copy") do layer3a
            @test AG.nfeature(layer3a) == 4
            @test AG.getname(layer3a) == "copy"
        end

        layer3b = AG.copy(layer3a)
        @test AG.nlayer(dataset2) == 1 # layer3b is not associated with dataset2
        @test AG.getname(layer3b) == "copy(copy)"

        AG.copy(layer3b, dataset = dataset2)
        @test AG.nlayer(dataset2) == 2
        AG.deletelayer!(dataset2, 1)
        @test AG.nlayer(dataset2) == 1

        # the following test is to cover an example of `macro ogrerr(code, message)`
        @test_throws ErrorException AG.deletelayer!(dataset2, -1)

        dataset4 = AG.create(tempname(), driver = AG.getdriver("KML"))
        @test AG.nlayer(dataset4) == 0
        layer4 = AG.createlayer(
            name = "layer4",
            dataset = dataset4,
            geom = AG.wkbLineString,
        )
        @test AG.nlayer(dataset4) == 1

        AG.create(tempname(), driver = AG.getdriver("KML")) do dataset5
            @test AG.nlayer(dataset5) == 0
            AG.createlayer(
                name = "layer5",
                dataset = dataset5,
                geom = AG.wkbLineString,
            ) do layer5
                @test AG.nfeature(layer5) == 0
            end
            @test AG.nlayer(dataset5) == 1
        end

        layer5 = AG.createlayer()
        @test AG.getname(layer5) == ""
        @test AG.nfeature(layer5) == 0
        @test AG.nfield(layer5) == 0
        @test AG.ngeom(layer5) == 1

        AG.create(AG.getdriver("Memory")) do dataset6
            for i in 1:20
                AG.createlayer(name = "layer$(i - 1)", dataset = dataset6)
            end
            @test AG.nlayer(dataset6) == 20
            @test sprint(print, dataset6) == """
            GDAL Dataset (Driver: Memory/Memory)
            File(s): 

            Number of feature layers: 20
              Layer 0: layer0 (wkbUnknown)
              Layer 1: layer1 (wkbUnknown)
              Layer 2: layer2 (wkbUnknown)
              Layer 3: layer3 (wkbUnknown)
              Layer 4: layer4 (wkbUnknown)
              Remaining layers:
                layer5, layer6, layer7, layer8, layer9, 
                layer10, layer11, layer12, layer13, layer14, 
                layer15, layer16, layer17, layer18, layer19, """
        end
    end
end
