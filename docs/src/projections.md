# Spatial Projections
(This is based entirely on the [GDAL/OSR Tutorial](http://www.gdal.org/osr_tutorial.html) and [Python GDAL/OGR Cookbook](https://pcjericks.github.io/py-gdalogr-cookbook/projection.html).)

The `ArchGDAL.SpatialRef`, and `ArchGDAL.CoordTransform` types are lightweight wrappers around GDAL objects that represent coordinate systems (projections and datums) and provide services to transform between them. These services are loosely modeled on the OpenGIS Coordinate Transformations specification, and use the same Well Known Text format for describing coordinate systems.

## Coordinate Systems
There are two primary kinds of coordinate systems. The first is geographic (positions are measured in long/lat) and the second is projected (such as UTM - positions are measured in meters or feet).

* **Geographic Coordinate Systems**: A Geographic coordinate system contains information on the datum (which implies an spheroid described by a semi-major axis, and inverse flattening), prime meridian (normally Greenwich), and an angular units type which is normally degrees.

* **Projected Coordinate Systems**: A projected coordinate system (such as UTM, Lambert Conformal Conic, etc) requires and underlying geographic coordinate system as well as a definition for the projection transform used to translate between linear positions (in meters or feet) and angular long/lat positions.

## Creating Spatial References
```@example spatialref
import ArchGDAL; const AG = ArchGDAL

projstring2927 = AG.importEPSG(2927) do spref
    AG.toPROJ4(spref)
end
```

The details of how to interpret the results can be found in http://proj4.org/usage/projections.html.

In the above example, we constructed a `SpatialRef` object from the [EPSG Code 2927](http://spatialreference.org/ref/epsg/2927/). There are a variety of other formats from which `SpatialRef`s can be constructed, such as

* `ArchGDAL.importEPSG(::Int)`: based on the [EPSG code](http://spatialreference.org/ref/epsg/)
* `ArchGDAL.importEPSGA(::Int)`: based on the EPSGA code
* `ArchGDAL.importESRI(::String)`: based on ESRI projection codes
* `ArchGDAL.importPROJ4(::String)` based on the PROJ.4 string ([reference](http://proj4.org/usage/projections.html))
* `ArchGDAL.importURL(::String)`: download from a given URL and feed it into `SetFromUserInput` for you.
* `ArchGDAL.importWKT(::String)`: WKT string
* `ArchGDAL.importXML(::String)`: XML format (GML only currently)

We currently support a few export formats too:

* `ArchGDAL.toMICoordSys(spref)`: Mapinfo style CoordSys format.
* `ArchGDAL.toPROJ4(spref)`: coordinate system in PROJ.4 format.
* `ArchGDAL.toWKT(spref)`: nicely formatted WKT string for display to a person.
* `ArchGDAL.toXML(spref)`: converts into XML format to the extent possible.

## Reprojecting a Geometry
```@example spatialref
AG.importEPSG(2927) do source
    AG.importEPSG(4326) do target
        AG.createcoordtrans(source, target) do transform
            AG.fromWKT("POINT (1120351.57 741921.42)") do point
                println("Before: $(AG.toWKT(point))")
                AG.transform!(point, transform)
                println("After: $(AG.toWKT(point))")
end end end end
```

## References

Some background on OpenGIS coordinate systems and services can be found in the Simple Features for COM, and Spatial Reference Systems Abstract Model documents available from the [Open Geospatial Consortium](http://www.opengeospatial.org/). The [GeoTIFF Projections Transform List](http://geotiff.maptools.org/proj_list/) may also be of assistance in understanding formulations of projections in WKT. The [EPSG](http://www.epsg.org/) Geodesy web page is also a useful resource. You may also consult the [OGC WKT Coordinate System Issues](http://www.gdal.org/wktproblems.html) page.

