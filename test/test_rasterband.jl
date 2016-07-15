using FactCheck
import ArchGDAL; const AG = ArchGDAL

facts("Test methods for rasterband") do
    AG.registerdrivers() do
        AG.read("data/utmsmall.tif") do dataset
            println(dataset)
            rb = AG.getband(dataset, 1)
            println(rb)
            println(AG.getdataset(rb))

            @fact AG.getunittype(rb) --> ""
            AG.setunittype!(rb,"ft")
            @fact AG.getunittype(rb) --> "ft"
            AG.setunittype!(rb,"")
            @fact AG.getunittype(rb) --> ""

            @fact AG.getoffset(rb) --> 0
            AG.setoffset!(rb, 10)
            @fact AG.getoffset(rb) --> roughly(10)
            AG.setoffset!(rb, 0)
            @fact AG.getoffset(rb) --> roughly(0)

            @fact AG.getscale(rb) --> 1
            AG.setscale!(rb, 0.5)
            @fact AG.getscale(rb) --> roughly(0.5)
            AG.setscale!(rb, 2)
            @fact AG.getscale(rb) --> roughly(2)
            AG.setscale!(rb, 1)
            @fact AG.getscale(rb) --> roughly(1)

            @fact AG.getnodatavalue(rb) --> roughly(-1e10)
            AG.setnodatavalue!(rb, -100)
            @fact AG.getnodatavalue(rb) --> roughly(-100)
            AG.deletenodatavalue!(rb)
            @fact AG.getnodatavalue(rb) --> roughly(-1e10)

            AG.createcolortable(AG.GPI_RGB) do ct
                # AG.setcolortable!(rb, ct)
                # println(AG.getcolortable(rb))
                # AG.clearcolortable!(rb)
                
                AG.createRAT(ct) do rat
                    AG.setdefaultRAT!(rb, rat)
                    println(AG.getdefaultRAT(rb))
                end

                # AG.setcolorinterp!(rb, AG.GCI_RedBand)
            end

            AG.createcopy(dataset, "tmp/utmsmall.tif") do dest
                destband = AG.getband(dest, 1)
                AG.copywholeraster!(rb, destband)
                println(destband)
                @fact AG.noverview(destband) --> 0
                AG.buildoverviews!(dest, Cint[2, 4, 8])
                @fact AG.noverview(destband) --> 3
                println(destband)
                println(AG.getsampleoverview(destband, 100))
                println(AG.getsampleoverview(destband, 200))
                println(AG.getsampleoverview(destband, 500))
                println(AG.getsampleoverview(destband, 1000))
                println(AG.getmaskband(destband))
                @fact AG.getmaskflags(destband) --> 1
                AG.createmaskband!(destband, 3)
                println(AG.getmaskband(destband))
                @fact AG.getmaskflags(destband) --> 3
                AG.fillraster!(destband, 3)
                AG.setcategorynames!(destband, ["foo","bar"])
                @fact AG.getcategorynames(destband) --> ["foo", "bar"]
            end

            rm("tmp/utmsmall.tif")
            rm("tmp/utmsmall.tif.aux.xml")
            rm("tmp/utmsmall.tif.msk")
        end
    end
end
