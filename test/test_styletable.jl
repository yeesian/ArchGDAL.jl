using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Testing StyleTable Methods" begin
    AG.createstylemanager() do sm
        @test AG.initialize!(sm) == true
        @test AG.npart(sm) == 0
        @test AG.initialize!(sm, "PEN(w:2px,c:#000000,id:\"mapinfo-pen-2,ogr-pen-0\")") == true
        AG.getpart(sm, 0) do st
            @test AG.getstylestring(st) == "PEN(w:2px,c:#000000,id:\"mapinfo-pen-2,ogr-pen-0\")"
            @test AG.getrgba(st, "#123456") == (18, 52, 86, 255)
        end
        @test AG.npart(sm) == 1
        @test AG.addstyle!(sm, "name1", "style1") == false
        @test AG.npart(sm) == 1
        @test AG.addstyle!(sm, "name2") == false
        @test AG.npart(sm) == 1

        AG.createstyletool(GDAL.OGRSTCBrush) do st
            @test AG.gettype(st) == GDAL.OGRSTCBrush
            @test AG.getunit(st) == GDAL.OGRSTUMM
            AG.setunit!(st, GDAL.OGRSTUPixel, 2.0)
            @test AG.getunit(st) == GDAL.OGRSTUPixel

            AG.setparam!(st, 0, 0)
                @test AG.asint(st, 0) == 0
                @test AG.asstring(st, 0) == "0"
                @test AG.asdouble(st, 0) == 0
            AG.setparam!(st, 1, 12)
                @test AG.asint(st, 1) == 12
                @test AG.asstring(st, 1) == "12"
                @test AG.asdouble(st, 1) == 12
            AG.setparam!(st, 2, "foo")
                @test AG.asstring(st, 2) == "foo"
            AG.setparam!(st, 3, 0.5)
                @test AG.asdouble(st, 3) ≈ 0.5

            @test AG.npart(sm) == 1
            AG.addpart!(sm, st)
            @test AG.npart(sm) == 2
            @test AG.npart(sm, "some stylestring") == 1
        end

        AG.createstyletable() do stbl
            AG.addstyle!(stbl, "name1", "style1")
            AG.addstyle!(stbl, "name2", "style2")
            AG.addstyle!(stbl, "name3", "style3")
            AG.addstyle!(stbl, "name4", "style4")
            @test AG.findstylestring(stbl, "name3") == "style3"
            @test AG.laststyle(stbl) == ""
            @test AG.nextstyle(stbl) == "style1"
            @test AG.nextstyle(stbl) == "style2"
            AG.resetreading!(stbl)
            @test AG.nextstyle(stbl) == "style1"
            AG.savestyletable(stbl, "tmp/styletable.txt")
        end
        AG.createstyletable() do stbl
            AG.loadstyletable!(stbl, "tmp/styletable.txt")
            @test AG.findstylestring(stbl, "name3") == "style3"
            @test AG.laststyle(stbl) == ""
            @test AG.nextstyle(stbl) == "style1"
            @test AG.nextstyle(stbl) == "style2"
            AG.resetreading!(stbl)
            @test AG.nextstyle(stbl) == "style1"
        end
        rm("tmp/styletable.txt")
    end
end

# Untested: initialize!(stylemanager::StyleManager, feature::Feature)