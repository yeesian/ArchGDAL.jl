using Test
import ArchGDAL as AG

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

            @testset "Missing and Null Semantics" begin
                @test isnothing(AG.getdefault(f, 1))
                AG.setdefault!(AG.getfielddefn(f, 1), "default value")
                @test AG.getdefault(f, 1) == "default value"

                @test AG.isfieldsetandnotnull(f, 1)
                @test AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1)
                @test AG.getfield(f, 1) == "point-a"

                AG.unsetfield!(f, 1)
                @test !AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1) # carried over from earlier
                @test isnothing(AG.getfield(f, 1))

                # unset & notnull: missing
                AG.fillunsetwithdefault!(f)
                # nothing has changed
                @test isnothing(AG.getfield(f, 1))
                # because it is a nullable field
                @test AG.isnullable(AG.getfielddefn(f, 1))
                # even though it is not a null value
                @test !AG.isfieldnull(f, 1)
                # the field is still not set
                @test !AG.isfieldset(f, 1)

                # set & notnull: value
                AG.fillunsetwithdefault!(f, notnull = false)
                # now the field is set to the default
                @test AG.getfield(f, 1) == AG.getdefault(f, 1)
                @test !AG.isfieldnull(f, 1) # still as expected
                @test AG.isfieldset(f, 1) # the field is now set

                # set the field to be notnullable
                AG.setnullable!(AG.getfielddefn(f, 1), false)
                # now if we unset the field
                AG.unsetfield!(f, 1)
                @test !AG.isfieldnull(f, 1)
                @test !AG.isfieldset(f, 1)
                @test isnothing(AG.getfield(f, 1))
                # and we fill unset with default again
                AG.fillunsetwithdefault!(f)
                # the field is set to the default
                @test AG.getfield(f, 1) == AG.getdefault(f, 1)

                # set & null: missing
                @test !AG.isfieldnull(f, 1)
                @test AG.isfieldset(f, 1)
                AG.setfieldnull!(f, 1)
                @test AG.isfieldnull(f, 1)
                @test AG.isfieldset(f, 1)
                @test ismissing(AG.getfield(f, 1))

                # unset & null: N/A (but nothing otherwise)
                AG.unsetfield!(f, 1)
                # Observe that OGRUnset and OGRNull are mutually exclusive
                @test !AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1) # notice the field is notnull

                # setting the field for a notnullable column
                AG.setnullable!(AG.getfielddefn(f, 1), false)
                AG.setfield!(f, 1, "value")
                @test AG.getfield(f, 1) == "value"
                @test AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1)
                AG.setfield!(f, 1, missing)
                @test AG.getfield(f, 1) == AG.getdefault(f, 1)
                @test AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1)
                AG.setfield!(f, 1, nothing)
                @test isnothing(AG.getfield(f, 1))
                @test !AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1)

                # setting the field for a nullable column
                AG.setnullable!(AG.getfielddefn(f, 1), true)
                AG.setfield!(f, 1, "value")
                @test AG.getfield(f, 1) == "value"
                @test AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1)
                AG.setfield!(f, 1, missing)
                @test ismissing(AG.getfield(f, 1))
                @test AG.isfieldset(f, 1)
                @test AG.isfieldnull(f, 1) # different from that of notnullable
                AG.setfield!(f, 1, nothing)
                @test isnothing(AG.getfield(f, 1))
                @test !AG.isfieldset(f, 1)
                @test !AG.isfieldnull(f, 1)
            end
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
                for i in 1:AG.nfield(feature)
                    @test !AG.isfieldnull(feature, i - 1)
                    @test AG.isfieldsetandnotnull(feature, i - 1)
                end
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
                    for i in 1:AG.nfield(newfeature)
                        @test !AG.isfieldnull(newfeature, i - 1)
                        @test AG.isfieldsetandnotnull(newfeature, i - 1)
                    end
                    @test AG.getfield(newfeature, 1) ≈ 1.0
                    @test AG.getfield(newfeature, 2) == Int32[1, 2]
                    @test AG.getfield(newfeature, 3) == Int64[1, 2]
                    @test AG.getfield(newfeature, 4) ≈ Float64[1.0, 2.0]
                    @test AG.getfield(newfeature, 5) == String["1", "2.0"]
                    @test AG.getfield(newfeature, 6) == UInt8[1, 2, 3, 4]
                    @test AG.getfield(newfeature, 7) ==
                          Dates.DateTime(2016, 9, 25, 21, 17, 0)
                    @test AG.getfield(newfeature, 8) == true
                    @test AG.getfield(newfeature, 9) == 1
                    @test AG.getfield(newfeature, 10) == 1
                    @test AG.getfield(newfeature, 11) == 1.0

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
                        AG.setfrom!(
                            newfeature,
                            lastfeature,
                            collect(Cint, 0:AG.nfield(newfeature)),
                        )
                        @test AG.getfield(newfeature, 0) == 45
                        @test AG.getfield(newfeature, 1) ≈ 18.2
                        @test AG.getfield(newfeature, 5) == String["foo", "bar"]

                        @test AG.isfieldsetandnotnull(newfeature, 5)
                        AG.setfieldnull!(newfeature, 5)
                        @test !AG.isfieldsetandnotnull(newfeature, 5)
                        @test AG.isfieldset(newfeature, 5)
                        @test AG.isfieldnull(newfeature, 5)
                        @test ismissing(AG.getfield(newfeature, 5))
                    end
                    @test AG.nfeature(layer) == 1
                end
                @test AG.nfeature(layer) == 2
            end
            @test AG.nfeature(layer) == 3
        end
    end
end
