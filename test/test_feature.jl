using FactCheck
import ArchGDAL; const AG = ArchGDAL

AG.registerdrivers() do
    AG.read("data/point.geojson") do dataset
        layer = AG.getlayer(dataset, 0)
        AG.getfeature(layer, 0) do f1
            AG.getfeature(layer, 2) do f2
                println(f1)
                println(AG.getgeom(f1))
                fid1 = AG.getfid(f1); println(fid1)
                println(f2)
                println(AG.getgeom(f2))
                fid2 = AG.getfid(f2); println(fid2)
                println(AG.equals(AG.getgeom(f1),AG.getgeom(f2)))
                AG.setfid!(f1, fid2); AG.setfid!(f2, fid1)
                println(fid1, fid2)
                println(AG.getfid(f1), AG.getfid(f2))

                println("f1 geomfieldindex for geom: $(AG.getgeomfieldindex(f1, "geom"))")
                println("f1 geomfieldindex for \"\": $(AG.getgeomfieldindex(f1, ""))")
                println("f2 geomfieldindex for geom: $(AG.getgeomfieldindex(f2, "geom"))")
                println("f2 geomfieldindex for \"\": $(AG.getgeomfieldindex(f2, ""))")
                println("f1 geomfielddefn: $(AG.getgeomfielddefn(f1, 0))")
                println("f2 geomfielddefn: $(AG.getgeomfielddefn(f2, 0))")
            end
        end
        AG.getfeature(layer, 0) do f
            @fact AG.toWKT(AG.getgeomfield(f,0)) --> "POINT (100 0)"
            AG.setgeomfielddirectly!(f, 0, AG.unsafe_createpoint(0,100))
            @fact AG.toWKT(AG.getgeomfield(f,0)) --> "POINT (0 100)"
            AG.createpolygon([(0.,100.),(100.,0.)]) do poly
                AG.setgeomfield!(f, 0, poly)
            end
            @fact AG.toWKT(AG.getgeomfield(f,0)) --> "POLYGON ((0 100,100 0))"
            
            AG.setstylestring!(f, "@Name")
            @fact AG.getstylestring(f) --> "@Name"
            AG.setstylestring!(f, "NewName")
            @fact AG.getstylestring(f) --> "NewName"

            AG.setstyletabledirectly!(f, AG.unsafe_createstyletable())
            println(AG.getstyletable(f))
            AG.createstyletable() do st
                AG.setstyletable!(f, st)
            end
            println(AG.getstyletable(f))

            AG.setnativedata!(f, "nativedata1")
            @fact AG.getnativedata(f) --> "nativedata1"
            AG.setnativedata!(f, "nativedata2")
            @fact AG.getnativedata(f) --> "nativedata2"

            AG.setmediatype!(f, "mediatype1")
            @fact AG.getmediatype(f) --> "mediatype1"
            AG.setmediatype!(f, "mediatype2")
            @fact AG.getmediatype(f) --> "mediatype2"

            @fact AG.validate(f, GDAL.OGR_F_VAL_NULL, false) --> false
            @fact AG.validate(f, GDAL.OGR_F_VAL_GEOM_TYPE, false) --> false
            @fact AG.validate(f, GDAL.OGR_F_VAL_WIDTH, false) --> true
            @fact AG.validate(f, GDAL.OGR_F_VAL_ALLOW_NULL_WHEN_DEFAULT, false) --> true
            @fact AG.validate(f, GDAL.OGR_F_VAL_ALLOW_DIFFERENT_GEOM_DIM, false) --> true

            @fact AG.getfield(f, 1) --> "point-a"
            AG.setdefault!(AG.getfielddefn(f, 1),"nope")
            @fact AG.getfield(f, 1) --> "point-a"
            AG.unsetfield!(f, 1)
            @fact AG.getfield(f, 1) --> nothing
            AG.fillunsetwithdefault!(f, notnull=false)
            @fact AG.getfield(f, 1) --> "nope"
        end
    end
end
