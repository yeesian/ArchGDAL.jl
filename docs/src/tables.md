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
- Geometry columns are of type `<: Union{IGeometry, Nothing,  Missing}`
- Object contains at least one column of geometries 
- Non geometry columns contains types handled by GDAL (e.g. not `Int128` nor composite type)

_Note: as geometries and fields are stored separately in GDAL features, the backward conversion of the layer won't have the same column ordering. Geometry columns will be the first columns._

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

The layer converted from a source implementing the Tables.jl interface, will be in a memory dataset. Hence you can:
- Add other layers to it
- Copy it to a dataset with another driver
- Write it to a file

```@repl tables
ds = AG.write(layer.ownedby, "test.shp", driver=AG.getdriver("ESRI Shapefile"))
DataFrame(AG.getlayer(AG.read("test.shp"), 0))
rm.(["test.shp", "test.shx", "test.dbf"]) # hide
```
_Note: As GDAL "ESRI Shapefile" driver_
- _does not support multi geometries, the second geometry has been dropped_
- _does not support nullable fields, the `missing` location has been replaced by `""`_
