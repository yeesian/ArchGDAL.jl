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
end

end
