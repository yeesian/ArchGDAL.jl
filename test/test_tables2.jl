using Test
import ArchGDAL
const AG = ArchGDAL
using Dates
using Tables

@testset "Unit testing of parameterized types" begin
    @testset "FType, GType and FDType helper functions" begin
        FD = Tuple{
            NamedTuple{(Symbol(""),),Tuple{AG.GType{AG.wkbLineString}}},
            NamedTuple{
                (:gid, :roadcode),
                Tuple{
                    AG.FType{AG.OFTInteger,AG.OFSTNone},
                    AG.FType{AG.OFTString,AG.OFSTNone},
                },
            },
        }
        @test AG._ngt(FD) == 1
        @test AG._gtnames(FD) === (Symbol(""),)
        @test AG._gttypes(FD) === (AG.GType{AG.wkbLineString},)
        @test AG._nft(FD) == 2
        @test AG._ftnames(FD) === (:gid, :roadcode)
        @test AG._fttypes(FD) === (
            AG.FType{AG.OFTInteger,AG.OFSTNone},
            AG.FType{AG.OFTString,AG.OFSTNone},
        )

        @test AG.getGType(
            AG.getgeomdefn(
                AG.layerdefn(
                    AG.getFDPlayer(
                        AG.read(
                            "data/multi_geom.csv",
                            options = [
                                "GEOM_POSSIBLE_NAMES=point,linestring",
                                "KEEP_GEOM_COLUMNS=NO",
                            ],
                        ),
                        0,
                    ),
                ),
            ).ptr,
        ) == AG.GType{AG.wkbUnknown}

        @test AG.getFType(
            AG.getfielddefn(
                AG.layerdefn(
                    AG.getFDPlayer(
                        AG.read(
                            "data/multi_geom.csv",
                            options = [
                                "GEOM_POSSIBLE_NAMES=point,linestring",
                                "KEEP_GEOM_COLUMNS=NO",
                            ],
                        ),
                        0,
                    ),
                ),
            ).ptr,
        ) == AG.FType{AG.OFTString,AG.OFSTNone}

        @test AG._getFDType(
            AG.layerdefn(
                AG.getFDPlayer(
                    AG.read(
                        "data/multi_geom.csv",
                        options = [
                            "GEOM_POSSIBLE_NAMES=point,linestring",
                            "KEEP_GEOM_COLUMNS=NO",
                        ],
                    ),
                    0,
                ),
            ).ptr,
        ) == Tuple{
            NamedTuple{
                (:point, :linestring),
                Tuple{AG.GType{AG.wkbUnknown},AG.GType{AG.wkbUnknown}},
            },
            NamedTuple{
                (:id, :zoom, :location),
                Tuple{
                    AG.FType{AG.OFTString,AG.OFSTNone},
                    AG.FType{AG.OFTString,AG.OFSTNone},
                    AG.FType{AG.OFTString,AG.OFSTNone},
                },
            },
        }

        @test AG._getFD(
            AG.getFDPlayer(
                AG.read(
                    "data/multi_geom.csv",
                    options = [
                        "GEOM_POSSIBLE_NAMES=point,linestring",
                        "KEEP_GEOM_COLUMNS=NO",
                    ],
                ),
                0,
            ),
        ) == Tuple{
            NamedTuple{
                (:point, :linestring),
                Tuple{AG.GType{AG.wkbUnknown},AG.GType{AG.wkbUnknown}},
            },
            NamedTuple{
                (:id, :zoom, :location),
                Tuple{
                    AG.FType{AG.OFTString,AG.OFSTNone},
                    AG.FType{AG.OFTString,AG.OFSTNone},
                    AG.FType{AG.OFTString,AG.OFSTNone},
                },
            },
        }
    end

    @testset "Parameterized types constructors and destructors" begin
        @testset "Tests for FTP_AbstractFieldDefn" begin
            fielddefn = AG.getfielddefn(
                AG.layerdefn(
                    AG.getFDPlayer(
                        AG.read(
                            "data/multi_geom.csv",
                            options = [
                                "GEOM_POSSIBLE_NAMES=point,linestring",
                                "KEEP_GEOM_COLUMNS=NO",
                            ],
                        ),
                        0,
                    ),
                ),
            )
            @test AG.getname(fielddefn) == "id"
            @test AG.gettype(fielddefn) == AG.OFTString
            @test AG.getsubtype(fielddefn) == AG.OFSTNone
        end

        @testset "Tests for GFTP_AbstractGeomFieldDefn" begin
            geomdefn = AG.getgeomdefn(
                AG.layerdefn(
                    AG.getFDPlayer(
                        AG.read(
                            "data/multi_geom.csv",
                            options = [
                                "GEOM_POSSIBLE_NAMES=point,linestring",
                                "KEEP_GEOM_COLUMNS=NO",
                            ],
                        ),
                        0,
                    ),
                ),
            )
            @test AG.getname(geomdefn) == "point"
            @test AG.gettype(geomdefn) == AG.wkbUnknown
        end
    end
