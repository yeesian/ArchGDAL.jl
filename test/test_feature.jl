using Test
import ArchGDAL;
const AG = ArchGDAL;

@testset "test_feature.jl" begin
    AG.read("data/point.geojson") do dataset
        layer = AG.getlayer(dataset, 0)
        AG.getfeature(layer, 0) do f1
            AG.getfeature(layer, 2) do f2
                @test sprint(print, f1) == """
                Feature
                  (index 0) geom => POINT
                  (index 0) FID => 2.0
                  (index 1) pointname => point-a
                """
                AG.getgeom(f1) do g1
                    @test sprint(print, g1) == "Geometry: POINT (100 0)"
                end
                fid1 = AG.getfid(f1)
                @test fid1 == 0

                AG.getgeom(f2, "fake name") do g
                    @test sprint(print, g) == "NULL Geometry"
                end

                @test sprint(print, f2) == """
                Feature
                  (index 0) geom => POINT
                  (index 0) FID => 0.0
                  (index 1) pointname => a
                """
                AG.getgeom(f2, "") do g2
                    @test sprint(print, g2) == "Geometry: POINT (100 0)"
                end
                fid2 = AG.getfid(f2)
                @test fid2 == 2

                AG.clone(f1) do f3
                    @test AG.equals(AG.getgeom(f1), AG.getgeom(f3)) == true
                end
                AG.setfid!(f1, fid2)
                AG.setfid!(f2, fid1)
                @test AG.getfid(f1) == 2
                @test AG.getfid(f2) == 0

                @test AG.findgeomindex(f1, "geom") == -1
                @test AG.findgeomindex(f1, "") == 0
                @test AG.findgeomindex(f2, "geom") == -1
                @test AG.findgeomindex(f2, "") == 0
                @test AG.gettype(AG.getgeomdefn(f1, 0)) == AG.wkbPoint
                @test AG.gettype(AG.getgeomdefn(f2, 0)) == AG.wkbPoint
            end
        end

        AG.getfeature(layer, 0) do f
            @test AG.toWKT(AG.getgeom(f, 0)) == "POINT (100 0)"
            AG.setgeom!(f, 0, AG.createpoint(0, 100))
            @test AG.toWKT(AG.getgeom(f, 0)) == "POINT (0 100)"
            AG.createpolygon([(0.0, 100.0), (100.0, 0.0)]) do poly
                return AG.setgeom!(f, 0, poly)
            end
            @test AG.toWKT(AG.getgeom(f, 0)) == "POLYGON ((0 100,100 0))"

            AG.setstylestring!(f, "@Name")
            @test AG.getstylestring(f) == "@Name"
            AG.setstylestring!(f, "NewName")
            @test AG.getstylestring(f) == "NewName"

            AG.createstyletable() do st
                AG.addstyle!(st, "name", "style")
                AG.setstyletable!(f, st)
                @test AG.findstylestring(AG.getstyletable(f), "name") == "style"
            end

            AG.setnativedata!(f, "nativedata1")
            @test AG.getnativedata(f) == "nativedata1"
            AG.setnativedata!(f, "nativedata2")
            @test AG.getnativedata(f) == "nativedata2"

            AG.setmediatype!(f, "mediatype1")
            @test AG.getmediatype(f) == "mediatype1"
            AG.setmediatype!(f, "mediatype2")
            @test AG.getmediatype(f) == "mediatype2"

            @test AG.validate(f, AG.F_VAL_NULL, false) == true
            @test AG.validate(f, AG.F_VAL_GEOM_TYPE, false) == false
            @test AG.validate(f, AG.F_VAL_WIDTH, false) == true
            @test AG.validate(f, AG.F_VAL_ALLOW_NULL_WHEN_DEFAULT, false) ==
                  true
            @test AG.validate(f, AG.F_VAL_ALLOW_DIFFERENT_GEOM_DIM, false) ==
                  true

            @test AG.getfield(f, 1) == "point-a"
            @test AG.getdefault(f, 1) == ""
            AG.setdefault!(AG.getfielddefn(f, 1), "default value")
            @test AG.getdefault(f, 1) == "default value"
            @test AG.getfield(f, 1) == "point-a"
            AG.unsetfield!(f, 1)
            @test AG.getfield(f, 1) == "default value"
            AG.fillunsetwithdefault!(f, notnull = false)
            @test AG.getfield(f, 1) == AG.getdefault(f, 1)
        end
    end

    @testset "In-Memory Driver" begin
        AG.create(AG.getdriver("MEMORY")) do output
            layer = AG.createlayer(dataset = output, geom = AG.wkbPolygon)
            AG.createfielddefn("int64field", AG.OFTInteger64) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("float64field", AG.OFTReal) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("intlistfield", AG.OFTIntegerList) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn(
                "int64listfield",
                AG.OFTInteger64List,
            ) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("float64listfield", AG.OFTRealList) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("stringlistfield", AG.OFTStringList) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("binaryfield", AG.OFTBinary) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("datetimefield", AG.OFTDateTime) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("booleanfield", AG.OFTInteger) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("int16field", AG.OFTInteger) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("int32field", AG.OFTInteger) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfielddefn("float32field", AG.OFTReal) do fielddefn
                return AG.addfielddefn!(layer, fielddefn)
            end
            AG.createfeature(layer) do feature
                AG.setfield!(feature, 0, Int64(1))
                AG.setfield!(feature, 1, Float64(1.0))
                AG.setfield!(feature, 2, Int32[1, 2])
                AG.setfield!(feature, 3, Int64[1, 2])
                AG.setfield!(feature, 4, Float64[1.0, 2.0])
                AG.setfield!(feature, 5, ["1", "2.0"])
                AG.setfield!(feature, 6, UInt8[1, 2, 3, 4])
                AG.setfield!(feature, 7, Dates.DateTime(2016, 9, 25, 21, 17, 0))
                AG.setfield!(feature, 8, true)
                AG.setfield!(feature, 9, Int16(1))
                AG.setfield!(feature, 10, Int32(1))
                AG.setfield!(feature, 11, Float32(1.0))
                @test sprint(print, AG.getgeom(feature)) == "NULL Geometry"
                AG.getgeom(feature) do geom
                    @test sprint(print, geom) == "NULL Geometry"
                end
                @test sprint(print, AG.getgeom(feature, 0)) == "NULL Geometry"
                AG.getgeom(feature, 0) do geom
                    @test sprint(print, geom) == "NULL Geometry"
                end

                AG.addfeature(layer) do newfeature
                    AG.setfrom!(newfeature, feature)
                    @test AG.getfield(newfeature, 0) == 1
                    @test AG.getfield(newfeature, 1) ≈ 1.0
                    @test AG.getfield(newfeature, 2) == Int32[1, 2]
                    @test AG.getfield(newfeature, 3) == Int64[1, 2]
                    @test AG.getfield(newfeature, 4) ≈ Float64[1.0, 2.0]
                    @test AG.getfield(newfeature, 5) == String["1", "2.0"]
                    @test AG.getfield(newfeature, 6) == UInt8[1, 2, 3, 4]
                    @test AG.getfield(newfeature, 7) ==
                          Dates.DateTime(2016, 9, 25, 21, 17, 0)
                    @test AG.getfield(newfeature, 8) == true
                    @test AG.getfield(newfeature, 9) == Int16(1)
                    @test AG.getfield(newfeature, 10) == Int32(1)
                    @test AG.getfield(newfeature, 11) == Float32(1.0)

                    AG.createfeature(layer) do lastfeature
                        AG.setfrom!(lastfeature, feature)
                        AG.setfield!(lastfeature, 0, 45)
                        AG.setfield!(lastfeature, 1, 18.2)
                        AG.setfield!(lastfeature, 5, ["foo", "bar"])
                        @test AG.getfield(lastfeature, 0) == 45
                        @test AG.getfield(lastfeature, 1) ≈ 18.2
                        @test AG.getfield(lastfeature, 2) == Int32[1, 2]
                        @test AG.getfield(lastfeature, 3) == Int64[1, 2]
                        @test AG.getfield(lastfeature, 4) ≈ Float64[1.0, 2.0]
                        @test AG.getfield(lastfeature, 5) ==
                              String["foo", "bar"]
                        @test AG.getfield(lastfeature, 6) == UInt8[1, 2, 3, 4]
                        @test AG.getfield(lastfeature, 7) ==
                              Dates.DateTime(2016, 9, 25, 21, 17, 0)

                        @test AG.getfield(newfeature, 0) == 1
                        @test AG.getfield(newfeature, 1) ≈ 1.0
                        @test AG.getfield(newfeature, 5) == String["1", "2.0"]
                        AG.setfrom!(newfeature, lastfeature, collect(Cint, 0:7))
                        @test AG.getfield(newfeature, 0) == 45
                        @test AG.getfield(newfeature, 1) ≈ 18.2
                        @test AG.getfield(newfeature, 5) == String["foo", "bar"]
                    end
                    @test AG.nfeature(layer) == 1
                end
                @test AG.nfeature(layer) == 2
            end
            @test AG.nfeature(layer) == 3
        end
    end
end
