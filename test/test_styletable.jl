using FactCheck
import ArchGDAL; const AG = ArchGDAL

facts("Testing StyleTable Methods") do
    AG.createstylemanager() do sm
        @fact AG.initialize!(sm) --> true
        @fact AG.npart(sm) --> 0
        @fact AG.initialize!(sm, "PEN(w:2px,c:#000000,id:\"mapinfo-pen-2,ogr-pen-0\")") --> true
        AG.getpart(sm, 0) do st
            @fact AG.getstylestring(st) --> "PEN(w:2px,c:#000000,id:\"mapinfo-pen-2,ogr-pen-0\")"
            @fact AG.getrgba(st, "#123456") --> (18, 52, 86, 255)
        end
        @fact AG.npart(sm) --> 1
        @fact AG.addstyle!(sm, "name1", "style1") --> false
        @fact AG.npart(sm) --> 1
        @fact AG.addstyle!(sm, "name2") --> false
        @fact AG.npart(sm) --> 1

        AG.createstyletool(AG.OGRSTCBrush) do st
            @fact AG.gettype(st) --> AG.OGRSTCBrush
            @fact AG.getunit(st) --> AG.OGRSTUMM
            AG.setunit!(st, AG.OGRSTUPixel, 2.0)
            @fact AG.getunit(st) --> AG.OGRSTUPixel

            AG.setparam!(st, 0, 0)
                @fact AG.asint(st, 0) --> 0
                @fact AG.asstring(st, 0) --> "0"
                @fact AG.asdouble(st, 0) --> 0
            AG.setparam!(st, 1, 12)
                @fact AG.asint(st, 1) --> 12
                @fact AG.asstring(st, 1) --> "12"
                @fact AG.asdouble(st, 1) --> 12
            AG.setparam!(st, 2, "foo")
                @fact AG.asstring(st, 2) --> "foo"
            AG.setparam!(st, 3, 0.5)
                @fact AG.asdouble(st, 3) --> roughly(0.5)

            @fact AG.npart(sm) --> 1
            AG.addpart!(sm, st)
            @fact AG.npart(sm) --> 2
            @fact AG.npart(sm, "some stylestring") --> 1
        end

        AG.createstyletable() do stbl
            AG.addstyle!(stbl, "name1", "style1")
            AG.addstyle!(stbl, "name2", "style2")
            AG.addstyle!(stbl, "name3", "style3")
            AG.addstyle!(stbl, "name4", "style4")
            @fact AG.find(stbl, "name3") --> "style3"
            @fact AG.laststyle(stbl) --> ""
            @fact AG.nextstyle(stbl) --> "style1"
            @fact AG.nextstyle(stbl) --> "style2"
            AG.resetreading!(stbl)
            @fact AG.nextstyle(stbl) --> "style1"
            AG.savestyletable(stbl, "tmp/styletable.txt")
        end
        AG.createstyletable() do stbl
            AG.loadstyletable!(stbl, "tmp/styletable.txt")
            @fact AG.find(stbl, "name3") --> "style3"
            @fact AG.laststyle(stbl) --> ""
            @fact AG.nextstyle(stbl) --> "style1"
            @fact AG.nextstyle(stbl) --> "style2"
            AG.resetreading!(stbl)
            @fact AG.nextstyle(stbl) --> "style1"
        end
        rm("tmp/styletable.txt")
    end
end

# Untested: initialize!(stylemanager::StyleManager, feature::Feature)