end

@testset "Unit testing of parametric feature layer types and associated methods" begin
    fdp_layer = AG.getFDPlayer(AG.read("data/unset_null_testcase.geojson"))

    # Parametric types display tests
    @test sprint(print, fdp_layer) ==
          "Layer: unset_null_testcase\n  Geometry 0 (): [wkbPoint], POINT (100 0), POINT (100.2785 0.0893), ...\n     Field 0 (FID): [OFTReal], 2.0, 3.0, 0.0, 3.0\n     Field 1 (pointname): [OFTString], point-a, nothing, missing, b\n"
    @test sprint(print, AG.layerdefn(fdp_layer)) ==
          "  Geometry (index 0):  (wkbPoint)\n     Field (index 0): FID (OFTReal)\n     Field (index 1): pointname (OFTString)\n"
    @test sprint(print, iterate(fdp_layer)[1]) ==
          "Feature\n  (index 0) geom => POINT\n  (index 0) FID => 2.0\n  (index 1) pointname => point-a\n"

    # Tests on methods for DUAL_xxx abstract types
    @test Base.IteratorSize(fdp_layer) == Base.SizeUnknown()
    @test Base.length(fdp_layer) == 4
    # Tests on methods for DUAL_xxx abstract types
    fdp_feature =
        iterate(AG.getFDPlayer(AG.read("data/test_DUALxxx_methods.geojson")))[1]
    @test AG.asint(fdp_feature, 0) == typemax(Int32)
    @test AG.asint64(fdp_feature, 1) == typemax(Int64)
    @test AG.asdouble(fdp_feature, 2) == floatmax(Float64)
    @test AG.asstring(fdp_feature, 3) == "Hello"
    @test AG.asintlist(fdp_feature, 4) == [1, typemax(Int32)]
    @test AG.asint64list(fdp_feature, 5) == [1, typemax(Int64)]
    @test AG.asdoublelist(fdp_feature, 6) == [1.0, floatmax(Float64)]
    @test AG.asstringlist(fdp_feature, 7) == ["Hello", "World"]
    @test AG.asbinary(fdp_feature, 8) == Vector{UInt8}("Hello")
    @test AG.asdatetime(fdp_feature, 9) == DateTime(2022, 1, 14, 7, 10, 1)
    @test AG.getfield(fdp_feature, nothing) === missing
    @test AG.toWKT(AG.getgeom(fdp_feature, 0)) == "POINT (100 0)"
    @test AG.toWKT(AG.getgeom(fdp_feature, "")) == "POINT (100 0)"
end

