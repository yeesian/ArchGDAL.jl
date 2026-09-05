using Test
import ArchGDAL as AG
import GDAL
import GeoFormatTypes as GFT
import GeoInterface
import JLD2

@testset "test_spatialref.jl" begin
    @testset "Test Formats for Spatial Reference Systems" begin
        proj4326 = "+proj=longlat +datum=WGS84 +no_defs"
        proj26912 = "+proj=utm +zone=12 +datum=NAD83 +units=m +no_defs"
        wkt4326 = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]"
        wkt26912 = "PROJCS[\"NAD83 / UTM zone 12N\",GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY[\"EPSG\",\"6269\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4269\"]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",-111],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],AUTHORITY[\"EPSG\",\"26912\"]]"
        esri4326 = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433],AXIS[\"Longitude\",EAST],AXIS[\"Latitude\",NORTH]]"
        esri26912 = "PROJCS[\"NAD83 / UTM zone 12N\",GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],AUTHORITY[\"EPSG\",\"6269\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",-111],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH]]"
        xml4326 = """<gml:GeographicCRS gml:id="ogrcrs1">
          <gml:srsName>GCS_WGS_1984</gml:srsName>
          <gml:usesEllipsoidalCS>
            <gml:EllipsoidalCS gml:id="ogrcrs2">
              <gml:csName>ellipsoidal</gml:csName>
              <gml:csID>
                <gml:name codeSpace="urn:ogc:def:cs:EPSG::">6402</gml:name>
              </gml:csID>
              <gml:usesAxis>
                <gml:CoordinateSystemAxis gml:id="ogrcrs3" gml:uom="urn:ogc:def:uom:EPSG::9102">
                  <gml:name>Geodetic latitude</gml:name>
                  <gml:axisID>
                    <gml:name codeSpace="urn:ogc:def:axis:EPSG::">9901</gml:name>
                  </gml:axisID>
                  <gml:axisAbbrev>Lat</gml:axisAbbrev>
                  <gml:axisDirection>north</gml:axisDirection>
                </gml:CoordinateSystemAxis>
              </gml:usesAxis>
              <gml:usesAxis>
                <gml:CoordinateSystemAxis gml:id="ogrcrs4" gml:uom="urn:ogc:def:uom:EPSG::9102">
                  <gml:name>Geodetic longitude</gml:name>
                  <gml:axisID>
                    <gml:name codeSpace="urn:ogc:def:axis:EPSG::">9902</gml:name>
                  </gml:axisID>
                  <gml:axisAbbrev>Lon</gml:axisAbbrev>
                  <gml:axisDirection>east</gml:axisDirection>
                </gml:CoordinateSystemAxis>
              </gml:usesAxis>
            </gml:EllipsoidalCS>
          </gml:usesEllipsoidalCS>
          <gml:usesGeodeticDatum>
            <gml:GeodeticDatum gml:id="ogrcrs5">
              <gml:datumName>D_WGS_1984</gml:datumName>
              <gml:usesPrimeMeridian>
                <gml:PrimeMeridian gml:id="ogrcrs6">
                  <gml:meridianName>Greenwich</gml:meridianName>
                  <gml:greenwichLongitude>
                    <gml:angle uom="urn:ogc:def:uom:EPSG::9102">0</gml:angle>
                  </gml:greenwichLongitude>
                </gml:PrimeMeridian>
              </gml:usesPrimeMeridian>
              <gml:usesEllipsoid>
                <gml:Ellipsoid gml:id="ogrcrs7">
                  <gml:ellipsoidName>WGS_1984</gml:ellipsoidName>
                  <gml:semiMajorAxis uom="urn:ogc:def:uom:EPSG::9001">6378137</gml:semiMajorAxis>
                  <gml:secondDefiningParameter>
                    <gml:inverseFlattening uom="urn:ogc:def:uom:EPSG::9201">298.257223563</gml:inverseFlattening>
                  </gml:secondDefiningParameter>
                </gml:Ellipsoid>
              </gml:usesEllipsoid>
            </gml:GeodeticDatum>
          </gml:usesGeodeticDatum>
        </gml:GeographicCRS>
        """
        xml26912 = """<gml:ProjectedCRS gml:id="ogrcrs8">
          <gml:srsName>NAD_1983_UTM_Zone_12N</gml:srsName>
          <gml:baseCRS>
            <gml:GeographicCRS gml:id="ogrcrs9">
              <gml:srsName>GCS_North_American_1983</gml:srsName>
              <gml:usesEllipsoidalCS>
                <gml:EllipsoidalCS gml:id="ogrcrs10">
                  <gml:csName>ellipsoidal</gml:csName>
                  <gml:csID>
                    <gml:name codeSpace="urn:ogc:def:cs:EPSG::">6402</gml:name>
                  </gml:csID>
                  <gml:usesAxis>
                    <gml:CoordinateSystemAxis gml:id="ogrcrs11" gml:uom="urn:ogc:def:uom:EPSG::9102">
                      <gml:name>Geodetic latitude</gml:name>
                      <gml:axisID>
                        <gml:name codeSpace="urn:ogc:def:axis:EPSG::">9901</gml:name>
                      </gml:axisID>
                      <gml:axisAbbrev>Lat</gml:axisAbbrev>
                      <gml:axisDirection>north</gml:axisDirection>
                    </gml:CoordinateSystemAxis>
                  </gml:usesAxis>
                  <gml:usesAxis>
                    <gml:CoordinateSystemAxis gml:id="ogrcrs12" gml:uom="urn:ogc:def:uom:EPSG::9102">
                      <gml:name>Geodetic longitude</gml:name>
                      <gml:axisID>
                        <gml:name codeSpace="urn:ogc:def:axis:EPSG::">9902</gml:name>
                      </gml:axisID>
                      <gml:axisAbbrev>Lon</gml:axisAbbrev>
                      <gml:axisDirection>east</gml:axisDirection>
                    </gml:CoordinateSystemAxis>
                  </gml:usesAxis>
                </gml:EllipsoidalCS>
              </gml:usesEllipsoidalCS>
              <gml:usesGeodeticDatum>
                <gml:GeodeticDatum gml:id="ogrcrs13">
                  <gml:datumName>D_North_American_1983</gml:datumName>
                  <gml:usesPrimeMeridian>
                    <gml:PrimeMeridian gml:id="ogrcrs14">
                      <gml:meridianName>Greenwich</gml:meridianName>
                      <gml:greenwichLongitude>
                        <gml:angle uom="urn:ogc:def:uom:EPSG::9102">0</gml:angle>
                      </gml:greenwichLongitude>
                    </gml:PrimeMeridian>
                  </gml:usesPrimeMeridian>
                  <gml:usesEllipsoid>
                    <gml:Ellipsoid gml:id="ogrcrs15">
                      <gml:ellipsoidName>GRS_1980</gml:ellipsoidName>
                      <gml:semiMajorAxis uom="urn:ogc:def:uom:EPSG::9001">6378137</gml:semiMajorAxis>
                      <gml:secondDefiningParameter>
                        <gml:inverseFlattening uom="urn:ogc:def:uom:EPSG::9201">298.257222101</gml:inverseFlattening>
                      </gml:secondDefiningParameter>
                    </gml:Ellipsoid>
                  </gml:usesEllipsoid>
                </gml:GeodeticDatum>
              </gml:usesGeodeticDatum>
            </gml:GeographicCRS>
          </gml:baseCRS>
          <gml:definedByConversion>
            <gml:Conversion gml:id="ogrcrs16">
              <gml:coordinateOperationName>Transverse_Mercator</gml:coordinateOperationName>
              <gml:usesMethod xlink:href="urn:ogc:def:method:EPSG::9807" />
              <gml:usesValue>
                <gml:value uom="urn:ogc:def:uom:EPSG::9102">0</gml:value>
                <gml:valueOfParameter xlink:href="urn:ogc:def:parameter:EPSG::8801" />
              </gml:usesValue>
              <gml:usesValue>
                <gml:value uom="urn:ogc:def:uom:EPSG::9102">-111</gml:value>
                <gml:valueOfParameter xlink:href="urn:ogc:def:parameter:EPSG::8802" />
              </gml:usesValue>
              <gml:usesValue>
                <gml:value uom="urn:ogc:def:uom:EPSG::9001">0.9996</gml:value>
                <gml:valueOfParameter xlink:href="urn:ogc:def:parameter:EPSG::8805" />
              </gml:usesValue>
              <gml:usesValue>
                <gml:value uom="urn:ogc:def:uom:EPSG::9001">500000</gml:value>
                <gml:valueOfParameter xlink:href="urn:ogc:def:parameter:EPSG::8806" />
              </gml:usesValue>
              <gml:usesValue>
                <gml:value uom="urn:ogc:def:uom:EPSG::9001">0</gml:value>
                <gml:valueOfParameter xlink:href="urn:ogc:def:parameter:EPSG::8807" />
              </gml:usesValue>
            </gml:Conversion>
          </gml:definedByConversion>
          <gml:usesCartesianCS>
            <gml:CartesianCS gml:id="ogrcrs17">
              <gml:csName>Cartesian</gml:csName>
              <gml:csID>
                <gml:name codeSpace="urn:ogc:def:cs:EPSG::">4400</gml:name>
              </gml:csID>
              <gml:usesAxis>
                <gml:CoordinateSystemAxis gml:id="ogrcrs18" gml:uom="urn:ogc:def:uom:EPSG::9001">
                  <gml:name>Easting</gml:name>
                  <gml:axisID>
                    <gml:name codeSpace="urn:ogc:def:axis:EPSG::">9906</gml:name>
                  </gml:axisID>
                  <gml:axisAbbrev>E</gml:axisAbbrev>
                  <gml:axisDirection>east</gml:axisDirection>
                </gml:CoordinateSystemAxis>
              </gml:usesAxis>
              <gml:usesAxis>
                <gml:CoordinateSystemAxis gml:id="ogrcrs19" gml:uom="urn:ogc:def:uom:EPSG::9001">
                  <gml:name>Northing</gml:name>
                  <gml:axisID>
                    <gml:name codeSpace="urn:ogc:def:axis:EPSG::">9907</gml:name>
                  </gml:axisID>
                  <gml:axisAbbrev>N</gml:axisAbbrev>
                  <gml:axisDirection>north</gml:axisDirection>
                </gml:CoordinateSystemAxis>
              </gml:usesAxis>
            </gml:CartesianCS>
          </gml:usesCartesianCS>
        </gml:ProjectedCRS>
        """
        cepsg = "EPSG:4326+3855"
        projjson = """
        {
          "\$schema": "https://proj.org/schemas/v0.4/projjson.schema.json",
          "type": "GeographicCRS",
          "name": "Monte Mario (Rome)",
          "datum": {
            "type": "GeodeticReferenceFrame",
            "name": "Monte Mario (Rome)",
            "ellipsoid": {
              "name": "International 1924",
              "semi_major_axis": 6378388,
              "inverse_flattening": 297
            },
            "prime_meridian": {
              "name": "Rome",
              "longitude": 12.4523333333333
            }
          },
          "coordinate_system": {
            "subtype": "ellipsoidal",
            "axis": [
              {
                "name": "Geodetic latitude",
                "abbreviation": "Lat",
                "direction": "north",
                "unit": "degree"
              },
              {
                "name": "Geodetic longitude",
                "abbreviation": "Lon",
                "direction": "east",
                "unit": "degree"
              }
            ]
          },
          "scope": "Geodesy, onshore minerals management.",
          "area": "Italy - onshore and offshore; San Marino, Vatican City State.",
          "bbox": {
            "south_latitude": 34.76,
            "west_longitude": 5.93,
            "north_latitude": 47.1,
            "east_longitude": 18.99
          },
          "id": {
            "authority": "EPSG",
            "code": 4806
          }
        }
        """

        @testset "PROJ4 Format" begin
            AG.importPROJ4(proj4326) do spatialref
                spatialref2 = AG.importPROJ4(proj26912)
                @test AG.toPROJ4(spatialref2) == proj26912
                AG.importPROJ4!(spatialref2, AG.toPROJ4(spatialref))
                @test AG.toPROJ4(spatialref2) == proj4326
                @test convert(GFT.WellKnownText, spatialref) isa
                      GFT.WellKnownText{GFT.CRS}
            end
        end

        @testset "WKT Format" begin
            AG.importWKT(wkt4326) do spatialref
                spatialref2 = AG.importWKT(wkt26912)
                @test AG.toWKT(spatialref2) == wkt26912
                AG.importWKT!(spatialref2, AG.toWKT(spatialref))
                @test AG.toWKT(spatialref2) == wkt4326
                @test convert(GFT.WellKnownText, spatialref) isa
                      GFT.WellKnownText{GFT.CRS}
            end
        end

        @testset "ESRI Format" begin
            AG.importESRI(esri4326) do spatialref
                spatialref2 = AG.importESRI(esri26912)
                @test AG.toWKT(spatialref2) == esri26912
                AG.importESRI!(spatialref2, AG.toWKT(spatialref))
                @test AG.toWKT(spatialref2) == esri4326
                @test convert(GFT.WellKnownText, spatialref) isa
                      GFT.WellKnownText{GFT.CRS}
            end
        end

        @testset "XML Format" begin
            AG.importXML(xml4326) do spatialref
                spatialref2 = AG.importXML(xml26912)
                @test startswith(AG.toXML(spatialref2), "<gml:ProjectedCRS")
                AG.importXML!(spatialref2, xml4326)
                @test startswith(AG.toXML(spatialref2), "<gml:GeographicCRS")
                @test convert(GFT.WellKnownText, spatialref) isa
                      GFT.WellKnownText{GFT.CRS}
            end
        end

        @testset "User provided Format" begin
            AG.importUserInput(cepsg) do spatialref
                spatialref2 = AG.importUserInput(cepsg)
                @test contains(AG.toPROJ4(spatialref2), "+geoidgrids=")
                AG.importUserInput!(spatialref2, cepsg)
                @test contains(AG.toPROJ4(spatialref2), "+geoidgrids=")
                @test convert(GFT.WellKnownText, spatialref) isa
                      GFT.WellKnownText{GFT.CRS}
            end
        end

        if VERSION >= v"1.6.0-"
            @testset "URL Import" begin
                url4326 = "http://spatialreference.org/ref/epsg/4326/ogcwkt/"
                wkt4326 = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]"
                urlsample = "http://spatialreference.org/ref/epsg/2039/esriwkt.txt"
                wktsample = "PROJCS[\"Israel 1993 / Israeli TM Grid\",GEOGCS[\"Israel 1993\",DATUM[\"Israel_1993\",SPHEROID[\"GRS 1980\",6378137,298.257222101,AUTHORITY[\"EPSG\",\"7019\"]],AUTHORITY[\"EPSG\",\"6141\"]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",31.7343936111111],PARAMETER[\"central_meridian\",35.2045169444444],PARAMETER[\"scale_factor\",1.0000067],PARAMETER[\"false_easting\",219529.584],PARAMETER[\"false_northing\",626907.39],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH]]"
                AG.importURL(url4326) do spatialref
                    spatialref2 = AG.importURL(urlsample)
                    @test AG.toWKT(spatialref2) == wktsample
                    AG.importURL!(spatialref2, url4326)
                    @test AG.toWKT(spatialref2) == wkt4326
                end
            end
        end

        @testset "generic importCRS" begin
            @test AG.toWKT(
                AG.importCRS(GFT.WellKnownText(GFT.CRS(), wkt4326)),
            ) == AG.toWKT(AG.importWKT(wkt4326))
            @test AG.toWKT(
                AG.importCRS(GFT.ESRIWellKnownText(GFT.CRS(), wkt4326)),
            ) == AG.toWKT(AG.importESRI(wkt4326))
            @test AG.toWKT(AG.importCRS(GFT.ProjString(proj4326))) ==
                  AG.toWKT(AG.importPROJ4(proj4326))
            @test AG.toWKT(AG.importCRS(GFT.EPSG(4326))) ==
                  AG.toWKT(AG.importEPSG(4326))
            @test AG.toWKT(AG.importCRS(GFT.EPSG(4326, 3855))) ==
                  AG.toWKT(AG.importUserInput("EPSG:4326+3855"))
            @test AG.toWKT(AG.importCRS(GFT.EPSG(4326), order = :trad)) ==
                  AG.toWKT(AG.importEPSG(4326))
            @test AG.toWKT(AG.importCRS(GFT.EPSG(4326), order = :compliant)) ==
                  AG.toWKT(AG.importEPSG(4326))
            @test AG.toWKT(AG.importCRS(GFT.GML(xml4326))) ==
                  AG.toWKT(AG.importXML(xml4326))
            @test AG.toWKT(AG.importCRS(GFT.KML(""))) ==
                  AG.toWKT(AG.importEPSG(4326))

            # WKT is never fully identical
            @test occursin(
                "Monte Mario (Rome)",
                AG.toWKT(AG.importCRS(GFT.ProjJSON(projjson))),
            )
            @test_throws ErrorException AG.importCRS(
                GFT.ProjJSON(Dict("type" => "")),
            )

            @test_throws ArgumentError AG.importCRS(
                GFT.EPSG(4326),
                order = :unknown,
            )
        end
    end

    @testset "Cloning NULL SRS" begin
        @test sprint(print, AG.clone(AG.ISpatialRef())) ==
              "NULL Spatial Reference System"
        AG.clone(AG.ISpatialRef()) do spatialref
            @test sprint(print, spatialref) == "NULL Spatial Reference System"
        end
    end

    @testset "Getting and Setting Attribute Values" begin
        AG.importEPSG(4326) do spatialref
            @test AG.toWKT(spatialref) ==
                  "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]"
            @test sprint(print, spatialref) ==
                  "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs"
            AG.setattrvalue!(spatialref, "GEOGCS|AUTHORITY|EPSG") # tests seems to be broken in gdal 3.0
            @test AG.toWKT(spatialref) ==
                  "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]"
            AG.setattrvalue!(spatialref, "GEOGCS|NEWATTRIBUTE", "7031") # tests seems to be broken in gdal 3.0
            @test AG.toWKT(spatialref) ==
                  "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]"
            @test AG.getattrvalue(spatialref, "AUTHORITY", 0) == "EPSG"
            @test AG.getattrvalue(spatialref, "AUTHORITY", 1) == "4326"
        end
    end

    @testset "Spatial references are GeoFormats" begin
        spref = AG.importEPSG(4326)

        @testset "GeoFormat interface" begin
            @test spref isa GFT.GeoFormat
            @test spref isa GFT.CoordinateReferenceSystemFormat
            @test GFT.mode(AG.ISpatialRef) === GFT.CRS()
            @test GFT.val(spref) == AG.toWKT2(spref)
            @test convert(String, spref) == AG.toWKT2(spref)
        end

        @testset "Empty and NULL" begin
            @test AG.isempty(AG.ISpatialRef())
            # A live handle that has had no CRS imported into it yet.
            @test AG.isempty(AG.newspatialref())
            @test !AG.isempty(spref)
            @test GFT.val(AG.ISpatialRef()) == ""
            @test GFT.val(AG.newspatialref()) == ""
            @test sprint(print, AG.newspatialref()) ==
                  "Empty Spatial Reference System"
            @test AG.ISpatialRef() == AG.ISpatialRef()
            @test AG.ISpatialRef() != spref
            @test spref != AG.ISpatialRef()
        end

        @testset "Equality is OSRIsSame" begin
            @test spref == AG.clone(spref)
            @test hash(spref) == hash(AG.clone(spref))
            @test Dict(spref => :wgs84)[AG.clone(spref)] === :wgs84
            @test spref != AG.importEPSG(26912)
            # CRS equivalence, not textual equality: roundtrips rename the CRS
            # but still compare equal.
            @test spref == AG.importPROJ4(AG.toPROJ4(spref))
            @test spref == AG.importWKT(AG.toWKT(spref))
            @test spref == AG.ISpatialRef(AG.toWKT2(spref))
            # The data axis to CRS axis mapping *is* compared, and these two
            # transform differently.
            @test spref != AG.importEPSG(4326; order = :trad)
        end

        @testset "Display is unchanged" begin
            @test sprint(print, spref) ==
                  "Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs"
            @test sprint(show, MIME"text/plain"(), spref) ==
                  sprint(print, spref)
        end

        @testset "reproject accepts spatial refs" begin
            # https://github.com/yeesian/ArchGDAL.jl/issues/403
            point() = AG.createpoint(10.0, 20.0)
            expected = AG.reproject(point(), GFT.EPSG(4326), GFT.EPSG(3857))
            @test AG.reproject(point(), spref, GFT.EPSG(3857)) == expected
            @test AG.reproject(point(), GFT.EPSG(4326), AG.importEPSG(3857)) ==
                  expected
            @test AG.reproject(point(), spref, AG.importEPSG(3857)) == expected

            # The crs a geometry carries feeds straight back into reproject,
            # which is what #403 asked for.
            AG.read("data/point.geojson") do dataset
                AG.getfeature(AG.getlayer(dataset, 0), 0) do feature
                    geom = AG.getgeom(feature, 0)
                    geomcrs = AG.getspatialref(geom)
                    @test !AG.isempty(geomcrs)
                    @test AG.reproject(geom, geomcrs, GFT.EPSG(3857)) isa
                          AG.AbstractGeometry
                end
            end

            # https://github.com/yeesian/ArchGDAL.jl/issues/434
            @test AG.reproject(
                AG.createpoint(1.0, 1.0),
                AG.importEPSG(4326; order = :trad),
                AG.importEPSG(3857),
            ) isa AG.AbstractGeometry

            # The caller's spatial ref is cloned, not consumed, by reproject.
            GC.gc()
            @test AG.toWKT(spref) == AG.toWKT(AG.importEPSG(4326))
            @test AG.reproject(point(), spref, GFT.EPSG(3857)) == expected

            # A crs is not a geometry, even though both are now GeoFormats.
            @test_throws MethodError AG.reproject(
                spref,
                GFT.EPSG(4326),
                GFT.EPSG(3857),
            )
        end

        @testset "Axis mapping strategy" begin
            trad = AG.importEPSG(4326; order = :trad)
            compliant = AG.importEPSG(4326; order = :compliant)
            @test GDAL.osrgetaxismappingstrategy(trad) ==
                  GDAL.OAMS_TRADITIONAL_GIS_ORDER
            @test GDAL.osrgetaxismappingstrategy(compliant) ==
                  GDAL.OAMS_AUTHORITY_COMPLIANT
            # Importing a spatial ref keeps its strategy, since resetting it
            # would silently swap the axes of a reprojection.
            @test GDAL.osrgetaxismappingstrategy(AG.importCRS(trad)) ==
                  GDAL.OAMS_TRADITIONAL_GIS_ORDER
            @test GDAL.osrgetaxismappingstrategy(
                AG.importCRS(trad; order = :compliant),
            ) == GDAL.OAMS_AUTHORITY_COMPLIANT
            @test GDAL.osrgetaxismappingstrategy(
                AG.importCRS(compliant; order = :trad),
            ) == GDAL.OAMS_TRADITIONAL_GIS_ORDER
            @test AG.reproject(
                AG.createpoint(10.0, 20.0),
                trad,
                GFT.EPSG(3857),
            ) != AG.reproject(
                AG.createpoint(10.0, 20.0),
                compliant,
                GFT.EPSG(3857),
            )
        end

        @testset "Custom axis mapping" begin
            custom = AG.importEPSG(4326)
            @test AG.getaxismapping(custom) == [1, 2]
            AG.setaxismapping!(custom, [2, 1])
            @test AG.getaxismapping(custom) == [2, 1]
            @test GDAL.osrgetaxismappingstrategy(custom) == GDAL.OAMS_CUSTOM
            @test AG.getaxismapping(AG.clone(custom)) == [2, 1]
        end

        @testset "importCRS! keeps what WKT cannot carry" begin
            source = AG.importEPSG(4326; order = :trad)
            GDAL.osrsetcoordinateepoch(source, 2021.3)
            target = AG.importCRS!(AG.newspatialref(), source)
            @test GDAL.osrgetcoordinateepoch(target) ≈ 2021.3
            @test GDAL.osrgetaxismappingstrategy(target) ==
                  GDAL.OAMS_TRADITIONAL_GIS_ORDER
            @test target == source

            # A custom mapping is not in the WKT either, so it is copied too.
            custom = AG.importEPSG(4326)
            AG.setaxismapping!(custom, [2, 1])
            copied = AG.importCRS!(AG.newspatialref(), custom)
            @test GDAL.osrgetaxismappingstrategy(copied) == GDAL.OAMS_CUSTOM
            @test AG.getaxismapping(copied) == [2, 1]
        end
    end

    @testset "WKT2 and PROJJSON export" begin
        spref = AG.importEPSG(4326)
        @test occursin("GEOGCRS", AG.toWKT2(spref))
        @test occursin("GEODCRS", AG.toWKT2(spref; format = "WKT2_2015"))
        @test !occursin("\n", AG.toWKT2(spref))
        @test occursin("\n", AG.toWKT2(spref; multiline = true))
        @test AG.ISpatialRef(AG.toWKT2(spref)) == spref

        # WKT1 cannot represent a compound CRS losslessly; WKT2 can.
        compound = AG.importUserInput("EPSG:4326+3855")
        @test occursin("COMPOUNDCRS", AG.toWKT2(compound))
        @test AG.ISpatialRef(AG.toWKT2(compound)) == compound

        @test occursin("\"type\"", AG.toPROJJSON(spref))
        @test occursin("\n", AG.toPROJJSON(spref; multiline = true))
    end

    @testset "Coordinate epoch" begin
        spref = AG.importEPSG(4326)
        @test AG.getcoordinateepoch(spref) == 0
        @test AG.setcoordinateepoch!(spref, 2021.3) === spref
        @test AG.getcoordinateepoch(spref) ≈ 2021.3
        # `OSRIsSame` compares the epoch, so this is not a cosmetic field.
        @test spref != AG.importEPSG(4326)
    end

    @testset "Attaching a spatial reference to a geometry" begin
        wkb = AG.toWKB(AG.fromWKT("POINT (1 2)"))
        @test AG.isempty(AG.getspatialref(AG.fromWKB(wkb)))

        geom = AG.fromWKB(wkb; spatialref = AG.importEPSG(4326))
        @test AG.getspatialref(geom) == AG.importEPSG(4326)
        # GDAL takes its own reference, so the geometry outlives the spatial
        # reference we handed it.
        GC.gc()
        GC.gc()
        @test AG.getspatialref(geom) == AG.importEPSG(4326)
        @test AG.toWKT(geom) == "POINT (1 2)"

        unowned = AG.unsafe_fromWKB(wkb; spatialref = AG.importEPSG(4326))
        @test AG.getspatialref(unowned) == AG.importEPSG(4326)
        AG.destroy(unowned)
    end

    @testset "deepcopy" begin
        # `deepcopy` copies the `ptr` field verbatim unless told otherwise,
        # which would leave the copy pointing into memory the original owns.
        spref = AG.importEPSG(4326)
        copied = deepcopy(spref)
        @test copied isa AG.ISpatialRef
        @test copied.ptr != spref.ptr
        @test copied == spref
        AG.destroy(spref)
        @test AG.toWKT(copied) == AG.toWKT(AG.importEPSG(4326))

        # Aliasing within one structure is preserved, as `deepcopy` requires.
        pair = deepcopy((copied, copied))
        @test pair[1] === pair[2]
        @test pair[1].ptr != copied.ptr

        # The unfinalized variant clones too, and stays unfinalized.
        unowned = AG.unsafe_clone(AG.importEPSG(4326))
        ucopy = deepcopy(unowned)
        @test ucopy isa AG.SpatialRef
        @test ucopy.ptr != unowned.ptr
        AG.destroy(unowned)
        @test ucopy == AG.importEPSG(4326)
        AG.destroy(ucopy)

        # A NULL handle has nothing to clone.
        @test deepcopy(AG.ISpatialRef()).ptr == C_NULL
    end

    @testset "JLD2 serialization" begin
        dir = mktempdir()
        spref = AG.importEPSG(4326)
        path = joinpath(dir, "srs.jld2")
        JLD2.save_object(path, spref)
        back = JLD2.load_object(path)
        @test back isa AG.ISpatialRef
        @test !AG.isempty(back)
        @test back == spref
        @test GDAL.osrgetaxismappingstrategy(back) ==
              GDAL.OAMS_AUTHORITY_COMPLIANT

        # Axis order survives, which is what decides whether coordinates read
        # as lon/lat or lat/lon downstream.
        tradpath = joinpath(dir, "srs_trad.jld2")
        trad = AG.importEPSG(4326; order = :trad)
        JLD2.save_object(tradpath, trad)
        tradback = JLD2.load_object(tradpath)
        @test AG.getaxismapping(tradback) == AG.getaxismapping(trad)
        @test tradback == trad
        @test tradback != AG.importEPSG(4326)

        # So does the coordinate epoch.
        epochpath = joinpath(dir, "srs_epoch.jld2")
        dynamic = AG.setcoordinateepoch!(AG.importEPSG(4326), 2021.3)
        JLD2.save_object(epochpath, dynamic)
        epochback = JLD2.load_object(epochpath)
        @test AG.getcoordinateepoch(epochback) ≈ 2021.3
        @test epochback == dynamic

        # An empty spatial reference has nothing to save and comes back empty
        # rather than throwing.
        emptypath = joinpath(dir, "srs_empty.jld2")
        JLD2.save_object(emptypath, AG.ISpatialRef())
        @test AG.isempty(JLD2.load_object(emptypath))

        # Equal spatial references share one crs record in the file: the
        # definition is written once, however many of them there are.
        manypath = joinpath(dir, "srs_many.jld2")
        emptiespath = joinpath(dir, "srs_empties.jld2")
        JLD2.save_object(manypath, [AG.importEPSG(4326) for _ in 1:200])
        JLD2.save_object(emptiespath, [AG.ISpatialRef() for _ in 1:200])
        @test filesize(manypath) - filesize(emptiespath) <
              3 * sizeof(AG.toWKT2(spref))
        # But not one GDAL object: each loaded reference is the caller's to
        # mutate.
        many = JLD2.load_object(manypath)
        @test all(==(spref), many)
        @test many[1].ptr != many[2].ptr
        AG.importEPSG!(many[1], 26912)
        @test many[1] != spref
        @test many[2] == spref

        # Whereas one object saved twice is one object when loaded, as with
        # any mutable struct.
        pairpath = joinpath(dir, "srs_pair.jld2")
        JLD2.save_object(pairpath, [spref, spref])
        pair = JLD2.load_object(pairpath)
        @test pair[1] === pair[2]
        @test pair[1] == spref
    end
end
