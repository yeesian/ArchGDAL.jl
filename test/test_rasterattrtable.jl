using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Testing Raster Attribute Tables" begin
    AG.createRAT() do rat
        @test AG.ncolumn(rat) == 0
        @test AG.nrow(rat) == 0
        @test AG.changesarewrittentofile(rat) == false
        
        AG.createcolumn!(rat, "col1", AG.GFT_Integer, AG.GFU_Generic)
        @test AG.ncolumn(rat) == 1
        @test AG.getcolumnname(rat, 0) == "col1"
        @test AG.getcolumnusage(rat, 0) == AG.GFU_Generic
        @test AG.getcolumntype(rat, 0) == AG.GFT_Integer
        @test AG.getcolumnindex(rat, AG.GFU_Generic) == 0
        @test AG.getcolumnindex(rat, AG.GFU_Red) == -1
        
        AG.createcolumn!(rat, "col2", AG.GFT_Real, AG.GFU_MinMax)
        AG.createcolumn!(rat, "col3", AG.GFT_String, AG.GFU_PixelCount)
        @test AG.ncolumn(rat) == 3
        @test AG.nrow(rat) == 0
        AG.setrowcount!(rat, 5)
        @test AG.nrow(rat) == 5

        @test AG.attributeio!(rat, AG.GF_Read, 0, 0, 5, Array{Cint}(5)) ==
            fill(0,5)
        @test AG.attributeio!(rat, AG.GF_Read, 0, 0, 5, Array{Float64}(5)) ==
            fill(0,5)
        @test AG.attributeio!(rat, AG.GF_Read, 1, 0, 5, Array{Float64}(5)) ==
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
            @test AG.getcolumnindex(ratclone, AG.GFU_Generic) == 0
            @test AG.getcolumnindex(ratclone, AG.GFU_Red) == -1
        end

        AG.setlinearbinning!(rat, 0, 10)
        @test AG.getlinearbinning(rat) == (0,10)
        AG.setlinearbinning!(rat, -1.5, 12.0)
        @test AG.getlinearbinning(rat) == (-1.5,12.0)
        
        @test AG.getrowindex(rat, 0) == 0
        @test AG.getrowindex(rat, -1) == 0
        @test AG.getrowindex(rat, -1.5) == 0
        @test AG.getrowindex(rat, 7.5) == 0
        @test AG.getrowindex(rat, 12) == 1
        @test AG.getrowindex(rat, 13) == 1

        println(AG.serializeJSON(rat))
    end
end

@testset ("Testing Color Tables") begin
    AG.createcolortable(AG.GPI_RGB) do ct
        @test AG.getpaletteinterp(ct) == AG.GPI_RGB
        @test AG.ncolorentry(ct) == 0
        AG.createcolorramp!(ct, 128, GDAL.GDALColorEntry(0,0,0,0),
                                255, GDAL.GDALColorEntry(0,0,255,0))
        @test AG.ncolorentry(ct) == 256
        println(AG.getcolorentry(ct, 0))  # GDAL.GDALColorEntry(0,0,0,0)
        println(AG.getcolorentry(ct, 128)) # GDAL.GDALColorEntry(0,0,0,0)
        println(AG.getcolorentry(ct, 200)) # GDAL.GDALColorEntry(0,0,144,0)
        println(AG.getcolorentry(ct, 255)) # GDAL.GDALColorEntry(0,0,255,0)

        println(AG.getcolorentryasrgb(ct, 0))  # GDAL.GDALColorEntry(0,0,0,0)
        println(AG.getcolorentryasrgb(ct, 128)) # GDAL.GDALColorEntry(0,0,0,0)
        println(AG.getcolorentryasrgb(ct, 200)) # GDAL.GDALColorEntry(0,0,144,0)
        println(AG.getcolorentryasrgb(ct, 255)) # GDAL.GDALColorEntry(0,0,255,0)
        
        AG.setcolorentry!(ct, 255, GDAL.GDALColorEntry(0,0,100,0))
        println(AG.getcolorentry(ct, 255)) # GDAL.GDALColorEntry(0,0,255,0)

        AG.clone(ct) do ctclone
            @test AG.getpaletteinterp(ctclone) == AG.GPI_RGB
            @test AG.ncolorentry(ctclone) == 256
            println(AG.getcolorentry(ctclone, 0))
            println(AG.getcolorentry(ctclone, 128))
            println(AG.getcolorentry(ctclone, 200))
            println(AG.getcolorentry(ctclone, 255))
            
            AG.createRAT(ctclone) do rat
                ct2 = AG.toColorTable(rat)
                @test AG.getpaletteinterp(ct2) == AG.GPI_RGB
                @test AG.ncolorentry(ct2) == 256
                println(AG.getcolorentry(ct2, 0))
                println(AG.getcolorentry(ct2, 128))
                println(AG.getcolorentry(ct2, 200))
                println(AG.getcolorentry(ct2, 255))
            end
        end
    end
end
