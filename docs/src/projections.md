# Spatial Projections

```@setup projections
using ArchGDAL; const AG = ArchGDAL
using Plots
```

(This is based entirely on the [GDAL/OSR Tutorial](https://gdal.org/tutorials/osr_api_tut.html) and [Python GDAL/OGR Cookbook](https://pcjericks.github.io/py-gdalogr-cookbook/projection.html).)

The `ArchGDAL.SpatialRef`, and `ArchGDAL.CoordTransform` types are lightweight wrappers around GDAL objects that represent coordinate systems (projections and datums) and provide services to transform between them. These services are loosely modeled on the OpenGIS Coordinate Transformations specification, and use the same Well Known Text format for describing coordinate systems.

## Coordinate Systems
There are two primary kinds of coordinate systems. The first is geographic (positions are measured in long/lat) and the second is projected (such as UTM - positions are measured in meters or feet).

* **Geographic Coordinate Systems**: A Geographic coordinate system contains information on the datum (which implies an spheroid described by a semi-major axis, and inverse flattening), prime meridian (normally Greenwich), and an angular units type which is normally degrees.

* **Projected Coordinate Systems**: A projected coordinate system (such as UTM, Lambert Conformal Conic, etc) requires and underlying geographic coordinate system as well as a definition for the projection transform used to translate between linear positions (in meters or feet) and angular long/lat positions.

## Creating Spatial References
```@example projections
spatialref = ArchGDAL.importEPSG(2927)
```

```@example projections
ArchGDAL.toPROJ4(spatialref)
```

The details of how to interpret the results can be found in http://proj4.org/usage/projections.html.

In the above example, we constructed a `SpatialRef` object from the [EPSG Code 2927](http://spatialreference.org/ref/epsg/2927/). There are a variety of other formats from which `SpatialRef`s can be constructed, such as

* [`ArchGDAL.importEPSG(::Int)`](@ref): based on the [EPSG code](http://spatialreference.org/ref/epsg/)
* [`ArchGDAL.importEPSGA(::Int)`](@ref): based on the EPSGA code
* [`ArchGDAL.importESRI(::String)`](@ref): based on ESRI projection codes
* [`ArchGDAL.importPROJ4(::String)` based on the PROJ.4 string ([reference](http://proj4.org/usage/projections.html))
* [`ArchGDAL.importURL(::String)`](@ref): download from a given URL and feed it into `SetFromUserInput` for you.
* [`ArchGDAL.importWKT(::String)`](@ref): WKT string
* [`ArchGDAL.importXML(::String)`](@ref): XML format (GML only currently)

We currently support a few export formats too:

* [`ArchGDAL.toMICoordSys(spref)`](@ref): Mapinfo style CoordSys format.
* [`ArchGDAL.toPROJ4(spref)`](@ref): coordinate system in PROJ.4 format.
* [`ArchGDAL.toWKT(spref)`](@ref): nicely formatted WKT string for display to a person.
* [`ArchGDAL.toXML(spref)`](@ref): converts into XML format to the extent possible.

## Reprojecting a Geometry
```@example projections
source = ArchGDAL.importEPSG(2927)
```

```@example projections
target = ArchGDAL.importEPSG(4326)
```

```@example projections
ArchGDAL.createcoordtrans(source, target) do transform
    point = ArchGDAL.fromWKT("POINT (1120351.57 741921.42)")
    println("Before: $(ArchGDAL.toWKT(point))")
    ArchGDAL.transform!(point, transform)
    println("After: $(ArchGDAL.toWKT(point))")
end
```

```@example projections
using DataFrames
import GeoFormatTypes as GFT

coords = zip(rand(10), rand(10))
df = DataFrame(geom=ArchGDAL.createpoint.(coords), name="test");
df.geom = reproject(df.geom, GFT.EPSG(4326), GFT.EPSG(28992))
```

## Reprojecting from a layer
```@setup projections
# Getting vector data
ds = AG.read("/vsicurl/https://raw.githubusercontent.com/yeesian/ArchGDALDatasets/master/data/metropole.geojson")
layer = AG.getlayer(ds, 0)
```
```@example projections
# Plotting with native GEOJSON geographic CRS
p_WGS_84 = AG.getfeature(layer, 0) do feature
    AG.getgeom(feature, 0) do geom
        plot(geom; fa=0.1, title="WGS 84")
    end
end

# Plotting with local projected CRS
p_Lambert_93 = AG.getfeature(layer, 0) do feature
    AG.getgeom(feature, 0) do geom
        source = AG.getspatialref(geom)
        target = AG.importEPSG(2154)
        AG.createcoordtrans(source, target) do transform
            plot(AG.transform!(geom, transform); fa=0.1, title="Lambert 93")
        end
    end
end

plot(p_WGS_84, p_Lambert_93; size=(600, 200), layout=(1,2))
```

## References

Some background on OpenGIS coordinate systems and services can be found in the Simple Features for COM, and Spatial Reference Systems Abstract Model documents available from the [Open Geospatial Consortium](https://www.opengeospatial.org/). The [GeoTIFF Projections Transform List](http://geotiff.maptools.org/proj_list/) may also be of assistance in understanding formulations of projections in WKT. The [EPSG](http://www.epsg.org/) Geodesy web page is also a useful resource. You may also consult the [OGC WKT Coordinate System Issues](https://gdal.org/tutorials/wktproblems.html) page.
