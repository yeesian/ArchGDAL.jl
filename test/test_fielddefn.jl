using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Tests for field defn" begin
    AG.createfielddefn("fieldname",GDAL.OFTInteger) do fd
        println(fd)
        println("name: $(AG.getname(fd))")
        println("Setting name to \"newname\"")
        AG.setname!(fd, "newname")
        println(AG.getname(fd))
        println("type: $(AG.gettype(fd))")
        println("Setting name to $(GDAL.OFTDate)")
        AG.settype!(fd, GDAL.OFTDate)
        println(AG.gettype(fd))
        AG.settype!(fd, GDAL.OFTInteger)
        @test AG.getsubtype(fd) == GDAL.OFSTNone
        AG.setsubtype!(fd, GDAL.OFSTInt16)
        @test AG.getsubtype(fd) == GDAL.OFSTInt16
        AG.setsubtype!(fd, GDAL.OFSTBoolean)
        @test AG.getsubtype(fd) == GDAL.OFSTBoolean
        AG.setsubtype!(fd, GDAL.OFSTNone)
        @test AG.getjustify(fd) == GDAL.OJUndefined
        AG.setjustify!(fd, GDAL.OJLeft)
        @test AG.getjustify(fd) == GDAL.OJLeft
        println("width: $(AG.getwidth(fd))")
        AG.setwidth!(fd, 10)
        println("after setting width to 10: new width=$(AG.getwidth(fd))")
        println("precision: $(AG.getprecision(fd))")
        AG.setprecision!(fd, 20)
        println("after setting to 20: new precision=$(AG.getprecision(fd))")
        AG.setparams!(fd, "finalname", GDAL.OFTDate, nwidth=5, nprecision=2,
                      justify=GDAL.OJRight)
        println("type: $((AG.gettype(fd),AG.getname(fd),AG.getsubtype(fd),
                          AG.getjustify(fd),AG.getwidth(fd),AG.getprecision(fd)))")
        @test AG.isignored(fd) == false
        AG.setignored!(fd, true)
        @test AG.isignored(fd) == true
        AG.setignored!(fd, false)
        @test AG.isignored(fd) == false

        @test AG.isnullable(fd) == true
        AG.setnullable!(fd, false)
        @test AG.isnullable(fd) == false
        AG.setnullable!(fd, true)
        @test AG.isnullable(fd) == true

        @test AG.getdefault(fd) == ""
        AG.setdefault!(fd, "0001/01/01 00:00:00")
        @test AG.getdefault(fd) == "0001/01/01 00:00:00"
        @test AG.isdefaultdriverspecific(fd) == true
    end
end

@testset "Tests for Geom Field Defn" begin
    AG.creategeomfielddefn("geomname", GDAL.wkbPolygon) do gfd
        @test AG.getname(gfd) == "geomname"
        AG.setname!(gfd, "my name!")
        @test AG.getname(gfd) == "my name!"

        @test AG.gettype(gfd) == GDAL.wkbPolygon
        AG.settype!(gfd, GDAL.wkbPolyhedralSurface)
        @test AG.gettype(gfd) == GDAL.wkbPolyhedralSurface

        println(AG.getspatialref(gfd))
        # AG.setspatialref!(gfd, AG.unsafe_fromEPSG(4326))
        # println(AG.getspatialref(gfd))

        @test AG.isignored(gfd) == false
        AG.setignored!(gfd, true)
        @test AG.isignored(gfd) == true
        AG.setignored!(gfd, false)
        @test AG.isignored(gfd) == false

        @test AG.isnullable(gfd) == true
        AG.setnullable!(gfd, false)
        @test AG.isnullable(gfd) == false
        AG.setnullable!(gfd, true)
        @test AG.isnullable(gfd) == true
    end
end

@testset "Tests for Feature Defn" begin
    AG.createfeaturedefn("new_feature") do fd
        println(AG.nreference(fd))
        AG.reference(fd)
        println(AG.nreference(fd))
        AG.reference(fd)
        println(AG.nreference(fd))
        AG.reference(fd)
        println(AG.nreference(fd))
        AG.release(fd)
        println(AG.nreference(fd))
        AG.dereference(fd)
        println(AG.nreference(fd))
        AG.dereference(fd)
        AG.createfielddefn("fieldname",GDAL.OFTInteger) do fielddef
            @test AG.nfield(fd) == 0
            AG.addfielddefn!(fd, fielddef)
            @test AG.nfield(fd) == 1
            AG.addfielddefn!(fd, fielddef)
            @test AG.nfield(fd) == 2
            AG.addfielddefn!(fd, fielddef)
            @test AG.nfield(fd) == 3
            AG.createfielddefn("newfield",GDAL.OFTInteger) do fielddef2
                AG.addfielddefn!(fd, fielddef2)
                @test AG.nfield(fd) == 4
                for i in 0:3
                    println("$i : $(AG.getname(AG.getfielddefn(fd,i)))")
                end
            end
            AG.deletefielddefn!(fd, 0)
            @test AG.nfield(fd) == 3
            for i in 0:2
                println("$i : $(AG.getname(AG.getfielddefn(fd,i)))")
            end
            println("After reordering (in reverse):")
            AG.reorderfielddefns!(fd, Cint[2,1,0])
            @test AG.nfield(fd) == 3
            for i in 0:2
                println("$i : $(AG.getname(AG.getfielddefn(fd,i)))")
            end
        end
        @test AG.ngeomfield(fd) == 1
        @test AG.getgeomtype(fd) == GDAL.wkbUnknown
        AG.setgeomtype!(fd, GDAL.wkbPolygon)
        @test AG.getgeomtype(fd) == GDAL.wkbPolygon
        @test AG.ngeomfield(fd) == 1

        @test AG.isgeomignored(fd) == false
        AG.setgeomignored!(fd, true)
        @test AG.isgeomignored(fd) == true
        AG.setgeomignored!(fd, false)
        @test AG.isgeomignored(fd) == false

        @test AG.isstyleignored(fd) == false
        AG.setstyleignored!(fd, true)
        @test AG.isstyleignored(fd) == true
        AG.setstyleignored!(fd, false)
        @test AG.isstyleignored(fd) == false

        @test AG.getgeomfieldindex(fd) == 0
        gfd0 = AG.getgeomfielddefn(fd, 0)
        @test AG.ngeomfield(fd) == 1
        AG.addgeomfielddefn!(fd, gfd0)
        @test AG.ngeomfield(fd) == 2
        gfd1 = AG.getgeomfielddefn(fd, 1)
        AG.setname!(gfd0, "name0")
        AG.setname!(gfd1, "name1")
        @test AG.getgeomfieldindex(fd, "") == -1
        @test AG.getgeomfieldindex(fd, "name0") == 0
        @test AG.getgeomfieldindex(fd, "name1") == 1
        AG.deletegeomfielddefn!(fd, 0)
        @test AG.ngeomfield(fd) == 1
        @test AG.getgeomfieldindex(fd, "") == -1
        @test AG.getgeomfieldindex(fd, "name0") == -1
        @test AG.getgeomfieldindex(fd, "name1") == 0
        @test AG.nreference(fd) == 0
        AG.createfeature(fd) do f
            @test AG.nreference(fd) == 2 # artificially inflated
            @test AG.issame(AG.getfeaturedefn(f), fd) == true
        end
        @test AG.nreference(fd) == 0
    end
end