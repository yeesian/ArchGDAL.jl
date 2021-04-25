using Test
import ArchGDAL; const AG = ArchGDAL

@testset "test_types.jl" begin

@testset "Testing GDAL Type Methods" begin
    @testset "GDAL Open Flags" begin
        @test AG.OF_READONLY | 0x04 == 0x04
        @test 0x06 | AG.OF_READONLY == 0x06
        @test AG.OF_READONLY | AG.OF_GNM == AG.OF_READONLY | AG.OF_GNM
    end

    @testset "GDAL Data Types" begin
        @test AG.typesize(AG.GDT_UInt16) == 16
        @test AG.typename(AG.GDT_UInt16) == "UInt16"
        @test AG.gettype("UInt16") == AG.GDT_UInt16

        @test AG.typeunion(AG.GDT_UInt16, AG.GDT_Byte) == AG.GDT_UInt16
        @test AG.iscomplex(AG.GDT_Float32) == false
    end

    @testset "GDAL Colors and Palettes" begin
        @test AG.getname(AG.GARIO_COMPLETE) == "COMPLETE"
        @test AG.asyncstatustype("COMPLETE") == AG.GARIO_COMPLETE
        @test AG.asyncstatustype("ERROR") == AG.GARIO_ERROR
        @test AG.asyncstatustype("PENDING") == AG.GARIO_PENDING
        @test AG.asyncstatustype("UPDATE") == AG.GARIO_UPDATE

        @test AG.colorinterp("Hue") == AG.GCI_HueBand
        @test AG.colorinterp("Red") == AG.GCI_RedBand
        @test AG.colorinterp("Blue") == AG.GCI_BlueBand

        @test AG.getname(AG.GPI_Gray) == "Gray"
        @test AG.getname(AG.GPI_RGB) == "RGB"
        @test AG.getname(AG.GPI_CMYK) == "CMYK"
        @test AG.getname(AG.GPI_HLS) == "HLS"
    end

    @testset "GDAL Field Types" begin
        @test AG.getname(AG.OFTString) == "String"
        @test AG.getname(AG.OFTIntegerList) == "IntegerList"
        @test AG.getname(AG.OFSTBoolean) == "Boolean"
        @test AG.getname(AG.OFSTFloat32) == "Float32"

        @test AG.arecompatible(AG.OFTReal, AG.OFSTNone) == true
        @test AG.arecompatible(AG.OFTReal, AG.OFSTBoolean) == false
        @test AG.arecompatible(AG.OFTReal, AG.OFSTInt16) == false
        @test AG.arecompatible(AG.OFTReal, AG.OFSTFloat32) == true
    end

    @testset "Base Geometry Types" begin
        @test AG.basetype(AG.wkbUnknown) == AG.wkbUnknown
        @test AG.basetype(AG.wkbPoint) == AG.wkbPoint
        @test AG.basetype(AG.wkbLineString) == AG.wkbLineString
        @test AG.basetype(AG.wkbPolygon) == AG.wkbPolygon
        @test AG.basetype(AG.wkbMultiPoint) == AG.wkbMultiPoint
        @test AG.basetype(AG.wkbMultiLineString) == AG.wkbMultiLineString
        @test AG.basetype(AG.wkbMultiPolygon) == AG.wkbMultiPolygon
        @test AG.basetype(AG.wkbGeometryCollection) == AG.wkbGeometryCollection
        @test AG.basetype(AG.wkbCircularString) == AG.wkbCircularString
        @test AG.basetype(AG.wkbCompoundCurve) == AG.wkbCompoundCurve
        @test AG.basetype(AG.wkbCurvePolygon) == AG.wkbCurvePolygon
        @test AG.basetype(AG.wkbMultiCurve) == AG.wkbMultiCurve
        @test AG.basetype(AG.wkbMultiSurface) == AG.wkbMultiSurface
        @test AG.basetype(AG.wkbCurve) == AG.wkbCurve
        @test AG.basetype(AG.wkbSurface) == AG.wkbSurface
        @test AG.basetype(AG.wkbPolyhedralSurface) == AG.wkbPolyhedralSurface
        @test AG.basetype(AG.wkbTIN) == AG.wkbTIN
        @test AG.basetype(AG.wkbTriangle) == AG.wkbTriangle
        @test AG.basetype(AG.wkbNone) == AG.wkbNone
        @test AG.basetype(AG.wkbLinearRing) == AG.wkbLinearRing
        @test AG.basetype(AG.wkbCircularStringZ) == AG.wkbCircularString
        @test AG.basetype(AG.wkbCompoundCurveZ) == AG.wkbCompoundCurve
        @test AG.basetype(AG.wkbCurvePolygonZ) == AG.wkbCurvePolygon
        @test AG.basetype(AG.wkbMultiCurveZ) == AG.wkbMultiCurve
        @test AG.basetype(AG.wkbMultiSurfaceZ) == AG.wkbMultiSurface
        @test AG.basetype(AG.wkbCurveZ) == AG.wkbCurve
        @test AG.basetype(AG.wkbSurfaceZ) == AG.wkbSurface
        @test AG.basetype(AG.wkbPolyhedralSurfaceZ) == AG.wkbPolyhedralSurface
        @test AG.basetype(AG.wkbTINZ) == AG.wkbTIN
        @test AG.basetype(AG.wkbTriangleZ) == AG.wkbTriangle
        @test AG.basetype(AG.wkbPointM) == AG.wkbPoint
        @test AG.basetype(AG.wkbLineStringM) == AG.wkbLineString
        @test AG.basetype(AG.wkbPolygonM) == AG.wkbPolygon
        @test AG.basetype(AG.wkbMultiPointM) == AG.wkbMultiPoint
        @test AG.basetype(AG.wkbMultiLineStringM) == AG.wkbMultiLineString
        @test AG.basetype(AG.wkbMultiPolygonM) == AG.wkbMultiPolygon
        @test AG.basetype(AG.wkbGeometryCollectionM) == AG.wkbGeometryCollection
        @test AG.basetype(AG.wkbCircularStringM) == AG.wkbCircularString
        @test AG.basetype(AG.wkbCompoundCurveM) == AG.wkbCompoundCurve
        @test AG.basetype(AG.wkbCurvePolygonM) == AG.wkbCurvePolygon
        @test AG.basetype(AG.wkbMultiCurveM) == AG.wkbMultiCurve
        @test AG.basetype(AG.wkbMultiSurfaceM) == AG.wkbMultiSurface
        @test AG.basetype(AG.wkbCurveM) == AG.wkbCurve
        @test AG.basetype(AG.wkbSurfaceM) == AG.wkbSurface
        @test AG.basetype(AG.wkbPolyhedralSurfaceM) == AG.wkbPolyhedralSurface
        @test AG.basetype(AG.wkbTINM) == AG.wkbTIN
        @test AG.basetype(AG.wkbTriangleM) == AG.wkbTriangle
        @test AG.basetype(AG.wkbPointZM) == AG.wkbPoint
        @test AG.basetype(AG.wkbLineStringZM) == AG.wkbLineString
        @test AG.basetype(AG.wkbPolygonZM) == AG.wkbPolygon
        @test AG.basetype(AG.wkbMultiPointZM) == AG.wkbMultiPoint
        @test AG.basetype(AG.wkbMultiLineStringZM) == AG.wkbMultiLineString
        @test AG.basetype(AG.wkbMultiPolygonZM) == AG.wkbMultiPolygon
        @test AG.basetype(AG.wkbGeometryCollectionZM) == AG.wkbGeometryCollection
        @test AG.basetype(AG.wkbCircularStringZM) == AG.wkbCircularString
        @test AG.basetype(AG.wkbCompoundCurveZM) == AG.wkbCompoundCurve
        @test AG.basetype(AG.wkbCurvePolygonZM) == AG.wkbCurvePolygon
        @test AG.basetype(AG.wkbMultiCurveZM) == AG.wkbMultiCurve
        @test AG.basetype(AG.wkbMultiSurfaceZM) == AG.wkbMultiSurface
        @test AG.basetype(AG.wkbCurveZM) == AG.wkbCurve
        @test AG.basetype(AG.wkbSurfaceZM) == AG.wkbSurface
        @test AG.basetype(AG.wkbPolyhedralSurfaceZM) == AG.wkbPolyhedralSurface
        @test AG.basetype(AG.wkbTINZM) == AG.wkbTIN
        @test AG.basetype(AG.wkbTriangleZM) == AG.wkbTriangle
        @test AG.basetype(AG.wkbPoint25D) == AG.wkbPoint
        @test AG.basetype(AG.wkbLineString25D) == AG.wkbLineString
        @test AG.basetype(AG.wkbPolygon25D) == AG.wkbPolygon
        @test AG.basetype(AG.wkbMultiPoint25D) == AG.wkbMultiPoint
        @test AG.basetype(AG.wkbMultiLineString25D) == AG.wkbMultiLineString
        @test AG.basetype(AG.wkbMultiPolygon25D) == AG.wkbMultiPolygon
        @test AG.basetype(AG.wkbGeometryCollection25D) == AG.wkbGeometryCollection
    end
end

end
