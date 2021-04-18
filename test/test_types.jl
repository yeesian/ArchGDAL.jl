using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Testing GDAL Type Methods" begin
    @testset "GDAL Open Flags" begin
        @test AG.OF_ReadOnly | 0x04 == 0x04
        @test 0x06 | AG.OF_ReadOnly == 0x06
        @test AG.OF_ReadOnly | AG.OF_GNM == GDAL.GDAL_OF_READONLY | GDAL.GDAL_OF_GNM
    end

    @testset "GDAL Data Types" begin
        @test AG.typesize(GDAL.GDT_UInt16) == 16
        @test AG.typename(GDAL.GDT_UInt16) == "UInt16"
        @test AG.gettype("UInt16") == GDAL.GDT_UInt16

        @test AG.typeunion(GDAL.GDT_UInt16, GDAL.GDT_Byte) == GDAL.GDT_UInt16
        @test AG.iscomplex(GDAL.GDT_Float32) == false

        @test AG.datatype(GDAL.GDT_Int16) == Int16
        @test_throws ErrorException("Unknown GDALDataType: GDT_TypeCount") AG.datatype(GDAL.GDT_TypeCount)
        @test AG.gdaltype(Int16) == GDAL.GDT_Int16
        @test_throws ErrorException("Unknown DataType: String") AG.gdaltype(String)
    end

    @testset "GDAL Colors and Palettes" begin
        @test AG.getname(GDAL.GARIO_COMPLETE) == "COMPLETE"
        @test AG.asyncstatustype("COMPLETE") == GDAL.GARIO_COMPLETE
        @test AG.asyncstatustype("ERROR") == GDAL.GARIO_ERROR
        @test AG.asyncstatustype("PENDING") == GDAL.GARIO_PENDING
        @test AG.asyncstatustype("UPDATE") == GDAL.GARIO_UPDATE

        @test AG.colorinterp("Hue") == GDAL.GCI_HueBand
        @test AG.colorinterp("Red") == GDAL.GCI_RedBand
        @test AG.colorinterp("Blue") == GDAL.GCI_BlueBand

        @test AG.getname(GDAL.GPI_Gray) == "Gray"
        @test AG.getname(GDAL.GPI_RGB) == "RGB"
        @test AG.getname(GDAL.GPI_CMYK) == "CMYK"
        @test AG.getname(GDAL.GPI_HLS) == "HLS"
    end

    @testset "GDAL Field Types" begin
        @test AG.getname(AG.OFTString) == "String"
        @test AG.getname(AG.OFTIntegerList) == "IntegerList"
        @test AG.getname(GDAL.OFSTBoolean) == "Boolean"
        @test AG.getname(GDAL.OFSTFloat32) == "Float32"

        @test AG.arecompatible(AG.OFTReal, GDAL.OFSTNone) == true
        @test AG.arecompatible(AG.OFTReal, GDAL.OFSTBoolean) == false
        @test AG.arecompatible(AG.OFTReal, GDAL.OFSTInt16) == false
        @test AG.arecompatible(AG.OFTReal, GDAL.OFSTFloat32) == true

        @test AG.datatype(AG.OFTString) == String
        @test AG.gdaltype(GDAL.OFTMaxType) == AG.OFTInteger64List
    end
end
