using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Test methods for rasterband" begin
    AG.registerdrivers() do
        AG.read("data/utmsmall.tif") do dataset
            println(dataset)
            rb = AG.getband(dataset, 1)
            println(rb)
            println(AG.getdataset(rb))

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

            AG.createcopy(dataset, "tmp/utmsmall.tif") do dest
                destband = AG.getband(dest, 1)
                AG.copywholeraster!(rb, destband)
                println(destband)
                @test AG.noverview(destband) == 0
                AG.buildoverviews!(dest, Cint[2, 4, 8])
                @test AG.noverview(destband) == 3
                println(destband)

                @test AG.getcolorinterp(destband) == GDAL.GCI_GrayIndex
                AG.setcolorinterp!(destband, GDAL.GCI_RedBand)
                @test AG.getcolorinterp(destband) == GDAL.GCI_RedBand

                println(AG.getsampleoverview(destband, 100))
                println(AG.getsampleoverview(destband, 200))
                println(AG.getsampleoverview(destband, 500))
                println(AG.getsampleoverview(destband, 1000))
                println(AG.getmaskband(destband))
                @test AG.getmaskflags(destband) == 1
                AG.createmaskband!(destband, 3)
                println(AG.getmaskband(destband))
                @test AG.getmaskflags(destband) == 3
                AG.fillraster!(destband, 3)
                AG.setcategorynames!(destband, ["foo","bar"])
                @test AG.getcategorynames(destband) == ["foo", "bar"]

                AG.regenerateoverviews!(destband, AG.RasterBand[
                    AG.getoverview(destband, 0),
                    AG.getoverview(destband, 2)
                ])

                AG.createcolortable(GDAL.GPI_RGB) do ct
                    AG.createcolorramp!(ct,
                        128, GDAL.GDALColorEntry(0,0,0,0),
                        255, GDAL.GDALColorEntry(0,0,255,0)
                    )
                    AG.setcolortable!(destband, ct)
                    println(AG.getcolortable(destband))
                    AG.clearcolortable!(destband)
                    
                    AG.createRAT(ct) do rat
                        AG.setdefaultRAT!(destband, rat)
                        println(AG.getdefaultRAT(destband))
                    end
                end
            end

            rm("tmp/utmsmall.tif")
            rm("tmp/utmsmall.tif.aux.xml")
            rm("tmp/utmsmall.tif.msk")
        end
    end
end
