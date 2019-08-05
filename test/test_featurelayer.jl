using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Testing FeatureLayer Methods" begin
    AG.read("data/point.geojson") do dataset
        AG.createcopy(dataset) do tmpcopy
            @test AG.nlayer(tmpcopy) == 1
            tmplayer = AG.getlayer(tmpcopy,0)
            @test sprint(print, AG.getspatialref(tmplayer)) == "NULL Spatial Reference System"
            AG.getspatialref(tmplayer) do spref
                @test sprint(print, spref) == "NULL Spatial Reference System"
            end
            @test AG.isignored(AG.getgeomdefn(AG.getlayerdefn(tmplayer),0)) == false
            AG.setignoredfields!(tmplayer, ["OGR_GEOMETRY"])
            @test AG.isignored(AG.getgeomdefn(AG.getlayerdefn(tmplayer),0)) == true
            AG.synctodisk!(tmplayer)
        end

        layer = AG.getlayer(dataset, 0)
        @test sprint(print, AG.getspatialref(layer)) == "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs "
        AG.getspatialref(layer) do spref
            @test sprint(print, spref) == "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs "
        end
        @test AG.getfidcolname(layer) == ""
        @test AG.getgeomcolname(layer) == ""
        @test AG.nreference(layer) == 0
        AG.reference(layer)
        @test AG.nreference(layer) == 1
        AG.dereference(layer)
        @test AG.nreference(layer) == 0

        @test AG.nfeature(layer) == 4
        @test AG.getfield.(layer, 1) == ["point-a", "point-b", "a", "b"]
        AG.setspatialfilter!(layer,100,-1,100.1,1)
        @test AG.toWKT(AG.getspatialfilter(layer)) == "POLYGON ((100 -1,100 1,100.1 1.0,100.1 -1.0,100 -1))"
        @test AG.nfeature(layer) == -1
        @test AG.getfield.(layer, 1) == ["point-a", "a"]
        AG.clearspatialfilter!(layer)

        @test AG.nfeature(layer) == 4
        @test AG.getfield.(layer, 1) == ["point-a", "point-b", "a", "b"]
        @test AG.getgeomindex(AG.getlayerdefn(layer)) == 0
        AG.setspatialfilter!(layer,0,100,-1,100.1,1)
        @test AG.toWKT(AG.getspatialfilter(layer)) == "POLYGON ((100 -1,100 1,100.1 1.0,100.1 -1.0,100 -1))"
        @test AG.nfeature(layer) == -1
        @test AG.getfield.(layer, 1) == ["point-a", "a"]

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
                AG.nextfeature(layer) do feature
                    @test AG.getfield(feature, 1) == "point-a"
                end
                AG.setnextbyindex!(layer, 2)
                AG.nextfeature(layer) do feature
                    @test AG.getfield(feature, 1) == "a"
                end
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

# Untested:

# write!(layer::FeatureLayer, feature::Feature)
# write!(layer::FeatureLayer, field::GeomFieldDefn, approx::Bool = false)
# deletefeature!(layer::FeatureLayer, i::Integer)

# intersection(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# union(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressdata = C_NULL, progressfunc::Function = GDAL.C.GDALDummyProgress)
# symdifference(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# identity(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# update(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# clip(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# erase(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)

# deletefield!(layer::FeatureLayer, i::Integer)
# reorderfields!(layer::FeatureLayer, indices::Vector{Cint})
# reorderfield!(layer::FeatureLayer, oldpos::Integer, newpos::Integer)
# alterfielddefn!(layer::FeatureLayer, i::Integer, newfielddefn::FieldDefn, flags::UInt8)
# starttransaction(layer)
# committransaction(layer)
# rollbacktransaction(layer)
