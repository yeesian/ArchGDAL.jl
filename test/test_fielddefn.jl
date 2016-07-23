import ArchGDAL; const AG = ArchGDAL
using FactCheck

facts("Tests for field defn") do
    AG.createfielddefn("fieldname",AG.OFTInteger) do fd
        println(fd)
        println("name: $(AG.getname(fd))")
        println("Setting name to \"newname\"")
        AG.setname!(fd, "newname")
        println(AG.getname(fd))
        println("type: $(AG.gettype(fd))")
        println("Setting name to $(AG.OFTDate)")
        AG.settype!(fd, AG.OFTDate)
        println(AG.gettype(fd))
        AG.settype!(fd, AG.OFTInteger)
        @fact AG.getsubtype(fd) --> AG.OFSTNone
        AG.setsubtype!(fd, AG.OFSTInt16)
        @fact AG.getsubtype(fd) --> AG.OFSTInt16
        AG.setsubtype!(fd, AG.OFSTBoolean)
        @fact AG.getsubtype(fd) --> AG.OFSTBoolean
        AG.setsubtype!(fd, AG.OFSTNone)
        @fact AG.getjustify(fd) --> AG.OJUndefined
        AG.setjustify!(fd, AG.OJLeft)
        @fact AG.getjustify(fd) --> AG.OJLeft
        println("width: $(AG.getwidth(fd))")
        AG.setwidth!(fd, 10)
        println("after setting width to 10: new width=$(AG.getwidth(fd))")
        println("precision: $(AG.getprecision(fd))")
        AG.setprecision!(fd, 20)
        println("after setting to 20: new precision=$(AG.getprecision(fd))")
        AG.setparams!(fd, "finalname", AG.OFTDate, nwidth=5, nprecision=2,
                      justify=AG.OJRight)
        println("type: $((AG.gettype(fd),AG.getname(fd),AG.getsubtype(fd),
                          AG.getjustify(fd),AG.getwidth(fd),AG.getprecision(fd)))")
        @fact AG.isignored(fd) --> false
        AG.setignored!(fd, true)
        @fact AG.isignored(fd) --> true
        AG.setignored!(fd, false)
        @fact AG.isignored(fd) --> false

        @fact AG.isnullable(fd) --> true
        AG.setnullable!(fd, false)
        @fact AG.isnullable(fd) --> false
        AG.setnullable!(fd, true)
        @fact AG.isnullable(fd) --> true

        @fact AG.getdefault(fd) --> ""
        AG.setdefault!(fd, "0001/01/01 00:00:00")
        @fact AG.getdefault(fd) --> "0001/01/01 00:00:00"
        @fact AG.isdefaultdriverspecific(fd) --> true
    end
end

facts("Tests for Geom Field Defn") do
    AG.creategeomfielddefn("geomname", AG.wkbPolygon) do gfd
        @fact AG.getname(gfd) --> "geomname"
        AG.setname!(gfd, "my name!")
        @fact AG.getname(gfd) --> "my name!"

        @fact AG.gettype(gfd) --> AG.wkbPolygon
        AG.settype!(gfd, AG.wkbPolyhedralSurface)
        @fact AG.gettype(gfd) --> AG.wkbPolyhedralSurface

        println(AG.getspatialref(gfd))
        # AG.setspatialref!(gfd, AG.unsafe_fromEPSG(4326))
        # println(AG.getspatialref(gfd))

        @fact AG.isignored(gfd) --> false
        AG.setignored!(gfd, true)
        @fact AG.isignored(gfd) --> true
        AG.setignored!(gfd, false)
        @fact AG.isignored(gfd) --> false

        @fact AG.isnullable(gfd) --> true
        AG.setnullable!(gfd, false)
        @fact AG.isnullable(gfd) --> false
        AG.setnullable!(gfd, true)
        @fact AG.isnullable(gfd) --> true
    end
end

facts("Tests for Feature Defn") do
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
        AG.createfielddefn("fieldname",AG.OFTInteger) do fielddef
            @fact AG.nfield(fd) --> 0
            AG.addfielddefn!(fd, fielddef)
            @fact AG.nfield(fd) --> 1
            AG.addfielddefn!(fd, fielddef)
            @fact AG.nfield(fd) --> 2
            AG.addfielddefn!(fd, fielddef)
            @fact AG.nfield(fd) --> 3
            AG.createfielddefn("newfield",AG.OFTInteger) do fielddef2
                AG.addfielddefn!(fd, fielddef2)
                @fact AG.nfield(fd) --> 4
                for i in 0:3
                    println("$i : $(AG.getname(AG.getfielddefn(fd,i)))")
                end
            end
            AG.deletefielddefn!(fd, 0)
            @fact AG.nfield(fd) --> 3
            for i in 0:2
                println("$i : $(AG.getname(AG.getfielddefn(fd,i)))")
            end
            println("After reordering (in reverse):")
            AG.reorderfielddefns!(fd, Cint[2,1,0])
            @fact AG.nfield(fd) --> 3
            for i in 0:2
                println("$i : $(AG.getname(AG.getfielddefn(fd,i)))")
            end
        end
        @fact AG.ngeomfield(fd) --> 1
        @fact AG.getgeomtype(fd) --> AG.wkbUnknown
        AG.setgeomtype!(fd, AG.wkbPolygon)
        @fact AG.getgeomtype(fd) --> AG.wkbPolygon
        @fact AG.ngeomfield(fd) --> 1

        @fact AG.isgeomignored(fd) --> false
        AG.setgeomignored!(fd, true)
        @fact AG.isgeomignored(fd) --> true
        AG.setgeomignored!(fd, false)
        @fact AG.isgeomignored(fd) --> false

        @fact AG.isstyleignored(fd) --> false
        AG.setstyleignored!(fd, true)
        @fact AG.isstyleignored(fd) --> true
        AG.setstyleignored!(fd, false)
        @fact AG.isstyleignored(fd) --> false

        @fact AG.getgeomfieldindex(fd) --> 0
        gfd0 = AG.getgeomfielddefn(fd, 0)
        @fact AG.ngeomfield(fd) --> 1
        AG.addgeomfielddefn!(fd, gfd0)
        @fact AG.ngeomfield(fd) --> 2
        gfd1 = AG.getgeomfielddefn(fd, 1)
        AG.setname!(gfd0, "name0")
        AG.setname!(gfd1, "name1")
        @fact AG.getgeomfieldindex(fd, "") --> -1
        @fact AG.getgeomfieldindex(fd, "name0") --> 0
        @fact AG.getgeomfieldindex(fd, "name1") --> 1
        AG.deletegeomfielddefn!(fd, 0)
        @fact AG.ngeomfield(fd) --> 1
        @fact AG.getgeomfieldindex(fd, "") --> -1
        @fact AG.getgeomfieldindex(fd, "name0") --> -1
        @fact AG.getgeomfieldindex(fd, "name1") --> 0
        @fact AG.nreference(fd) --> 0
        AG.createfeature(fd) do f
            @fact AG.nreference(fd) --> 2 # artificially inflated
            @fact AG.issame(AG.getfeaturedefn(f), fd) --> true
        end
        @fact AG.nreference(fd) --> 0
    end
end