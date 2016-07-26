using FactCheck
import ArchGDAL; const AG = ArchGDAL

AG.registerdrivers() do
    AG.read("data/point.geojson") do dataset
        AG.createcopy(dataset, "tmp/point.geojson") do tmpcopy
            @fact AG.nlayer(tmpcopy) --> 1
            AG.deletelayer!(tmpcopy, 0)
            @fact AG.nlayer(tmpcopy) --> 0
        end
        layer = AG.getlayer(dataset, 0)
        println(AG.getspatialref(layer))
        println("FID Column name: $(AG.getfidcolname(layer))")
        println("Geom Column name: $(AG.getgeomcolname(layer))")
        for feature in layer
            println(feature)
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
        println("Playing with Geoms and FIDs")
        AG.getfeature(layer, 0) do f1
            AG.getfeature(layer, 2) do f2
                println(f1)
                println(AG.getgeom(f1))
                fid1 = AG.getfid(f1); println(fid1)
                println(f2)
                println(AG.getgeom(f2))
                fid2 = AG.getfid(f2); println(fid2)
                println(AG.equals(AG.getgeom(f1),AG.getgeom(f2)))
                AG.setfid!(f1, fid2); AG.setfid!(f2, fid1)
                println(fid1, fid2)
                println(AG.getfid(f1), AG.getfid(f2))

                println("f1 geomfieldindex for geom: $(AG.getgeomfieldindex(f1, "geom"))")
                println("f1 geomfieldindex for \"\": $(AG.getgeomfieldindex(f1, ""))")
                println("f2 geomfieldindex for geom: $(AG.getgeomfieldindex(f2, "geom"))")
                println("f2 geomfieldindex for \"\": $(AG.getgeomfieldindex(f2, ""))")
                println("f1 geomfielddefn: $(AG.getgeomfielddefn(f1, 0))")
                println("f2 geomfielddefn: $(AG.getgeomfielddefn(f2, 0))")
            end
        end
        println("FID exact index: $(AG.findfieldindex(layer,"FID", true))")
        println("FID index: $(AG.findfieldindex(layer,"FID", false))")
        println("pointname exact index: $(AG.findfieldindex(layer,"pointname", true))")
        println("pointname index: $(AG.findfieldindex(layer,"pointname", false))")
        println("geom exact findfieldindex: $(AG.findfieldindex(layer,"geom", true))")
        println("geom findfieldindex: $(AG.findfieldindex(layer,"geom", true))")
        println("rubbish exact index: $(AG.findfieldindex(layer,"rubbish", true))")
        println("rubbish index: $(AG.findfieldindex(layer,"rubbish", false))")
    end
end

rm("tmp/point.geojson")

# Untested:
# setgeomfielddirectly!(feature::Feature, i::Integer, geom::Geometry)
# setgeomfield!(feature::Feature, i::Integer, geom::Geometry)
# getstylestring(feature::Feature)
# setstylestring!(feature::Feature, style::AbstractString)
# setstylestringdirectly!(feature::Feature, style::AbstractString)
# getstyletable(feature::Feature)
# setstyletabledirectly!(feature::Feature, styletable::StyleTable)
# setstyletable!(feature::Feature, styletable::StyleTable)
# getnativedata(feature::Feature)
# setnativedata!(feature::Feature, data::AbstractString)
# getmediatype(feature::Feature)
# setmediatype!(feature::Feature, mediatype::AbstractString)
# fillunsetwithdefault!(feature::Feature; notnull::Bool=true, options=StringList(C_NULL))
# validate(feature::Feature, flags::Integer, emiterror::Bool)
# getextent(layer::FeatureLayer, i::Integer, force::Bool=false)
# getextent(layer::FeatureLayer, force::Bool=false)
# creategeomfield!(layer::FeatureLayer, field::GeomFieldDefn, approx::Bool = false)
# deletefield!(layer::FeatureLayer, i::Integer)
# reorderfields!(layer::FeatureLayer, indices::Vector{Cint})
# reorderfield!(layer::FeatureLayer, oldpos::Integer, newpos::Integer)
# alterfielddefn!(layer::FeatureLayer, i::Integer, newfielddefn::FieldDefn, flags::UInt8)
# reference(layer::FeatureLayer)
# dereference(layer::FeatureLayer)
# nreference(layer::FeatureLayer)
# synctodisk!(layer::FeatureLayer)
# setignoredfields!(layer::FeatureLayer, fieldnames)
# intersection(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# union(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressdata = C_NULL, progressfunc::Function = GDAL.C.GDALDummyProgress)
# symdifference(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# identity(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# update(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# clip(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)
# erase(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.C.GDALDummyProgress, progressdata = C_NULL)