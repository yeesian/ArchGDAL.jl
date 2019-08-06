using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Tests for field defn" begin
    AG.createfielddefn("fieldname",GDAL.OFTInteger) do fd
        @test sprint(print, fd) == "fieldname (OFTInteger)"
        @test AG.getname(fd) == "fieldname"
        AG.setname!(fd, "newname")
        @test AG.getname(fd) == "newname"
        @test AG.gettype(fd) == GDAL.OFTInteger
        AG.settype!(fd, GDAL.OFTDate)
        @test AG.gettype(fd) == GDAL.OFTDate
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
        @test AG.getwidth(fd) == 0
        AG.setwidth!(fd, 10)
        @test AG.getwidth(fd) == 10
        @test AG.getprecision(fd) == 0
        AG.setprecision!(fd, 20)
        @test AG.getprecision(fd) == 20
        AG.setparams!(fd, "finalname", GDAL.OFTDate, nwidth=5, nprecision=2,
                      justify=GDAL.OJRight)
        @test AG.gettype(fd) == GDAL.OFTDate
        @test AG.getname(fd) == "finalname"
        @test AG.getsubtype(fd) == GDAL.OFSTNone
        @test AG.getjustify(fd) == GDAL.OJRight
        @test AG.getwidth(fd) == 5
        @test AG.getprecision(fd) == 2
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
    AG.creategeomdefn("geomname", GDAL.wkbPolygon) do gfd
        @test AG.getname(gfd) == "geomname"
        AG.setname!(gfd, "my name!")
        @test AG.getname(gfd) == "my name!"

        @test AG.gettype(gfd) == GDAL.wkbPolygon
        AG.settype!(gfd, GDAL.wkbPolyhedralSurface)
        @test AG.gettype(gfd) == GDAL.wkbPolyhedralSurface

        @test sprint(print, AG.getspatialref(gfd)) == "NULL Spatial Reference System"
        AG.getspatialref(gfd) do spref
            @test sprint(print, spref) == "NULL Spatial Reference System"
        end
        AG.setspatialref!(gfd, AG.importEPSG(4326))
        @test sprint(print, AG.getspatialref(gfd)) == "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs "
        AG.getspatialref(gfd) do spref
            if !Sys.iswindows()
                @test sprint(print, spref) == "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs "
                # NOTE(yeesian): we get the following error on x86 in Appveyor
                # Expression: sprint(print, spref) == "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs "
                #   GDALError (CE_Failure, code 6):
                #     No translation for an empty SRS to PROJ.4 format is known.
            end
        end

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
        @test AG.nreference(fd) == 0
        AG.reference(fd)
        @test AG.nreference(fd) == 1
        AG.reference(fd)
        @test AG.nreference(fd) == 2
        AG.release(fd)
        @test AG.nreference(fd) == 1
        AG.dereference(fd)
        @test AG.nreference(fd) == 0
        AG.createfielddefn("fieldname",GDAL.OFTInteger) do fielddef
            @test AG.nfield(fd) == 0
            AG.write!(fd, fielddef)
            @test AG.nfield(fd) == 1
            AG.write!(fd, fielddef)
            @test AG.nfield(fd) == 2
            AG.write!(fd, fielddef)
            @test AG.nfield(fd) == 3
            AG.createfielddefn("newfield",GDAL.OFTInteger) do fielddef2
                AG.write!(fd, fielddef2)
                @test AG.nfield(fd) == 4
                AG.getname(AG.getfielddefn(fd,0)) == "fieldname"
                AG.getname(AG.getfielddefn(fd,1)) == "fieldname"
                AG.getname(AG.getfielddefn(fd,2)) == "fieldname"
                AG.getname(AG.getfielddefn(fd,3)) == "newfield"
            end
            AG.deletefielddefn!(fd, 0)
            @test AG.nfield(fd) == 3
            AG.getname(AG.getfielddefn(fd,0)) == "fieldname"
            AG.getname(AG.getfielddefn(fd,1)) == "fieldname"
            AG.getname(AG.getfielddefn(fd,2)) == "newfield"
            AG.reorderfielddefns!(fd, Cint[2,1,0])
            @test AG.nfield(fd) == 3
            AG.getname(AG.getfielddefn(fd,0)) == "newfield"
            AG.getname(AG.getfielddefn(fd,1)) == "fieldname"
            AG.getname(AG.getfielddefn(fd,2)) == "fieldname"
        end
        @test AG.ngeom(fd) == 1
        @test AG.getgeomtype(fd) == GDAL.wkbUnknown
        AG.setgeomtype!(fd, GDAL.wkbPolygon)
        @test AG.getgeomtype(fd) == GDAL.wkbPolygon
        @test AG.ngeom(fd) == 1

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

        @test AG.getgeomindex(fd) == 0
        gfd0 = AG.getgeomdefn(fd, 0)
        @test AG.ngeom(fd) == 1
        AG.write!(fd, gfd0)
        @test AG.ngeom(fd) == 2
        gfd1 = AG.getgeomdefn(fd, 1)
        AG.setname!(gfd0, "name0")
        AG.setname!(gfd1, "name1")
        @test AG.getgeomindex(fd, "") == -1
        @test AG.getgeomindex(fd, "name0") == 0
        @test AG.getgeomindex(fd, "name1") == 1
        AG.deletegeomdefn!(fd, 0)
        @test AG.ngeom(fd) == 1
        @test AG.getgeomindex(fd, "") == -1
        @test AG.getgeomindex(fd, "name0") == -1
        @test AG.getgeomindex(fd, "name1") == 0
        @test AG.nreference(fd) == 0
        AG.createfeature(fd) do f
            @test AG.nreference(fd) == 2 # artificially inflated
            @test AG.issame(AG.getfeaturedefn(f), fd) == true
        end
        @test AG.nreference(fd) == 0
    end
end
