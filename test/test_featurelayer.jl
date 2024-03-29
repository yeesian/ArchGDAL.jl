using Test
import ArchGDAL as AG

@testset "test_featurelayer.jl" begin
    @testset "Testing FeatureLayer Methods" begin
        AG.read("data/point.geojson") do dataset
            AG.copy(dataset) do tmpcopy
                @test AG.nlayer(tmpcopy) == 1
                tmplayer = AG.getlayer(tmpcopy, 0)
                @test sprint(print, AG.getspatialref(tmplayer)) ==
                      "NULL Spatial Reference System"
                AG.getspatialref(tmplayer) do spref
                    @test sprint(print, spref) ==
                          "NULL Spatial Reference System"
                end
                @test AG.isignored(AG.getgeomdefn(AG.layerdefn(tmplayer), 0)) ==
                      false
                AG.setignoredfields!(tmplayer, ["OGR_GEOMETRY"])
                @test AG.isignored(AG.getgeomdefn(AG.layerdefn(tmplayer), 0)) ==
                      true
            end

            AG.copy(dataset, driver = AG.getdriver("Memory")) do tmpcopy
                tmplayer = AG.getlayer(dataset, 0)
                AG.copy(tmplayer) do copylayer
                    @test AG.nfeature(tmplayer) == AG.nfeature(copylayer)
                end
                @test sprint(print, AG.getspatialref(tmplayer)) ==
                      "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs"
                AG.getspatialref(tmplayer) do spref
                    @test sprint(print, spref) ==
                          "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs"
                end
                newlayer = AG.createlayer(
                    name = "new layer",
                    dataset = tmpcopy,
                    spatialref = AG.getspatialref(tmplayer),
                    geom = AG.wkbPoint,
                )
                @test AG.ngeom(AG.layerdefn(newlayer)) == 1
                @test sprint(print, newlayer) == """
                    Layer: new layer
                      Geometry 0 (): [wkbPoint]
                    """
                AG.writegeomdefn(newlayer, "new geom", AG.wkbLineString) do gfd
                    @test AG.getname(gfd) == "new geom"
                    @test AG.gettype(gfd) == AG.wkbLineString
                end
                @test sprint(print, newlayer) == """
                    Layer: new layer
                      Geometry 0 (): [wkbPoint]
                      Geometry 1 (new geom): [wkbLineString]
                    """
                @test AG.ngeom(AG.layerdefn(newlayer)) == 2
                @test AG.nfeature(newlayer) == 0
                AG.createfeature(newlayer) do newfeature
                    AG.setgeom!(newfeature, 0, AG.createpoint())
                    AG.setgeom!(newfeature, 1, AG.createlinestring())
                    return nothing
                end
                @test AG.nfeature(newlayer) == 1
                @test sprint(print, newlayer) == """
                    Layer: new layer
                      Geometry 0 (): [wkbPoint]
                      Geometry 1 (new geom): [wkbLineString]
                    """
                AG.deletefeature!(newlayer, 0)
                @test AG.nfeature(newlayer) == 0
                @test sprint(print, newlayer) == """
                    Layer: new layer
                      Geometry 0 (): [wkbPoint]
                      Geometry 1 (new geom): [wkbLineString]
                    """
                AG.writegeomdefn!(newlayer, "new poly", AG.wkbPolygon)
                @test AG.ngeom(AG.layerdefn(newlayer)) == 3
                @test sprint(print, newlayer) == """
                    Layer: new layer
                      Geometry 0 (): [wkbPoint]
                      Geometry 1 (new geom): [wkbLineString]
                      Geometry 2 (new poly): [wkbPolygon]
                    """

                AG.addfeature(newlayer) do newfeature
                    AG.setgeom!(newfeature, 0, AG.createpoint())
                    AG.setgeom!(newfeature, 1, AG.createlinestring())
                    AG.setgeom!(
                        newfeature,
                        2,
                        AG.createpolygon([[
                            [0.0, 0.0],
                            [1.0, 1.0],
                            [0.0, 1.0],
                        ]]),
                    )

                    @test sprint(print, AG.getgeom(newfeature)) ==
                          "Geometry: POINT EMPTY"
                    @test sprint(print, AG.getgeom(newfeature, 0)) ==
                          "Geometry: POINT EMPTY"
                    @test sprint(print, AG.getgeom(newfeature, 1)) ==
                          "Geometry: LINESTRING EMPTY"
                    @test sprint(print, AG.getgeom(newfeature, 2)) ==
                          "Geometry: POLYGON ((0 0,1 1,0 1))"
                    AG.getgeom(newfeature) do g
                        @test sprint(print, g) == "Geometry: POINT EMPTY"
                    end
                    AG.getgeom(newfeature, 1) do g
                        @test sprint(print, g) == "Geometry: LINESTRING EMPTY"
                    end
                    AG.getgeom(newfeature, 2) do g
                        @test sprint(print, g) ==
                              "Geometry: POLYGON ((0 0,1 1,0 1))"
                    end
                end
            end

            layer = AG.getlayer(dataset, 0)
            @test sprint(print, AG.getspatialref(layer)) ==
                  "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs"
            @test AG.fidcolumnname(layer) == ""
            @test AG.geomcolumnname(layer) == ""
            @test AG.nreference(layer) == 0
            AG.reference(layer)
            @test AG.nreference(layer) == 1
            AG.dereference(layer)
            @test AG.nreference(layer) == 0

            @test AG.nfeature(layer) == 4
            @test AG.getfield.(layer, 1) == ["point-a", "point-b", "a", "b"]
            AG.setspatialfilter!(layer, 100, -1, 100.1, 1)
            @test AG.toWKT(AG.getspatialfilter(layer)) ==
                  "POLYGON ((100 -1,100 1,100.1 1.0,100.1 -1,100 -1))"
            @test AG.nfeature(layer) == -1
            @test AG.getfield.(layer, 1) == ["point-a", "a"]
            AG.clearspatialfilter!(layer)

            @test AG.nfeature(layer) == 4
            @test AG.getfield.(layer, 1) == ["point-a", "point-b", "a", "b"]
            @test AG.findgeomindex(AG.layerdefn(layer)) == 0
            AG.setspatialfilter!(layer, 0, 100, -1, 100.1, 1)
            @test AG.toWKT(AG.getspatialfilter(layer)) ==
                  "POLYGON ((100 -1,100 1,100.1 1.0,100.1 -1,100 -1))"
            @test AG.nfeature(layer) == -1
            @test AG.getfield.(layer, 1) == ["point-a", "a"]

            AG.clone(AG.getspatialfilter(layer)) do poly
                n = 0
                for feature in layer
                    n += 1
                end
                @test n == 2
                AG.clearspatialfilter!(layer)
                @test sprint(print, AG.getspatialfilter(layer)) ==
                      "NULL Geometry"
                n = 0
                for feature in layer
                    n += 1
                end
                @test n == 4

                @testset "Test with setting to index of geomfield" begin
                    AG.setspatialfilter!(layer, 0, poly)
                    n = 0
                    for feature in layer
                        n += 1
                    end
                    @test n == 2
                    AG.clearspatialfilter!(layer, 0)
                    n = 0
                    for feature in layer
                        n += 1
                    end
                    @test n == 4

                    AG.setattributefilter!(layer, "FID = 2")
                    n = 0
                    for feature in layer
                        n += 1
                    end
                    @test n == 1
                    AG.setattributefilter!(layer, "FID = 3")
                    n = 0
                    for feature in layer
                        n += 1
                    end
                    @test n == 2
                    AG.clearattributefilter!(layer)
                    n = 0
                    for feature in layer
                        n += 1
                    end
                    @test n == 4
                    AG.nextfeature(layer) do feature
                        @test AG.getfield(feature, 1) == "point-a"
                    end
                    AG.setnextbyindex!(layer, 2)
                    AG.nextfeature(layer) do feature
                        @test AG.getfield(feature, 1) == "a"
                    end
                    @test AG.testcapability(layer, "OLCRandomWrite") == false
                end
            end
            @test AG.findfieldindex(layer, "FID", true) == 0
            @test AG.findfieldindex(layer, :FID, false) == 0
            @test AG.findfieldindex(layer, "pointname", true) == 1
            @test AG.findfieldindex(layer, "pointname", false) == 1
            @test AG.findfieldindex(layer, "geom", true) == -1
            @test AG.findfieldindex(layer, "geom", true) == -1
            @test AG.findfieldindex(layer, "rubbish", true) == -1
            @test AG.findfieldindex(layer, "rubbish", false) == -1
            @test sprint(print, AG.envelope(layer, 0, true)) ==
                  "GDAL.OGREnvelope(100.0, 100.2785, 0.0, 0.0893)"
            @test sprint(print, AG.envelope(layer, true)) ==
                  "GDAL.OGREnvelope(100.0, 100.2785, 0.0, 0.0893)"
        end
    end

    # Not implemented yet:

    # intersection(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.gdaldummyprogress, progressdata = C_NULL)
    # union(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressdata = C_NULL, progressfunc::Function = GDAL.gdaldummyprogress)
    # symdifference(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.gdaldummyprogress, progressdata = C_NULL)
    # identity(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.gdaldummyprogress, progressdata = C_NULL)
    # update(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.gdaldummyprogress, progressdata = C_NULL)
    # clip(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.gdaldummyprogress, progressdata = C_NULL)
    # erase(input::FeatureLayer, method::FeatureLayer, result::FeatureLayer; options = StringList(C_NULL), progressfunc::Function = GDAL.gdaldummyprogress, progressdata = C_NULL)

    # deletefielddefn!(layer::FeatureLayer, i::Integer)
    # reorderfielddefn!(layer::FeatureLayer, indices::Vector{Cint})
    # reorderfielddefn!(layer::FeatureLayer, oldpos::Integer, newpos::Integer)
    # updatefielddefn!(layer::FeatureLayer, i::Integer, newfielddefn::FieldDefn, flags::UInt8)

    # starttransaction(layer)
    # committransaction(layer)
    # rollbacktransaction(layer)

end
