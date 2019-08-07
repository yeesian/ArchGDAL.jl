using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Testing Raster Attribute Tables" begin
    AG.createRAT() do rat
        @test AG.ncolumn(rat) == 0
        @test AG.nrow(rat) == 0
        @test AG.changesarewrittentofile(rat) == false
        
        AG.createcolumn!(rat, "col1", GDAL.GFT_Integer, GDAL.GFU_Generic)
        @test AG.ncolumn(rat) == 1
        @test AG.columnname(rat, 0) == "col1"
        @test AG.columnusage(rat, 0) == GDAL.GFU_Generic
        @test AG.columntype(rat, 0) == GDAL.GFT_Integer
        @test AG.findcolumnindex(rat, GDAL.GFU_Generic) == 0
        @test AG.findcolumnindex(rat, GDAL.GFU_Red) == -1
        
        AG.createcolumn!(rat, "col2", GDAL.GFT_Real, GDAL.GFU_MinMax)
        AG.createcolumn!(rat, "col3", GDAL.GFT_String, GDAL.GFU_PixelCount)
        @test AG.ncolumn(rat) == 3
        @test AG.nrow(rat) == 0
        AG.setrowcount!(rat, 5)
        @test AG.nrow(rat) == 5

        @test AG.attributeio!(rat, GDAL.GF_Read, 0, 0, 5, Array{Cint}(undef, 5)) ==
            fill(0,5)
        @test AG.attributeio!(rat, GDAL.GF_Read, 0, 0, 5, Array{Float64}(undef, 5)) ==
            fill(0,5)
        @test AG.attributeio!(rat, GDAL.GF_Read, 1, 0, 5, Array{Float64}(undef, 5)) ==
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
        AG.attributeio!(rat, GDAL.GF_Write, 2, 0, 5, fill("abc",5))
        @test AG.asstring(rat, 0, 2) == "abc"
        @test AG.asstring(rat, 2, 2) == "abc"
        @test AG.asstring(rat, 4, 2) == "abc"
        
        AG.clone(rat) do ratclone
            @test AG.asstring(ratclone, 0, 2) == "abc"
            @test AG.asstring(ratclone, 2, 2) == "abc"
            @test AG.asstring(ratclone, 4, 2) == "abc"
            @test AG.ncolumn(ratclone) == 3
            @test AG.nrow(ratclone) == 5
            @test AG.findcolumnindex(ratclone, GDAL.GFU_Generic) == 0
            @test AG.findcolumnindex(ratclone, GDAL.GFU_Red) == -1
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
    AG.createcolortable(GDAL.GPI_RGB) do ct
        @test AG.getpaletteinterp(ct) == GDAL.GPI_RGB
        @test AG.ncolorentry(ct) == 0
        AG.createcolorramp!(ct, 128, GDAL.GDALColorEntry(0,0,0,0),
                                255, GDAL.GDALColorEntry(0,0,255,0))
        @test AG.ncolorentry(ct) == 256
        @test sprint(print, AG.getcolorentry(ct, 0)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
        @test sprint(print, AG.getcolorentry(ct, 128)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
        @test sprint(print, AG.getcolorentry(ct, 200)) == "GDAL.GDALColorEntry(0, 0, 144, 0)"
        @test sprint(print, AG.getcolorentry(ct, 255)) == "GDAL.GDALColorEntry(0, 0, 255, 0)"

        @test sprint(print, AG.getcolorentryasrgb(ct, 0)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
        @test sprint(print, AG.getcolorentryasrgb(ct, 128)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
        @test sprint(print, AG.getcolorentryasrgb(ct, 200)) == "GDAL.GDALColorEntry(0, 0, 144, 0)"
        @test sprint(print, AG.getcolorentryasrgb(ct, 255)) == "GDAL.GDALColorEntry(0, 0, 255, 0)"
        
        AG.setcolorentry!(ct, 255, GDAL.GDALColorEntry(0,0,100,0))
        @test sprint(print, AG.getcolorentry(ct, 255)) == "GDAL.GDALColorEntry(0, 0, 100, 0)"

        AG.clone(ct) do ctclone
            @test AG.getpaletteinterp(ctclone) == GDAL.GPI_RGB
            @test AG.ncolorentry(ctclone) == 256
            @test sprint(print, AG.getcolorentry(ctclone, 0)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
            @test sprint(print, AG.getcolorentry(ctclone, 128)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
            @test sprint(print, AG.getcolorentry(ctclone, 200)) == "GDAL.GDALColorEntry(0, 0, 144, 0)"
            @test sprint(print, AG.getcolorentry(ctclone, 255)) == "GDAL.GDALColorEntry(0, 0, 100, 0)"
            
            AG.createRAT(ctclone) do rat
                ct2 = AG.toColorTable(rat)
                @test AG.getpaletteinterp(ct2) == GDAL.GPI_RGB
                @test AG.ncolorentry(ct2) == 256
                @test sprint(print, AG.getcolorentry(ct2, 0)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
                @test sprint(print, AG.getcolorentry(ct2, 128)) == "GDAL.GDALColorEntry(0, 0, 0, 0)"
                @test sprint(print, AG.getcolorentry(ct2, 200)) == "GDAL.GDALColorEntry(0, 0, 144, 0)"
                @test sprint(print, AG.getcolorentry(ct2, 255)) == "GDAL.GDALColorEntry(0, 0, 100, 0)"
            end
        end
    end
end
