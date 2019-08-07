using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Test methods for rasterband" begin
    AG.read("data/utmsmall.tif") do dataset
        ds_result = """
        GDAL Dataset (Driver: GTiff/GeoTIFF)
        File(s): 
          data/utmsmall.tif

        Dataset (width x height): 100 x 100 (pixels)
        Number of raster bands: 1
          [GA_ReadOnly] Band 1 (Gray): 100 x 100 (UInt8)
        """
        @test sprint(print, dataset) == ds_result
        rb = AG.getband(dataset, 1)
        sprint(print, rb) == """
        [GA_ReadOnly] Band 1 (Gray): 100 x 100 (UInt8)
        blocksize: 100×81, nodata: -1.0e10, units: 1.0px + 0.0
        overviews: """
        @test sprint(print, AG.getdataset(rb)) == ds_result

        @test AG.getunittype(rb) == ""
        AG.setunittype!(rb,"ft")
        @test AG.getunittype(rb) == "ft"
        AG.setunittype!(rb,"")
        @test AG.getunittype(rb) == ""

        @test AG.getoffset(rb) == 0
        AG.setoffset!(rb, 10)
        @test AG.getoffset(rb) ≈ 10
        AG.setoffset!(rb, 0)
        @test AG.getoffset(rb) ≈ 0

        @test AG.getscale(rb) == 1
        AG.setscale!(rb, 0.5)
        @test AG.getscale(rb) ≈ 0.5
        AG.setscale!(rb, 2)
        @test AG.getscale(rb) ≈ 2
        AG.setscale!(rb, 1)
        @test AG.getscale(rb) ≈ 1

        @test AG.getnodatavalue(rb) ≈ -1e10
        AG.setnodatavalue!(rb, -100)
        @test AG.getnodatavalue(rb) ≈ -100
        AG.deletenodatavalue!(rb)
        @test AG.getnodatavalue(rb) ≈ -1e10

        AG.copy(dataset) do dest
            destband = AG.getband(dest, 1)
            AG.copywholeraster!(rb, destband)
            @test sprint(print, destband) == """
            [GA_Update] Band 1 (Gray): 100 x 100 (UInt8)
                blocksize: 100×81, nodata: -1.0e10, units: 1.0px + 0.0
                overviews: """
            @test AG.noverview(destband) == 0
            AG.buildoverviews!(dest, Cint[2, 4, 8])
            @test AG.noverview(destband) == 3
            @test sprint(print, destband) == """
            [GA_Update] Band 1 (Gray): 100 x 100 (UInt8)
                blocksize: 100×81, nodata: -1.0e10, units: 1.0px + 0.0
                overviews: (0) 50x50 (1) 25x25 (2) 13x13 
                           """
            @test AG.getcolorinterp(destband) == GDAL.GCI_GrayIndex
            AG.setcolorinterp!(destband, GDAL.GCI_RedBand)
            @test AG.getcolorinterp(destband) == GDAL.GCI_RedBand

            @test sprint(print, AG.getsampleoverview(destband, 100)) == """
            [GA_Update] Band 1 (Gray): 13 x 13 (UInt8)
                blocksize: 128×128, nodata: -1.0e10, units: 1.0px + 0.0
                overviews: """
            @test sprint(print, AG.getsampleoverview(destband, 200)) == """
            [GA_Update] Band 1 (Gray): 25 x 25 (UInt8)
                blocksize: 128×128, nodata: -1.0e10, units: 1.0px + 0.0
                overviews: """
            @test sprint(print, AG.getsampleoverview(destband, 500)) == """
            [GA_Update] Band 1 (Gray): 25 x 25 (UInt8)
                blocksize: 128×128, nodata: -1.0e10, units: 1.0px + 0.0
                overviews: """
            AG.getsampleoverview(destband, 1000) do sampleoverview
                @test sprint(print, sampleoverview) == """
                [GA_Update] Band 1 (Gray): 50 x 50 (UInt8)
                    blocksize: 128×128, nodata: -1.0e10, units: 1.0px + 0.0
                    overviews: """
            end
            @test sprint(print, AG.getmaskband(destband)) == """
            [GA_ReadOnly] Band 0 (Undefined): 100 x 100 (UInt8)
                blocksize: 100×81, nodata: -1.0e10, units: 1.0px + 0.0
                overviews: """
            @test AG.maskflags(destband) == 1
            AG.createmaskband!(destband, 3)
            AG.getmaskband(destband) do maskband
                @test sprint(print, maskband) == """
                [GA_Update] Band 1 (Gray): 100 x 100 (UInt8)
                    blocksize: 100×81, nodata: -1.0e10, units: 1.0px + 0.0
                    overviews: """
            end
            @test AG.maskflags(destband) == 3
            AG.fillraster!(destband, 3)
            AG.setcategorynames!(destband, ["foo","bar"])
            @test AG.getcategorynames(destband) == ["foo", "bar"]

            AG.getoverview(destband, 0) do overview
                AG.regenerateoverviews!(destband, [
                    overview,
                    AG.getoverview(destband, 2)
                ])
            end

            AG.createcolortable(GDAL.GPI_RGB) do ct
                AG.createcolorramp!(ct,
                    128, GDAL.GDALColorEntry(0,0,0,0),
                    255, GDAL.GDALColorEntry(0,0,255,0)
                )
                AG.setcolortable!(destband, ct)
                @test AG.ncolorentry(ct) == 256
                AG.getcolortable(destband) do ct2
                    @test AG.ncolorentry(ct) == AG.ncolorentry(ct2)
                end
                AG.clearcolortable!(destband)
                
                AG.createRAT(ct) do rat
                    AG.setdefaultRAT!(destband, rat)
                    @test AG.getdefaultRAT(destband) != C_NULL
                end
            end
        end
    end
end

# untested
# setcategorynames!(rasterband, names)
# getcolortable(band) do C_NULL
