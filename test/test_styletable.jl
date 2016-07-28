using FactCheck
import ArchGDAL; const AG = ArchGDAL

facts("Testing StyleTable Methods") do
    AG.registerdrivers() do
        AG.createstylemanager() do sm
            AG.initialize!(sm)
            @fact AG.npart(sm) --> 0
            AG.initialize!(sm, "some stylestring")
            @fact AG.npart(sm) --> 1
            AG.addstyle!(sm,"name1","style1")
            @fact AG.npart(sm) --> 1
            AG.addstyle!(sm,"name2")
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

                @fact AG.npart(sm) --> 1
                AG.addpart!(sm, st)
                @fact AG.npart(sm) --> 2
                @fact AG.npart(sm, "some stylestring") --> 1
                println(AG.getpart(sm, 1))
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
end

# initialize!(stylemanager::StyleManager, feature::Feature)
# getpart(stylemanager::StyleManager,id::Integer,stylestring::AbstractString)
# getrgba(styletool::StyleTool,color::AbstractString)
