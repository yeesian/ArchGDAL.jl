# Tabular Interface

```@setup tables
using ArchGDAL; AG = ArchGDAL
using DataFrames
```

ArchGDAL now brings in greater flexibilty in terms of vector data handling via the
[Tables.jl](https://github.com/JuliaData/Tables.jl) API. In general, tables are modelled based on feature layers and support multiple geometries per layer. Namely, the layer(s) of a dataset can be converted to DataFrame(s) to perform miscellaneous spatial operations.

## Conversion to table

Here is a quick example based on the
[`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson)
dataset:

```@repl tables
ds = AG.read("data/point.geojson")
DataFrame(AG.getlayer(ds, 0))
```

To illustrate multiple geometries, here is a second example based on the
[`data/multi_geom.csv`](https://github.com/yeesian/ArchGDALDatasets/blob/master/data/multi_geom.csv)
dataset:

```@repl tables
ds = AG.read("data/multi_geom.csv", options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])
DataFrame(AG.getlayer(ds, 0))
```
## Conversion to layer
A table-like source implementing Tables.jl interface can be converted to a layer, provided that:
- Source must contains at least one geometry column
- Geometry columns are recognized by their element type being a subtype of `Union{IGeometry, Nothing,  Missing}`
- Non geometry columns must contain types handled by GDAL/OGR (e.g. not `Int128` nor composite type)

**Note**: As geometries and fields are stored separately in GDAL features, the backward conversion of the layer won't have the same column ordering. Geometry columns will be the first columns.

```@repl tables
df = DataFrame([
    :point => [AG.createpoint(30, 10), missing],
    :mixedgeom => [AG.createpoint(5, 10), AG.createlinestring([(30.0, 10.0), (10.0, 30.0)])],
    :id => ["5.1", "5.2"],
    :zoom => [1.0, 2],
    :location => [missing, "New Delhi"],
])
layer = AG.IFeatureLayer(df)
```

The layer, converted from a source implementing the Tables.jl interface, will be in a memory dataset.  
Hence you can:
- Add other layers to it
- Copy it to a dataset with another driver
- Write it to a file
### Example of writing with ESRI Shapefile driver
```@repl tables
ds = AG.write(layer.ownedby, "test.shp", driver=AG.getdriver("ESRI Shapefile"))
DataFrame(AG.getlayer(AG.read("test.shp"), 0))
rm.(["test.shp", "test.shx", "test.dbf"]) # hide
```
As OGR ESRI Shapefile driver
- [does not support multi geometries](https://gdal.org/development/rfc/rfc41_multiple_geometry_fields.html#drivers), the second geometry has been dropped
- does not support nullable fields, the `missing` location has been replaced by `""`
### Example of writing with GML driver
Using the GML 3.2.1 more capable driver/format, you can write more information to the file
```@repl tables
ds = AG.write(layer.ownedby, "test.gml", driver=AG.getdriver("GML"), options=["FORMAT=GML3.2"])
DataFrame(AG.getlayer(AG.read("test.gml", options=["EXPOSE_GML_ID=NO"]), 0))
rm.(["test.gml", "test.xsd"]) # hide
```
**Note:** [OGR GML driver](https://gdal.org/drivers/vector/gml.html#open-options) option **EXPOSE\_GML\_ID=NO** avoids to read the `gml_id` field, mandatory in GML 3.x format and automatically created by the OGR GML driver
