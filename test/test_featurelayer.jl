using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Testing FeatureLayer Methods" begin
    AG.registerdrivers() do
        AG.read("data/point.geojson") do dataset
            AG.createcopy(dataset, "tmp/point.geojson") do tmpcopy
                @test AG.nlayer(tmpcopy) == 1
                # AG.deletelayer!(tmpcopy, 0)
                # @test AG.nlayer(tmpcopy) == 0
                tmplayer = AG.getlayer(tmpcopy,0)
                @test AG.isignored(AG.getgeomfielddefn(AG.getlayerdefn(tmplayer),0)) == false
                AG.setignoredfields!(tmplayer, ["OGR_GEOMETRY"])
                @test AG.isignored(AG.getgeomfielddefn(AG.getlayerdefn(tmplayer),0)) == true
                AG.synctodisk!(tmplayer)
            end
            rm("tmp/point.geojson")

            layer = AG.getlayer(dataset, 0)
            println(AG.getspatialref(layer))
            println("FID Column name: $(AG.getfidcolname(layer))")
            println("Geom Column name: $(AG.getgeomcolname(layer))")
            @test AG.nreference(layer) == 0
            AG.reference(layer)
            @test AG.nreference(layer) == 1
            AG.dereference(layer)
            @test AG.nreference(layer) == 0
            for feature in layer
                println(feature)
                @test AG.nreference(layer) == 0
                println("Features read: $(AG.getfeaturesread(layer))")
            end
            AG.getfeature(layer, 2) do feature
                print(feature)
            end
            AG.setspatialfilter!(layer,100,-1,100.1,1)
            println("Filtering all points in $(AG.getspatialfilter(layer))")
            AG.clone(AG.getspatialfilter(layer)) do poly
                println(poly)
                for feature in layer
                    println(feature)
                end
                AG.clearspatialfilter!(layer)
                println("Clearing Spatial Filter")
                println("New $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                AG.setspatialfilter!(layer, poly)
                println("Re-filter all points in $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                AG.clearspatialfilter!(layer)
                println("Clearing Spatial Filter")
                println("New $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                println("Test with setting to index of geomfield")
                AG.setspatialfilter!(layer, 0, poly)
                println("  Re-filter all points in $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                AG.clearspatialfilter!(layer, 0)
                println("  Clearing Spatial Filter")
                println("  New $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                AG.setspatialfilter!(layer, 0,100,-1,100.1,1)
                println("Re-filter all points in $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                AG.clearspatialfilter!(layer)
                println("Clearing Spatial Filter")
                println("New $(AG.getspatialfilter(layer))")
                for feature in layer
                    println(feature)
                end
                query = "FID = 2"
                println("Setting attribute filter: $query")
                AG.setattributefilter!(layer, query)
                for feature in layer
                    println(feature)
                end
                query = "FID = 3"
                println("Setting attribute filter: $query")
                AG.setattributefilter!(layer, query)
                for feature in layer
                    println(feature)
                end
                AG.clearattributefilter!(layer)
                println("After clearing attribute filter:")
                for feature in layer
                    println(feature)
                end
                println("Fast forward to index 2:")
                AG.setnextbyindex!(layer, 2)
                for feature in layer
                    println(feature)
                end
                print("Test capability for random access writing: ")
                println(AG.testcapability(layer,"OLCRandomWrite"))
            end
            println("FID exact index: $(AG.findfieldindex(layer,"FID", true))")
            println("FID index: $(AG.findfieldindex(layer,"FID", false))")
            println("pointname exact index: $(AG.findfieldindex(layer,"pointname", true))")
            println("pointname index: $(AG.findfieldindex(layer,"pointname", false))")
            println("geom exact findfieldindex: $(AG.findfieldindex(layer,"geom", true))")
            println("geom findfieldindex: $(AG.findfieldindex(layer,"geom", true))")
            println("rubbish exact index: $(AG.findfieldindex(layer,"rubbish", true))")
            println("rubbish index: $(AG.findfieldindex(layer,"rubbish", false))")

            println(AG.getextent(layer, 0, true))
            println(AG.getextent(layer, true))
        end
    end
end

# Untested:
# setfeature!(layer::FeatureLayer, feature::Feature) 
# deletefeature!(layer::FeatureLayer, i::Integer)
# creategeomfield!(layer::FeatureLayer, field::GeomFieldDefn, approx::Bool = false)
# deletefield!(layer::FeatureLayer, i::Integer)
# reorderfields!(layer::FeatureLayer, indices::Vector{Cint})
# reorderfield!(layer::FeatureLayer, oldpos::Integer, newpos::Integer)
# alterfielddefn!(layer::FeatureLayer, i::Integer, newfielddefn::FieldDefn, flags::UInt8)
# setignoredfields!(layer::FeatureLayer, fieldnames)
# intersection(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# union(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressdata = C_NULL, progressfunc::Function = GDAL.C.GDALDummyProgress)
# symdifference(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# identity(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# update(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# clip(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# erase(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
