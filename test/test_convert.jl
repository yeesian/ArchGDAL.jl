using Test
import ArchGDAL as AG
import GeoFormatTypes as GFT
using FixedPointNumbers

struct CustomInt <: Integer
    value::Int64
end
Base.convert(::Type{Int64}, x::CustomInt) = x.value

@testset "test_convert.jl" begin

    # Tests high level convert methods
    @testset "convert point format" begin
        point = AG.createpoint(100, 70)
        json = convert(GFT.GeoJSON, point)
        @test sprint(print, convert(AG.IGeometry, json)) ==
              "Geometry: POINT (100 70)"
        kml = convert(GFT.KML, point)
        gml = convert(GFT.GML, point)
        wkb = convert(GFT.WellKnownBinary, point)
        wkt = convert(GFT.WellKnownText, point)
        @test json.val == AG.toJSON(point)
        @test kml.val == AG.toKML(point)
        @test gml.val == AG.toGML(point)
        @test wkb.val == AG.toWKB(point)
        @test wkt.val == AG.toWKT(point)
        @test convert(GFT.GeoJSON, json) ==
              convert(GFT.GeoJSON, wkb) ==
              convert(GFT.GeoJSON, wkt) ==
              convert(GFT.GeoJSON, gml) ==
              json
        @test convert(GFT.KML, gml) == convert(GFT.KML, wkt)
    end

    @testset "convert crs format" begin
        proj4326 = GFT.ProjString("+proj=longlat +datum=WGS84 +no_defs")
        @test convert(
            GFT.ProjString,
            GFT.CRS(),
            convert(
                GFT.WellKnownText,
                GFT.CRS(),
                convert(GFT.ESRIWellKnownText, GFT.CRS(), GFT.EPSG(4326)),
            ),
        ) == proj4326
        @test convert(GFT.CoordSys, GFT.CRS(), proj4326) isa GFT.CoordSys
        @test convert(GFT.GML, GFT.CRS(), proj4326) isa GFT.GML

        epsg = GFT.EPSG(4326)
        wkt = convert(GFT.WellKnownText, epsg)
        @test convert(GFT.EPSG, wkt) == epsg

        epsg = GFT.EPSG(3013)
        wkt = convert(GFT.WellKnownText, epsg)
        @test convert(GFT.EPSG, wkt) == epsg
    end

    @testset "convert spatial refs" begin
        spref = AG.importEPSG(4326)

        @testset "to another GeoFormat" begin
            @test convert(GFT.WellKnownText, spref) isa
                  GFT.WellKnownText{GFT.CRS}
            @test convert(GFT.WellKnownText2, spref) isa
                  GFT.WellKnownText2{GFT.CRS}
            @test GFT.val(convert(GFT.WellKnownText2, spref)) ==
                  AG.toWKT2(spref)
            @test convert(GFT.EPSG, spref) == GFT.EPSG(4326)
            @test convert(GFT.ProjString, spref) isa GFT.ProjString
            @test convert(GFT.ProjJSON, spref) isa GFT.ProjJSON
            @test convert(GFT.CoordSys, spref) isa GFT.CoordSys
        end

        @testset "to a supertype is the identity" begin
            @test convert(GFT.GeoFormat, spref) === spref
            @test convert(GFT.CoordinateReferenceSystemFormat, spref) === spref
            @test convert(AG.AbstractSpatialRef, spref) === spref
            @test convert(AG.ISpatialRef, spref) === spref
            @test only(push!(GFT.GeoFormat[], spref)) === spref
        end

        @testset "from another GeoFormat" begin
            @test convert(AG.ISpatialRef, GFT.EPSG(4326)) == spref
            @test convert(AG.ISpatialRef, GFT.EPSG(4326)) isa AG.ISpatialRef
            @test convert(AG.AbstractSpatialRef, GFT.EPSG(4326)) == spref
            @test convert(AG.ISpatialRef, "EPSG:4326") == spref
            @test convert(AG.ISpatialRef, GFT.val(spref)) == spref
            # Converting to the unfinalized SpatialRef would leak.
            @test_throws ErrorException convert(AG.SpatialRef, GFT.EPSG(4326))
        end

        @testset "ESRI export does not mutate its source" begin
            before = AG.toWKT(spref)
            esri = convert(GFT.ESRIWellKnownText, spref)
            @test esri isa GFT.ESRIWellKnownText{GFT.CRS}
            @test occursin("D_WGS_1984", GFT.val(esri))
            @test AG.toWKT(spref) == before
        end
    end

    @testset "geometry conversions" begin
        geom1 = AG.createpoint(1, 2)
        @test typeof(geom1) == AG.IGeometry{AG.wkbPoint}
        geom2 = convert(AG.IGeometry{AG.wkbUnknown}, geom1)
        @test typeof(geom2) == AG.IGeometry{AG.wkbUnknown}
        @test AG.toWKT(geom1) == AG.toWKT(geom2)
    end

    @testset "type conversions" begin
        @test convert(AG.OGRFieldType, Bool) == AG.OFTInteger
        @test convert(AG.OGRFieldType, UInt8) == AG.OFTInteger
        @test convert(AG.OGRFieldType, Int8) == AG.OFTInteger
        @test convert(AG.OGRFieldType, UInt16) == AG.OFTInteger
        @test convert(AG.OGRFieldType, Int16) == AG.OFTInteger
        @test convert(AG.OGRFieldType, UInt32) == AG.OFTInteger64
        @test convert(AG.OGRFieldType, Int32) == AG.OFTInteger
        @test convert(AG.OGRFieldType, Int64) == AG.OFTInteger64
        @test convert(AG.OGRFieldType, CustomInt) == AG.OFTInteger64

        @test convert(AG.OGRFieldType, Float16) == AG.OFTReal
        @test convert(AG.OGRFieldType, Float32) == AG.OFTReal
        @test convert(AG.OGRFieldType, Float64) == AG.OFTReal
        @test convert(AG.OGRFieldType, N0f16) == AG.OFTReal

        # Reverse conversion should result in default type, not subtype
        @test convert(DataType, AG.OFSTBoolean) == Bool
        @test convert(DataType, AG.OFSTInt16) == Int16
        @test convert(DataType, AG.OFTInteger) == Int32
        @test convert(DataType, AG.OFTInteger64) == Int64
        @test convert(DataType, AG.OFSTFloat32) == Float32
        @test convert(DataType, AG.OFTReal) == Float64
        @test convert(DataType, AG.OFSTNone) == Nothing
    end
end