@testset "Unit testing of Table object and its Tables.jl interface" begin
    # Helper functions
    toWKT_withmissings(::Missing) = missing
    toWKT_withmissings(x::AG.AbstractGeometry) = AG.toWKT(x)
    toWKT_withmissings(x::Any) = x
    function toWKT_withmissings(
        x::T,
    ) where {T<:NamedTuple{N,<:Tuple{Vararg{Vector}}}} where {N}
        return NamedTuple([k => toWKT_withmissings.(x[k]) for k in keys(x)])
    end

    @testset "Unit testing of Table object constructors" begin
        # Table constructor from AG standard layer type
        @test string(
            toWKT_withmissings(
                AG.Table(
                    AG.getlayer(AG.read("data/unset_null_testcase.geojson")),
                ).cols,
            ),
        ) == string(
            NamedTuple([
                Symbol("") => Union{Missing,String}[
                    "POINT (100 0)",
                    "POINT (100.2785 0.0893)",
                    "POINT (100 0)",
                    missing,
                ],
                :FID => [2.0, 3.0, 0.0, 3.0],
                :pointname => Union{Missing,Nothing,String}[
                    "point-a",
                    nothing,
                    missing,
                    "b",
                ],
            ]),
        )

        # Table constructors from from dataset
        @test string(
            toWKT_withmissings(
                AG.Table(AG.read("data/unset_null_testcase.geojson"), 0).cols,
            ),
        ) == string(
            NamedTuple([
                Symbol("") => Union{Missing,String}[
                    "POINT (100 0)",
                    "POINT (100.2785 0.0893)",
                    "POINT (100 0)",
                    missing,
                ],
                :FID => [2.0, 3.0, 0.0, 3.0],
                :pointname => Union{Missing,Nothing,String}[
                    "point-a",
                    nothing,
                    missing,
                    "b",
                ],
            ]),
        )
        @test string(
            toWKT_withmissings(
                AG.Table(AG.read("data/unset_null_testcase.geojson")).cols,
            ),
        ) == string(
            NamedTuple([
                Symbol("") => Union{Missing,String}[
                    "POINT (100 0)",
                    "POINT (100.2785 0.0893)",
                    "POINT (100 0)",
                    missing,
                ],
                :FID => [2.0, 3.0, 0.0, 3.0],
                :pointname => Union{Missing,Nothing,String}[
                    "point-a",
                    nothing,
                    missing,
                    "b",
                ],
            ]),
        )

        # Table constructors from a file
        @test string(
            toWKT_withmissings(
                AG.Table("data/unset_null_testcase.geojson", 0).cols,
            ),
        ) == string(
            NamedTuple([
                Symbol("") => Union{Missing,String}[
                    "POINT (100 0)",
                    "POINT (100.2785 0.0893)",
                    "POINT (100 0)",
                    missing,
                ],
                :FID => [2.0, 3.0, 0.0, 3.0],
                :pointname => Union{Missing,Nothing,String}[
                    "point-a",
                    nothing,
                    missing,
                    "b",
                ],
            ]),
        )
        @test string(
            toWKT_withmissings(
                AG.Table("data/unset_null_testcase.geojson").cols,
            ),
        ) == string(
            NamedTuple([
                Symbol("") => Union{Missing,String}[
                    "POINT (100 0)",
                    "POINT (100.2785 0.0893)",
                    "POINT (100 0)",
                    missing,
                ],
                :FID => [2.0, 3.0, 0.0, 3.0],
                :pointname => Union{Missing,Nothing,String}[
                    "point-a",
                    nothing,
                    missing,
                    "b",
                ],
            ]),
        )
    end

    @testset "Tables interface for AG.Table" begin
        table = AG.Table("data/unset_null_testcase.geojson")
        @test Tables.istable(table) == true
        @test Tables.schema(table) == Tables.Schema(
            (Symbol(""), :FID, :pointname),
            Tuple{
                Union{Missing,AG.IGeometry{AG.wkbPoint}},
                Float64,
                Union{Missing,Nothing,String},
            },
        )
        @test Tables.rowaccess(table) == true
        @test Tables.columnaccess(table) == true
        @test string(toWKT_withmissings(Tables.columns(table))) ==
              string(toWKT_withmissings(table.cols))
        @test string(
            toWKT_withmissings(Tables.columntable(Tables.rows(table))),
        ) == string(toWKT_withmissings(table.cols))
    end
end
