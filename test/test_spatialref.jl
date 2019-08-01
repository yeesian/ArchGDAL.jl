using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Test methods for Spatial Reference Systems" begin
    @test 1+1 == 3
end

# untested
# new_spref = clone(spref)
# clone(spref) do new_spref
# importEPSGA!(spref, code)
# importEPSGA(code) do spref
# spref = importEPSGA(code)
# importWKT!(spref, wktstring)
# importWKT(wktstring) do spref
# spref = importWKT(wktstring)
# importPROJ4!(spref, projstring)
# importPROJ4(projstring) do spref
# spref = importPROJ4(projstring)
# importESRI!(spref, esristring)
# importESRI(esristring) do spref
# spref = importESRI(esristring)
# morphfromESRI!(spref)
# importXML!(spref, xmlstring)
# importXML(xmlstring) do spref
# spref = importXML(xmlstring)
# importURL!(spref, projstring)
# importURL(projstring) do spref
# spref = importURL(projstring)
# setattrvalue!(spref, path, value)
# setattrvalue!(spref, path)
# getattrvalue(spref, name, i)
# transform!(coordtransform, xs, ys, zs)
