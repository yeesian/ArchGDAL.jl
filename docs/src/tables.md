# Tabular Interface

```@setup tables
using ArchGDAL, DataFrames
```

ArchGDAL now brings in greater flexibilty in terms of vector data handling via the
[Tables.jl](https://github.com/JuliaData/Tables.jl) API. In general, tables are modelled based on feature layers and support multiple geometries per layer. Namely, the layer(s) of a dataset can be converted to DataFrame(s) to perform miscellaneous spatial operations.

Here is a quick example based on the
[`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson)
dataset:

```@example tables
dataset = ArchGDAL.read("data/point.geojson")

DataFrames.DataFrame(ArchGDAL.getlayer(dataset, 0))
```

To illustrate multiple geometries, here is a second example based on the
[`data/multi_geom.csv`](https://github.com/yeesian/ArchGDALDatasets/blob/master/data/multi_geom.csv)
dataset:

```@example tables
dataset1 = ArchGDAL.read("data/multi_geom.csv", options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])

DataFrames.DataFrame(ArchGDAL.getlayer(dataset1, 0))
```

## Feature IDs

Database-like formats (GeoPackage, PostGIS, SQLite, ...) give every feature a
persistent primary key, the *FID*. GDAL models it separately from the ordinary
fields, so it does not appear among the field definitions. Where a driver
reports such a column, via
[`ArchGDAL.fidcolumnname`](@ref), it is included as the leading column of the
table, under the name the driver gives it:

```julia
julia> dataset2 = ArchGDAL.read("data/rivers.gpkg")

julia> ArchGDAL.fidcolumnname(ArchGDAL.getlayer(dataset2, 0))
"fid"

julia> DataFrames.DataFrame(ArchGDAL.getlayer(dataset2, 0))
357×5 DataFrame
 Row │ fid    geom                     property_0  property_1      property_2
     │ Int64  IGeometry                String      String          String
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1  Geometry: wkbLineString  6           Sutlej          null
   2 │     2  Geometry: wkbLineString  4           Svernaya Dvina  null
  ⋮  │   ⋮               ⋮                 ⋮             ⋮              ⋮
```

This matches what QGIS and R's `sf` show for the same data, and the values agree
with [`ArchGDAL.getfid`](@ref) on the individual features.

Formats that carry no such column — ESRI Shapefile, FlatGeobuf and the like —
report `""` and are unaffected, gaining no extra column. A driver that reports a
FID column which is *also* an ordinary field (the GeoJSON driver does this for
`id`, where both hold the same value) keeps just the field, so the column is
never duplicated.
