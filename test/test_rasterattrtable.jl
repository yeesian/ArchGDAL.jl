using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "test_rasterattrtable.jl" begin

@testset "Testing Raster Attribute Tables" begin
    AG.createRAT() do rat
        @test AG.ncolumn(rat) == 0
        @test AG.nrow(rat) == 0
        @test AG.changesarewrittentofile(rat) == false
        
        AG.createcolumn!(rat, "col1", AG.GFT_Integer, AG.GFU_Generic)
        @test AG.ncolumn(rat) == 1
        @test AG.columnname(rat, 0) == "col1"
        @test AG.columnusage(rat, 0) == AG.GFU_Generic
        @test AG.columntype(rat, 0) == AG.GFT_Integer
        @test AG.findcolumnindex(rat, AG.GFU_Generic) == 0
        @test AG.findcolumnindex(rat, AG.GFU_Red) == -1
        
        AG.createcolumn!(rat, "col2", AG.GFT_Real, AG.GFU_MinMax)
        AG.createcolumn!(rat, "col3", AG.GFT_String, AG.GFU_PixelCount)
        @test AG.ncolumn(rat) == 3
        @test AG.nrow(rat) == 0
        AG.setrowcount!(rat, 5)
        @test AG.nrow(rat) == 5

        @test AG.attributeio!(rat, AG.GF_Read, 0, 0, 5, Array{Cint}(undef, 5)) ==
            fill(0,5)
        @test AG.attributeio!(rat, AG.GF_Read, 0, 0, 5, Array{Float64}(undef, 5)) ==
            fill(0,5)
        @test AG.attributeio!(rat, AG.GF_Read, 1, 0, 5, Array{Float64}(undef, 5)) ==
            fill(0,5)

        @test AG.asstring(rat, 2, 0) == "0"
        @test AG.asint(rat, 2, 0) == 0
        @test AG.asdouble(rat, 2, 0) == 0
        
        AG.setvalue!(rat, 2, 0, "2")
        @test AG.asstring(rat, 2, 0) == "2"
        @test AG.asint(rat, 2, 0) == 2
        @test AG.asdouble(rat, 2, 0) == 2

        AG.setvalue!(rat, 2, 0, 3)
        @test AG.asstring(rat, 2, 0) == "3"
        @test AG.asint(rat, 2, 0) == 3
        @test AG.asdouble(rat, 2, 0) == 3
        
        AG.setvalue!(rat, 2, 0, 4.5)
        @test AG.asstring(rat, 2, 0) == "4"
        @test AG.asint(rat, 2, 0) == 4
        @test AG.asdouble(rat, 2, 0) == 4

        @test AG.asstring(rat, 2, 1) == "0"
        @test AG.asstring(rat, 2, 2) == ""

        @test AG.asstring(rat, 0, 2) == ""
        @test AG.asstring(rat, 2, 2) == ""
        @test AG.asstring(rat, 4, 2) == ""
        AG.attributeio!(rat, AG.GF_Write, 2, 0, 5, fill("abc",5))
        @test AG.asstring(rat, 0, 2) == "abc"
        @test AG.asstring(rat, 2, 2) == "abc"
        @test AG.asstring(rat, 4, 2) == "abc"
        
        AG.clone(rat) do ratclone
            @test AG.asstring(ratclone, 0, 2) == "abc"
            @test AG.asstring(ratclone, 2, 2) == "abc"
            @test AG.asstring(ratclone, 4, 2) == "abc"
            @test AG.ncolumn(ratclone) == 3
            @test AG.nrow(ratclone) == 5
            @test AG.findcolumnindex(ratclone, AG.GFU_Generic) == 0
            @test AG.findcolumnindex(ratclone, AG.GFU_Red) == -1
        end

        AG.setlinearbinning!(rat, 0, 10)
        @test AG.getlinearbinning(rat) == (0,10)
        AG.setlinearbinning!(rat, -1.5, 12.0)
        @test AG.getlinearbinning(rat) == (-1.5,12.0)
        
        @test AG.findrowindex(rat, 0) == 0
        @test AG.findrowindex(rat, -1) == 0
        @test AG.findrowindex(rat, -1.5) == 0
        @test AG.findrowindex(rat, 7.5) == 0
        @test AG.findrowindex(rat, 12) == 1
        @test AG.findrowindex(rat, 13) == 1
    end
end

@testset ("Testing Color Tables") begin
    AG.createcolortable(AG.GPI_RGB) do ct
        @test sprint(print, ct) == "ColorTable[GPI_RGB]"
        @test AG.paletteinterp(ct) == AG.GPI_RGB
        AG.clone(AG.ColorTable(C_NULL)) do ct
            @test sprint(print, ct) == "NULL ColorTable"
        end
        AG.createRAT(ct) do rat
            @test sprint(print, AG.toColorTable(rat, 0)) == "ColorTable[GPI_RGB]"
        end
    end
end

end
