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
            @test sprint(print, AG.getspatialref(layer)) == "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs "
            @test AG.getfidcolname(layer) == ""
            @test AG.getgeomcolname(layer) == ""
            @test AG.nreference(layer) == 0
            AG.reference(layer)
            @test AG.nreference(layer) == 1
            AG.dereference(layer)
            @test AG.nreference(layer) == 0
            AG.setspatialfilter!(layer,100,-1,100.1,1)
            @test AG.toWKT(AG.getspatialfilter(layer)) == "POLYGON ((100 -1,100 1,100.1 1.0,100.1 -1.0,100 -1))"
            AG.clone(AG.getspatialfilter(layer)) do poly
                n = 0; for feature in layer; n += 1 end; @test n == 2
                AG.clearspatialfilter!(layer)
                @test sprint(print, AG.getspatialfilter(layer)) == "NULL Geometry"
                n = 0; for feature in layer; n += 1 end; @test n == 4
                
                @testset "Test with setting to index of geomfield" begin
                    AG.setspatialfilter!(layer, 0, poly)
                    n = 0; for feature in layer; n += 1 end; @test n == 2
                    AG.clearspatialfilter!(layer, 0)
                    n = 0; for feature in layer; n += 1 end; @test n == 4
                    
                    AG.setattributefilter!(layer, "FID = 2")
                    n = 0; for feature in layer; n += 1 end; @test n == 1
                    AG.setattributefilter!(layer, "FID = 3")
                    n = 0; for feature in layer; n += 1 end; @test n == 2
                    AG.clearattributefilter!(layer)
                    n = 0; for feature in layer; n += 1 end; @test n == 4
                    AG.setnextbyindex!(layer, 2)
                    n = 0; for feature in layer; n += 1 end; @test n == 2
                    @test AG.testcapability(layer,"OLCRandomWrite") == false
                end
            end
            @test AG.findfieldindex(layer,"FID", true) == 0
            @test AG.findfieldindex(layer,"FID", false) == 0
            @test AG.findfieldindex(layer,"pointname", true) == 1
            @test AG.findfieldindex(layer,"pointname", false) == 1
            @test AG.findfieldindex(layer,"geom", true) == -1
            @test AG.findfieldindex(layer,"geom", true) == -1
            @test AG.findfieldindex(layer,"rubbish", true) == -1
            @test AG.findfieldindex(layer,"rubbish", false) == -1
            @test sprint(print, AG.getextent(layer, 0, true)) == "GDAL.OGREnvelope(100.0, 100.2785, 0.0, 0.0893)"
            @test sprint(print, AG.getextent(layer, true)) == "GDAL.OGREnvelope(100.0, 100.2785, 0.0, 0.0893)"
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
